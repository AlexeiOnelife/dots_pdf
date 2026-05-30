import 'dart:math' show pi;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_template.dart';
import '../logging/dots_logger.dart';
import 'crop_marks.dart';
import 'dots_font_bundle.dart';
import 'page_chrome.dart';

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Oval QR element constants (renderer-side; NOT exposed on DotsOvalQrElement)
// ---------------------------------------------------------------------------

/// Caption font size for [DotsOvalQrElement] in PDF points (8pt).
const double _kOvalQrCaptionFontSize = 8.0;

/// Line-height multiplier for the QR caption (8pt × 1.2 = 9.6pt leading).
const double _kOvalQrCaptionLineHeight = 1.2;

/// Caption colour for [DotsOvalQrElement] — grey `#9E9E9D`.
const PdfColor _kOvalQrCaptionColor = PdfColor(
  0x9E / 255.0,
  0x9E / 255.0,
  0x9D / 255.0,
);

/// Gap between the bottom of the oval frame and the top of the caption, in mm.
const double _kOvalQrCaptionGapMm = 3.0;

/// Oval border stroke width in PDF points.
const double _kOvalBorderWidthPt = 0.5;

/// Oval border colour — same grey as the caption `#9E9E9D`.
const PdfColor _kOvalBorderColor = PdfColor(
  0x9E / 255.0,
  0x9E / 255.0,
  0x9D / 255.0,
);

/// Padding from the oval bounding-box edge to the QR side, in mm.
const double _kQrInsetMm = 4.0;

// ---------------------------------------------------------------------------
// Polaroid frame constants (renderer-side; NOT exposed on DotsPolaroidElement)
// ---------------------------------------------------------------------------

/// Left frame border width for a polaroid card, in millimetres.
const double _kPolaroidFrameLeftBorderMm = 5.5;

/// Right frame border width for a polaroid card, in millimetres.
const double _kPolaroidFrameRightBorderMm = 5.5;

/// Top frame border width for a polaroid card, in millimetres.
const double _kPolaroidFrameTopBorderMm = 5.5;

/// Bottom frame border width for a polaroid card, in millimetres.
/// Slightly taller than the other three to produce the classic polaroid
/// caption-strip aesthetic (5.5 + 6.5 = 12 mm total vertical border vs
/// 11 mm horizontal; inner photo is 97 × 122 mm for a 108 × 134 mm outer).
const double _kPolaroidFrameBottomBorderMm = 6.5;

/// Millimetres → PDF points (1 pt = 1/72 inch; 1 inch = 25.4 mm).
const double _kMmToPt = 2.834645669;

// ---------------------------------------------------------------------------
// Testing constants (refer to private constants above — must be declared after)
// ---------------------------------------------------------------------------

/// Exposed for testing: polaroid frame left border width in millimetres.
@visibleForTesting
const double kPolaroidFrameLeftBorderMmForTest = _kPolaroidFrameLeftBorderMm;

/// Exposed for testing: polaroid frame right border width in millimetres.
@visibleForTesting
const double kPolaroidFrameRightBorderMmForTest = _kPolaroidFrameRightBorderMm;

/// Exposed for testing: polaroid frame top border width in millimetres.
@visibleForTesting
const double kPolaroidFrameTopBorderMmForTest = _kPolaroidFrameTopBorderMm;

/// Exposed for testing: polaroid frame bottom border width in millimetres.
@visibleForTesting
const double kPolaroidFrameBottomBorderMmForTest = _kPolaroidFrameBottomBorderMm;

/// Exposed for testing: mm → pt conversion factor.
@visibleForTesting
const double kMmToPtForTest = _kMmToPt;

/// Exposed for testing: gradient parameters when [DotsPolaroidElement.gradientRtl]
/// is `true`. The gradient runs left (85% white) → right (0% white).
@visibleForTesting
const pw.LinearGradient kPolaroidGradientForTest = pw.LinearGradient(
  begin: pw.Alignment.centerLeft,
  end: pw.Alignment.centerRight,
  colors: <PdfColor>[
    PdfColor(1, 1, 1, 0.85),
    PdfColor(1, 1, 1, 0.00),
  ],
);

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

