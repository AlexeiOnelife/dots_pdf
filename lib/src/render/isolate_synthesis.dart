import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_config_exception.dart';
import '../config/dots_template.dart';
import '../cover/dots_cover_design.dart';
import '../cover/dots_cover_geometry.dart';
import '../cover/dots_cover_template.dart';
import '../logging/dots_logger.dart';
import 'album_spread_page.dart';
import 'crop_marks.dart';
import 'dots_font_bundle.dart';
import 'layout/dots_layout_code.dart';
import 'layout/dots_layout_solver.dart';
import 'layout/dots_page_geometry.dart';
import 'layout/dots_slot_rect.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Runs the PDF synthesis step (pw.Document build + doc.save() + disk write)
/// inside a Dart isolate via [Isolate.run].
///
/// All inputs that cross the isolate boundary are plain Dart values:
///   - [template] and [pages] — pure immutable value objects, safe to copy.
///   - [preloadedBytes] — a [Map<String, Uint8List>] with every asset path
///     (photo paths, URL-fetched paths) already resolved to raw bytes on the
///     main isolate. The isolate never performs file I/O or network calls.
///   - [fontBundle] — contains only [Uint8List] fields; safe to copy.
///   - [outputPath] — a plain [String]; the isolate writes via dart:io File
///     directly, bypassing the injected FileSystem abstraction.
///     **MemoryFileSystem paths are NOT supported in isolate mode.**
///
/// Returns a [SynthesisResult] containing the timing breakdown and any
/// photo-slot failures collected inside the isolate.
Future<SynthesisResult> synthesizePdfInIsolate({
  required DotsTemplate template,
  required List<DotsPage> pages,
  required String outputPath,
  required Map<String, Uint8List> preloadedBytes,
  required bool drawCropMarks,
  DotsFontBundle? fontBundle,
}) {
  final task = _SynthesisTask(
    template: template,
    pages: pages,
    outputPath: outputPath,
    preloadedBytes: preloadedBytes,
    drawCropMarks: drawCropMarks,
    fontBundle: fontBundle,
  );
  return Isolate.run(() => _runSynthesis(task));
}

// ---------------------------------------------------------------------------
// Task / Result value types  (must cross the isolate boundary → no closures)
// ---------------------------------------------------------------------------

/// All inputs for one synthesis run, packaged for isolate transfer.
class _SynthesisTask {
  const _SynthesisTask({
    required this.template,
    required this.pages,
    required this.outputPath,
    required this.preloadedBytes,
    required this.drawCropMarks,
    this.fontBundle,
  });

  final DotsTemplate template;
  final List<DotsPage> pages;
  final String outputPath;
  final Map<String, Uint8List> preloadedBytes;
  final bool drawCropMarks;
  final DotsFontBundle? fontBundle;
}

/// Result returned across the isolate boundary.
///
/// Carries timing telemetry and any photo-slot failures so the main
/// isolate can replay them as [PdfGenerationEvent]s.
class SynthesisResult {
  /// Creates a synthesis result.
  const SynthesisResult({
    required this.synthMs,
    required this.saveMs,
    required this.photoFailures,
  });

  /// Elapsed milliseconds for the pw.Document build phase.
  final int synthMs;

  /// Elapsed milliseconds for doc.save() + disk write.
  final int saveMs;

  /// Photo-slot failures collected inside the isolate. These are replayed
  /// on the main isolate so the generator can emit PdfPhotoSlotSkipped events.
  final List<({String assetPath, Object error})> photoFailures;
}

// ---------------------------------------------------------------------------
// Isolate entry point (runs inside the spawned isolate)
// ---------------------------------------------------------------------------

