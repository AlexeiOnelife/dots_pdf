import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logging/dots_logger.dart';
import '../render/dots_font_bundle.dart';
import 'dots_cover_geometry.dart';
import 'dots_cover_template.dart';

/// Renders a [DotsCoverTemplate] into a single-page PDF.
///
/// This is a separate code path from the interior body-block
/// renderer: the page size comes from [DotsCoverGeometry] (not from a
/// `DotsTemplate`), and only one page is ever emitted.
///
/// Drawing order is:
///
/// 1. Back-cover artwork (left panel, including wrap overhang).
/// 2. Optional spine artwork (centre column).
/// 3. Front-cover artwork (right panel, including wrap overhang).
/// 4. Optional spine title, rotated 90° and centred on the spine.
/// 5. Crop marks at the four trim corners — only when
///    [DotsCoverGeometry.supplier] has `drawsCropMarks == true`
///    (i.e. europa; latam ships without crop marks per
///    `SPECS.md` resolved clarification #1).
///
/// Each artwork is authored at the panel's board dimensions
/// (front/back = 199 × 260 mm); the renderer extends the image into
/// the surrounding 20 mm wrap by drawing it on a panel rectangle that
/// includes the wrap band (`pw.BoxFit.cover` keeps the centre stable
/// and samples edge pixels into the wrap).
///
/// All per-artwork image bytes are read lazily and released between
/// panels (no list-of-images is retained beyond the `pw.Stack`
/// children list, which only ever holds 2–4 widgets).
class DotsCoverRenderer {
  /// Creates a cover renderer.
  ///
  /// [fileSystem] backs every artwork read; pass `LocalFileSystem()`
  /// in app code and `MemoryFileSystem()` in tests. [logger] is the
  /// injected logger — the renderer never calls `print` directly.
  ///
  /// [fontBundle] supplies the typography used for the optional spine
  /// title (P22 Mackinac medium). When `null`, the spine title falls
  /// back to the pdf package's built-in Helvetica.
  DotsCoverRenderer({
    required FileSystem fileSystem,
    required DotsLogger logger,
    DotsFontBundle? fontBundle,
  })  : _fs = fileSystem,
        _log = logger,
        _fontBundle = fontBundle;

  final FileSystem _fs;
  final DotsLogger _log;
  final DotsFontBundle? _fontBundle;
  pw.Font? _spineTitleFont;

  /// Returns the P22 Mackinac medium font for spine-title rendering,
  /// parsing the bytes once and caching the result. Returns `null`
  /// when no font bundle is wired.
  pw.Font? _resolveSpineTitleFont() {
    final bundle = _fontBundle;
    if (bundle == null) return null;
    return _spineTitleFont ??= pw.Font.ttf(
      ByteData.sublistView(bundle.p22MackinacMedium),
    );
  }

  /// Millimetres → PDF points multiplier (1 mm = 2.834645 pt).
  static const double _mmToPt = 2.834645;

  /// Crop-mark tick length in millimetres.
  ///
  /// Each tick is two perpendicular 3 mm strokes that meet at the
  /// trim corner; this matches the standard PDF/X-4 crop-mark length.
  static const double _cropMarkLengthMm = 3;

  /// Crop-mark stroke thickness in millimetres.
  static const double _cropMarkStrokeMm = 0.25;