/// Builds a single `pw.Page` for [page] — the shared pure rendering path
/// used by both the main-isolate renderer and the isolate-side renderer.
///
/// All external dependencies (font resolution, asset loading, logging, and
/// the photo-failure callback) are injected via closures so this function
/// stays state-free and testable without any renderer instance.
///
/// [fontResolver] returns a parsed `pw.Font` for the given [DotsFontRole],
/// or `null` to fall back to the pdf package's built-in Helvetica.
///
/// [bytesResolver] loads raw asset bytes by path.
///
/// [logger] receives [DotsLogger.warn] calls when a [DotsTextBlockElement]'s
/// content exceeds its declared [DotsTextBlockElement.maxChars] or
/// [DotsTextBlockElement.maxLines] thresholds.
///
/// [onPhotoFailure] is called when a [DotsImageElement] asset cannot be
/// decoded. The slot is silently skipped and rendering continues.
///
/// [drawCropMarks] — when `true`, L-shaped crop marks are appended to the
/// page stack in the 3mm bleed band.
Future<pw.Page> buildAlbumSpreadPage({
  required PdfPageFormat format,
  required DotsAlbumSpreadPage page,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required bool drawCropMarks,
}) async {
  final children = <pw.Widget>[];

  // ── Chrome (background + header + footer) ────────────────────────────────
  // Build a DotsPageChrome from the spread page's header/footer and delegate
  // to the shared buildPageChrome helper. This is the single chrome site (R8).
  // Cover pages set leftPageNumber/rightPageNumber both null and wordmark ''
  // so buildPageChrome returns [] — cover stays chrome-free (R1).
  final leftNum = page.header.leftPageNumber;
  final rightNum = page.header.rightPageNumber;
  final spreadChrome = DotsPageChrome(
    pageNumber: leftNum ?? rightNum,
    isLeftPage: leftNum != null,
    centerLabel: page.header.centerLabel,
    wordmark: page.footer.wordmark,
  );
  children.addAll(buildPageChrome(spreadChrome, format, fontResolver));

  // ── Elements ─────────────────────────────────────────────────────────────
  for (final element in page.elements) {
    final widget = await _buildElement(
      element: element,
      fontResolver: fontResolver,
      bytesResolver: bytesResolver,
      logger: logger,
      onPhotoFailure: onPhotoFailure,
      pageNumber: page.pageNumber,
      format: format,
    );
    if (widget != null) children.add(widget);
  }

  // ── Width warning (spread pages require >= 406 mm width) ────────────────
  // Photo-arc (DotsPhotoCircleElement / DotsOvalQrElement) and boda-cluster
  // (DotsClusterPhotoElement) layouts both span the full 406 mm spread.
  // Fire once per page — NOT once per element.
  const double kSpreadWidthMm = 406.0;
  const double minSpreadWidthPt = kSpreadWidthMm * _kMmToPt;
  if (page.elements.any((e) =>
          e is DotsPhotoCircleElement ||
          e is DotsOvalQrElement ||
          e is DotsClusterPhotoElement ||
          e is DotsRotatedPhotoElement) &&
      format.width < minSpreadWidthPt - 1.0 /* 1 pt tolerance */) {
    logger.warn(
      'DotsAlbumSpreadPage rendered on a page narrower than 406 mm '
      '(got ${(format.width / _kMmToPt).toStringAsFixed(2)} mm); '
      'page contains elements that may be clipped at format.width < 406 mm.',
    );
  }

  // ── Crop marks ───────────────────────────────────────────────────────────
  if (drawCropMarks) {
    children.addAll(
      dotsCropMarks(
        pageWidthPt: format.width,
        pageHeightPt: format.height,
        trimMarginPt: 8.503936, // 3 mm in PDF points
      ),
    );
  }

  return pw.Page(
    pageFormat: format,
    build: (context) => pw.Stack(children: children),
  );
}

// ---------------------------------------------------------------------------
// Private element builder
// ---------------------------------------------------------------------------