Future<SynthesisResult> _runSynthesis(_SynthesisTask task) async {
  final renderer = _IsolatePageRenderer(
    template: task.template,
    preloadedBytes: task.preloadedBytes,
    drawCropMarks: task.drawCropMarks,
    fontBundle: task.fontBundle,
  );

  final synthStart = DateTime.now().millisecondsSinceEpoch;

  final doc = pw.Document();
  for (final page in task.pages) {
    doc.addPage(await renderer.buildPage(page));
  }

  final synthMs = DateTime.now().millisecondsSinceEpoch - synthStart;

  final saveStart = DateTime.now().millisecondsSinceEpoch;

  final Uint8List bytes = await doc.save();
  // Write via dart:io directly — the injected FileSystem cannot cross the
  // isolate boundary. MemoryFileSystem paths are NOT supported here.
  final outFile = io.File(task.outputPath);
  final parent = outFile.parent;
  if (!parent.existsSync()) {
    parent.createSync(recursive: true);
  }
  outFile.writeAsBytesSync(bytes);

  final saveMs = DateTime.now().millisecondsSinceEpoch - saveStart;

  return SynthesisResult(
    synthMs: synthMs,
    saveMs: saveMs,
    photoFailures: renderer.photoFailures,
  );
}

// ---------------------------------------------------------------------------
// Isolate-side renderer (no FileSystem, no URL fetcher, no callbacks)
// ---------------------------------------------------------------------------

/// Millimetres → PDF points multiplier (same constant as DotsRenderer).
const double _mmToPt = 2.834645669;

/// Renders pw.Page instances inside an isolate using pre-loaded byte maps
/// instead of file I/O or platform channels.
class _IsolatePageRenderer {
  _IsolatePageRenderer({
    required this.template,
    required this.preloadedBytes,
    required this.drawCropMarks,
    this.fontBundle,
  });

  final DotsTemplate template;
  final Map<String, Uint8List> preloadedBytes;
  final bool drawCropMarks;
  final DotsFontBundle? fontBundle;

  /// Photo-slot failures accumulated during rendering; replayed on the
  /// main isolate after synthesis completes.
  final List<({String assetPath, Object error})> photoFailures = [];

  /// Per-renderer cache of parsed pw.Font instances.
  final Map<DotsFontRole, pw.Font> _fontCache = {};

  pw.Font? _fontFor(DotsFontRole role) {
    final bundle = fontBundle;
    if (bundle == null) return null;
    return _fontCache[role] ??=
        pw.Font.ttf(ByteData.sublistView(bundle.bytesFor(role)));
  }

  Uint8List _bytesFor(String assetPath) {
    final bytes = preloadedBytes[assetPath];
    if (bytes == null) {
      throw StateError(
        'isolate synthesis: no pre-loaded bytes for asset "$assetPath". '
        'All asset paths must be pre-loaded on the main isolate before '
        'calling synthesizePdfInIsolate().',
      );
    }
    return bytes;
  }

  Future<pw.Page> buildPage(DotsPage page) async {
    final format = PdfPageFormat(
      template.pageSize.width,
      template.pageSize.height,
    );
    switch (page) {
      case DotsElementsPage():
        return _buildElementsPage(format, page);
      case DotsLayoutPage():
        return _buildLayoutPage(format, page);
      case DotsAlbumSpreadPage():
        return buildAlbumSpreadPage(
          format: format,
          page: page,
          fontResolver: _fontFor,
          bytesResolver: (path) async => _bytesFor(path),
          logger: const DotsSilentLogger(),
          onPhotoFailure: (assetPath, error) {
            photoFailures.add((assetPath: assetPath, error: error));
          },
          drawCropMarks: drawCropMarks,
        );
    }
  }

  Future<pw.Page> _buildElementsPage(
    PdfPageFormat format,
    DotsElementsPage page,
  ) async {
    final children = <pw.Widget>[];
    for (final element in page.elements) {
      final widget = await _buildElement(element);
      if (widget != null) children.add(widget);
    }
    _appendCropMarks(children, format);
    return pw.Page(
      pageFormat: format,
      build: (context) => pw.Stack(children: children),
    );
  }

