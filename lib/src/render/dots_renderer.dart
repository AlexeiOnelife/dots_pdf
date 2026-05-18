import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:file/file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_template.dart';
import '../logging/dots_logger.dart';
import 'asset_loader.dart';
import 'crop_marks.dart';
import 'dots_font_bundle.dart';
import 'layout/dots_layout_code.dart';
import 'layout/dots_layout_solver.dart';
import 'layout/dots_page_geometry.dart';
import 'layout/dots_slot_rect.dart';

/// Conversion factor: 1 millimetre is `25.4 / 72` PDF points
/// (i.e. 1 pt = 1/72 inch, 1 inch = 25.4 mm). Held to seven decimals so
/// equality checks against literal pt values in tests remain stable.
const double _mmToPt = 2.834645669;

/// Renders a single PDF file for the given pages from a template.
///
/// Subclasses implement either whole-document or 2-page-pair semantics.
/// All implementations MUST:
///   - construct a fresh `pw.Document` per output file,
///   - process one page at a time and release page-scoped resources
///     before moving on,
///   - stream the resulting bytes to disk via `IOSink` to avoid keeping
///     the full PDF in RAM,
///   - guarantee the document instance goes out of scope before the
///     method returns.
abstract class DotsRenderer {
  /// Creates a renderer.
  ///
  /// When [drawCropMarks] is `true`, every emitted page has four
  /// L-shaped trim-corner ticks drawn in the 3 mm bleed band. Callers
  /// should derive this from `DotsSupplier.drawsCropMarks` (europa=true,
  /// latam=false).
  ///
  /// [tmpDir] is the per-document scratch directory passed in by
  /// `DotsGenerator`; it is required when any element resolves an
  /// `http(s)` URL (downloads are written there and cleaned up by the
  /// orchestration layer). Pass `null` only when constructing a
  /// renderer outside the generator's pipeline (unit tests with only
  /// local-path assets).
  ///
  /// [urlFetcher] overrides the default `dart:io HttpClient` used to
  /// download URL-sourced images. Unit tests inject a fake here to
  /// keep the suite hermetic.
  ///
  /// [fontBundle] supplies the typography (P22 Mackinac, Inter,
  /// Biro Script Plus). When `null`, text falls back to the pdf
  /// package's built-in Helvetica. Each font is parsed at most once
  /// per renderer instance and shared across every page.
  DotsRenderer({
    required FileSystem fileSystem,
    required DotsLogger logger,
    this.drawCropMarks = false,
    this.tmpDir,
    this.urlFetcher,
    this.fontBundle,
  })  : fs = fileSystem,
        log = logger;

  /// File system handle injected for testability. Intended for use by
  /// subclasses within this library only.
  final FileSystem fs;

  /// Logger handle injected for testability. Intended for use by
  /// subclasses within this library only.
  final DotsLogger log;

  /// Whether trim-corner crop marks are drawn on every page.
  final bool drawCropMarks;

  /// Per-document scratch directory used for URL downloads.
  ///
  /// `null` when the renderer is constructed outside the generator
  /// pipeline; in that case attempting to render a URL-sourced image
  /// throws a [StateError] with a descriptive message.
  final Directory? tmpDir;

  /// Optional HTTP fetcher injected for testability. When `null` the
  /// default `dart:io HttpClient`-based implementation is used.
  final DotsUrlFetcher? urlFetcher;

  /// Optional font bundle. When `null`, text falls back to the pdf
  /// package's built-in Helvetica.
  final DotsFontBundle? fontBundle;

  DotsAssetLoader? _assetLoader;

  /// Per-renderer cache of parsed `pw.Font` instances. The pdf package
  /// charges TTF/OTF parsing on every construction, so we memoize per
  /// role and reuse across every page.
  final Map<DotsFontRole, pw.Font> _fontCache = <DotsFontRole, pw.Font>{};

  /// Returns the `pw.Font` for [role], parsing once and caching.
  /// Returns `null` when no font bundle is wired — callers should fall
  /// back to the pdf package default.
  pw.Font? fontFor(DotsFontRole role) {
    final bundle = fontBundle;
    if (bundle == null) return null;
    return _fontCache[role] ??=
        pw.Font.ttf(ByteData.sublistView(bundle.bytesFor(role)));
  }