Future<pw.Widget?> _buildElement({
  required DotsElement element,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required int pageNumber,
  required PdfPageFormat format,
}) async {
  switch (element) {
    case DotsTextElement():
      return _buildText(element, fontResolver);

    case DotsImageElement():
      return _buildImage(
        element: element,
        bytesResolver: bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );

    case DotsSpreadImageElement():
      // Spread images are not used on album-spread pages in slice 2.
      // Fall through — skip silently.
      return null;

    case DotsRotatedTextElement():
      return _buildRotatedText(element, fontResolver);

    case DotsTextBlockElement():
      return _buildTextBlock(
        element: element,
        fontResolver: fontResolver,
        logger: logger,
        pageNumber: pageNumber,
      );

    case DotsPolaroidElement():
      return _buildPolaroidElement(
        element: element,
        bytesResolver: bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );

    case DotsDecorativeCircleElement():
      return _buildDecorativeCircleElement(element);

    case DotsDecorativeRectElement():
      return _buildDecorativeRectElement(element);

    case DotsPhotoCircleElement():
      return _buildPhotoCircleElement(
        element: element,
        bytesResolver: bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );

    case DotsOvalQrElement():
      return _buildOvalQrElement(
        element: element,
        fontResolver: fontResolver,
      );

    case DotsClusterPhotoElement():
      return _buildClusterPhotoElement(
        element,
        bytesResolver,
        onPhotoFailure,
      );

    case DotsRotatedPhotoElement():
      return _buildRotatedPhotoElement(
        element: element,
        bytesResolver: bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );

    case DotsUnimplementedElement():
      // Stub element from a category factory whose body lands in a later
      // task (Tasks 4–7). Throw with the responsible task in the message
      // so the failure mode is loud and unambiguous.
      throw UnimplementedError(
        '${element.taskId}: ${element.message}',
      );
  }
}

// ---------------------------------------------------------------------------
// Rasterization cache (T3.1)
// Keyed by (diameterPt rounded to 4 decimals, colorHex, gaussianFadeMm).
// Process-wide; cleared by resetDecorativeCircleCacheForTest in tests.
// ---------------------------------------------------------------------------

typedef _CircleCacheKey = ({
  double diameterPt,
  String colorHex,
  double gaussianFadeMm,
});

final Map<_CircleCacheKey, Uint8List> _circleCache = {};

/// Clears the decorative-circle rasterization cache.
///
/// Call this in [setUp] when a test needs to observe cache-miss / cache-hit
/// behaviour or when test isolation requires a clean slate.
@visibleForTesting
void resetDecorativeCircleCacheForTest() => _circleCache.clear();

/// Test-only window into the decorative-circle rasterization cache.
///
/// Returns the number of entries currently held. A test that wants to
/// verify "N circles sharing K unique (diameter, color, fade) keys
/// produce exactly K rasterizations" can call this after rendering.
@visibleForTesting
int decorativeCircleCacheSizeForTest() => _circleCache.length;

// ---------------------------------------------------------------------------
// Cluster-photo rasterization cache (T3.1)
// Keyed by (assetPath, widthPt, heightPt, gradientStart, gradientEnd,
// gradientDirection, gaussianFadeMm). Process-wide; cleared by
// resetClusterPhotoCacheForTest in tests.
// ---------------------------------------------------------------------------

typedef _ClusterCacheKey = ({
  String assetPath,
  double widthPt,
  double heightPt,
  double opacityGradientStart,
  double opacityGradientEnd,
  DotsGradientDirection opacityGradientDirection,
  double gaussianFadeMm,
});

final Map<_ClusterCacheKey, Uint8List> _clusterPhotoCache = {};

/// Clears the cluster-photo rasterization cache.
///
/// Call this in [setUp] when a test needs to observe cache-miss / cache-hit
/// behaviour or when test isolation requires a clean slate.
@visibleForTesting
void resetClusterPhotoCacheForTest() => _clusterPhotoCache.clear();

/// Test-only window into the cluster-photo rasterization cache.
///
/// Returns the number of entries currently held.
@visibleForTesting
int clusterPhotoCacheSizeForTest() => _clusterPhotoCache.length;

// ---------------------------------------------------------------------------
// Rasterization pipeline (T3.2)
// Produces a PNG with a filled circle that has a Gaussian-blurred soft edge.
// ---------------------------------------------------------------------------