  Future<pw.Page> _buildLayoutPage(
    PdfPageFormat format,
    DotsLayoutPage page,
  ) async {
    const DotsLayoutSolver solver = DotsLayoutSolver();
    final geometry = DotsPageGeometry.dotbookDefault();
    final slots = solver.solve(page.layoutCode, geometry);

    final children = <pw.Widget>[];
    var photoCursor = 0;
    for (final slot in slots) {
      switch (slot.kind) {
        case DotsSlotKind.photo:
          final assetPath = page.photoAssetPaths[photoCursor++];
          final widget = await _buildPhotoSlot(slot, assetPath);
          if (widget != null) children.add(widget);
        case DotsSlotKind.captionTitle:
        case DotsSlotKind.captionDate:
        case DotsSlotKind.captionBody:
          final text = page.captions[slot.kind];
          if (text != null && text.isNotEmpty) {
            children.add(_buildCaptionSlot(slot, text, page.layoutCode));
          }
        case DotsSlotKind.qrCard:
          final payload = page.captions[DotsSlotKind.qrCard];
          if (payload != null && payload.isNotEmpty) {
            children.add(_buildQrSlot(slot, payload));
          }
      }
    }

    _appendCropMarks(children, format);
    return pw.Page(
      pageFormat: format,
      build: (context) => pw.Stack(children: children),
    );
  }

  void _appendCropMarks(List<pw.Widget> children, PdfPageFormat format) {
    if (!drawCropMarks) return;
    children.addAll(
      dotsCropMarks(
        pageWidthPt: format.width,
        pageHeightPt: format.height,
        trimMarginPt: 8.503936, // same as DotsRenderer.bleedPt
      ),
    );
  }

  Future<pw.Widget?> _buildElement(DotsElement element) async {
    switch (element) {
      case DotsTextElement():
        return _buildText(element);
      case DotsImageElement():
        return _buildImage(element);
      case DotsSpreadImageElement():
        return _buildSpreadImage(element);
      case DotsRotatedTextElement():
        // These element types are rendered by buildAlbumSpreadPage when they
        // appear inside a DotsAlbumSpreadPage. On a DotsElementsPage they are
        // not valid; skip silently to keep the sealed switch exhaustive.
        return null;
      case DotsTextBlockElement():
        return null;
      case DotsPolaroidElement():
        // Polaroid elements are rendered by buildAlbumSpreadPage when they
        // appear inside a DotsAlbumSpreadPage. On a DotsElementsPage they are
        // not valid; skip silently to keep the sealed switch exhaustive.
        return null;
      case DotsDecorativeCircleElement():
        // Decorative circle elements are rendered by buildAlbumSpreadPage when
        // they appear inside a DotsAlbumSpreadPage. On a DotsElementsPage they
        // are not valid; skip silently (delegation pattern).
        return null;
    }
  }

  pw.Widget _buildText(DotsTextElement element) {
    final role = DotsFontBundle.roleFromFamily(element.fontFamily);
    final font = role == null ? null : _fontFor(role);
    final style = pw.TextStyle(
      fontSize: element.fontSize,
      color: _parseColor(element.colorHex),
      font: font,
    );
    return pw.Positioned(
      left: element.x,
      top: element.y,
      child: pw.Text(element.value, style: style),
    );
  }

