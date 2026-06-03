import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_config_exception.dart';
import '../logging/dots_logger.dart';
import '../render/dots_font_bundle.dart';
import 'dots_cover_design.dart';
import 'dots_cover_geometry.dart';
import 'dots_cover_template.dart';

/// Renders a [DotsCoverTemplate] into a single-page PDF.
///
/// This is a separate code path from the interior body-block
/// renderer: the page size comes from [DotsCoverGeometry] (not from a
/// `DotsTemplate`), and only one page is ever emitted.
///
/// The cover layout depends on `template.design`:
///
/// - [DotsCoverDesign.square]: front artwork is rendered as a rectangle
///   covering 80% × 80% of the front panel, anchored 10 mm above the
///   trim bottom and 10 mm left of the trim right of the front panel.
///   The rest of the cover is painted with the background color.
/// - [DotsCoverDesign.circle]: front artwork is rendered as a circular
///   clip centred on the front panel; the diameter is 50% of the
///   front-panel width (so the shape stays a true circle even though
///   the panel is portrait). The rest of the cover is painted with the
///   background color.
/// - [DotsCoverDesign.linen]: front artwork is rendered as a horizontal
///   strip spanning the full cover width (back panel + spine + front
///   panel, including wraps). The strip's vertical centerline sits at
///   40% from the bottom of the cover; its height is derived from the
///   source aspect ratio so the image keeps its natural shape.
///
/// Optional spine artwork, spine title, and crop marks are drawn the
/// same way for every design. Each design enforces a minimum source
/// pixel size via [DotsCoverDesign]; the renderer eagerly validates
/// incoming artworks and throws [DotsConfigException] when the source
/// is too small.
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

  /// Millimetres → PDF points multiplier (1 mm = 2.834645669 pt).
  ///
  /// Matches the canonical constant in `docs/specs/00-foundation.md`
  /// and the interior renderer.
  static const double _mmToPt = 2.834645669;

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
      'DotsCoverRenderer: rendering ${template.design.name} cover for '
      '"${template.documentId}" to "$outputPath"',
    );

    final DotsCoverGeometry geometry = template.geometry;
    final double pageWidthMm = geometry.totalCoverWidthInclBleedMm;
    final double pageHeightMm = geometry.totalCoverHeightInclBleedMm;
    final double pageWidthPt = pageWidthMm * _mmToPt;
    final double pageHeightPt = pageHeightMm * _mmToPt;
    final PdfPageFormat format = PdfPageFormat(pageWidthPt, pageHeightPt);

    // --- Panel geometry, mm, top-left origin -----------------------
    const double bleedMm = DotsCoverGeometry.bleedMm;
    const double wrapMm = DotsCoverGeometry.wrapMm;
    const double hinchMm = DotsCoverGeometry.hinchMm;
    final double panelWidthMm = geometry.frontBackWidthMm;
    final double panelHeightMm = geometry.bookBlockHeightInclBleedMm;
    final double spineWidthMm = geometry.spineWidthMm;

    const double backPanelXMm = bleedMm + wrapMm;
    const double panelYMm = bleedMm + wrapMm;
    final double spineXMm = backPanelXMm + panelWidthMm + hinchMm;
    final double frontPanelXMm = spineXMm + spineWidthMm + hinchMm;

    final PdfColor backgroundColor = _parseColor(template.backgroundColorHex);

    final List<pw.Widget> children = <pw.Widget>[];

    // --- 1. Background fill ---------------------------------------
    children.add(
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.Container(
          width: pageWidthPt,
          height: pageHeightPt,
          color: backgroundColor,
        ),
      ),
    );

    // --- 2. Design-specific artwork -------------------------------
    switch (template.design) {
      case DotsCoverDesign.square:
        children.add(
          await _buildSquareArtwork(
            assetPath: template.frontArtworkPath,
            frontPanelXMm: frontPanelXMm,
            frontPanelYMm: panelYMm,
            panelWidthMm: panelWidthMm,
            panelHeightMm: panelHeightMm,
          ),
        );
      case DotsCoverDesign.circle:
        children.add(
          await _buildCircleArtwork(
            assetPath: template.frontArtworkPath,
            frontPanelXMm: frontPanelXMm,
            frontPanelYMm: panelYMm,
            panelWidthMm: panelWidthMm,
            panelHeightMm: panelHeightMm,
          ),
        );
      case DotsCoverDesign.linen:
        children.add(
          await _buildLinenArtwork(
            assetPath: template.frontArtworkPath,
            pageWidthMm: pageWidthMm,
            pageHeightMm: pageHeightMm,
          ),
        );
    }

    // --- 3. Optional spine artwork --------------------------------
    if (template.spineArtworkPath != null &&
        template.spineArtworkPath!.isNotEmpty) {
      children.add(
        await _buildArtworkLayer(
          assetPath: template.spineArtworkPath!,
          panelXMm: spineXMm,
          panelYMm: panelYMm,
          panelWidthMm: spineWidthMm,
          panelHeightMm: panelHeightMm,
          wrapMm: 0,
        ),
      );
    }

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

    // --- 5. Crop marks (europa only) ------------------------------
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

  /// Loads bytes, decodes the source pixel dimensions, validates them
  /// against [design], and returns a `(bytes, width, height)` triple.
  ///
  /// Throws [DotsConfigException] when the image is below the minimum
  /// pixel size declared by the design.
  Future<_DecodedArtwork> _loadAndValidate({
    required final String assetPath,
    required final DotsCoverDesign design,
  }) async {
    final Uint8List bytes = await _fs.file(assetPath).readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw DotsConfigException(
        'cover artwork "$assetPath" could not be decoded as an image.',
        pointer: r'$.frontArtworkPath',
      );
    }
    if (decoded.width < design.minSourceWidthPx ||
        decoded.height < design.minSourceHeightPx) {
      throw DotsConfigException(
        'cover artwork "$assetPath" is ${decoded.width}×${decoded.height}px, '
        'below the minimum '
        '${design.minSourceWidthPx}×${design.minSourceHeightPx}px '
        'required by the ${design.name} design.',
        pointer: r'$.frontArtworkPath',
      );
    }
    return _DecodedArtwork(
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
    );
  }

  /// Builds the front-panel square artwork: 80% w × 80% h of the front
  /// panel, anchored to the bottom-right with 10 mm of padding from
  /// the trim edges.
  Future<pw.Widget> _buildSquareArtwork({
    required final String assetPath,
    required final double frontPanelXMm,
    required final double frontPanelYMm,
    required final double panelWidthMm,
    required final double panelHeightMm,
  }) async {
    final _DecodedArtwork artwork = await _loadAndValidate(
      assetPath: assetPath,
      design: DotsCoverDesign.square,
    );
    final pw.MemoryImage image = pw.MemoryImage(artwork.bytes);

    final double squareWidthMm = panelWidthMm * 0.8;
    final double squareHeightMm = panelHeightMm * 0.8;
    const double paddingMm = 10;

    final double trimRightMm = frontPanelXMm + panelWidthMm;
    final double trimBottomMm = frontPanelYMm + panelHeightMm;
    final double leftMm = trimRightMm - paddingMm - squareWidthMm;
    final double topMm = trimBottomMm - paddingMm - squareHeightMm;

    return pw.Positioned(
      left: leftMm * _mmToPt,
      top: topMm * _mmToPt,
      child: pw.Image(
        image,
        width: squareWidthMm * _mmToPt,
        height: squareHeightMm * _mmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  /// Builds the front-panel circle artwork: a true circle centred on
  /// the front panel, diameter = 50% of the front-panel width.
  Future<pw.Widget> _buildCircleArtwork({
    required final String assetPath,
    required final double frontPanelXMm,
    required final double frontPanelYMm,
    required final double panelWidthMm,
    required final double panelHeightMm,
  }) async {
    final _DecodedArtwork artwork = await _loadAndValidate(
      assetPath: assetPath,
      design: DotsCoverDesign.circle,
    );
    final pw.MemoryImage image = pw.MemoryImage(artwork.bytes);

    // The user spec says "covers 50% height and 50% of the width".
    // The panel is portrait (199 × 254 mm), so 50% of each dimension
    // gives a 99.5 × 127 mm rectangle. To keep the shape an actual
    // circle, use the smaller of the two as the diameter.
    final double diameterMm =
        math.min(panelWidthMm * 0.5, panelHeightMm * 0.5);
    final double leftMm =
        frontPanelXMm + (panelWidthMm - diameterMm) / 2.0;
    final double topMm =
        frontPanelYMm + (panelHeightMm - diameterMm) / 2.0;
    final double diameterPt = diameterMm * _mmToPt;

    return pw.Positioned(
      left: leftMm * _mmToPt,
      top: topMm * _mmToPt,
      child: pw.SizedBox(
        width: diameterPt,
        height: diameterPt,
        child: pw.ClipOval(
          child: pw.Image(image, fit: pw.BoxFit.cover),
        ),
      ),
    );
  }

  /// Builds the linen-design horizontal strip: spans the full cover
  /// width (back + spine + front, incl. wraps), centerline at 40% from
  /// the bottom of the cover, height derived from the source aspect
  /// ratio so the image is not distorted.
  Future<pw.Widget> _buildLinenArtwork({
    required final String assetPath,
    required final double pageWidthMm,
    required final double pageHeightMm,
  }) async {
    final _DecodedArtwork artwork = await _loadAndValidate(
      assetPath: assetPath,
      design: DotsCoverDesign.linen,
    );
    final pw.MemoryImage image = pw.MemoryImage(artwork.bytes);

    final double stripWidthMm = pageWidthMm;
    final double stripHeightMm = stripWidthMm * artwork.height / artwork.width;
    // Vertical centerline at 40% from the bottom -> 60% from the top.
    final double centerlineYMm = pageHeightMm * 0.6;
    final double topMm = centerlineYMm - stripHeightMm / 2.0;

    return pw.Positioned(
      left: 0,
      top: topMm * _mmToPt,
      child: pw.Image(
        image,
        width: stripWidthMm * _mmToPt,
        height: stripHeightMm * _mmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
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
  /// without crop marks (see `DotsSupplier.drawsCropMarks`); the
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

    addHorizontal(trimLeftMm - _cropMarkLengthMm, trimTopMm);
    addVertical(trimLeftMm, trimTopMm - _cropMarkLengthMm);

    addHorizontal(trimRightMm, trimTopMm);
    addVertical(trimRightMm - _cropMarkStrokeMm, trimTopMm - _cropMarkLengthMm);

    addHorizontal(
      trimLeftMm - _cropMarkLengthMm,
      trimBottomMm - _cropMarkStrokeMm,
    );
    addVertical(trimLeftMm, trimBottomMm);

    addHorizontal(trimRightMm, trimBottomMm - _cropMarkStrokeMm);
    addVertical(trimRightMm - _cropMarkStrokeMm, trimBottomMm);

    return marks;
  }

  /// Parses an `#RRGGBB` (or `RRGGBB`) hex string into a [PdfColor].
  ///
  /// Falls back to white on malformed input — the renderer is best-effort
  /// here because the background fill is a finish, not a structural
  /// invariant; throwing would punish callers for a typo that is easy
  /// to spot visually.
  PdfColor _parseColor(final String hex) {
    final String trimmed = hex.startsWith('#') ? hex.substring(1) : hex;
    if (trimmed.length != 6) return PdfColors.white;
    final int? value = int.tryParse(trimmed, radix: 16);
    if (value == null) return PdfColors.white;
    final double r = ((value >> 16) & 0xff) / 255.0;
    final double g = ((value >> 8) & 0xff) / 255.0;
    final double b = (value & 0xff) / 255.0;
    return PdfColor(r, g, b);
  }
}

class _DecodedArtwork {
  const _DecodedArtwork({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