/// Rasterizes a single filled circle with a Gaussian fade to transparent.
///
/// Steps:
///   1. Convert dimensions to pixels at 300 dpi.
///   2. Canvas = ceil(diameterPx + 2 * fadePx * 3) — reserves 3σ for the blur.
///   3. Build an RGBA image with transparent background.
///   4. Fill the circle (antialias: true) with [color] at full opacity.
///   5. Apply gaussianBlur with radius = fadePx.round().
///   6. Encode as PNG and return the bytes.
///
/// ## Gaussian blur convention (radius vs sigma)
///
/// [gaussianFadeMm] is passed as the `radius` argument to `img.gaussianBlur`.
/// This follows the Illustrator / Photoshop convention where the UI control
/// labelled "Radius" equals the full extent of the blur kernel, not the
/// standard-deviation (sigma). The `image:^4.8.0` package internally derives
/// `sigma = radius * 2/3`, so the effective soft-edge band is approximately
/// 2/3 of [gaussianFadeMm] in physical units.
///
/// If the spec authors intended [gaussianFadeMm] to be sigma (i.e. one
/// standard deviation), multiply the value by approximately 1.5 before
/// passing it to this function:
/// ```dart
/// gaussianFadeMm: element.gaussianFadeMm * 1.5,
/// ```
///
/// Visual QA against the design reference is required to confirm which
/// interpretation is correct before changing the multiplier.
Uint8List _rasterizeFadedCircle({
  required double diameterPt,
  required PdfColor color,
  required double gaussianFadeMm,
}) {
  const int dpi = 300;
  const double inchesPerMm = 1.0 / 25.4;

  final double diameterPx = diameterPt / 72.0 * dpi;
  final double fadePx = gaussianFadeMm * inchesPerMm * dpi;
  final int canvasPx = (diameterPx + 2 * fadePx * 3).ceil();
  final int center = canvasPx ~/ 2;
  final int radius = (diameterPx / 2).round();

  final int r = (color.red * 255).round();
  final int g = (color.green * 255).round();
  final int b = (color.blue * 255).round();

  final image = img.Image(
    width: canvasPx,
    height: canvasPx,
    numChannels: 4,
  );

  img.fillCircle(
    image,
    x: center,
    y: center,
    radius: radius,
    color: img.ColorRgba8(r, g, b, 255),
    antialias: true,
  );

  img.gaussianBlur(image, radius: fadePx.round());

  return img.encodePng(image);
}

// ---------------------------------------------------------------------------
// Cluster-photo rasterization pipeline (T3.2)
// Loads, resizes, applies per-pixel opacity gradient, Gaussian edge blur,
// and encodes as PNG.
// ---------------------------------------------------------------------------