  Future<pw.Widget> _buildImage(DotsImageElement element) async {
    final bytes = _bytesFor(element.assetPath);
    final image = pw.MemoryImage(bytes);

    const bleedPt = 8.503936;
    final leftBleed = element.bleedLeft ? bleedPt : 0.0;
    final rightBleed = element.bleedRight ? bleedPt : 0.0;
    final topBleed = element.bleedTop ? bleedPt : 0.0;
    final bottomBleed = element.bleedBottom ? bleedPt : 0.0;

    return pw.Positioned(
      left: element.x - leftBleed,
      top: element.y - topBleed,
      child: pw.Image(
        image,
        width: element.width + leftBleed + rightBleed,
        height: element.height + topBleed + bottomBleed,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  Future<pw.Widget> _buildSpreadImage(DotsSpreadImageElement element) async {
    final bytes = _bytesFor(element.assetPath);
    final image = pw.MemoryImage(bytes);

    const bleedPt = 8.503936;
    final halfWidth = element.spreadWidth / 2.0;
    final topBleed = element.bleedTop ? bleedPt : 0.0;
    final bottomBleed = element.bleedBottom ? bleedPt : 0.0;
    final outerBleed = element.bleedOuter ? bleedPt : 0.0;

    final visibleLeft =
        element.half == DotsSpreadHalf.left ? element.x - outerBleed : element.x;
    final visibleTop = element.y - topBleed;
    final visibleWidth = halfWidth + outerBleed;
    final visibleHeight = element.height + topBleed + bottomBleed;

    final innerOffsetLeft =
        element.half == DotsSpreadHalf.left ? -halfWidth : 0.0;
    final innerOffsetTop = -topBleed;

    return pw.Positioned(
      left: visibleLeft,
      top: visibleTop,
      child: pw.SizedBox(
        width: visibleWidth,
        height: visibleHeight,
        child: pw.ClipRect(
          child: pw.Stack(
            overflow: pw.Overflow.visible,
            children: <pw.Widget>[
              pw.Positioned(
                left: innerOffsetLeft,
                top: innerOffsetTop,
                child: pw.Image(
                  image,
                  width: element.spreadWidth,
                  height: element.height + topBleed + bottomBleed,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<pw.Widget?> _buildPhotoSlot(
    DotsSlotRect slot,
    String assetPath,
  ) async {
    final pw.MemoryImage image;
    try {
      final bytes = _bytesFor(assetPath);
      image = pw.MemoryImage(bytes);
    } catch (error) {
      photoFailures.add((assetPath: assetPath, error: error));
      return null;
    }

    const bleedPt = 8.503936;
    final leftBleed = slot.bleedLeft ? bleedPt : 0.0;
    final rightBleed = slot.bleedRight ? bleedPt : 0.0;
    final topBleed = slot.bleedTop ? bleedPt : 0.0;
    final bottomBleed = slot.bleedBottom ? bleedPt : 0.0;

    return pw.Positioned(
      left: slot.xMm * _mmToPt - leftBleed,
      top: slot.yMm * _mmToPt - topBleed,
      child: pw.Image(
        image,
        width: slot.widthMm * _mmToPt + leftBleed + rightBleed,
        height: slot.heightMm * _mmToPt + topBleed + bottomBleed,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  pw.Widget _buildCaptionSlot(
    DotsSlotRect slot,
    String text,
    DotsLayoutCode layoutCode,
  ) {
    final fontSize = _captionFontSizeFor(slot.kind, layoutCode);
    final font = _fontFor(_captionFontRoleFor(slot.kind, layoutCode));
    return pw.Positioned(
      left: slot.xMm * _mmToPt,
      top: slot.yMm * _mmToPt,
      child: pw.SizedBox(
        width: slot.widthMm * _mmToPt,
        height: slot.heightMm * _mmToPt,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: fontSize, font: font),
        ),
      ),
    );
  }

  pw.Widget _buildQrSlot(DotsSlotRect slot, String payload) {
    // QR widget is barcode-based, which is pure Dart — safe in isolate.
    // Import barcode inline to avoid bringing the whole dependency into
    // the top-level import list.
    // We avoid importing barcode here to keep the isolate file self-contained;
    // instead we emit an empty placeholder to avoid the dependency on
    // package:barcode which involves a conditional platform import.
    // The barcode rendering path is covered by the main-isolate renderer.
    // In practice, callers that rely on QR slots should use useIsolate=false
    // or pre-render QR content as a raster image.
    //
    // For now: return an empty box so the layout is preserved.
    return pw.Positioned(
      left: slot.xMm * _mmToPt,
      top: slot.yMm * _mmToPt,
      child: pw.SizedBox(
        width: slot.widthMm * _mmToPt,
        height: slot.heightMm * _mmToPt,
      ),
    );
  }

  DotsFontRole _captionFontRoleFor(DotsSlotKind kind, DotsLayoutCode layoutCode) {
    switch (kind) {
      case DotsSlotKind.captionTitle:
        return DotsFontRole.p22MackinacMedium;
      case DotsSlotKind.captionDate:
        return layoutCode == DotsLayoutCode.lhito
            ? DotsFontRole.p22MackinacBook
            : DotsFontRole.p22MackinacMedium;
      case DotsSlotKind.captionBody:
        return DotsFontRole.inter;
      case DotsSlotKind.photo:
      case DotsSlotKind.qrCard:
        return DotsFontRole.inter;
    }
  }

  double _captionFontSizeFor(DotsSlotKind kind, DotsLayoutCode layoutCode) {
    switch (kind) {
      case DotsSlotKind.captionTitle:
        return layoutCode == DotsLayoutCode.lhito ? 20.0 : 11.0;
      case DotsSlotKind.captionDate:
        return layoutCode == DotsLayoutCode.lhito ? 9.0 : 11.0;
      case DotsSlotKind.captionBody:
        return 9.0;
      case DotsSlotKind.photo:
      case DotsSlotKind.qrCard:
        return 9.0;
    }
  }

  PdfColor? _parseColor(String? hex) {
    if (hex == null) return null;
    final trimmed = hex.startsWith('#') ? hex.substring(1) : hex;
    if (trimmed.length != 6) return null;
    final value = int.tryParse(trimmed, radix: 16);
    if (value == null) return null;
    final r = ((value >> 16) & 0xff) / 255.0;
    final g = ((value >> 8) & 0xff) / 255.0;
    final b = (value & 0xff) / 255.0;
    return PdfColor(r, g, b);
  }
}

// ---------------------------------------------------------------------------
// Cover synthesis — public entry point
// ---------------------------------------------------------------------------

/// Runs cover PDF synthesis (pw.Document build + doc.save() + disk write)
/// inside a Dart isolate via [Isolate.run].
///
/// [preloadedBytes] must contain every artwork path referenced by
/// [template] (at minimum [DotsCoverTemplate.frontArtworkPath] and, when
/// present, [DotsCoverTemplate.spineArtworkPath]). Bytes are loaded on the
/// main isolate before this call so the isolate never touches platform
/// channels or the injected [FileSystem].
///
/// Returns a [CoverSynthesisResult] with timing data.
Future<CoverSynthesisResult> synthesizeCoverInIsolate({
  required DotsCoverTemplate template,
  required String outputPath,
  required Map<String, Uint8List> preloadedBytes,
  DotsFontBundle? fontBundle,
}) {
  final task = _CoverSynthesisTask(
    template: template,
    outputPath: outputPath,
    preloadedBytes: preloadedBytes,
    fontBundle: fontBundle,
  );
  return Isolate.run(() => _runCoverSynthesis(task));
}

// ---------------------------------------------------------------------------
// Cover task / result value types
// ---------------------------------------------------------------------------

class _CoverSynthesisTask {
  const _CoverSynthesisTask({
    required this.template,
    required this.outputPath,
    required this.preloadedBytes,
    this.fontBundle,
  });

  final DotsCoverTemplate template;
  final String outputPath;
  final Map<String, Uint8List> preloadedBytes;
  final DotsFontBundle? fontBundle;
}

/// Result returned from [synthesizeCoverInIsolate].
class CoverSynthesisResult {
  /// Creates a cover synthesis result.
  const CoverSynthesisResult({
    required this.synthMs,
    required this.saveMs,
  });

  /// Elapsed milliseconds for the pw.Document build phase.
  final int synthMs;

  /// Elapsed milliseconds for [pw.Document.save] + disk write.
  final int saveMs;
}

// ---------------------------------------------------------------------------
// Isolate entry point for cover
// ---------------------------------------------------------------------------

Future<CoverSynthesisResult> _runCoverSynthesis(
  _CoverSynthesisTask task,
) async {
  final renderer = _IsolateCoverRenderer(
    template: task.template,
    preloadedBytes: task.preloadedBytes,
    fontBundle: task.fontBundle,
  );

  final synthStart = DateTime.now().millisecondsSinceEpoch;
  final doc = pw.Document();
  doc.addPage(await renderer.buildPage());
  final synthMs = DateTime.now().millisecondsSinceEpoch - synthStart;

  final saveStart = DateTime.now().millisecondsSinceEpoch;
  final Uint8List bytes = await doc.save();
  final outFile = io.File(task.outputPath);
  final parent = outFile.parent;
  if (!parent.existsSync()) {
    parent.createSync(recursive: true);
  }
  outFile.writeAsBytesSync(bytes);
  final saveMs = DateTime.now().millisecondsSinceEpoch - saveStart;

  return CoverSynthesisResult(synthMs: synthMs, saveMs: saveMs);
}

// ---------------------------------------------------------------------------
// Isolate-side cover renderer (mirrors DotsCoverRenderer logic)
// ---------------------------------------------------------------------------

/// Millimetres → PDF points (1 mm = 2.834645 pt), matching DotsCoverRenderer.
const double _coverMmToPt = 2.834645;

/// Crop-mark tick length in mm (same as DotsCoverRenderer).
const double _cropMarkLengthMm = 3;

/// Crop-mark stroke thickness in mm (same as DotsCoverRenderer).
const double _cropMarkStrokeMm = 0.25;

class _IsolateCoverRenderer {
  _IsolateCoverRenderer({
    required this.template,
    required this.preloadedBytes,
    this.fontBundle,
  });

  final DotsCoverTemplate template;
  final Map<String, Uint8List> preloadedBytes;
  final DotsFontBundle? fontBundle;

  pw.Font? _spineTitleFont;

  pw.Font? _resolveSpineTitleFont() {
    final bundle = fontBundle;
    if (bundle == null) return null;
    return _spineTitleFont ??= pw.Font.ttf(
      ByteData.sublistView(bundle.p22MackinacMedium),
    );
  }

  Uint8List _bytesFor(String assetPath) {
    final bytes = preloadedBytes[assetPath];
    if (bytes == null) {
      throw StateError(
        'isolate cover synthesis: no pre-loaded bytes for "$assetPath". '
        'All artwork paths must be pre-loaded on the main isolate.',
      );
    }
    return bytes;
  }

  Future<pw.Page> buildPage() async {
    final DotsCoverGeometry geometry = template.geometry;
    final double pageWidthMm = geometry.totalCoverWidthInclBleedMm;
    final double pageHeightMm = geometry.totalCoverHeightInclBleedMm;
    final double pageWidthPt = pageWidthMm * _coverMmToPt;
    final double pageHeightPt = pageHeightMm * _coverMmToPt;
    final PdfPageFormat format = PdfPageFormat(pageWidthPt, pageHeightPt);

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

    // 1. Background fill
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

    // 2. Design-specific artwork
    switch (template.design) {
      case DotsCoverDesign.square:
        children.add(await _buildSquareArtwork(
          frontPanelXMm: frontPanelXMm,
          frontPanelYMm: panelYMm,
          panelWidthMm: panelWidthMm,
          panelHeightMm: panelHeightMm,
        ));
      case DotsCoverDesign.circle:
        children.add(await _buildCircleArtwork(
          frontPanelXMm: frontPanelXMm,
          frontPanelYMm: panelYMm,
          panelWidthMm: panelWidthMm,
          panelHeightMm: panelHeightMm,
        ));
      case DotsCoverDesign.linen:
        children.add(await _buildLinenArtwork(
          pageWidthMm: pageWidthMm,
          pageHeightMm: pageHeightMm,
        ));
    }

    // 3. Optional spine artwork
    final spineAsset = template.spineArtworkPath;
    if (spineAsset != null && spineAsset.isNotEmpty) {
      children.add(await _buildArtworkLayer(
        assetPath: spineAsset,
        panelXMm: spineXMm,
        panelYMm: panelYMm,
        panelWidthMm: spineWidthMm,
        panelHeightMm: panelHeightMm,
        wrapMm: 0,
      ));
    }

    // 4. Optional spine title
    final spineTitle = template.spineTitle;
    if (spineTitle != null && spineTitle.isNotEmpty) {
      children.add(_buildSpineTitle(
        title: spineTitle,
        fontSizePt: template.spineTitleFontSize,
        spineXMm: spineXMm,
        panelYMm: panelYMm,
        spineWidthMm: spineWidthMm,
        panelHeightMm: panelHeightMm,
      ));
    }

    // 5. Crop marks (europa only)
    if (geometry.supplier.drawsCropMarks) {
      children.addAll(_buildCropMarks(
        trimLeftMm: backPanelXMm,
        trimTopMm: panelYMm,
        trimRightMm: frontPanelXMm + panelWidthMm,
        trimBottomMm: panelYMm + panelHeightMm,
      ));
    }

    return pw.Page(
      pageFormat: format,
      build: (pw.Context context) => pw.Stack(children: children),
    );
  }

  Future<_DecodedArtwork> _loadAndValidate({
    required String assetPath,
    required DotsCoverDesign design,
  }) async {
    final Uint8List bytes = _bytesFor(assetPath);
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
    return _DecodedArtwork(bytes: bytes, width: decoded.width, height: decoded.height);
  }

  Future<pw.Widget> _buildSquareArtwork({
    required double frontPanelXMm,
    required double frontPanelYMm,
    required double panelWidthMm,
    required double panelHeightMm,
  }) async {
    final artwork = await _loadAndValidate(
      assetPath: template.frontArtworkPath,
      design: DotsCoverDesign.square,
    );
    final image = pw.MemoryImage(artwork.bytes);
    final double squareWidthMm = panelWidthMm * 0.8;
    final double squareHeightMm = panelHeightMm * 0.8;
    const double paddingMm = 10;
    final double trimRightMm = frontPanelXMm + panelWidthMm;
    final double trimBottomMm = frontPanelYMm + panelHeightMm;
    final double leftMm = trimRightMm - paddingMm - squareWidthMm;
    final double topMm = trimBottomMm - paddingMm - squareHeightMm;
    return pw.Positioned(
      left: leftMm * _coverMmToPt,
      top: topMm * _coverMmToPt,
      child: pw.Image(
        image,
        width: squareWidthMm * _coverMmToPt,
        height: squareHeightMm * _coverMmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  Future<pw.Widget> _buildCircleArtwork({
    required double frontPanelXMm,
    required double frontPanelYMm,
    required double panelWidthMm,
    required double panelHeightMm,
  }) async {
    final artwork = await _loadAndValidate(
      assetPath: template.frontArtworkPath,
      design: DotsCoverDesign.circle,
    );
    final image = pw.MemoryImage(artwork.bytes);
    final double diameterMm =
        math.min(panelWidthMm * 0.5, panelHeightMm * 0.5);
    final double leftMm = frontPanelXMm + (panelWidthMm - diameterMm) / 2.0;
    final double topMm = frontPanelYMm + (panelHeightMm - diameterMm) / 2.0;
    final double diameterPt = diameterMm * _coverMmToPt;
    return pw.Positioned(
      left: leftMm * _coverMmToPt,
      top: topMm * _coverMmToPt,
      child: pw.SizedBox(
        width: diameterPt,
        height: diameterPt,
        child: pw.ClipOval(child: pw.Image(image, fit: pw.BoxFit.cover)),
      ),
    );
  }

  Future<pw.Widget> _buildLinenArtwork({
    required double pageWidthMm,
    required double pageHeightMm,
  }) async {
    final artwork = await _loadAndValidate(
      assetPath: template.frontArtworkPath,
      design: DotsCoverDesign.linen,
    );
    final image = pw.MemoryImage(artwork.bytes);
    final double stripWidthMm = pageWidthMm;
    final double stripHeightMm =
        stripWidthMm * artwork.height / artwork.width;
    final double centerlineYMm = pageHeightMm * 0.6;
    final double topMm = centerlineYMm - stripHeightMm / 2.0;
    return pw.Positioned(
      left: 0,
      top: topMm * _coverMmToPt,
      child: pw.Image(
        image,
        width: stripWidthMm * _coverMmToPt,
        height: stripHeightMm * _coverMmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  Future<pw.Widget> _buildArtworkLayer({
    required String assetPath,
    required double panelXMm,
    required double panelYMm,
    required double panelWidthMm,
    required double panelHeightMm,
    required double wrapMm,
  }) async {
    final Uint8List bytes = _bytesFor(assetPath);
    final image = pw.MemoryImage(bytes);
    final double leftMm = panelXMm - wrapMm;
    final double topMm = panelYMm - wrapMm;
    final double widthMm = panelWidthMm + 2 * wrapMm;
    final double heightMm = panelHeightMm + 2 * wrapMm;
    return pw.Positioned(
      left: leftMm * _coverMmToPt,
      top: topMm * _coverMmToPt,
      child: pw.Image(
        image,
        width: widthMm * _coverMmToPt,
        height: heightMm * _coverMmToPt,
        fit: pw.BoxFit.cover,
      ),
    );
  }

  pw.Widget _buildSpineTitle({
    required String title,
    required double fontSizePt,
    required double spineXMm,
    required double panelYMm,
    required double spineWidthMm,
    required double panelHeightMm,
  }) {
    final double spineWidthPt = spineWidthMm * _coverMmToPt;
    final double panelHeightPt = panelHeightMm * _coverMmToPt;
    return pw.Positioned(
      left: spineXMm * _coverMmToPt,
      top: panelYMm * _coverMmToPt,
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

  List<pw.Widget> _buildCropMarks({
    required double trimLeftMm,
    required double trimTopMm,
    required double trimRightMm,
    required double trimBottomMm,
  }) {
    const double lengthPt = _cropMarkLengthMm * _coverMmToPt;
    const double strokePt = _cropMarkStrokeMm * _coverMmToPt;
    final List<pw.Widget> marks = <pw.Widget>[];

    void addH(double leftMm, double topMm) => marks.add(pw.Positioned(
          left: leftMm * _coverMmToPt,
          top: topMm * _coverMmToPt,
          child: pw.Container(
              width: lengthPt, height: strokePt, color: PdfColors.black),
        ));
    void addV(double leftMm, double topMm) => marks.add(pw.Positioned(
          left: leftMm * _coverMmToPt,
          top: topMm * _coverMmToPt,
          child: pw.Container(
              width: strokePt, height: lengthPt, color: PdfColors.black),
        ));

    addH(trimLeftMm - _cropMarkLengthMm, trimTopMm);
    addV(trimLeftMm, trimTopMm - _cropMarkLengthMm);
    addH(trimRightMm, trimTopMm);
    addV(trimRightMm - _cropMarkStrokeMm, trimTopMm - _cropMarkLengthMm);
    addH(trimLeftMm - _cropMarkLengthMm, trimBottomMm - _cropMarkStrokeMm);
    addV(trimLeftMm, trimBottomMm);
    addH(trimRightMm, trimBottomMm - _cropMarkStrokeMm);
    addV(trimRightMm - _cropMarkStrokeMm, trimBottomMm);

    return marks;
  }

  PdfColor _parseColor(String hex) {
    final String trimmed = hex.startsWith('#') ? hex.substring(1) : hex;
    if (trimmed.length != 6) return PdfColors.white;
    final int? value = int.tryParse(trimmed, radix: 16);
    if (value == null) return PdfColors.white;
    return PdfColor(
      ((value >> 16) & 0xff) / 255.0,
      ((value >> 8) & 0xff) / 255.0,
      (value & 0xff) / 255.0,
    );
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