  /// Lazily-constructed asset loader bound to this renderer's
  /// [tmpDir] / [urlFetcher].
  ///
  /// Throws a [StateError] when [tmpDir] is `null` and the caller is
  /// attempting to read bytes for an `http(s)` URL — this surface
  /// gives unit tests a clear failure mode when they forget to wire
  /// the scratch directory.
  DotsAssetLoader assetLoaderFor(String pathOrUrl) {
    if (DotsAssetLoader.isUrl(pathOrUrl) && tmpDir == null) {
      throw StateError(
        'DotsRenderer was constructed without a tmpDir but encountered a '
        'URL-sourced asset "$pathOrUrl"; URL downloads require the '
        'per-document scratch directory provided by DotsGenerator.',
      );
    }
    return _assetLoader ??= DotsAssetLoader(
      fileSystem: fs,
      // For local-path-only renderers we still need a Directory handle
      // for the loader, but it will never be touched: `loadBytes`
      // short-circuits on local paths before consulting tmpDir.
      tmpDir: tmpDir ?? fs.systemTempDirectory,
      urlFetcher: urlFetcher,
    );
  }

  /// Width of a bleed band in PDF points.
  ///
  /// Equal to 3 mm (1 mm = 2.834645 pt).
  ///
  // TODO(dots-pdf): move to `DotsPageSize.bleedMm` once the model
  // grows a per-page bleed field.
  static const double bleedPt = 8.503936;

  /// Renders [pages] from [template] into the file at [outputPath].
  ///
  /// The implementation is responsible for opening, writing, and
  /// closing the output sink. Callers should not assume any partial
  /// state on disk if the future throws.
  Future<void> render({
    required DotsTemplate template,
    required List<DotsPage> pages,
    required String outputPath,
  });

  /// Renders [pages] into a fresh `pw.Document` and writes the result
  /// to [outputPath] via a streaming `IOSink`.
  ///
  /// This is the shared workhorse used by both the whole-document and
  /// pair renderers. It builds pages one at a time so per-page state
  /// (image bytes, the page tree, etc.) goes out of scope before the
  /// next iteration.
  Future<void> renderPagesToFile({
    required DotsTemplate template,
    required List<DotsPage> pages,
    required String outputPath,
  }) async {
    final sink = fs.file(outputPath).openWrite();
    try {
      final doc = pw.Document();
      for (final page in pages) {
        // Per-page resources (image bytes, `pw.MemoryImage`) are
        // created inside `buildPage` and become unreachable as soon as
        // `addPage` returns — they cannot leak beyond this iteration.
        doc.addPage(await buildPage(template, page));
      }
      // `doc.save()` returns the assembled bytes in one shot. The
      // pdf package's API does not expose an incremental save, so a
      // single buffer of the final PDF is unavoidable; the constraint
      // is on intermediate per-page state, which we keep bounded.
      final Uint8List bytes = await doc.save();
      sink.add(bytes);
    } finally {
      await sink.close();
    }
  }