/// Rasterizes a single cluster photo slot with an opacity gradient and a
/// Gaussian edge fade.
///
/// Steps:
///   1. Load source bytes via [bytesResolver].
///   2. Decode with `img.decodeImage`.
///   3. Resize to target (widthPt × heightPt) at 300 DPI using `img.copyResize`.
///   4. Apply per-pixel opacity gradient from [element.opacityGradientStart] to
///      [element.opacityGradientEnd] along [element.opacityGradientDirection].
///      Short-circuits when start == end (uniform opacity, no gradient pass).
///   5. Apply Gaussian blur to a [element.gaussianFadeMm] edge band at 300 DPI.
///   6. Encode as PNG and return the bytes.
///
/// On failure, calls [onPhotoFailure] and returns `null`.
Future<Uint8List?> _rasterizeClusterPhoto(
  DotsClusterPhotoElement element,
  Future<Uint8List> Function(String assetPath) bytesResolver, {
  void Function(String, Object)? onPhotoFailure,
}) async {
  const int dpi = 300;
  const double inchesPerMm = 1.0 / 25.4;

  try {
    final srcBytes = await bytesResolver(element.assetPath);
    final srcImage = img.decodeImage(srcBytes);
    if (srcImage == null) {
      onPhotoFailure?.call(
          element.assetPath, StateError('img.decodeImage returned null'));
      return null;
    }

    // Convert pt → px at 300 DPI (1 pt = 1/72 inch).
    final int widthPx = (element.width / 72.0 * dpi).round();
    final int heightPx = (element.height / 72.0 * dpi).round();

    final resized = img.copyResize(
      srcImage,
      width: widthPx,
      height: heightPx,
      interpolation: img.Interpolation.linear,
    );

    // ── Per-pixel opacity gradient pass ─────────────────────────────────────
    // Short-circuit sentinel: start == end means uniform opacity.
    if (element.opacityGradientStart != element.opacityGradientEnd) {
      final double start = element.opacityGradientStart;
      final double end = element.opacityGradientEnd;

      for (var y = 0; y < heightPx; y++) {
        for (var x = 0; x < widthPx; x++) {
          final pixel = resized.getPixel(x, y);

          final double t;
          switch (element.opacityGradientDirection) {
            case DotsGradientDirection.topToBottom:
              t = heightPx > 1 ? y / (heightPx - 1) : 0.0;
            case DotsGradientDirection.bottomToTop:
              t = heightPx > 1 ? 1.0 - (y / (heightPx - 1)) : 0.0;
            case DotsGradientDirection.leftToRight:
              t = widthPx > 1 ? x / (widthPx - 1) : 0.0;
            case DotsGradientDirection.rightToLeft:
              t = widthPx > 1 ? 1.0 - (x / (widthPx - 1)) : 0.0;
          }

          // Lerp: opacity = start + (end - start) * t
          final double opacity = start + (end - start) * t;
          final int newAlpha = (pixel.a * opacity).round().clamp(0, 255);
          resized.setPixel(
            x,
            y,
            img.ColorRgba8(
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              newAlpha,
            ),
          );
        }
      }
    }

    // ── Gaussian edge blur ───────────────────────────────────────────────────
    final int fadePx = (element.gaussianFadeMm * inchesPerMm * dpi).round();
    if (fadePx > 0) {
      img.gaussianBlur(resized, radius: fadePx);
    }

    return img.encodePng(resized);
  } catch (e) {
    onPhotoFailure?.call(element.assetPath, e);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Cluster-photo element builder (T3.3)
// Replaces the UnimplementedError stub from PR 1.
// ---------------------------------------------------------------------------

/// Builds a [pw.Widget] that positions a rasterized cluster-photo PNG via
/// [pw.Positioned].
///
/// Uses [_clusterPhotoCache] keyed by the element's rendering parameters so
/// the rasterization runs at most once per unique key per process lifetime.
///
/// Returns `null` (and calls [onPhotoFailure]) when the asset cannot be
/// decoded or the rasterization fails.
Future<pw.Widget?> _buildClusterPhotoElement(
  DotsClusterPhotoElement element,
  Future<Uint8List> Function(String assetPath) bytesResolver,
  void Function(String, Object)? onPhotoFailure,
) async {
  try {
    final cacheKey = (
      assetPath: element.assetPath,
      widthPt: element.width,
      heightPt: element.height,
      opacityGradientStart: element.opacityGradientStart,
      opacityGradientEnd: element.opacityGradientEnd,
      opacityGradientDirection: element.opacityGradientDirection,
      gaussianFadeMm: element.gaussianFadeMm,
    );

    Uint8List? bytes = _clusterPhotoCache[cacheKey];
    if (bytes == null) {
      bytes = await _rasterizeClusterPhoto(
        element,
        bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );
      if (bytes == null) return null; // bytesResolver failed; onPhotoFailure already invoked
      _clusterPhotoCache[cacheKey] = bytes;
    }

    return pw.Positioned(
      left: element.x,
      top: element.y,
      child: pw.Image(
        pw.MemoryImage(bytes),
        width: element.width,
        height: element.height,
      ),
    );
  } catch (e) {
    onPhotoFailure?.call(element.assetPath, e);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Decorative circle element builder (T3.3)
// Replaces the UnimplementedError stub from PR 1.
// ---------------------------------------------------------------------------

/// Builds a [pw.Widget] that positions a pre-rasterized Gaussian-halo circle
/// PNG onto the page via [pw.Positioned].
///
/// ## Bleed flag handling
///
/// [DotsDecorativeCircleElement] carries `bleedLeft`, `bleedRight`,
/// `bleedTop`, and `bleedBottom` flags that are stored on the model but are
/// NOT applied as explicit positional offsets here. This differs from
/// `_buildImage` and `_buildPhotoSlot`, which shift the widget by `bleedPt`
/// when a bleed flag is set (e.g. `left: element.x - bleedPt`).
///
/// The reason the offset is unnecessary for decorative circles is that the
/// rasterized PNG canvas is already larger than the nominal `diameter`:
/// `_rasterizeFadedCircle` grows the canvas by `2 * fadePx * 3` (i.e. 3σ on
/// each side) so the Gaussian halo extends well past the circle edge.
/// Because `pw.Stack` does not clip its children by default, a circle
/// positioned at, say, `x = 210 mm` on a 203 mm-wide page will naturally
/// paint its halo past the right edge without any additional offset.
///
/// If print QA reveals unexpected clipping (e.g. the PDF viewer clips the
/// Stack), add an explicit positional shift following the `_buildImage`
/// pattern:
/// ```dart
/// final double bleedPt = element.gaussianFadeMm * _kMmToPt;
/// left: element.bleedLeft ? element.x - bleedPt : element.x - haloPt,
/// ```
pw.Widget _buildDecorativeCircleElement(DotsDecorativeCircleElement element) {
  // Round diameter to 4 decimals to absorb float noise from mm→pt conversion.
  final double roundedDiameter =
      (element.diameter * 10000).round() / 10000.0;

  final color = _parseColor(element.colorHex) ??
      const PdfColor(
        0xCD / 255.0,
        0xE7 / 255.0,
        0xF2 / 255.0,
      );

  final key = (
    diameterPt: roundedDiameter,
    colorHex: element.colorHex,
    gaussianFadeMm: element.gaussianFadeMm,
  );

  final bytes = _circleCache.putIfAbsent(
    key,
    () => _rasterizeFadedCircle(
      diameterPt: roundedDiameter,
      color: color,
      gaussianFadeMm: element.gaussianFadeMm,
    ),
  );

  final memImage = pw.MemoryImage(bytes);

  // The PNG canvas is larger than the circle diameter by 2 * fadePx * 3 on
  // each side so the halo doesn't clip. Compute the pt dimensions of the
  // canvas and shift the Positioned widget accordingly so the circle's
  // geometric centre lands at (element.x + diameter/2, element.y + diameter/2).
  final double haloPt = element.gaussianFadeMm * _kMmToPt * 3;
  final double canvasPt = element.diameter + 2 * haloPt;

  return pw.Positioned(
    left: element.x - haloPt,
    top: element.y - haloPt,
    child: pw.Image(memImage, width: canvasPt, height: canvasPt),
  );
}

// ---------------------------------------------------------------------------
// Decorative-rect element builder
// ---------------------------------------------------------------------------

pw.Widget _buildDecorativeRectElement(DotsDecorativeRectElement element) {
  final color = _parseColor(element.colorHex) ??
      const PdfColor(
        0xCD / 255.0,
        0xE7 / 255.0,
        0xF2 / 255.0,
      );
  final radius = element.borderRadius;
  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Container(
      width: element.width,
      height: element.height,
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: radius > 0 ? pw.BorderRadius.all(pw.Radius.circular(radius)) : null,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Photo-circle element builder (T3.2)
// ---------------------------------------------------------------------------

/// Exposed for testing: delegates to the private [_buildPhotoCircleElement]
/// so tests can assert that a valid photo yields a [pw.Positioned] whose
/// immediate child is a [pw.ClipOval] without walking the full page stack.
@visibleForTesting
Future<pw.Widget?> buildPhotoCircleElementForTest({
  required DotsPhotoCircleElement element,
  required Future<Uint8List> Function(String) bytesResolver,
  required void Function(String, Object) onPhotoFailure,
}) =>
    _buildPhotoCircleElement(
      element: element,
      bytesResolver: bytesResolver,
      onPhotoFailure: onPhotoFailure,
    );

/// Builds a [pw.Widget] that clips a decoded photo to a circle of [element.diameter]
/// and positions it at ([element.x], [element.y]) via [pw.Positioned].
///
/// Returns `null` and calls [onPhotoFailure] when the asset cannot be decoded
/// (same contract as `_buildImage`). The rest of the page continues to render.
Future<pw.Widget?> _buildPhotoCircleElement({
  required DotsPhotoCircleElement element,
  required Future<Uint8List> Function(String) bytesResolver,
  required void Function(String, Object) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null;
  }

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.ClipOval(
      child: pw.Image(
        image,
        width: element.diameter,
        height: element.diameter,
        fit: pw.BoxFit.cover,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Oval QR element builder (T3.3)
// ---------------------------------------------------------------------------

/// Builds a composite [pw.Widget] for [element] positioned at ([element.x],
/// [element.y]).
///
/// The composite is a [pw.Stack] with three layers:
///   1. An outlined ellipse ([pw.Container] + [pw.BoxDecoration] with
///      [pw.BoxShape.circle]) sized to [element.ovalWidth] × [element.ovalHeight].
///   2. A [pw.BarcodeWidget] QR code (medium error correction) inscribed in
///      the oval, minus [_kQrInsetMm] padding on each side.
///   3. A centred caption [pw.Text] below the oval at [_kOvalQrCaptionGapMm]
///      gap, using P22 Mackinac Book [_kOvalQrCaptionFontSize], colour
///      [_kOvalQrCaptionColor].
pw.Widget _buildOvalQrElement({
  required DotsOvalQrElement element,
  required pw.Font? Function(DotsFontRole) fontResolver,
}) {
  final captionFont = fontResolver(DotsFontRole.p22MackinacBook);

  // Inscribed-square QR side: min(ovalWidth, ovalHeight) minus inset on each side.
  final double qrSidePt = (element.ovalWidth < element.ovalHeight
          ? element.ovalWidth
          : element.ovalHeight) -
      2.0 * _kQrInsetMm * _kMmToPt;
  final double qrLeftPt = (element.ovalWidth - qrSidePt) / 2.0;
  final double qrTopPt = (element.ovalHeight - qrSidePt) / 2.0;
  final double captionTopPt =
      element.ovalHeight + _kOvalQrCaptionGapMm * _kMmToPt;

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Stack(
      children: [
        // Oval frame — BoxShape.circle draws an ellipse inscribed in the bbox.
        pw.Container(
          width: element.ovalWidth,
          height: element.ovalHeight,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(
              color: _kOvalBorderColor,
              width: _kOvalBorderWidthPt,
            ),
          ),
        ),
        // QR code centred inside the oval.
        pw.Positioned(
          left: qrLeftPt,
          top: qrTopPt,
          child: pw.SizedBox(
            width: qrSidePt,
            height: qrSidePt,
            child: pw.BarcodeWidget(
              data: element.qrPayload,
              barcode: pw.Barcode.qrCode(
                errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
              ),
              drawText: false,
            ),
          ),
        ),
        // Caption below the oval.
        pw.Positioned(
          left: 0,
          top: captionTopPt,
          child: pw.SizedBox(
            width: element.ovalWidth,
            child: pw.Text(
              element.caption,
              style: pw.TextStyle(
                font: captionFont,
                fontSize: _kOvalQrCaptionFontSize,
                color: _kOvalQrCaptionColor,
                lineSpacing:
                    _kOvalQrCaptionFontSize * (_kOvalQrCaptionLineHeight - 1),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Individual element builders
// ---------------------------------------------------------------------------

pw.Widget _buildText(
  DotsTextElement element,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);
  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Text(
      element.value,
      style: pw.TextStyle(
        fontSize: element.fontSize,
        font: font,
        color: _parseColor(element.colorHex),
      ),
    ),
  );
}

Future<pw.Widget?> _buildImage({
  required DotsImageElement element,
  required Future<Uint8List> Function(String) bytesResolver,
  required void Function(String, Object) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null;
  }

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Image(
        image,
        width: element.width,
        height: element.height,
        fit: pw.BoxFit.cover,
      ),
    ),
  );
}

/// Renders a [DotsRotatedTextElement] by wrapping a [pw.Text] in
/// [pw.Transform.rotate].
///
/// The un-rotated bounding box (x, y) is used for positioning via
/// [pw.Positioned]. The rotation is applied around the child's geometric
/// centre (`alignment: pw.Alignment.center`). At 2°, the visual excursion
/// beyond the un-rotated bbox is ≈0.4 mm — negligible at print resolution.
pw.Widget _buildRotatedText(
  DotsRotatedTextElement element,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);
  final angleRadians = element.angleDegrees * pi / 180.0;

  // Wrap in SizedBox sized for the un-rotated text so the rotation has a
  // deterministic centre (design decision D1).  Width estimate: character
  // width ≈ 0.6 × fontSize (rough but sufficient at 2° rotation).
  final double estimatedWidth = element.fontSize * element.value.length * 0.6;

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Transform.rotate(
      angle: angleRadians,
      child: pw.SizedBox(
        width: estimatedWidth,
        child: pw.Text(
          element.value,
          style: pw.TextStyle(
            fontSize: element.fontSize,
            font: font,
            color: _parseColor(element.colorHex),
          ),
        ),
      ),
    ),
  );
}

/// Renders a [DotsTextBlockElement] inside a [pw.SizedBox] for width
/// constraining and word-wrapping.
///
/// Emits a [DotsLogger.warn] message (but continues rendering) when:
///   - [DotsTextBlockElement.maxChars] is set and
///     `value.length > maxChars`, or
///   - [DotsTextBlockElement.maxLines] is set and
///     `value.split('\n').length > maxLines`.
pw.Widget _buildTextBlock({
  required DotsTextBlockElement element,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required DotsLogger logger,
  required int pageNumber,
}) {
  // Overflow guards — warn but always render.
  final maxChars = element.maxChars;
  if (maxChars != null && element.value.length > maxChars) {
    logger.warn(
      'DotsTextBlockElement on page $pageNumber: '
      'body length ${element.value.length} exceeds maxChars $maxChars',
    );
  }
  final maxLines = element.maxLines;
  if (maxLines != null && element.value.split('\n').length > maxLines) {
    logger.warn(
      'DotsTextBlockElement on page $pageNumber: '
      'line count ${element.value.split('\n').length} exceeds maxLines $maxLines',
    );
  }

  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);

  final textAlign = switch (element.textAlign) {
    DotsTextAlign.left => pw.TextAlign.left,
    DotsTextAlign.center => pw.TextAlign.center,
    DotsTextAlign.right => pw.TextAlign.right,
  };

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.SizedBox(
      width: element.width,
      child: pw.Text(
        element.value,
        style: pw.TextStyle(
          fontSize: element.fontSize,
          font: font,
          color: _parseColor(element.colorHex),
          lineSpacing: element.fontSize * (element.lineHeight - 1),
        ),
        textAlign: textAlign,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PdfColor? _parseColor(String? hex) {
  if (hex == null) return null;
  final trimmed = hex.startsWith('#') ? hex.substring(1) : hex;
  if (trimmed.length != 6) return null;
  final value = int.tryParse(trimmed, radix: 16);
  if (value == null) return null;
  return PdfColor(
    ((value >> 16) & 0xff) / 255.0,
    ((value >> 8) & 0xff) / 255.0,
    (value & 0xff) / 255.0,
  );
}

// ---------------------------------------------------------------------------
// Polaroid element builder
// ---------------------------------------------------------------------------

/// Builds a polaroid card widget for [element].
///
/// Composes:
///   1. White outer [pw.Container] at [element.width] × [element.height].
///   2. [pw.Padding] with the hardcoded LTRB frame border widths
///      (5.5 / 5.5 / 5.5 / 6.5 mm).
///   3. Inner [pw.Stack] containing [pw.Image] and, when
///      [DotsPolaroidElement.gradientRtl] is `true`, a
///      [pw.Positioned.fill] gradient overlay.
///   4. Wraps the container in [pw.Transform.rotate] around the geometric
///      centre.
///   5. Positions the rotated card via [pw.Positioned] at
///      ([element.x], [element.y]).
///
/// Returns `null` and calls [onPhotoFailure] when the asset cannot be
/// decoded (same contract as `_buildImage`).
Future<pw.Widget?> _buildPolaroidElement({
  required DotsPolaroidElement element,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required void Function(String assetPath, Object error) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null;
  }

  final angleRadians = element.angleDegrees * pi / 180.0;

  // Polaroid body — un-rotated coordinate frame.
  final body = pw.Container(
    width: element.width,
    height: element.height,
    color: PdfColors.white,
    child: pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(
        _kPolaroidFrameLeftBorderMm * _kMmToPt,
        _kPolaroidFrameTopBorderMm * _kMmToPt,
        _kPolaroidFrameRightBorderMm * _kMmToPt,
        _kPolaroidFrameBottomBorderMm * _kMmToPt,
      ),
      child: pw.Stack(
        children: <pw.Widget>[
          pw.Image(image, fit: pw.BoxFit.cover),
          if (element.gradientRtl)
            pw.Positioned.fill(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight,
                    colors: <PdfColor>[
                      PdfColor(1, 1, 1, 0.85),
                      PdfColor(1, 1, 1, 0.00),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Transform.rotate(
      angle: angleRadians,
      alignment: pw.Alignment.center,
      child: body,
    ),
  );
}

// ---------------------------------------------------------------------------
// Rotated photo helper (slice 7, T3.1)
// ---------------------------------------------------------------------------

/// Builds a `pw.Positioned` → `pw.Transform.rotate` → `pw.ClipRRect` →
/// `pw.Image` widget tree for [element].
///
/// The element carries NO white frame (unlike [_buildPolaroidElement]).
/// Rotation is center-preserving: `pw.Alignment.center` is used so the
/// rendered AABB matches the original extracted AABB coordinates.
///
/// Returns `null` and calls [onPhotoFailure] when the asset cannot be
/// decoded (same contract as `_buildImage` / `_buildPolaroidElement`).
Future<pw.Widget?> _buildRotatedPhotoElement({
  required DotsRotatedPhotoElement element,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required void Function(String assetPath, Object error) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null;
  }

  final double angleRadians = element.angleDegrees * pi / 180.0;
  final double radiusPt = element.cornerRadiusMm * _kMmToPt;

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Transform.rotate(
      angle: angleRadians,
      alignment: pw.Alignment.center,
      child: pw.ClipRRect(
        horizontalRadius: radiusPt,
        verticalRadius: radiusPt,
        child: pw.Image(
          image,
          width: element.width,
          height: element.height,
          fit: pw.BoxFit.cover,
        ),
      ),
    ),
  );
}