  /// Renders [template] into a single-page PDF at [outputPath].
  ///
  /// The output file is overwritten if it exists. Image bytes are
  /// read on demand per panel and not retained between iterations.
  Future<void> render({
    required DotsCoverTemplate template,
    required String outputPath,
  }) async {
    _log.info(
      'DotsCoverRenderer: rendering cover for '
      '"${template.documentId}" to "$outputPath"',
    );

    final DotsCoverGeometry geometry = template.geometry;
    final double pageWidthPt = geometry.totalCoverWidthInclBleedMm * _mmToPt;
    final double pageHeightPt = geometry.totalCoverHeightInclBleedMm * _mmToPt;
    final PdfPageFormat format = PdfPageFormat(pageWidthPt, pageHeightPt);

    final List<pw.Widget> children = <pw.Widget>[];

    // --- Panel geometry, mm, top-left origin -----------------------
    const double bleedMm = DotsCoverGeometry.bleedMm;
    const double wrapMm = DotsCoverGeometry.wrapMm;
    const double hinchMm = DotsCoverGeometry.hinchMm;
    final double panelWidthMm = geometry.frontBackWidthMm;
    final double panelHeightMm = geometry.bookBlockHeightInclBleedMm;
    final double spineWidthMm = geometry.spineWidthMm;

    // Back panel: bleed + wrap inset from the top-left corner.
    const double backPanelXMm = bleedMm + wrapMm;
    const double panelYMm = bleedMm + wrapMm;
    // Spine column begins immediately after back panel + hinch.
    final double spineXMm = backPanelXMm + panelWidthMm + hinchMm;
    // Front panel begins after the spine and the right-hand hinch.
    final double frontPanelXMm = spineXMm + spineWidthMm + hinchMm;

    // --- 1. Back-cover artwork (extends into surrounding wrap) -----
    children.add(
      await _buildArtworkLayer(
        assetPath: template.backArtworkPath,
        panelXMm: backPanelXMm,
        panelYMm: panelYMm,
        panelWidthMm: panelWidthMm,
        panelHeightMm: panelHeightMm,
        wrapMm: wrapMm,
      ),
    );

    // --- 2. Optional spine artwork ---------------------------------
    if (template.spineArtworkPath != null &&
        template.spineArtworkPath!.isNotEmpty) {
      children.add(
        await _buildArtworkLayer(
          assetPath: template.spineArtworkPath!,
          panelXMm: spineXMm,
          panelYMm: panelYMm,
          panelWidthMm: spineWidthMm,
          panelHeightMm: panelHeightMm,
          // No wrap on the spine — it is bounded by the two hinches.
          wrapMm: 0,
        ),
      );
    }

    // --- 3. Front-cover artwork (extends into surrounding wrap) ----
    children.add(
      await _buildArtworkLayer(
        assetPath: template.frontArtworkPath,
        panelXMm: frontPanelXMm,
        panelYMm: panelYMm,
        panelWidthMm: panelWidthMm,
        panelHeightMm: panelHeightMm,
        wrapMm: wrapMm,
      ),
    );

    // --- 4. Optional spine title ----------------------------------
    final String? spineTitle = template.spineTitle;
    if (spineTitle != null && spineTitle.isNotEmpty) {
      children.add(
        _buildSpineTitle(
          title: spineTitle,
          fontSizePt: template.spineTitleFontSize,
          spineXMm: spineXMm,
          panelYMm: panelYMm,
          spineWidthMm: spineWidthMm,
          panelHeightMm: panelHeightMm,
        ),
      );
    }

    // --- 5. Crop marks (europa only) -------------------------------
    if (geometry.supplier.drawsCropMarks) {
      children.addAll(
        _buildCropMarks(
          trimLeftMm: backPanelXMm,
          trimTopMm: panelYMm,
          trimRightMm: frontPanelXMm + panelWidthMm,
          trimBottomMm: panelYMm + panelHeightMm,
        ),
      );
    }

    // --- Assemble + write -----------------------------------------
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (final pw.Context context) => pw.Stack(children: children),
      ),
    );

    final Uint8List bytes = await doc.save();
    final IOSink sink = _fs.file(outputPath).openWrite();
    try {
      sink.add(bytes);
    } finally {
      await sink.close();
    }
  }

  /// Builds a positioned image widget for a single artwork panel.
  ///
  /// The rectangle is expanded by [wrapMm] on each side so the image
  /// bleeds into the wrap allowance. `pw.BoxFit.cover` keeps the
  /// authored centre in place and samples outer pixels into the wrap.
  Future<pw.Widget> _buildArtworkLayer({
    required final String assetPath,
    required final double panelXMm,
    required final double panelYMm,
    required final double panelWidthMm,
    required final double panelHeightMm,
    required final double wrapMm,
  }) async {
    final Uint8List bytes = await _fs.file(assetPath).readAsBytes();
    final pw.MemoryImage image = pw.MemoryImage(bytes);

    final double leftMm = panelXMm - wrapMm;
    final double topMm = panelYMm - wrapMm;
    final double widthMm = panelWidthMm + 2 * wrapMm;
    final double heightMm = panelHeightMm + 2 * wrapMm;

    return pw.Positioned(
      left: leftMm * _mmToPt,
      top: topMm * _mmToPt,
      child: pw.Image(
        image,
        width: widthMm * _mmToPt,
        height: heightMm * _mmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  /// Builds the centred, rotated spine title widget.
  ///
  /// The text is rotated −π/2 (reading bottom-to-top when the cover
  /// lies flat), then anchored at the spine's geometric centre.
  pw.Widget _buildSpineTitle({
    required final String title,
    required final double fontSizePt,
    required final double spineXMm,
    required final double panelYMm,
    required final double spineWidthMm,
    required final double panelHeightMm,
  }) {
    // pw.Transform.rotate rotates about the child's centre, which is
    // why we wrap the rotated Text inside a Center → SizedBox that
    // sizes the spine band; positioning the band's top-left gives us
    // a deterministic anchor for the rotated label.
    final double spineWidthPt = spineWidthMm * _mmToPt;
    final double panelHeightPt = panelHeightMm * _mmToPt;
    return pw.Positioned(
      left: spineXMm * _mmToPt,
      top: panelYMm * _mmToPt,
      child: pw.SizedBox(
        width: spineWidthPt,
        height: panelHeightPt,
        child: pw.Center(
          child: pw.Transform.rotate(
            angle: -math.pi / 2,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: fontSizePt,
                font: _resolveSpineTitleFont(),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds eight thin rectangles — two perpendicular strokes per
  /// trim corner — used as crop marks by Europa-region printers.
  ///
  /// Each "tick" sits **outside** the trim rectangle: it starts at
  /// the corner and extends [_cropMarkLengthMm] into the wrap area,
  /// matching standard PDF/X-4 crop-mark conventions. Latam ships
  /// without crop marks (see [DotsSupplier.drawsCropMarks]); the
  /// renderer skips this whole block in that case.
  List<pw.Widget> _buildCropMarks({
    required final double trimLeftMm,
    required final double trimTopMm,
    required final double trimRightMm,
    required final double trimBottomMm,
  }) {
    const double lengthPt = _cropMarkLengthMm * _mmToPt;
    const double strokePt = _cropMarkStrokeMm * _mmToPt;
    final List<pw.Widget> marks = <pw.Widget>[];

    void addHorizontal(final double leftMm, final double topMm) {
      marks.add(
        pw.Positioned(
          left: leftMm * _mmToPt,
          top: topMm * _mmToPt,
          child: pw.Container(
            width: lengthPt,
            height: strokePt,
            color: PdfColors.black,
          ),
        ),
      );
    }

    void addVertical(final double leftMm, final double topMm) {
      marks.add(
        pw.Positioned(
          left: leftMm * _mmToPt,
          top: topMm * _mmToPt,
          child: pw.Container(
            width: strokePt,
            height: lengthPt,
            color: PdfColors.black,
          ),
        ),
      );
    }

    // Top-left corner: horizontal stroke extending left, vertical
    // stroke extending up (both into the wrap area).
    addHorizontal(trimLeftMm - _cropMarkLengthMm, trimTopMm);
    addVertical(trimLeftMm, trimTopMm - _cropMarkLengthMm);

    // Top-right corner.
    addHorizontal(trimRightMm, trimTopMm);
    addVertical(trimRightMm - _cropMarkStrokeMm, trimTopMm - _cropMarkLengthMm);

    // Bottom-left corner.
    addHorizontal(
      trimLeftMm - _cropMarkLengthMm,
      trimBottomMm - _cropMarkStrokeMm,
    );
    addVertical(trimLeftMm, trimBottomMm);

    // Bottom-right corner.
    addHorizontal(trimRightMm, trimBottomMm - _cropMarkStrokeMm);
    addVertical(trimRightMm - _cropMarkStrokeMm, trimBottomMm);

    return marks;
  }
}