  /// Builds a single `pw.Page` from a typed [DotsPage].
  ///
  /// Dispatches on the sealed [DotsPage] variant:
  ///   - [DotsElementsPage] is rendered with the legacy explicit-coords
  ///     pipeline (top-left origin model, pt units).
  ///   - [DotsLayoutPage] is rendered by invoking the layout solver
  ///     and projecting the resulting slot rectangles to PDF points.
  Future<pw.Page> buildPage(DotsTemplate template, DotsPage page) async {
    final format = PdfPageFormat(
      template.pageSize.width,
      template.pageSize.height,
    );
    switch (page) {
      case DotsElementsPage():
        return _buildElementsPage(format, page);
      case DotsLayoutPage():
        return _buildLayoutPage(format, page);
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
    // TODO(dots-pdf): make the page geometry pluggable per template;
    // for now the dotbook default is the only supported configuration.
    const DotsLayoutSolver solver = DotsLayoutSolver();
    final geometry = DotsPageGeometry.dotbookDefault();
    final slots = solver.solve(page.layoutCode, geometry);

    final children = <pw.Widget>[];
    var photoCursor = 0;
    for (final slot in slots) {
      switch (slot.kind) {
        case DotsSlotKind.photo:
          final assetPath = page.photoAssetPaths[photoCursor++];
          children.add(await _buildPhotoSlot(slot, assetPath));
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
        trimMarginPt: bleedPt,
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
    }
  }

  pw.Widget _buildText(DotsTextElement element) {
    final role = DotsFontBundle.roleFromFamily(element.fontFamily);
    final font = role == null ? null : fontFor(role);
    final style = pw.TextStyle(
      fontSize: element.fontSize,
      color: _parseColor(element.colorHex),
      font: font,
    );
    // Model y is the top edge of the text in a top-left frame.
    // `pw.Positioned.top` also measures from the page's top, so the
    // mapping is the identity once we choose a top-anchored layout.
    return pw.Positioned(
      left: element.x,
      top: element.y,
      child: pw.Text(element.value, style: style),
    );
  }

  Future<pw.Widget> _buildImage(DotsImageElement element) async {
    final loader = assetLoaderFor(element.assetPath);
    final bytes = await loader.loadBytes(element.assetPath);
    final image = pw.MemoryImage(bytes);

    final leftBleed = element.bleedLeft ? bleedPt : 0.0;
    final rightBleed = element.bleedRight ? bleedPt : 0.0;
    final topBleed = element.bleedTop ? bleedPt : 0.0;
    final bottomBleed = element.bleedBottom ? bleedPt : 0.0;

    final left = element.x - leftBleed;
    final width = element.width + leftBleed + rightBleed;
    final height = element.height + topBleed + bottomBleed;
    // Model y is the top edge of the trim rect; we expand upward by
    // `topBleed` and the rectangle's bottom edge lives at
    // `y + height + bottomBleed`. The pdf-package `Positioned.top`
    // measures from the page's *top*, so a top-left model frame maps
    // 1-to-1 once we account for bleed.
    final top = element.y - topBleed;

    return pw.Positioned(
      left: left,
      top: top,
      // BoxFit.cover preserves the source image's aspect ratio,
      // centring the content and cropping the overflow along the
      // shorter axis. This matches the spec's "center-crop, fill
      // without deformation" rule.
      child: pw.Image(image, width: width, height: height, fit: pw.BoxFit.cover),
    );
  }

  /// Renders one half of a spread-spanning image.
  ///
  /// The full image is conceptually drawn at size
  /// `(spreadWidth, height)`. Each page only shows half of it; we
  /// clip via `pw.ClipRect` and offset the underlying image so the
  /// correct half lands inside the page trim.
  ///
  /// Layout on the page:
  ///   - [DotsSpreadHalf.left]: the visible window is
  ///     `(x, y, spreadWidth/2, height)`. The underlying image is
  ///     shifted *left* by `-spreadWidth/2` so the right edge of the
  ///     image aligns with the page's binding (right) edge.
  ///   - [DotsSpreadHalf.right]: the visible window is
  ///     `(x, y, spreadWidth/2, height)`. The underlying image is
  ///     shifted *left* by 0 so the left edge of the image aligns
  ///     with the page's binding (left) edge.
  ///
  /// Bleed flags grow the visible window outward on the corresponding
  /// edges by [bleedPt]. The inner (binding) edge never bleeds — the
  /// two halves meet there, so any bleed would be hidden by the
  /// opposite page.
  Future<pw.Widget> _buildSpreadImage(DotsSpreadImageElement element) async {
    final loader = assetLoaderFor(element.assetPath);
    final bytes = await loader.loadBytes(element.assetPath);
    final image = pw.MemoryImage(bytes);

    final halfWidth = element.spreadWidth / 2.0;
    final topBleed = element.bleedTop ? bleedPt : 0.0;
    final bottomBleed = element.bleedBottom ? bleedPt : 0.0;
    final outerBleed = element.bleedOuter ? bleedPt : 0.0;

    // Visible window expressed in page coordinates.
    final visibleLeft =
        element.half == DotsSpreadHalf.left ? element.x - outerBleed : element.x;
    final visibleTop = element.y - topBleed;
    final visibleWidth = halfWidth + outerBleed;
    final visibleHeight = element.height + topBleed + bottomBleed;

    // Inside the clipped window, position the full image so only the
    // correct half is visible. For the left half, the image's right
    // edge meets the window's right edge -> offset by `-halfWidth`.
    // For the right half, the image's left edge meets the window's
    // left edge -> offset by `0` (but we still need to compensate for
    // outer bleed on the right half's outer side, which is on the
    // right; the image extends beyond the window naturally).
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
                  // Preserve the panorama's aspect ratio; cover crops
                  // along the shorter axis rather than stretching.
                  fit: pw.BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<pw.Widget> _buildPhotoSlot(
    DotsSlotRect slot,
    String assetPath,
  ) async {
    final loader = assetLoaderFor(assetPath);
    final bytes = await loader.loadBytes(assetPath);
    final image = pw.MemoryImage(bytes);

    final leftBleed = slot.bleedLeft ? bleedPt : 0.0;
    final rightBleed = slot.bleedRight ? bleedPt : 0.0;
    final topBleed = slot.bleedTop ? bleedPt : 0.0;
    final bottomBleed = slot.bleedBottom ? bleedPt : 0.0;

    final left = slot.xMm * _mmToPt - leftBleed;
    final top = slot.yMm * _mmToPt - topBleed;
    final width = slot.widthMm * _mmToPt + leftBleed + rightBleed;
    final height = slot.heightMm * _mmToPt + topBleed + bottomBleed;

    return pw.Positioned(
      left: left,
      top: top,
      // BoxFit.cover preserves the source image's aspect ratio,
      // centring the content and cropping the overflow along the
      // shorter axis. This matches the spec's "center-crop, fill
      // without deformation" rule.
      child: pw.Image(image, width: width, height: height, fit: pw.BoxFit.cover),
    );
  }

  pw.Widget _buildCaptionSlot(
    DotsSlotRect slot,
    String text,
    DotsLayoutCode layoutCode,
  ) {
    final left = slot.xMm * _mmToPt;
    final top = slot.yMm * _mmToPt;
    final width = slot.widthMm * _mmToPt;
    final height = slot.heightMm * _mmToPt;
    final fontSize = _captionFontSizeFor(slot.kind, layoutCode);
    final font = fontFor(_captionFontRoleFor(slot.kind, layoutCode));

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: fontSize, font: font),
        ),
      ),
    );
  }

  /// Maps a caption slot kind to its design-intent font role.
  ///
  /// Per `docs/templates/SPECS_interior.md`:
  ///   - body-page caption blocks (L1/L7/etc.): title + date are P22
  ///     Mackinac MEDIUM; body is Inter Book;
  ///   - L_hito milestone page: title is P22 Mackinac MEDIUM, but the
  ///     date (subtitle) is P22 Mackinac BOOK at 9 pt / 10.8 pt.
  DotsFontRole _captionFontRoleFor(
    DotsSlotKind kind,
    DotsLayoutCode layoutCode,
  ) {
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

  /// Builds a real QR-code widget for the given [payload] string at the
  /// position and size described by [slot].
  ///
  /// Uses `pw.BarcodeWidget` from `package:pdf/widgets.dart`, which
  /// accepts a `barcode` factory from `package:barcode/barcode.dart`.
  /// We pin to medium error correction (~15% recovery) which is the
  /// pdf-package default and a good fit for printed milestone cards
  /// — high enough to survive moderate ink/wear, low enough to keep
  /// the matrix compact for a typical URL payload.
  ///
  /// The caller in `_buildLayoutPage` is responsible for skipping
  /// empty / null payloads; this method assumes the payload is a
  /// non-empty string (typically a URL — see SPECS clarification #10).
  pw.Widget _buildQrSlot(DotsSlotRect slot, String payload) {
    final left = slot.xMm * _mmToPt;
    final top = slot.yMm * _mmToPt;
    final width = slot.widthMm * _mmToPt;
    final height = slot.heightMm * _mmToPt;
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.BarcodeWidget(
          data: payload,
          barcode: Barcode.qrCode(
            errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
          ),
          padding: const pw.EdgeInsets.all(4),
          drawText: false,
        ),
      ),
    );
  }

  /// Font size in PDF points for a caption slot.
  ///
  /// Title is 20 pt for the L_hito milestone page (P22 Mackinac medium
  /// in the spec) and 11 pt elsewhere. Date is always 11 pt and body is
  /// 9 pt. Actual font families per the spec
  /// (`docs/templates/SPECS_interior.md`) are not bundled yet; the
  /// renderer falls back to the pdf-package default font.
  double _captionFontSizeFor(DotsSlotKind kind, DotsLayoutCode layoutCode) {
    switch (kind) {
      case DotsSlotKind.captionTitle:
        // L_hito title is 20 pt; everywhere else 11 pt per the spec.
        return layoutCode == DotsLayoutCode.lhito ? 20.0 : 11.0;
      case DotsSlotKind.captionDate:
        // L_hito date (subtitle) is 9 pt / 10.8 pt — the slot reserves
        // exactly 10.8 pt of leading, so 11 pt overflows and pw.Text
        // silently clips. Everywhere else dates are 11 pt.
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
