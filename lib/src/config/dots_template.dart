import 'package:meta/meta.dart';

import '../api/album_before_journey_content.dart';
import '../api/album_before_you_start_content.dart';
import '../api/album_boda_cluster_content.dart';
import '../api/album_boda_halo_content.dart';
import '../api/album_eventos_closing_content.dart';
import '../api/album_photo_arc_content.dart';
import '../api/album_photo_only_cover_content.dart';
import '../api/album_qr_spread_content.dart';
import '../api/album_welcome_journey_content.dart';
import '../api/dots_album_type.dart';
import '../render/boda_halo_layout.dart';
import '../render/cover_circles.dart';
import '../render/layout/dots_layout_code.dart';
import '../render/boda_cluster_layout.dart';
import '../render/photo_arc_layout.dart';
import '../render/layout/dots_slot_rect.dart';
import '../render/polaroid_slot_position.dart';
import '../render/polaroid_slots.dart';
import 'dots_pliego.dart';

// ---------------------------------------------------------------------------
// Millimetres → PDF points constant (same as DotsRenderer._mmToPt).
// ---------------------------------------------------------------------------

/// 1 mm expressed in PDF points (1 pt = 1/72 inch; 1 inch = 25.4 mm).
const double _mmToPt = 2.834645669;

/// Right-page decorative-circle scatter for the shared
/// `closingQrSpread` (and, by symmetry, the generalEventos
/// `openingQrSpread`). Twenty-eight circles authored against
/// `pdf13_general_eventos_final.pdf` p.1 (annotated diameters) +
/// p.2 (annotated X/Y positions). X/Y are top-left of each circle's
/// bounding box, in spread mm (right page = x in 137..395 mm; the
/// cluster straddles the gutter near x=200). Diameter pairings were
/// done by visual matching between the two PDF pages — the histogram
/// is exact (matches every annotated diameter exactly once), but
/// individual position↔diameter pairings within a cluster are
/// best-effort and may need refinement after visual QA.
const List<({double xMm, double yMm, double diameterMm})>
    _kRightPageCircles = [
  // Top-right corner area.
  (xMm: 390, yMm: 57, diameterMm: 40),
  (xMm: 362, yMm: 77, diameterMm: 13),
  (xMm: 338, yMm: 57, diameterMm: 23),
  (xMm: 389, yMm: 94, diameterMm: 16),
  (xMm: 307, yMm: 94, diameterMm: 32),
  (xMm: 266, yMm: 102, diameterMm: 26),
  // Mid right / centre.
  (xMm: 236, yMm: 140, diameterMm: 43),
  (xMm: 202, yMm: 128, diameterMm: 23),
  (xMm: 205, yMm: 160, diameterMm: 13),
  (xMm: 348, yMm: 138, diameterMm: 56),
  (xMm: 395, yMm: 139, diameterMm: 5),
  (xMm: 291, yMm: 135, diameterMm: 13),
  (xMm: 266, yMm: 151, diameterMm: 13),
  // Dense small cluster near the gutter.
  (xMm: 137, yMm: 142, diameterMm: 8),
  (xMm: 149, yMm: 142, diameterMm: 5),
  (xMm: 163, yMm: 136, diameterMm: 6),
  (xMm: 165, yMm: 154, diameterMm: 8),
  (xMm: 182, yMm: 157, diameterMm: 9),
  (xMm: 177, yMm: 140, diameterMm: 13),
  (xMm: 185, yMm: 132, diameterMm: 13),
  // Lower area.
  (xMm: 241, yMm: 186, diameterMm: 23),
  (xMm: 310, yMm: 194, diameterMm: 56),
  (xMm: 271, yMm: 203, diameterMm: 8),
  (xMm: 307, yMm: 216, diameterMm: 37),
  (xMm: 348, yMm: 232, diameterMm: 40),
  (xMm: 369, yMm: 182, diameterMm: 43),
  (xMm: 391, yMm: 201, diameterMm: 23),
  (xMm: 389, yMm: 238, diameterMm: 43),
];

/// Right-to-left opacity gradient for the `_kRightPageCircles` scatter,
/// emulating pdf13 p.1's "transparencia de 100% A 0% sobre 181 mm"
/// annotation.
///
/// Computes `[0.2, 1.0]` linearly: circles at the right edge of the
/// cluster (`xMm ≈ 395`) get full opacity; circles near the gutter
/// (`xMm ≈ 137`) get 20% — the floor keeps the dense small-circle
/// cluster faintly visible rather than rendering it invisible. The
/// gradient span is the full cluster width (~258 mm) rather than the
/// annotated 181 mm because applying 181 mm strictly would clip the
/// left half of the cluster, which is clearly drawn in the source.
///
/// Best-effort approximation; refine via visual QA against pdf13 p.1.
double _qrCircleAlphaForX(double xMm) {
  const double leftEdgeMm = 137;
  const double rightEdgeMm = 395;
  const double minAlpha = 0.2;
  const double maxAlpha = 1.0;
  final double t = ((xMm - leftEdgeMm) / (rightEdgeMm - leftEdgeMm))
      .clamp(0.0, 1.0);
  return minAlpha + (maxAlpha - minAlpha) * t;
}

/// Immutable page size in PDF points (1 pt = 1/72 inch).
@immutable
class DotsPageSize {
  /// Creates a page size with explicit [width] and [height] in points.
  const DotsPageSize({required this.width, required this.height});

  /// Page width in PDF points.
  final double width;

  /// Page height in PDF points.
  final double height;

  @override
  bool operator ==(Object other) =>
      other is DotsPageSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Base class for every element that can appear on a page.
///
/// Subclasses are sealed: extending [DotsElement] outside this library
/// is not supported because the rendering pipeline switches on the
/// concrete type.
@immutable
sealed class DotsElement {
  /// Position of the element's anchor in PDF points (origin top-left).
  const DotsElement({required this.x, required this.y});

  /// Horizontal position in PDF points.
  final double x;

  /// Vertical position in PDF points.
  final double y;
}

/// A run of styled text positioned at ([x], [y]).
class DotsTextElement extends DotsElement {
  /// Creates a text element.
  const DotsTextElement({
    required super.x,
    required super.y,
    required this.value,
    required this.fontSize,
    this.fontFamily,
    this.colorHex,
  });

  /// Literal text content.
  final String value;

  /// Font size in PDF points.
  final double fontSize;

  /// Optional font family name; falls back to the template default.
  final String? fontFamily;

  /// Optional RGB color encoded as `#RRGGBB`.
  final String? colorHex;

  @override
  bool operator ==(Object other) =>
      other is DotsTextElement &&
      other.x == x &&
      other.y == y &&
      other.value == value &&
      other.fontSize == fontSize &&
      other.fontFamily == fontFamily &&
      other.colorHex == colorHex;

  @override
  int get hashCode =>
      Object.hash(x, y, value, fontSize, fontFamily, colorHex);
}

/// An image positioned at ([x], [y]) with explicit [width] and [height].
///
/// Bleed flags mark which edges of the image extend past the trim into the
/// 3 mm bleed area. A flagged edge means the image's drawn area is grown
/// by `bleedMm` beyond [width] / [height] on that edge; the trim coordinates
/// in [x], [y], [width], [height] remain authoritative.
class DotsImageElement extends DotsElement {
  /// Creates an image element.
  const DotsImageElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.width,
    required this.height,
    this.bleedTop = false,
    this.bleedBottom = false,
    this.bleedLeft = false,
    this.bleedRight = false,
  });

  /// Path or asset key resolvable by the caller-provided asset loader.
  final String assetPath;

  /// Render width in PDF points (trim-area width; does not include bleed).
  final double width;

  /// Render height in PDF points (trim-area height; does not include bleed).
  final double height;

  /// Whether the image extends into the bleed above its trim top edge.
  final bool bleedTop;

  /// Whether the image extends into the bleed below its trim bottom edge.
  final bool bleedBottom;

  /// Whether the image extends into the bleed beyond its trim left edge.
  final bool bleedLeft;

  /// Whether the image extends into the bleed beyond its trim right edge.
  final bool bleedRight;

  @override
  bool operator ==(Object other) =>
      other is DotsImageElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.width == width &&
      other.height == height &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        width,
        height,
        bleedTop,
        bleedBottom,
        bleedLeft,
        bleedRight,
      );
}

/// Gradient direction for elements that support an opacity gradient.
///
/// Used by [DotsClusterPhotoElement] to specify which direction the
/// `opacityGradientStart` → `opacityGradientEnd` ramp runs across the element.
/// This enum is intentionally kept separate from [DotsPolaroidElement.gradientRtl],
/// which pre-dates it and uses a simpler bool API.
enum DotsGradientDirection {
  /// Opacity gradient runs from the top edge (start) to the bottom edge (end).
  topToBottom,

  /// Opacity gradient runs from the bottom edge (start) to the top edge (end).
  bottomToTop,

  /// Opacity gradient runs from the left edge (start) to the right edge (end).
  leftToRight,

  /// Opacity gradient runs from the right edge (start) to the left edge (end).
  rightToLeft,
}

/// Alignment of text within a [DotsTextBlockElement].
///
/// Maps 1-to-1 to `pw.TextAlign` internally; the public API does not
/// expose any `package:pdf` types directly.
enum DotsTextAlign {
  /// Align text to the left edge of the block.
  left,

  /// Centre text horizontally within the block.
  center,

  /// Align text to the right edge of the block.
  right,
}

/// A run of styled text that is visually rotated by [angleDegrees] around
/// its geometric centre and positioned at ([x], [y]).
///
/// Positive [angleDegrees] values rotate the text clockwise. The bounding
/// box used for positioning is that of the **un-rotated** text; glyphs may
/// extend slightly beyond it when the angle is non-zero.
class DotsRotatedTextElement extends DotsElement {
  /// Creates a rotated text element.
  const DotsRotatedTextElement({
    required super.x,
    required super.y,
    required this.value,
    required this.fontSize,
    required this.angleDegrees,
    this.fontFamily,
    this.colorHex,
  });

  /// Literal text content.
  final String value;

  /// Font size in PDF points.
  final double fontSize;

  /// Rotation angle in degrees. Positive = clockwise.
  ///
  /// The renderer converts this to radians at the call site using
  /// `angleDegrees * pi / 180`.
  final double angleDegrees;

  /// Optional font family name; falls back to the template default.
  final String? fontFamily;

  /// Optional RGB color encoded as `#RRGGBB`.
  final String? colorHex;

  @override
  bool operator ==(Object other) =>
      other is DotsRotatedTextElement &&
      other.x == x &&
      other.y == y &&
      other.value == value &&
      other.fontSize == fontSize &&
      other.angleDegrees == angleDegrees &&
      other.fontFamily == fontFamily &&
      other.colorHex == colorHex;

  @override
  int get hashCode =>
      Object.hash(x, y, value, fontSize, angleDegrees, fontFamily, colorHex);
}

/// A width-constrained, word-wrapping text block positioned at ([x], [y]).
///
/// The renderer wraps this in a `pw.SizedBox(width:)` so the `pdf` package
/// handles word-wrap automatically. When [maxChars] or [maxLines] is
/// exceeded the renderer emits a warning via the injected [DotsLogger] but
/// still renders the full text without throwing.
class DotsTextBlockElement extends DotsElement {
  /// Creates a text block element.
  const DotsTextBlockElement({
    required super.x,
    required super.y,
    required this.value,
    required this.fontSize,
    required this.width,
    this.fontFamily,
    this.colorHex,
    this.textAlign = DotsTextAlign.left,
    this.lineHeight = 1.2,
    this.maxChars,
    this.maxLines,
  });

  /// Literal text content.
  final String value;

  /// Font size in PDF points.
  final double fontSize;

  /// Maximum width of the text block in PDF points. The caller converts
  /// millimetres to points before constructing this element.
  final double width;

  /// Optional font family name; falls back to the template default.
  final String? fontFamily;

  /// Optional RGB color encoded as `#RRGGBB`.
  final String? colorHex;

  /// Horizontal alignment of text within the block.
  final DotsTextAlign textAlign;

  /// Line-height multiplier applied to [fontSize] to compute leading.
  final double lineHeight;

  /// When non-null, the renderer warns if `value.length > maxChars`.
  final int? maxChars;

  /// When non-null, the renderer warns if `value.split('\n').length > maxLines`.
  final int? maxLines;

  @override
  bool operator ==(Object other) =>
      other is DotsTextBlockElement &&
      other.x == x &&
      other.y == y &&
      other.value == value &&
      other.fontSize == fontSize &&
      other.width == width &&
      other.fontFamily == fontFamily &&
      other.colorHex == colorHex &&
      other.textAlign == textAlign &&
      other.lineHeight == lineHeight &&
      other.maxChars == maxChars &&
      other.maxLines == maxLines;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        value,
        fontSize,
        width,
        fontFamily,
        colorHex,
        textAlign,
        lineHeight,
        maxChars,
        maxLines,
      );
}

/// A solid, decorative rounded rectangle (no photo, no text).
///
/// Used by the generalEventos welcomeJourney spread to render the 48×60 mm
/// blue "door" placeholder above the title. Geometry is in PDF points
/// (1 pt = 1/72 inch); [colorHex] is `#RRGGBB`. Set [borderRadius] to 0 for
/// a square-cornered rectangle.
@immutable
class DotsDecorativeRectElement extends DotsElement {
  /// Creates a decorative rounded-rectangle element.
  const DotsDecorativeRectElement({
    required super.x,
    required super.y,
    required this.width,
    required this.height,
    required this.colorHex,
    this.borderRadius = 0,
  });

  /// Rectangle width in PDF points.
  final double width;

  /// Rectangle height in PDF points.
  final double height;

  /// Fill colour encoded as `#RRGGBB`. The renderer parses this once per
  /// build call.
  final String colorHex;

  /// Corner radius in PDF points. Default `0` (square corners).
  final double borderRadius;

  @override
  bool operator ==(Object other) =>
      other is DotsDecorativeRectElement &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.colorHex == colorHex &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(x, y, width, height, colorHex, borderRadius);
}

/// A decorative circle element for album cover pages.
///
/// Bundles position + diameter + colour + Gaussian fade radius + four bleed
/// flags into a single immutable element. The renderer pre-rasterizes a PNG
/// per unique `(diameter, colorHex, gaussianFadeMm)` tuple and caches it
/// process-wide to avoid redundant work across the 14 circles on a cover page.
///
/// All geometry fields use PDF points (1 pt = 1/72 inch); [gaussianFadeMm]
/// uses millimetres because the spec is authored in mm (`1.764 mm`) and every
/// cover circle shares the same fade. Default `1.764` mm from `SPECS_album_types.md` p.4.
///
/// Bleed flags match the `DotsImageElement` / `DotsPolaroidElement` convention.
@immutable
class DotsDecorativeCircleElement extends DotsElement {
  /// Creates a decorative circle element.
  const DotsDecorativeCircleElement({
    required super.x,
    required super.y,
    required this.diameter,
    required this.colorHex,
    this.gaussianFadeMm = 1.764,
    this.opacityAlpha = 1.0,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  }) : assert(
          opacityAlpha >= 0.0 && opacityAlpha <= 1.0,
          'opacityAlpha must be in [0.0, 1.0]',
        );

  /// Circle diameter in PDF points.
  final double diameter;

  /// Fill colour encoded as `#RRGGBB`. Baked into the rasterized PNG;
  /// the renderer does NOT tint at runtime.
  final String colorHex;

  /// Gaussian-blur edge-feather width in millimetres. Default is 1.764 mm
  /// (spec p.4). This value is intentionally kept in mm because the spec
  /// authors in mm; the factory converts to pixels at rasterisation time.
  final double gaussianFadeMm;

  /// Per-circle opacity multiplier in `[0.0, 1.0]`. Default `1.0` (fully
  /// opaque). The renderer applies this via `pw.Opacity` around the
  /// rasterized PNG, so it composes cleanly with [gaussianFadeMm]
  /// (alpha multiplies the already-faded edges).
  ///
  /// Used by the `closingQrSpread` / `openingQrSpread` right-page circle
  /// scatter to emulate the "transparencia de 100% A 0% sobre 181 mm"
  /// gradient annotated in `pdf13_general_eventos_final.pdf` p.1.
  final double opacityAlpha;

  /// Whether the circle extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the circle extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the circle extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the circle extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsDecorativeCircleElement &&
      other.x == x &&
      other.y == y &&
      other.diameter == diameter &&
      other.colorHex == colorHex &&
      other.gaussianFadeMm == gaussianFadeMm &&
      other.opacityAlpha == opacityAlpha &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        diameter,
        colorHex,
        gaussianFadeMm,
        opacityAlpha,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}

/// A circular-cropped photo element positioned at ([x], [y]) with a uniform
/// [diameter].
///
/// Used on the photo-arc spread page. The renderer wraps the decoded
/// [assetPath] bytes in `pw.ClipOval` at `width: diameter, height: diameter`
/// and positions it via `pw.Positioned(left: x, top: y)`.
///
/// All geometry fields are in PDF points (1 pt = 1/72 inch). Bleed flags
/// match the [DotsImageElement] / [DotsPolaroidElement] convention; all
/// 10 photo-arc circles are inside the spread trim, so the flags default
/// to `false`.
@immutable
class DotsPhotoCircleElement extends DotsElement {
  /// Creates a photo-circle element.
  const DotsPhotoCircleElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.diameter,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Path or asset key resolvable by the caller-provided asset loader.
  final String assetPath;

  /// Circle diameter in PDF points.
  final double diameter;

  /// Whether the circle extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the circle extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the circle extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the circle extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsPhotoCircleElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.diameter == diameter &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        diameter,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}

/// An oval-framed QR card positioned at ([x], [y]).
///
/// Used on the photo-arc spread page. The renderer produces a composite
/// at `(x, y)` consisting of:
///   1. A stroked ellipse frame of `ovalWidth × ovalHeight`.
///   2. A `pw.BarcodeWidget` for [qrPayload] centred inside the oval.
///   3. A caption text line below the oval at a renderer-side constant font
///      size (P22 Mackinac Book 8 pt, colour `#9E9E9D`, 3 mm gap).
///
/// Caption font size, font family, and colour are renderer-side constants
/// (file-private in `album_spread_page.dart`) — NOT exposed as element
/// fields.
///
/// All geometry fields are in PDF points (1 pt = 1/72 inch).
@immutable
class DotsOvalQrElement extends DotsElement {
  /// Creates an oval QR element.
  const DotsOvalQrElement({
    required super.x,
    required super.y,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.qrPayload,
    required this.caption,
  });

  /// Bounding-box width of the oval in PDF points.
  final double ovalWidth;

  /// Bounding-box height of the oval in PDF points.
  final double ovalHeight;

  /// QR code payload (typically a URL).
  final String qrPayload;

  /// Caption text rendered below the oval frame.
  ///
  /// The caption font size, family, and colour are renderer-side constants;
  /// this field carries only the resolved text string.
  final String caption;

  @override
  bool operator ==(Object other) =>
      other is DotsOvalQrElement &&
      other.x == x &&
      other.y == y &&
      other.ovalWidth == ovalWidth &&
      other.ovalHeight == ovalHeight &&
      other.qrPayload == qrPayload &&
      other.caption == caption;

  @override
  int get hashCode =>
      Object.hash(x, y, ovalWidth, ovalHeight, qrPayload, caption);
}

/// A rectangular photo element with per-photo opacity gradient and Gaussian
/// edge fade, for use in the boda-cluster spread layout.
///
/// Each [DotsClusterPhotoElement] carries its own opacity-gradient parameters
/// (`opacityGradientStart`, `opacityGradientEnd`, `opacityGradientDirection`)
/// plus a `gaussianFadeMm` edge-fade width (default `1.764` mm, matching the
/// decorative-circle convention).
///
/// Sentinel semantics: when `opacityGradientStart == opacityGradientEnd` the
/// renderer short-circuits the gradient pass and renders at uniform opacity.
///
/// All geometry fields are in PDF points (1 pt = 1/72 inch). Bleed flags
/// match the [DotsImageElement] / [DotsPolaroidElement] convention.
@immutable
class DotsClusterPhotoElement extends DotsElement {
  /// Creates a cluster-photo element.
  const DotsClusterPhotoElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.width,
    required this.height,
    this.opacityGradientStart = 1.0,
    this.opacityGradientEnd = 1.0,
    this.opacityGradientDirection = DotsGradientDirection.topToBottom,
    this.gaussianFadeMm = 1.764,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Path or asset key resolvable by the caller-provided asset loader.
  final String assetPath;

  /// Render width in PDF points.
  final double width;

  /// Render height in PDF points.
  final double height;

  /// Opacity at the gradient start edge (0.0–1.0). Default `1.0`.
  final double opacityGradientStart;

  /// Opacity at the gradient end edge (0.0–1.0). Default `1.0`.
  ///
  /// When equal to [opacityGradientStart], the renderer short-circuits the
  /// gradient pass (sentinel: no gradient, full uniform opacity).
  final double opacityGradientEnd;

  /// Which direction the opacity ramp runs across the element.
  final DotsGradientDirection opacityGradientDirection;

  /// Gaussian edge-fade width in millimetres. Default `1.764` mm.
  ///
  /// Kept in mm because the spec authors in mm; the renderer converts to
  /// pixels at rasterization time (300 DPI).
  final double gaussianFadeMm;

  /// Whether the element extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the element extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the element extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the element extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsClusterPhotoElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.width == width &&
      other.height == height &&
      other.opacityGradientStart == opacityGradientStart &&
      other.opacityGradientEnd == opacityGradientEnd &&
      other.opacityGradientDirection == opacityGradientDirection &&
      other.gaussianFadeMm == gaussianFadeMm &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        width,
        height,
        opacityGradientStart,
        opacityGradientEnd,
        opacityGradientDirection,
        gaussianFadeMm,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}

/// A rectangular photo element with signed rotation and rounded-rect clip,
/// for use in the boda-halo radial spread layout (boda p.4).
///
/// [x] and [y] are the **unrotated** top-left coordinates in PDF points (pt).
/// [width] and [height] are the unrotated bounding dimensions in pt.
/// [angleDegrees] is a signed clockwise rotation in degrees; positive = CW.
/// [cornerRadiusMm] is applied via [pw.ClipRRect]; default 6.0 mm.
///
/// This element carries NO white frame (unlike [DotsPolaroidElement]).
/// The renderer applies:
///   `pw.Positioned(left: x, top: y)` →
///   `pw.Transform.rotate(angle: angleDegrees * pi/180, alignment: center)` →
///   `pw.ClipRRect` → `pw.Image`.
///
/// Bleed flags follow the [DotsImageElement] / [DotsPolaroidElement] convention.
@immutable
class DotsRotatedPhotoElement extends DotsElement {
  /// Creates a rotated photo element.
  const DotsRotatedPhotoElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.angleDegrees,
    this.cornerRadiusMm = 6.0,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Path or asset key resolvable by the caller-provided asset loader.
  final String assetPath;

  /// Unrotated render width in PDF points.
  final double width;

  /// Unrotated render height in PDF points.
  final double height;

  /// Signed rotation angle in degrees. Positive = clockwise.
  ///
  /// The renderer converts to radians: `angleDegrees * pi / 180`.
  final double angleDegrees;

  /// Corner radius in millimetres applied via [pw.ClipRRect]. Default 6.0 mm.
  final double cornerRadiusMm;

  /// Whether the unrotated rect extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the unrotated rect extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the unrotated rect extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the unrotated rect extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsRotatedPhotoElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.width == width &&
      other.height == height &&
      other.angleDegrees == angleDegrees &&
      other.cornerRadiusMm == cornerRadiusMm &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        width,
        height,
        angleDegrees,
        cornerRadiusMm,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}

/// A polaroid-style photo card positioned at ([x], [y]) with explicit
/// [width] and [height] for the outer white frame, a signed rotation
/// [angleDegrees] around the geometric centre, and an optional
/// right-to-left opacity gradient overlay on the inner photo.
///
/// [x] and [y] are the un-rotated outer-frame top-left coordinates in
/// PDF points. [width] and [height] are the outer frame dimensions in
/// PDF points (typically 108 × 134 mm converted to pt).
///
/// The polaroid frame border widths (5.5/5.5/5.5/6.5 mm) and inner-photo
/// corner radius (0) are renderer-side constants — they are NOT exposed
/// here so the element stays free of styling concerns.
///
/// [gradientRtl] — when `true`, the renderer paints a horizontal
/// `pw.LinearGradient` from `centerLeft` (85% white) to `centerRight`
/// (fully transparent) over the inner photo BEFORE the rotation transform
/// is applied. Used for the `otros` p.6 bottom-left slot only.
///
/// Bleed flags declare which edges of the un-rotated frame extend past
/// the trim into the 3 mm bleed band. [bleedLeft] is `true` for polar-2
/// which bleeds off the left page edge at +8°.
@immutable
class DotsPolaroidElement extends DotsElement {
  /// Creates a polaroid element.
  const DotsPolaroidElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.angleDegrees,
    this.gradientRtl = false,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Path or asset key for the inner photo, resolvable by the caller-
  /// provided asset loader.
  final String assetPath;

  /// Outer frame width in PDF points (un-rotated; typically 108 mm × _mmToPt).
  final double width;

  /// Outer frame height in PDF points (un-rotated; typically 134 mm × _mmToPt).
  final double height;

  /// Signed rotation angle in degrees. Positive = clockwise.
  ///
  /// The renderer converts to radians: `angleDegrees * pi / 180`.
  final double angleDegrees;

  /// When `true`, paints a right-to-left opacity gradient over the inner
  /// photo (left edge 85% opaque → right edge fully transparent).
  final bool gradientRtl;

  /// Whether the un-rotated frame extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the un-rotated frame extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the un-rotated frame extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the un-rotated frame extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsPolaroidElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.width == width &&
      other.height == height &&
      other.angleDegrees == angleDegrees &&
      other.gradientRtl == gradientRtl &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        width,
        height,
        angleDegrees,
        gradientRtl,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}

/// Which half of a [DotsSpreadImageElement]'s source image this
/// instance is rendering.
///
/// A spread image conceptually spans both pages of a 2-page pair. Each
/// page only draws half of it: the page on the left shows the
/// [DotsSpreadHalf.left] half, the page on the right shows the
/// [DotsSpreadHalf.right] half. The renderer is responsible for
/// clipping appropriately so the visible portion lands inside the
/// page trim.
enum DotsSpreadHalf {
  /// The left half of the source image. Rendered on the left page of
  /// a pair; the image's right edge meets the binding (page right
  /// edge).
  left,

  /// The right half of the source image. Rendered on the right page
  /// of a pair; the image's left edge meets the binding (page left
  /// edge).
  right,
}

/// An image that spans the full 2-page spread but is split in half so
/// each page renders only its side.
///
/// The same [assetPath] is supplied to both halves; placing one
/// [DotsSpreadImageElement] with [half] = [DotsSpreadHalf.left] on the
/// left page and another with [half] = [DotsSpreadHalf.right] on the
/// right page produces a continuous image across the spread.
///
/// Coordinates ([x], [y]) describe the position of the visible half on
/// the page in the standard top-left page coordinate system.
/// [spreadWidth] is the total rendered width of the image across the
/// full spread; the visible half on a single page is `spreadWidth / 2`
/// pt wide.
class DotsSpreadImageElement extends DotsElement {
  /// Creates a spread image element.
  const DotsSpreadImageElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.spreadWidth,
    required this.height,
    required this.half,
    this.bleedTop = false,
    this.bleedBottom = false,
    this.bleedOuter = false,
  });

  /// Local path or `http(s)` URL of the source image. The same value
  /// is supplied to both halves of the spread.
  final String assetPath;

  /// Total rendered width of the image across the full 2-page spread,
  /// in PDF points. The visible half on a single page is
  /// `spreadWidth / 2` pt wide.
  final double spreadWidth;

  /// Rendered height in PDF points. The image is scaled to fill
  /// `(spreadWidth, height)` and then clipped per [half].
  final double height;

  /// Which half of the source image this instance draws.
  final DotsSpreadHalf half;

  /// Whether the image extends into the bleed above its trim top edge.
  final bool bleedTop;

  /// Whether the image extends into the bleed below its trim bottom edge.
  final bool bleedBottom;

  /// Whether the image extends past the page's *outer* edge into the
  /// bleed band. The outer edge is the one opposite the binding: the
  /// left page's left edge for [DotsSpreadHalf.left], the right page's
  /// right edge for [DotsSpreadHalf.right]. The inner (binding) edge
  /// never bleeds because the two halves meet there.
  final bool bleedOuter;

  @override
  bool operator ==(Object other) =>
      other is DotsSpreadImageElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.spreadWidth == spreadWidth &&
      other.height == height &&
      other.half == half &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom &&
      other.bleedOuter == bleedOuter;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        assetPath,
        spreadWidth,
        height,
        half,
        bleedTop,
        bleedBottom,
        bleedOuter,
      );
}

/// Placeholder element produced by the seven `DotsAlbumSpreadPage` factory
/// stubs introduced by Task 2 of the `final-render-refinement` series.
///
/// Carriers of this element parse and construct cleanly so that the
/// JSON parser's category-driven mandatory-pliego injection succeeds
/// for every category; the actual visual content is filled in by
/// Tasks 4–7 (per-category fidelity work). At render time, the
/// renderer throws an [UnimplementedError] whose message points at
/// the responsible task — this is how stub spreads communicate "valid
/// to declare, not yet renderable."
@immutable
class DotsUnimplementedElement extends DotsElement {
  /// Creates a placeholder element pointing at the task that will
  /// implement its real content.
  const DotsUnimplementedElement({
    required this.taskId,
    required this.message,
  }) : super(x: 0, y: 0);

  /// Human-friendly identifier of the task that will replace this stub
  /// with real content. Typical values are `'Task 4'`, `'Task 5'`,
  /// `'Task 6'`, `'Task 7'`.
  final String taskId;

  /// Descriptive message used when the renderer throws
  /// [UnimplementedError] for this element.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DotsUnimplementedElement &&
      other.taskId == taskId &&
      other.message == message;

  @override
  int get hashCode => Object.hash(taskId, message);
}

/// A page declaration at a 1-based [pageNumber].
///
/// Sealed: two concrete variants exist — [DotsElementsPage] for the
/// "explicit coordinates" path, and [DotsLayoutPage] for the
/// layout-driven path that delegates positioning to
/// `DotsLayoutSolver`.
@immutable
sealed class DotsPage {
  /// Creates a page.
  const DotsPage({required this.pageNumber});

  /// 1-based page index within the document.
  final int pageNumber;
}

/// A page whose contents are described as an ordered list of
/// pre-positioned [DotsElement]s.
class DotsElementsPage extends DotsPage {
  /// Creates an elements-page.
  const DotsElementsPage({
    required super.pageNumber,
    required this.elements,
  });

  /// Elements laid out on the page, in declaration order.
  final List<DotsElement> elements;

  @override
  bool operator ==(Object other) =>
      other is DotsElementsPage &&
      other.pageNumber == pageNumber &&
      _listEquals(other.elements, elements);

  @override
  int get hashCode => Object.hash(pageNumber, Object.hashAll(elements));
}

/// A page whose contents are described abstractly by a layout code plus
/// the raw assets / caption strings to be placed into the solver's
/// slot rectangles.
///
/// [photoAssetPaths] is matched **in order** to the photo slots produced
/// by `DotsLayoutSolver`. [captions] keys must be a subset of the
/// caption-bearing slot kinds produced by the same solver call. The
/// parser is responsible for enforcing both constraints; the renderer
/// trusts the model.
class DotsLayoutPage extends DotsPage {
  /// Creates a layout-driven page.
  const DotsLayoutPage({
    required super.pageNumber,
    required this.layoutCode,
    this.photoAssetPaths = const <String>[],
    this.captions = const <DotsSlotKind, String>{},
  });

  /// Layout identifier consumed by `DotsLayoutSolver`.
  final DotsLayoutCode layoutCode;

  /// Asset paths to be assigned to photo slots in declaration order.
  final List<String> photoAssetPaths;

  /// Text payloads (or, for [DotsSlotKind.qrCard], the QR data) to be
  /// placed into the caption-bearing slots emitted by the solver.
  final Map<DotsSlotKind, String> captions;

  @override
  bool operator ==(Object other) =>
      other is DotsLayoutPage &&
      other.pageNumber == pageNumber &&
      other.layoutCode == layoutCode &&
      _listEquals(other.photoAssetPaths, photoAssetPaths) &&
      _mapEquals(other.captions, captions);

  @override
  int get hashCode => Object.hash(
        pageNumber,
        layoutCode,
        Object.hashAll(photoAssetPaths),
        Object.hashAllUnordered(
          captions.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

/// Structural header for an album-spread page.
///
/// Carries the three top-of-page label positions: a left page number, a
/// centre context label (e.g. the resolved `{Protagonistas}` token), and a
/// right page number. All three are optional — absent positions are simply
/// not drawn by the renderer.
@immutable
class DotsSpreadHeader {
  /// Creates a spread header.
  const DotsSpreadHeader({
    this.leftPageNumber,
    this.centerLabel,
    this.rightPageNumber,
  });

  /// Optional page-number string shown at the top-left of the spread.
  final String? leftPageNumber;

  /// Optional context-label string shown at the top-centre of the spread.
  ///
  /// Typically the resolved value of `category.contextLabelToken` after
  /// parse-time variable substitution.
  final String? centerLabel;

  /// Optional page-number string shown at the top-right of the spread.
  final String? rightPageNumber;

  @override
  bool operator ==(Object other) =>
      other is DotsSpreadHeader &&
      other.leftPageNumber == leftPageNumber &&
      other.centerLabel == centerLabel &&
      other.rightPageNumber == rightPageNumber;

  @override
  int get hashCode => Object.hash(leftPageNumber, centerLabel, rightPageNumber);
}

/// Structural footer for an album-spread page.
///
/// Carries the single bottom-centre wordmark position (e.g. "Dots. Memories").
@immutable
class DotsSpreadFooter {
  /// Creates a spread footer.
  const DotsSpreadFooter({required this.wordmark});

  /// Wordmark string shown at the bottom-centre of the spread.
  ///
  /// Typically `"Dots. Memories"`.
  final String wordmark;

  @override
  bool operator ==(Object other) =>
      other is DotsSpreadFooter && other.wordmark == wordmark;

  @override
  int get hashCode => wordmark.hashCode;
}

/// Chrome configuration applied uniformly to every interior page.
///
/// Carries the six fields required to render a page's background, header
/// trio (outer page-number, centre label, and the empty opposite column),
/// and footer wordmark. All string fields are nullable — absent values are
/// simply not drawn by [buildPageChrome].
///
/// Instances are `const`-constructible and compare by value. The `==` and
/// `hashCode` implementations cover all six fields so that a [DotsTemplate]
/// whose [DotsTemplate.defaultChrome] changes produces a different
/// [DotsTemplate.contentHash].
@immutable
class DotsPageChrome {
  /// Creates a page-chrome configuration.
  ///
  /// All parameters are optional. Omitting [pageNumber], [centerLabel], and
  /// [wordmark] suppresses the corresponding drawn elements while the
  /// full-bleed background is always rendered.
  const DotsPageChrome({
    this.pageNumber,
    this.centerLabel,
    this.wordmark,
    this.isLeftPage = true,
    this.suppressHeader = false,
    this.suppressFooter = false,
  });

  /// Page-number string placed in the outer-left column on a left page, or
  /// the outer-right column on a right page.
  ///
  /// A `null` value omits the page-number slot entirely.
  final String? pageNumber;

  /// Context-label string placed in the centre column of the header band.
  ///
  /// Typically the resolved value of `category.contextLabelToken` after
  /// variable substitution. A `null` value omits the centre slot.
  final String? centerLabel;

  /// Wordmark string placed in the bottom-right footer corner.
  ///
  /// Typically `"Dots. Memories"`. A `null` or empty value suppresses the
  /// footer entirely.
  final String? wordmark;

  /// Whether this page is a left (odd) page.
  ///
  /// When `true`, [pageNumber] is placed in the outer-left column and the
  /// outer-right column is empty. When `false`, [pageNumber] appears in the
  /// outer-right column.
  final bool isLeftPage;

  /// When `true`, all header text widgets (page-number and centre-label) are
  /// omitted. The full-bleed background is still rendered.
  ///
  /// Set by the renderer when a photo slot bleeds into the header band.
  final bool suppressHeader;

  /// When `true`, the footer wordmark widget is omitted. The full-bleed
  /// background is still rendered.
  ///
  /// Set by the renderer when a photo slot bleeds into the footer band.
  final bool suppressFooter;

  @override
  bool operator ==(Object other) =>
      other is DotsPageChrome &&
      other.pageNumber == pageNumber &&
      other.centerLabel == centerLabel &&
      other.wordmark == wordmark &&
      other.isLeftPage == isLeftPage &&
      other.suppressHeader == suppressHeader &&
      other.suppressFooter == suppressFooter;

  @override
  int get hashCode => Object.hash(
        pageNumber,
        centerLabel,
        wordmark,
        isLeftPage,
        suppressHeader,
        suppressFooter,
      );
}

/// An album-spread page whose top and bottom edges carry first-class
/// structural [header] and [footer] declarations.
///
/// This is a sibling subtype alongside [DotsElementsPage] and
/// [DotsLayoutPage] in the sealed [DotsPage] hierarchy. It adds an
/// optional [elements] list (the same primitive [DotsElementsPage] uses)
/// so spread-specific decorative elements can be authored at explicit
/// coordinates.
///
/// Renderer support for drawing the header and footer positions is
/// introduced in slice 2. Slice 1 only establishes the model and parser
/// support; attempting to render a [DotsAlbumSpreadPage] in slice 1
/// throws an [UnimplementedError].
class DotsAlbumSpreadPage extends DotsPage {
  /// Creates an album-spread page.
  const DotsAlbumSpreadPage({
    required super.pageNumber,
    required this.header,
    required this.footer,
    this.elements = const <DotsElement>[],
  });

  // ---------------------------------------------------------------------------
  // Named constructors
  // ---------------------------------------------------------------------------

  /// Builds a dedication page for [type] at [pageNumber].
  ///
  /// Assembles:
  ///   - TITLE: [DotsTextElement] in P22 Mackinac Medium 23pt
  ///   - BODY:  [DotsTextBlockElement] in Inter Book 9pt, 102mm wide, centred,
  ///            with maxChars=1000 and maxLines=32 warn thresholds
  ///   - SIGNATURE (when [signature] is non-empty):
  ///     [DotsRotatedTextElement] in Biro Script Plus 12pt at 2°
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '$pageNumber'.
  /// Footer: wordmark = "Dots. Memories".
  ///
  /// [contextLabelValue] is a pre-resolved string (the caller is responsible
  /// for substituting the token before passing it here).
  factory DotsAlbumSpreadPage.dedication({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required String title,
    required String body,
    required String signature,
  }) {
    // Canonical element positions corrected against pdf02 p.5 / pdf08 p.5
    // (Task 4 fidelity work):
    //   - text x = 50.53 mm from the (right-page) trim left edge.
    //   - body width = 120 mm (was 102 mm — too narrow).
    //   - y values stay near the previous defaults until the relative-y
    //     refinement lands (deferred follow-up: title→body 6.5 mm gap,
    //     body→signature 8 mm gap).
    const double textX = 50.53 * _mmToPt;
    const double titleY = 60 * _mmToPt;
    const double bodyY = 90 * _mmToPt;
    const double signatureY = 160 * _mmToPt;
    const double bodyWidthMm = 120;
    const double bodyWidthPt = bodyWidthMm * _mmToPt;

    final elements = <DotsElement>[
      DotsTextElement(
        x: textX,
        y: titleY,
        value: title,
        fontSize: 23,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextBlockElement(
        x: textX,
        y: bodyY,
        value: body,
        fontSize: 9,
        width: bodyWidthPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 1.2,
        maxChars: 1000,
        maxLines: 32,
      ),
      if (signature.isNotEmpty)
        DotsRotatedTextElement(
          x: textX,
          y: signatureY,
          value: signature,
          fontSize: 12,
          angleDegrees: 2.0,
          fontFamily: 'Biro Script Plus',
          colorHex: '#1e1e1e',
        ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '$pageNumber',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// Builds a closing single page for [type] at [pageNumber].
  ///
  /// The TITLE font size depends on [type]:
  ///   - [DotsAlbumType.boda]                                          → 12pt
  ///   - [DotsAlbumType.parejas], [DotsAlbumType.hijos],
  ///     [DotsAlbumType.individuales], [DotsAlbumType.otros]           → 20pt
  ///
  /// Assembles (in order):
  ///   - PHOTO (when [photoPath] is non-null): [DotsImageElement] 66×86mm,
  ///     centred on the page
  ///   - TITLE: [DotsTextElement] in P22 Mackinac Medium at computed size
  ///   - SUBTITLE: [DotsTextBlockElement] in P22 Mackinac Book 9pt, 2 lines
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '$pageNumber'.
  /// Footer: wordmark = "Dots. Memories".
  factory DotsAlbumSpreadPage.closing({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required String? photoPath,
    required String title,
    required String subtitle,
  }) {
    // Exhaustive switch — compile-time guarantee every type is handled.
    final double titleFontSize = switch (type) {
      DotsAlbumType.boda => 12.0,
      DotsAlbumType.parejas ||
      DotsAlbumType.hijos ||
      DotsAlbumType.individuales ||
      DotsAlbumType.otros ||
      DotsAlbumType.generalEventos =>
        20.0,
    };

    // Text box width is per-category:
    //   - boda (pdf07 p.3):                  86 mm box
    //   - parejas/hijos/individuales/otros/generalEventos:  115 mm box
    final double textBoxWidthMm = switch (type) {
      DotsAlbumType.boda => 86.0,
      DotsAlbumType.parejas ||
      DotsAlbumType.hijos ||
      DotsAlbumType.individuales ||
      DotsAlbumType.otros ||
      DotsAlbumType.generalEventos =>
        115.0,
    };

    // Canonical element positions verified against pdf03 p.3 / pdf09 p.3
    // (parejas/hijos — Task 4 fidelity work) and pdf07 p.3 (boda):
    //   - photo 66×86 mm centred horizontally at y=71.534 mm.
    //   - title  centred horizontally in a per-category-width box;
    //     y = photo_bottom + 5 mm.
    //   - subtitle in the same per-category-width box;
    //     y = title_bottom + 5 mm.
    const double pageWidthMm = 203;
    const double pageWidthPt = pageWidthMm * _mmToPt;
    const double photoWidthPt = 66.0 * _mmToPt;
    const double photoHeightPt = 86.0 * _mmToPt;
    const double photoX = (pageWidthPt - photoWidthPt) / 2.0;
    const double photoY = 71.534 * _mmToPt;
    final double textBoxWidthPt = textBoxWidthMm * _mmToPt;
    final double textBoxX = (pageWidthPt - textBoxWidthPt) / 2.0;
    const double titleY = photoY + photoHeightPt + 5.0 * _mmToPt;
    final double subtitleY = titleY + titleFontSize * 1.2 + 5.0 * _mmToPt;

    final elements = <DotsElement>[
      if (photoPath != null)
        DotsImageElement(
          x: photoX,
          y: photoY,
          assetPath: photoPath,
          width: photoWidthPt,
          height: photoHeightPt,
        ),
      DotsTextElement(
        x: textBoxX,
        y: titleY,
        value: title,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextBlockElement(
        x: textBoxX,
        y: subtitleY,
        value: subtitle,
        fontSize: 9,
        width: textBoxWidthPt,
        fontFamily: 'P22 Mackinac Book',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 1.2,
        maxLines: 2,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '$pageNumber',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  // ---------------------------------------------------------------------------
  // Named constructors
  // ---------------------------------------------------------------------------

  /// Builds a polaroid-collage spread page.
  ///
  /// Zips [photoPaths] against [kDefaultPolaroidSlots] (the 6 documented slot
  /// positions) plus any caller-supplied [additionalSlots] to produce a list
  /// of [DotsPolaroidElement] instances.
  ///
  /// When [applyOtrosGradient] is `true`, the element for slot index 1
  /// (polar-2) carries `gradientRtl: true`; all other elements carry
  /// `gradientRtl: false`.
  ///
  /// [photoPaths] must have exactly
  /// `kDefaultPolaroidSlots.length + additionalSlots.length` entries.
  /// A [RangeError] is thrown if the lengths do not match.
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '${pageNumber + 1}'. This factory builds a
  ///         two-page spread; the right page's number is one greater than
  ///         the left.
  /// Footer: wordmark = "Dots. Memories".
  factory DotsAlbumSpreadPage.polaroidCollage({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required List<String> photoPaths,
    bool applyOtrosGradient = false,
    List<PolaroidSlotPosition> additionalSlots = const <PolaroidSlotPosition>[],
  }) {
    final allSlots = [...kDefaultPolaroidSlots, ...additionalSlots];
    final expectedLength = allSlots.length;
    if (photoPaths.length != expectedLength) {
      throw RangeError.value(
        photoPaths.length,
        'photoPaths.length',
        'Expected $expectedLength photo paths '
            '(${kDefaultPolaroidSlots.length} default slots + '
            '${additionalSlots.length} additional slots), '
            'but got ${photoPaths.length}.',
      );
    }

    final elements = <DotsElement>[];
    for (var i = 0; i < allSlots.length; i++) {
      final slot = allSlots[i];
      // The effective gradient is true when:
      // - the spread-level applyOtrosGradient flag forces it on index 1
      //   (polar-2 otros behavior), OR
      // - the slot itself declares gradientRtl: true.
      final gradientRtl = (applyOtrosGradient && i == 1) || slot.gradientRtl;
      elements.add(DotsPolaroidElement(
        x: slot.x,
        y: slot.y,
        assetPath: photoPaths[i],
        width: slot.width,
        height: slot.height,
        angleDegrees: slot.angleDegrees,
        gradientRtl: gradientRtl,
        bleedLeft: slot.bleedLeft,
        bleedRight: slot.bleedRight,
        bleedTop: slot.bleedTop,
        bleedBottom: slot.bleedBottom,
      ));
    }

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// Builds a cover page for [type] at [pageNumber].
  ///
  /// Supported types: [DotsAlbumType.parejas] and [DotsAlbumType.hijos].
  /// Calling with any other type throws an [ArgumentError].
  ///
  /// Assembles:
  ///   - 14 [DotsDecorativeCircleElement] instances from [kCoverCircleLayout]
  ///     (colour `#CDE7F2`, Gaussian fade 1.764 mm).
  ///   - 3 text elements: eyebrow, title, date line — centered on the page.
  ///
  /// The eyebrow is resolved as follows:
  ///   - [eyebrowOverride] wins when non-null.
  ///   - [DotsAlbumType.parejas] default → `"DOTBOOK DE {PROTAGONISTA}"`.
  ///   - [DotsAlbumType.hijos]   default → `"DOTBOOK DE {PROTAGONISTA}"`.
  ///
  /// The eyebrow token `{PROTAGONISTA}` is resolved by the caller's
  /// variables map at parse time. The literal eyebrow text was corrected
  /// in Task 4 of `final-render-refinement` against
  /// `pdf02_pareja_inicial.pdf` p.2 and `pdf08_hijos_inicial.pdf` p.2;
  /// both PDFs use the same eyebrow format.
  ///
  /// [header] and [footer] are set so that no page-number trio or wordmark
  /// appears on the cover (header trio is all-null; footer wordmark is empty).
  factory DotsAlbumSpreadPage.cover({
    required DotsAlbumType type,
    required int pageNumber,
    required String title,
    required String dateLine,
    String? eyebrowOverride,
  }) {
    // Resolve per-type eyebrow; throw for unsupported types.
    // Both parejas and hijos use the same eyebrow text per the PDF spec
    // sheet (pdf02 p.2 + pdf08 p.2); the {PROTAGONISTA} token is
    // resolved by the variables-map at JSON parse time.
    final String defaultEyebrow = switch (type) {
      DotsAlbumType.parejas ||
      DotsAlbumType.hijos =>
        'DOTBOOK DE {PROTAGONISTA}',
      _ => throw ArgumentError.value(
          type,
          'type',
          'DotsAlbumSpreadPage.cover only supports '
              'DotsAlbumType.parejas and DotsAlbumType.hijos; got $type',
        ),
    };
    final String eyebrow = eyebrowOverride ?? defaultEyebrow;

    // ── 14 decorative circles from kCoverCircleLayout ────────────────────────
    final circles = kCoverCircleLayout
        .map(
          (a) => DotsDecorativeCircleElement(
            x: a.xMm * _mmToPt,
            y: a.yMm * _mmToPt,
            diameter: a.diameterMm * _mmToPt,
            colorHex: '#CDE7F2',
            gaussianFadeMm: 1.764,
            bleedLeft: a.bleedLeft,
            bleedRight: a.bleedRight,
            bleedTop: a.bleedTop,
            bleedBottom: a.bleedBottom,
          ),
        )
        .toList();

    // ── 3 text elements (eyebrow / title / date) ─────────────────────────────
    // PDF coordinates (pdf02 p.2 / pdf08 p.2 annotations):
    // - text box 120 mm wide, x = (203 - 120) / 2 = 41.5 mm
    // - eyebrow y = 110.249 mm
    // - title y   ≈ 119 mm (eyebrow_bottom + small gap)
    // - date y    ≈ 130.7 mm (title_bottom + 5 mm gap)
    const double textBoxWidthMm = 120;
    const double textBoxWidthPt = textBoxWidthMm * _mmToPt;
    const double textBoxXPt = (203.0 - textBoxWidthMm) / 2 * _mmToPt;
    const double eyebrowY = 110.249 * _mmToPt;
    const double titleY = 119.0 * _mmToPt;
    const double dateY = 130.7 * _mmToPt;

    final texts = <DotsElement>[
      DotsTextBlockElement(
        x: textBoxXPt,
        y: eyebrowY,
        value: eyebrow,
        fontSize: 9,
        width: textBoxWidthPt,
        fontFamily: 'Inter',
        textAlign: DotsTextAlign.center,
      ),
      DotsTextBlockElement(
        x: textBoxXPt,
        y: titleY,
        value: title,
        fontSize: 23,
        width: textBoxWidthPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
      ),
      DotsTextBlockElement(
        x: textBoxXPt,
        y: dateY,
        value: dateLine,
        fontSize: 9,
        width: textBoxWidthPt,
        fontFamily: 'Inter',
        textAlign: DotsTextAlign.center,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: const DotsSpreadHeader(),
      footer: const DotsSpreadFooter(wordmark: ''),
      elements: [...circles, ...texts],
    );
  }

  // ---------------------------------------------------------------------------
  // Named constructor — photo-arc spread
  // ---------------------------------------------------------------------------

  /// Builds the "Un año lleno de recuerdos" photo-arc spread for [type].
  ///
  /// Supported types: [DotsAlbumType.parejas], [DotsAlbumType.hijos],
  /// [DotsAlbumType.individuales], and [DotsAlbumType.otros].
  /// Calling with [DotsAlbumType.boda] throws an [ArgumentError].
  ///
  /// **Caller contract**: the [DotsTemplate.pageSize] that wraps this page
  /// MUST have `width >= 406 mm (1150.87 pt)`. Elements with
  /// `x + diameter > pageWidth` will be clipped silently by the PDF viewer.
  ///
  /// Throws a [RangeError] when `content.photoPaths.length != 10`.
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '${pageNumber + 1}'. This factory builds a
  ///         two-page spread; the right page's number is one greater than
  ///         the left.
  factory DotsAlbumSpreadPage.photoArc({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required AlbumPhotoArcContent content,
  }) {
    // Type guard — boda and generalEventos are not supported here.
    if (type == DotsAlbumType.boda || type == DotsAlbumType.generalEventos) {
      throw ArgumentError.value(
        type,
        'type',
        'DotsAlbumSpreadPage.photoArc supports parejas, hijos, individuales, '
            'and otros only. boda uses bodaHalo; generalEventos has its own '
            'opening QR spread (Task 7).',
      );
    }

    // Photo-paths length check.
    if (content.photoPaths.length != kPhotoArcLayout.length) {
      throw RangeError.value(
        content.photoPaths.length,
        'photoPaths.length',
        'Expected ${kPhotoArcLayout.length} photo paths, '
            'got ${content.photoPaths.length}.',
      );
    }

    // Per-type QR caption defaults.
    const String rightCaption = 'Todos tus hitos en un lugar';
    final String defaultLeftCaption = switch (type) {
      DotsAlbumType.parejas => 'Vuestro álbum en digital',
      DotsAlbumType.hijos ||
      DotsAlbumType.individuales ||
      DotsAlbumType.otros =>
        'Tu album en digital',
      DotsAlbumType.boda ||
      DotsAlbumType.generalEventos =>
        '', // unreachable — guarded above
    };
    final String leftCaption =
        content.qrCaptionLeftOverride ?? defaultLeftCaption;
    final String rightCaptionResolved =
        content.qrCaptionRightOverride ?? rightCaption;

    // Oval QR geometry constants (mm → pt).
    // Source: parejas p.9 / boda p.4 canonical spec dimensions.
    const double kOvalWidthMm = 25.841;
    const double kOvalHeightMm = 43.127;
    // Gutter centre at 203 mm; QR centres 27 mm each side.
    // Left QR centre x = 203 - 27 = 176 mm → top-left x = 176 - 25.841/2 = 163.0795 mm.
    // Right QR centre x = 203 + 27 = 230 mm → top-left x = 230 - 25.841/2 = 217.0795 mm.
    // Top of QR caption: 20 mm above page bottom (254 mm) → caption top at 234 mm.
    // Oval top-left y = 254 - 20 - 43.127 = 190.873 mm (caption-top interpretation).
    const double ovalYMm = 190.873;
    const double ovalLeftXMm = 163.0795;
    const double ovalRightXMm = 217.0795;

    // Build 10 photo-circle elements from kPhotoArcLayout.
    final circles = <DotsElement>[
      for (var i = 0; i < kPhotoArcLayout.length; i++)
        DotsPhotoCircleElement(
          x: kPhotoArcLayout[i].xMm * _mmToPt,
          y: kPhotoArcLayout[i].yMm * _mmToPt,
          assetPath: content.photoPaths[i],
          diameter: kPhotoArcLayout[i].diameterMm * _mmToPt,
        ),
    ];

    // Build 2 oval-QR elements at the bottom gutter.
    final ovals = <DotsElement>[
      DotsOvalQrElement(
        x: ovalLeftXMm * _mmToPt,
        y: ovalYMm * _mmToPt,
        ovalWidth: kOvalWidthMm * _mmToPt,
        ovalHeight: kOvalHeightMm * _mmToPt,
        qrPayload: content.qrPayloadLeft,
        caption: leftCaption,
      ),
      DotsOvalQrElement(
        x: ovalRightXMm * _mmToPt,
        y: ovalYMm * _mmToPt,
        ovalWidth: kOvalWidthMm * _mmToPt,
        ovalHeight: kOvalHeightMm * _mmToPt,
        qrPayload: content.qrPayloadRight,
        caption: rightCaptionResolved,
      ),
    ];

    // Build title text at (19 mm, 43 mm) — P22 Mackinac Medium 23pt.
    // Build date subtitle at (19 mm, 43 mm + 23pt*1.2/mmToPt + 5 mm).
    // 23pt * 1.2 = 27.6pt; 27.6pt / 2.834645669 ≈ 9.737 mm; + 5 mm = 14.737 mm gap.
    const double titleXMm = 19.0;
    const double titleYMm = 43.0;
    const double titleFontSize = 23.0;
    const double subtitleXMm = 19.0;
    const double subtitleYMm =
        titleYMm + (titleFontSize * 1.2 / _mmToPt) + 5.0;

    final texts = <DotsElement>[
      DotsTextElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: content.title,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextElement(
        x: subtitleXMm * _mmToPt,
        y: subtitleYMm * _mmToPt,
        value: content.dateSubtitle,
        fontSize: 9.0,
        fontFamily: 'P22 Mackinac Book',
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: [...circles, ...ovals, ...texts],
    );
  }

  /// Builds a boda-cluster spread page for [type] at [pageNumber].
  ///
  /// The page is the boda p.3 "Antes de empezar el viaje" layout: 7 cluster
  /// photos, a two-line title (medium + medium italic), and a body block.
  ///
  /// Supported type: [DotsAlbumType.boda] only.
  /// Throws [ArgumentError] for any other type.
  /// Throws [RangeError] when `content.photoPaths.length != 7`.
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '${pageNumber + 1}'.
  /// Footer: wordmark = 'Dots. Memories'.
  factory DotsAlbumSpreadPage.bodaCluster({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required AlbumBodaClusterContent content,
  }) {
    if (type != DotsAlbumType.boda) {
      throw ArgumentError.value(
        type,
        'type',
        'DotsAlbumSpreadPage.bodaCluster only supports DotsAlbumType.boda.',
      );
    }

    if (content.photoPaths.length != kBodaClusterLayout.length) {
      throw RangeError.value(
        content.photoPaths.length,
        'photoPaths.length',
        'Expected ${kBodaClusterLayout.length} photo paths, '
            'got ${content.photoPaths.length}.',
      );
    }

    // ── 7 cluster photo elements ────────────────────────────────────────────
    // Coordinates from kBodaClusterLayout are right-page-relative (origin at
    // right-page gutter). Translate to spread coordinates by adding 203 mm.
    const double rightPageOffsetMm = 203.0;

    final photoElements = <DotsElement>[
      for (var i = 0; i < kBodaClusterLayout.length; i++)
        DotsClusterPhotoElement(
          x: (kBodaClusterLayout[i].xMm + rightPageOffsetMm) * _mmToPt,
          y: kBodaClusterLayout[i].yMm * _mmToPt,
          assetPath: content.photoPaths[i],
          width: kBodaClusterLayout[i].widthMm * _mmToPt,
          height: kBodaClusterLayout[i].heightMm * _mmToPt,
          opacityGradientStart: kBodaClusterLayout[i].opacityGradientStart,
          opacityGradientEnd: kBodaClusterLayout[i].opacityGradientEnd,
          opacityGradientDirection:
              kBodaClusterLayout[i].opacityGradientDirection,
          gaussianFadeMm: kBodaClusterLayout[i].gaussianFadeMm,
          bleedTop: kBodaClusterLayout[i].bleedTop,
        ),
    ];

    // ── 2 title text elements ───────────────────────────────────────────────
    // Line 1: P22 Mackinac Medium 23pt at (19 mm + 203 mm offset, 43 mm).
    // Line 2: P22 Mackinac Medium Italic 23pt, 27.6 pt below line 1.
    const double titleXPt = (19.0 + rightPageOffsetMm) * _mmToPt;
    const double titleYPt = 43.0 * _mmToPt;
    const double titleFontSize = 23.0;
    const double line2YPt = titleYPt + 27.6;

    final textElements = <DotsElement>[
      DotsTextElement(
        x: titleXPt,
        y: titleYPt,
        value: content.title,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextElement(
        x: titleXPt,
        y: line2YPt,
        value: content.titleItalicLine,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium Italic',
      ),
    ];

    // ── 1 body text block ───────────────────────────────────────────────────
    // Inter Book 9pt, 95 mm wide, lineHeight 1.2, left-aligned.
    // Positioned 27.6 pt below line 2 + 5 mm gap.
    const double bodyXPt = (19.0 + rightPageOffsetMm) * _mmToPt;
    const double bodyYPt = line2YPt + 27.6 + 5.0 * _mmToPt;
    const double bodyWidthPt = 95.0 * _mmToPt;

    final bodyElement = DotsTextBlockElement(
      x: bodyXPt,
      y: bodyYPt,
      value: content.body,
      fontSize: 9,
      width: bodyWidthPt,
      fontFamily: 'Inter',
      textAlign: DotsTextAlign.left,
      lineHeight: 1.2,
    );

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: [...photoElements, ...textElements, bodyElement],
    );
  }

  // ---------------------------------------------------------------------------
  // Named constructor — boda-halo spread (stub; body implemented in PR 2)
  // ---------------------------------------------------------------------------

  /// Builds the "Boda de Nombre&Nombre" radial halo title spread for
  /// [DotsAlbumType.boda] (boda p.4).
  ///
  /// Throws [ArgumentError] for any `type != DotsAlbumType.boda`.
  /// Throws [RangeError] if `content.photoPaths.length != 10`.
  ///
  /// Produces exactly 15 elements:
  ///   - 10 [DotsRotatedPhotoElement] instances from [kBodaHaloLayout].
  ///   - 2 [DotsOvalQrElement] instances for the gutter QR cards.
  ///   - 3 [DotsTextElement] instances: title line 1, title line 2, date.
  ///
  /// Header: leftPageNumber = '$pageNumber', centerLabel = [contextLabelValue],
  ///         rightPageNumber = '${pageNumber + 1}'.
  /// Footer: wordmark = 'Dots. Memories'.
  factory DotsAlbumSpreadPage.bodaHalo({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required AlbumBodaHaloContent content,
  }) {
    if (type != DotsAlbumType.boda) {
      throw ArgumentError.value(
        type,
        'type',
        'DotsAlbumSpreadPage.bodaHalo only supports DotsAlbumType.boda.',
      );
    }

    if (content.photoPaths.length != 10) {
      throw RangeError.value(
        content.photoPaths.length,
        'photoPaths.length',
        'Expected 10 photo paths, got ${content.photoPaths.length}.',
      );
    }

    // ── 10 rotated photo elements from kBodaHaloLayout ─────────────────────
    // Indices 0–4 are R-slots (right-page-relative): add 203 mm offset.
    // Indices 5–9 are L-slots (left-page-relative): no offset.
    const double rightPageOffsetMm = 203.0;
    // Uniform unrotated dimensions: 33.5 mm wide × 46.4 mm tall.
    const double widthPt = 33.5 * _mmToPt;
    const double heightPt = 46.4 * _mmToPt;

    final photoElements = <DotsElement>[
      for (var i = 0; i < kBodaHaloLayout.length; i++)
        DotsRotatedPhotoElement(
          x: (kBodaHaloLayout[i].xMm +
                  (i < 5 ? rightPageOffsetMm : 0.0)) *
              _mmToPt,
          y: kBodaHaloLayout[i].yMm * _mmToPt,
          assetPath: content.photoPaths[i],
          width: widthPt,
          height: heightPt,
          angleDegrees: kBodaHaloLayout[i].angleDegrees,
          bleedBottom: kBodaHaloLayout[i].bleedBottom,
        ),
    ];

    // ── 2 oval QR elements at the bottom gutter ─────────────────────────────
    // Oval dimensions reused from slice 5 (25.841 × 43.127 mm).
    // Left QR centre x = 176 mm → TL x = 176 − 25.841/2 = 163.0795 mm.
    // Right QR centre x = 230 mm → TL x = 230 − 25.841/2 = 217.0795 mm.
    // y = 190.87 mm (caption-top interpretation, same as slice 5).
    const double kOvalWidthMm = 25.841;
    const double kOvalHeightMm = 43.127;
    const double ovalYMm = 190.87;
    const double ovalLeftXMm = 176.0 - kOvalWidthMm / 2.0;
    const double ovalRightXMm = 230.0 - kOvalWidthMm / 2.0;

    const String defaultLeftCaption = 'Vuestro álbum en digital';
    const String defaultRightCaption =
        'Escanea el QR para volver a ver el álbum y los vídeos';

    final String leftCaption =
        content.qrCaptionLeftOverride ?? defaultLeftCaption;
    final String rightCaption =
        content.qrCaptionRightOverride ?? defaultRightCaption;

    final ovals = <DotsElement>[
      DotsOvalQrElement(
        x: ovalLeftXMm * _mmToPt,
        y: ovalYMm * _mmToPt,
        ovalWidth: kOvalWidthMm * _mmToPt,
        ovalHeight: kOvalHeightMm * _mmToPt,
        qrPayload: content.qrPayloadLeft,
        caption: leftCaption,
      ),
      DotsOvalQrElement(
        x: ovalRightXMm * _mmToPt,
        y: ovalYMm * _mmToPt,
        ovalWidth: kOvalWidthMm * _mmToPt,
        ovalHeight: kOvalHeightMm * _mmToPt,
        qrPayload: content.qrPayloadRight,
        caption: rightCaption,
      ),
    ];

    // ── 3 text elements (title line 1, title line 2, date subtitle) ─────────
    // Title: P22 Mackinac Medium 23pt / 27.6pt leading at (19 mm, 43 mm)
    // on the left page (no +203 mm offset — boda halo title is left-page only).
    // Line 2: 27.6 pt below line 1 (23pt × 1.2 leading).
    // Date: P22 Mackinac Book 9pt, 5 mm below line 2.
    const double titleXMm = 19.0;
    const double titleYMm = 43.0;
    const double titleFontSize = 23.0;
    const double titleLeadingPt = titleFontSize * 1.2; // 27.6 pt
    const double line2YPt = titleYMm * _mmToPt + titleLeadingPt;
    const double dateYPt = line2YPt + titleLeadingPt + 5.0 * _mmToPt;

    final texts = <DotsElement>[
      DotsTextElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: content.titleLine1,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextElement(
        x: titleXMm * _mmToPt,
        y: line2YPt,
        value: content.titleLine2,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextElement(
        x: titleXMm * _mmToPt,
        y: dateYPt,
        value: content.dateSubtitle,
        fontSize: 9.0,
        fontFamily: 'P22 Mackinac Book',
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: [...photoElements, ...ovals, ...texts],
    );
  }

  // ---------------------------------------------------------------------------
  // Category factory stubs (Task 2 — pliego-first-category).
  //
  // Each stub builds a DotsAlbumSpreadPage whose elements list carries a
  // single [DotsUnimplementedElement]. The page parses and constructs
  // cleanly so the parser's category-driven mandatory-pliego injection
  // succeeds for every category, but rendering throws an
  // [UnimplementedError] whose message names the task that fills in the
  // real visual content. The header trio + footer wordmark follow the
  // existing chrome convention so Tasks 4–7 can swap the elements list
  // without touching the chrome plumbing.
  // ---------------------------------------------------------------------------

  /// Photo-only cover (no decorative circles) — used by `individuales`,
  /// `otros`, and `generalEventos`.
  ///
  /// Filled against `pdf10_individual_inicial.pdf` p.1. Single-page layout:
  /// 59×73 mm photo centered horizontally (72 mm margins on a 203 mm-wide
  /// page) at y=80.756; title (P22 Mackinac Medium 23pt, 120 mm wide,
  /// center-aligned) 5 mm below the photo; date line (Inter Book 9pt,
  /// 120 mm wide, center-aligned) 5 mm below the title.
  ///
  /// `content.title` carries whatever variable the caller resolved (e.g.
  /// `{NombreDelAlbum}` for individuales/otros, `{TítuloDelAlbum}` for
  /// generalEventos). `content.dateLine` is the rendered text — typically
  /// the resolved start-date variable.
  ///
  /// `parejas`, `hijos`, and `boda` reject with `ArgumentError` (those
  /// categories use the decorative-circle `cover(...)` factory or the
  /// boda-specific cover that remains deferred).
  factory DotsAlbumSpreadPage.photoOnlyCover({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumPhotoOnlyCoverContent content,
    String contextLabelValue = '',
  }) {
    switch (type) {
      case DotsAlbumType.individuales:
      case DotsAlbumType.otros:
      case DotsAlbumType.generalEventos:
        break; // supported categories.
      case DotsAlbumType.parejas:
      case DotsAlbumType.hijos:
      case DotsAlbumType.boda:
        throw ArgumentError.value(
          type,
          'type',
          'DotsAlbumSpreadPage.photoOnlyCover only supports '
              'DotsAlbumType.individuales, otros, and generalEventos '
              '(parejas/hijos use cover(...); boda has no cover layout '
              'in docs/templates/final_templates/).',
        );
    }
    assert(content.photoPath.isNotEmpty);

    // Layout constants (mm) — verified against pdf10 p.1.
    const double photoWidthMm = 59;
    const double photoHeightMm = 73;
    const double photoYMm = 80.756;
    // Photo centered horizontally on a 203 mm page: x = (203 - 59) / 2 = 72.
    const double photoXMm = (203 - photoWidthMm) / 2;

    const double titleFontSize = 23.0;
    const double titleLineHeight = 27.6 / 23; // 1.2.
    const double titleWidthMm = 120;
    const double titleXMm = (203 - titleWidthMm) / 2; // 41.5 mm.
    const double titleYMm = photoYMm + photoHeightMm + 5; // 158.756 mm.
    // 6.635 mm title-box height per pdf10 annotation.
    const double titleBoxHeightMm = 6.635;

    const double dateFontSize = 9.0;
    const double dateLineHeight = 10.8 / 9; // 1.2.
    const double dateWidthMm = 120;
    const double dateXMm = (203 - dateWidthMm) / 2; // 41.5 mm.
    const double dateYMm = titleYMm + titleBoxHeightMm + 5; // 170.391 mm.

    final elements = <DotsElement>[
      DotsImageElement(
        x: photoXMm * _mmToPt,
        y: photoYMm * _mmToPt,
        assetPath: content.photoPath,
        width: photoWidthMm * _mmToPt,
        height: photoHeightMm * _mmToPt,
      ),
      DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: content.title,
        fontSize: titleFontSize,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: titleLineHeight,
      ),
      DotsTextBlockElement(
        x: dateXMm * _mmToPt,
        y: dateYMm * _mmToPt,
        value: content.dateLine,
        fontSize: dateFontSize,
        width: dateWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: dateLineHeight,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: pageNumber.isOdd ? '$pageNumber' : null,
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: pageNumber.isOdd ? null : '$pageNumber',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// Photo-grid + chapter-cluster (Q1/Q2) instruction spread — two pages
  /// spanning 0..406 mm in spread coordinates.
  ///
  /// Layout (uniform across all six categories, verified against
  /// `pdf02_pareja_inicial.pdf` p.9, `pdf08_hijos_inicial.pdf` p.9,
  /// `pdf10_individual_inicial.pdf` p.7, `pdf04_otros_inicial.pdf` p.7,
  /// `pdf12_general_eventos_inicial.pdf` p.2, `pdf06_boda_inicial.pdf`
  /// p.2):
  ///   - 5+5 photo slots at y=36 mm (35×46 mm each).
  ///   - Per-page chapter cluster below the slots: marker, title,
  ///     body. Title centered in a 141 mm-wide box at x=30.53 mm;
  ///     body centered in a 93 mm-wide box at x=55.309 mm.
  ///
  /// Per-category copy:
  ///   - `parejas`, `hijos`: marker `(Q1)` / `(Q2)`, canonical bodies
  ///     from the source PDFs.
  ///   - `individuales`, `otros`, `boda`, `generalEventos`: marker
  ///     `(01)` / `(02)`, per-category bodies.
  ///
  /// History: Task 4 originally combined this spread with a separate
  /// "Antes de empezar el viaje" decorative-circles spread (pdf02 p.10
  /// / pdf08 equivalent / pdf10 p.8 / etc.) into a single factory with
  /// invented Q1/Q2 body copy. That fidelity bug was fixed in a
  /// follow-up: this factory now matches the canonical Q1/Q2 spread
  /// only, and the standalone "Antes de empezar el viaje" spread is
  /// either a future factory addition or remains unrendered.
  factory DotsAlbumSpreadPage.beforeYouStart({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumBeforeYouStartContent content,
    String contextLabelValue = '',
  }) {
    // Per-category Q1/Q2 chapter-cluster copy. Canonical, NOT editable
    // by the caller — the factory selects per-category Spanish text
    // from the source PDFs.
    final (
      String q1Marker,
      String q1Title,
      String q1Body,
      String q2Marker,
      String q2Title,
      String q2Body,
    ) = switch (type) {
      DotsAlbumType.parejas => (
          // pdf02 p.9 — vosotros form, marker uses Q-letter prefix.
          '(Q1)',
          'Buscad vuestro momento',
          'Encontrad un espacio donde podáis estar en calma. Sentaos. '
              'Respirad despacio. Dejad que el silencio os encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'con ello comienza vuestro viaje al pasado. Sentid. '
              'Dejaos llevar. Ese es el único objetivo.',
          '(Q2)',
          'Escuchad vuestra historia',
          'Hay recuerdos que no caben en una foto. Durante todo este '
              'tiempo habéis ido guardando esos instantes que han '
              'marcado vuestra historia, para que encuentren un lugar '
              'permanente en vuestra memoria. Estos recuerdos van '
              'acompañados de un código QR; escanéalo y podréis revivir '
              'las voces, las palabras y las emociones de esos momentos '
              'compartidos, guardados en el tiempo para vosotros.',
        ),
      DotsAlbumType.hijos => (
          // pdf08 p.9 — tú form, marker uses Q-letter prefix.
          '(Q1)',
          'Busca un lugar tranquilo',
          'Encuentra un espacio donde puedas estar en calma. Siéntate. '
              'Respira despacio. Deja que el silencio te encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'con ello comienza tu viaje al pasado. Siente. Déjate '
              'llevar. Ese es el único objetivo.',
          '(Q2)',
          'Escucha los momentos especiales',
          'Hay páginas con recuerdos que no caben en una foto. Durante '
              'todo este tiempo hemos ido guardando esos instantes que '
              'marcaron tu camino, para que encuentren un lugar '
              'permanente en tu memoria. Estos recuerdos van '
              'acompañados de un código QR, escanéalo: escucharás la '
              'voz de quienes estuvieron contigo mientras crecías, sus '
              'palabras congeladas en el tiempo para ti.',
        ),
      DotsAlbumType.generalEventos => (
          // pdf12 p.2 — tú form, numeric markers.
          '(01)',
          'Busca un lugar tranquilo',
          'Encuentra un espacio donde puedas estar en calma. Siéntate. '
              'Respira despacio. Deja que el silencio te encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'con ello comienza tu viaje al pasado. Siente. Déjate '
              'llevar. Ese es el único objetivo.',
          '(02)',
          'Más allá del papel',
          'Las fotografías capturan instantes. Los vídeos conservan las '
              'voces, las emociones y todo aquello que el papel no '
              'puede guardar. En el final de este Dotbook encontrarás '
              'un código QR para revivir esos momentos más especiales '
              'de una forma más viva y real. Porque hay recuerdos que '
              'no solo se miran… también se sienten.',
        ),
      DotsAlbumType.boda => (
          // pdf06 p.2 — Q1 body matches generalEventos; Q2 body differs
          // (wedding-photo + QR copy).
          '(01)',
          'Busca un lugar tranquilo',
          'Encuentra un espacio donde puedas estar en calma. Siéntate. '
              'Respira despacio. Deja que el silencio te encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'con ello comienza tu viaje al pasado. Siente. Déjate '
              'llevar. Ese es el único objetivo.',
          '(02)',
          'Más allá del papel',
          'En estas páginas tienes la historia impresa para guardarla '
              'siempre. Las fotos, no son solo imágenes, sino una señal '
              'de que aquellos que más quieres estuvieron a tu lado en '
              'este día tan importante. Sin embargo, hay momentos que '
              'se viven mejor en movimiento: los vídeos forman una parte '
              'importante de este recuerdo. En las última páginas de '
              'este libro encontraréis un código QR, escanéalo y vuelve '
              'al álbum digital cuando quieras para revivir un instante '
              'concreto y ver todo lo que quedó más allá del papel.',
        ),
      DotsAlbumType.individuales => (
          // pdf10 p.7 — tú form. Title from pdf reads "Encontra" (no u);
          // body uses "Encuentra". Faithful to the source.
          '(01)',
          'Encontra tu momento',
          'Encuentra un espacio donde puedas estar en calma. Siéntate. '
              'Respira despacio. Deja que el silencio te encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'comienza este viaje hacia tus recuerdos. Siente. Déjate '
              'llevar. Ese es el único objetivo.',
          '(02)',
          'Escucha la historia',
          'Hay recuerdos que no caben en una foto. Momentos, palabras y '
              'emociones que merecen ser vividos también con la voz. A '
              'lo largo de este Dotbook encontrarás tarjetas '
              'acompañadas de un código QR. Cuando llegues a ellas, '
              'escanéalo y deja que el recuerdo cobre vida. Escucharás '
              'fragmentos guardados en el tiempo: palabras, voces y '
              'momentos que un día formaron parte de esta historia y '
              'que hoy puedes volver a sentir.',
        ),
      DotsAlbumType.otros => (
          // pdf04 p.7 — vosotros form.
          '(01)',
          'Encontrad vuestro momento',
          'Encontrad un espacio donde podáis estar en calma. Sentaos. '
              'Respirad despacio. Dejad que el silencio os encuentre, '
              'aunque sea por un instante, y que todo lo demás se '
              'disuelva un poco: las prisas, los pensamientos, el ruido '
              'de fuera... En ese pequeño respiro, el tiempo se abre y '
              'comienza este viaje hacia vuestros recuerdos. Sentid. '
              'Dejaos llevar. Ese es el único objetivo.',
          '(02)',
          'Escuchad la historia',
          'Hay recuerdos que no caben en una foto. Momentos, palabras y '
              'emociones que merecen ser vividos también con la voz. A '
              'lo largo de este Dotbook encontraréis tarjetas '
              'acompañadas de un código QR. Cuando lleguéis a ellas, '
              'escaneadlo y dejad que el recuerdo cobre vida. '
              'Escucharéis fragmentos guardados en el tiempo: palabras, '
              'voces y momentos que un día formaron parte de esta '
              'historia y que hoy podéis volver a sentir.',
        ),
    };

    // Layout constants (mm) — verified against pdf02 p.9 + pdf08 p.9
    // and the four single-category source PDFs.
    const double slotWidthMm = 35;
    const double slotHeightMm = 46;
    const double slotYMm = 36;
    const List<double> slotXLeftPageMm = [8, 43, 78, 113, 148];

    // Per-page chapter cluster below the slots. Two box widths:
    //   - Title box: x=30.53, width=141 mm (wide, holds marker + title).
    //   - Body  box: x=55.309, width=93 mm (narrower, holds body text).
    const double titleClusterXMm = 30.53;
    const double titleClusterWidthMm = 141;
    const double bodyClusterXMm = 55.309;
    const double bodyClusterWidthMm = 93;
    const double clusterYNumberMm = 89.5; // slot_bottom (36+46=82) + 7.5 mm.
    const double clusterYTitleMm = 101.5; // number_bottom + small gap.
    const double clusterYBodyMm = 113.5; // title_bottom + 5 mm gap.

    final elements = <DotsElement>[
      // ── Left-page photo slots ──────────────────────────────────────
      for (int i = 0; i < 5; i++)
        DotsImageElement(
          x: slotXLeftPageMm[i] * _mmToPt,
          y: slotYMm * _mmToPt,
          assetPath: content.photoPaths[i],
          width: slotWidthMm * _mmToPt,
          height: slotHeightMm * _mmToPt,
        ),
      // ── Right-page photo slots (spread coords x += 203) ────────────
      for (int i = 0; i < 5; i++)
        DotsImageElement(
          x: (203 + slotXLeftPageMm[i]) * _mmToPt,
          y: slotYMm * _mmToPt,
          assetPath: content.photoPaths[5 + i],
          width: slotWidthMm * _mmToPt,
          height: slotHeightMm * _mmToPt,
        ),
      // ── Q1 cluster (LEFT page) ─────────────────────────────────────
      // Marker centered within the title-width box.
      DotsTextBlockElement(
        x: titleClusterXMm * _mmToPt,
        y: clusterYNumberMm * _mmToPt,
        value: q1Marker,
        fontSize: 23,
        width: titleClusterWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 27.6 / 23,
      ),
      DotsTextBlockElement(
        x: titleClusterXMm * _mmToPt,
        y: clusterYTitleMm * _mmToPt,
        value: q1Title,
        fontSize: 23,
        width: titleClusterWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 27.6 / 23,
      ),
      DotsTextBlockElement(
        x: bodyClusterXMm * _mmToPt,
        y: clusterYBodyMm * _mmToPt,
        value: q1Body,
        fontSize: 9,
        width: bodyClusterWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 10.8 / 9,
      ),
      // ── Q2 cluster (RIGHT page; spread coords x += 203) ────────────
      DotsTextBlockElement(
        x: (203 + titleClusterXMm) * _mmToPt,
        y: clusterYNumberMm * _mmToPt,
        value: q2Marker,
        fontSize: 23,
        width: titleClusterWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 27.6 / 23,
      ),
      DotsTextBlockElement(
        x: (203 + titleClusterXMm) * _mmToPt,
        y: clusterYTitleMm * _mmToPt,
        value: q2Title,
        fontSize: 23,
        width: titleClusterWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 27.6 / 23,
      ),
      DotsTextBlockElement(
        x: (203 + bodyClusterXMm) * _mmToPt,
        y: clusterYBodyMm * _mmToPt,
        value: q2Body,
        fontSize: 9,
        width: bodyClusterWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 10.8 / 9,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// "Bienvenido/a a tu viaje al pasado" welcome spread — supports the
  /// `generalEventos` (initial pliego 2) and `boda` categories.
  ///
  /// Filled in Task 5 of `final-render-refinement` against
  /// `pdf12_general_eventos_inicial.pdf` p.1. The boda arm was added in
  /// a follow-up against `pdf06_boda_inicial.pdf` p.1 — same layout as
  /// generalEventos, but the body gets a boda-specific intro sentence
  /// ("Prepárate para revivir uno de los días más bonitos de tu vida.")
  /// prepended to the shared "door" copy.
  ///
  /// Visual layout: 48×60 mm light-blue rounded rectangle at top, the
  /// two-line title "Bienvenido/a / a tu viaje al pasado" (P22 Mackinac
  /// Medium 18pt, centered) 5 mm below, multi-paragraph body block
  /// (Inter Book 9pt, centered, 87 mm wide) 5 mm below the title.
  /// Single-page coords (0..203 mm).
  factory DotsAlbumSpreadPage.welcomeJourney({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumWelcomeJourneyContent content,
    String contextLabelValue = '',
  }) {
    // Per-category body copy. Title and layout are shared.
    final String defaultBody = switch (type) {
      DotsAlbumType.generalEventos =>
        'Este no es un álbum cualquiera: es una puerta que se abre hacia '
            'esos momentos que parecían efímeros, pero que quedaron '
            'guardados para siempre.\n'
            'Antes de empezar, sigue los pasos que encontrarás a '
            'continuación. Lee despacio, sin prisa y siente cada momento '
            'de nuevo.',
      DotsAlbumType.boda =>
        'Prepárate para revivir uno de los días más bonitos de tu vida.\n'
            'Este no es un álbum cualquiera: es una puerta que se abre '
            'hacia esos momentos que parecían efímeros, pero que '
            'quedaron guardados para siempre.\n'
            'Antes de empezar, sigue los pasos que encontrarás a '
            'continuación. Lee despacio, sin prisa y siente cada momento '
            'de nuevo.',
      _ => throw ArgumentError.value(
          type,
          'type',
          'DotsAlbumSpreadPage.welcomeJourney supports '
              'DotsAlbumType.generalEventos and DotsAlbumType.boda only.',
        ),
    };

    // Layout constants (mm) — verified against pdf12 p.1 and pdf06 p.1.
    const double rectXMm = 77.5;
    const double rectYMm = 67;
    const double rectWidthMm = 48;
    const double rectHeightMm = 60;
    const double rectBorderRadiusMm = 4;
    const String rectColorHex = '#CDE7F2';

    const double titleXMm = 58;
    const double titleYMm = 132; // rect.bottom (67 + 60) + 5 mm gap.
    const double titleWidthMm = 87;

    const double bodyXMm = 58;
    const double bodyYMm = 149.7; // title.bottom (~144.7) + 5 mm gap.
    const double bodyWidthMm = 87;

    const String defaultTitle = 'Bienvenido/a\na tu viaje al pasado';

    final elements = <DotsElement>[
      const DotsDecorativeRectElement(
        x: rectXMm * _mmToPt,
        y: rectYMm * _mmToPt,
        width: rectWidthMm * _mmToPt,
        height: rectHeightMm * _mmToPt,
        colorHex: rectColorHex,
        borderRadius: rectBorderRadiusMm * _mmToPt,
      ),
      DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: content.titleOverride ?? defaultTitle,
        fontSize: 18,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 1.167, // 21pt / 18pt per pdf12 annotation.
      ),
      DotsTextBlockElement(
        x: bodyXMm * _mmToPt,
        y: bodyYMm * _mmToPt,
        value: content.bodyOverride ?? defaultBody,
        fontSize: 9,
        width: bodyWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 1.2,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: pageNumber.isOdd ? '$pageNumber' : null,
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: pageNumber.isOdd ? null : '$pageNumber',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// "Porque algunos recuerdos…" opening QR spread — specific to the
  /// `generalEventos` category (initial pliego 1).
  ///
  /// Filled in Task 5 of `final-render-refinement`. No annotated source
  /// PDF exists for the opening variant; the LEFT-page geometry mirrors
  /// `closingQrSpread` (`pdf03_pareja_final.pdf` p.1 — title at y=50.892,
  /// body at y=71.346, square 27×27 mm QR at (30, 94.081), caption to the
  /// right of the QR). The opening differs from the closing in role
  /// (welcome vs farewell) and body copy; visual layout is otherwise
  /// identical. The RIGHT-page decorative-circle scatter is shared with
  /// `closingQrSpread` (see [_kRightPageCircles]) per the design's
  /// "QR LEFT, circles RIGHT" specification.
  factory DotsAlbumSpreadPage.openingQrSpread({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumQrSpreadContent content,
    String contextLabelValue = '',
  }) {
    if (type != DotsAlbumType.generalEventos) {
      throw ArgumentError.value(
        type,
        'type',
        'DotsAlbumSpreadPage.openingQrSpread only supports '
            'DotsAlbumType.generalEventos.',
      );
    }
    assert(content.placement == AlbumQrSpreadPlacement.opening);

    // Layout constants (mm) — mirror closingQrSpread (pdf03 p.1).
    const double titleXMm = 30;
    const double titleYMm = 50.892;
    const double titleWidthMm = 143;
    const double bodyXMm = 30;
    const double bodyYMm = 71.346;
    const double bodyWidthMm = 92;
    const double qrXMm = 30;
    const double qrYMm = 94.081;
    const double qrSizeMm = 27;
    const double qrCaptionXMm = 62; // 30 + 27 + 5 gap.
    const double qrCaptionYMm = 94.081;
    const double qrCaptionWidthMm = 36.178;

    final String qrCaption = content.captionOverride ??
        'Escanea el QR para abrir tu viaje al pasado.';

    final elements = <DotsElement>[
      // Title — shared opening/closing wording.
      const DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: 'Porque algunos recuerdos merecen seguir vivos',
        fontSize: 23,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.087, // 25 / 23.
      ),
      // Body — opening copy (welcoming role).
      const DotsTextBlockElement(
        x: bodyXMm * _mmToPt,
        y: bodyYMm * _mmToPt,
        value: 'Las fotografías capturan instantes. Los vídeos conservan '
            'las voces, las emociones y todo aquello que el papel no puede '
            'guardar. Escanea el QR al final de este Dotbook para revivir '
            'esos momentos más especiales de una forma más viva y real.',
        fontSize: 9,
        width: bodyWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.2,
      ),
      // QR block — 27×27 mm square; oval element with equal w/h is a
      // temporary approximation pending a true square-frame element
      // variant (same approximation as closingQrSpread).
      DotsOvalQrElement(
        x: qrXMm * _mmToPt,
        y: qrYMm * _mmToPt,
        ovalWidth: qrSizeMm * _mmToPt,
        ovalHeight: qrSizeMm * _mmToPt,
        qrPayload: content.qrPayload,
        caption: '', // caption rendered separately to the right of the QR.
      ),
      // QR caption — to the right of the QR block.
      DotsTextBlockElement(
        x: qrCaptionXMm * _mmToPt,
        y: qrCaptionYMm * _mmToPt,
        value: qrCaption,
        fontSize: 9,
        width: qrCaptionWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.2,
      ),
      // Right-page decorative-circle scatter — shared with
      // closingQrSpread per the design's "QR LEFT, circles RIGHT"
      // specification. Same 28-circle layout from pdf13 p.1 + p.2,
      // with the right-to-left opacity gradient applied per-circle.
      for (final c in _kRightPageCircles)
        DotsDecorativeCircleElement(
          x: c.xMm * _mmToPt,
          y: c.yMm * _mmToPt,
          diameter: c.diameterMm * _mmToPt,
          colorHex: '#CDE7F2',
          opacityAlpha: _qrCircleAlphaForX(c.xMm),
        ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// "Porque algunos recuerdos merecen seguir vivos" closing QR spread
  /// — shared by ALL six categories as the penultimate pliego.
  ///
  /// Body landed in Task 4 of `final-render-refinement` against
  /// `pdf03_pareja_final.pdf` p.1–2 and `pdf09_hijos_final.pdf` p.1–2.
  /// The LEFT page carries the title, body, QR block, QR caption, and
  /// bottom variable text. The RIGHT-page decorative-circle scatter was
  /// landed in a follow-up against `pdf13_general_eventos_final.pdf`
  /// p.1 (annotated diameters) + p.2 (annotated X/Y positions); see
  /// [_kRightPageCircles] for the 28-circle data table.
  factory DotsAlbumSpreadPage.closingQrSpread({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumQrSpreadContent content,
    String contextLabelValue = '',
  }) {
    assert(content.placement == AlbumQrSpreadPlacement.closing);

    // Layout constants (mm) — verified against pdf03 p.1.
    const double titleXMm = 30;
    const double titleYMm = 50.892;
    const double titleWidthMm = 143;
    const double bodyXMm = 30;
    const double bodyYMm = 71.346;
    const double bodyWidthMm = 92;
    const double qrXMm = 30;
    const double qrYMm = 94.081;
    const double qrSizeMm = 27;
    const double qrCaptionXMm = 62; // 30 + 27 + 5 gap.
    const double qrCaptionYMm = 94.081;
    const double qrCaptionWidthMm = 36.178;
    const double bottomXMm = 30;
    const double bottomYMm = 229.42;
    const double bottomWidthMm = 143;

    final String bottomText = content.bottomTextOverride ??
        (contextLabelValue.isEmpty
            ? '{Protagonistas}, disfruta de está última experiencia.'
            : '$contextLabelValue, disfruta de está última experiencia.');
    final String qrCaption =
        content.captionOverride ?? 'Escanea el QR y vuelve a esta etapa siempre que quieras.';

    final elements = <DotsElement>[
      // Title.
      const DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleYMm * _mmToPt,
        value: 'Porque algunos recuerdos merecen seguir vivos',
        fontSize: 23,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.087, // 25 / 23.
      ),
      // Body — fixed canonical copy.
      const DotsTextBlockElement(
        x: bodyXMm * _mmToPt,
        y: bodyYMm * _mmToPt,
        value: 'Las fotografías capturan momentos. Las palabras los hacen '
            'vivir. En este álbum, ambos viajan juntos para que el tiempo '
            'no los borre.',
        fontSize: 9,
        width: bodyWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.2,
      ),
      // QR block. The PDF shows a SQUARE 27×27 mm block; we use the
      // existing oval QR element with equal width/height as a temporary
      // approximation. A follow-up task replaces this with a true
      // square-frame variant.
      DotsOvalQrElement(
        x: qrXMm * _mmToPt,
        y: qrYMm * _mmToPt,
        ovalWidth: qrSizeMm * _mmToPt,
        ovalHeight: qrSizeMm * _mmToPt,
        qrPayload: content.qrPayload,
        caption: '', // caption rendered separately to the right of the QR.
      ),
      // QR caption — to the right of the QR block.
      DotsTextBlockElement(
        x: qrCaptionXMm * _mmToPt,
        y: qrCaptionYMm * _mmToPt,
        value: qrCaption,
        fontSize: 9,
        width: qrCaptionWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.2,
      ),
      // Bottom variable text — `{Protagonistas}, disfruta de está…`.
      DotsTextBlockElement(
        x: bottomXMm * _mmToPt,
        y: bottomYMm * _mmToPt,
        value: bottomText,
        fontSize: 9,
        width: bottomWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.left,
        lineHeight: 1.2,
      ),
      // Right-page decorative-circle scatter — 28 circles from
      // pdf13 p.1 (diameters) + p.2 (positions), with the right-to-left
      // opacity gradient ("transparencia 100% A 0% sobre 181 mm")
      // applied per-circle via [_qrCircleAlphaForX]. Each circle uses
      // the default 1.764 mm Gaussian edge fade.
      for (final c in _kRightPageCircles)
        DotsDecorativeCircleElement(
          x: c.xMm * _mmToPt,
          y: c.yMm * _mmToPt,
          diameter: c.diameterMm * _mmToPt,
          colorHex: '#CDE7F2',
          opacityAlpha: _qrCircleAlphaForX(c.xMm),
        ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// generalEventos closing spread variant — photo + `{TítuloDelAlbum}`
  /// + dual-signature subtitle. Distinct from `closing(...)` because the
  /// subtitle composes from two signature inputs unique to the
  /// generalEventos category.
  ///
  /// Filled in Task 7 of `final-render-refinement` against
  /// `pdf13_general_eventos_final.pdf` p.3. Layout mirrors the standard
  /// `closing` factory: 66×86 mm photo centered horizontally at y=71.534,
  /// 20pt title at y=photo_bottom+5, 9pt subtitle at y=title_bottom+5.
  /// The dual-signature subtitle is composed from `content.signature1`
  /// and `content.signature2` per the spec text "Vivido con mucho amor
  /// por: {Firma 1} y {Firma 2}".
  factory DotsAlbumSpreadPage.eventosClosing({
    required DotsAlbumType type,
    required int pageNumber,
    required AlbumEventosClosingContent content,
    String contextLabelValue = '',
  }) {
    if (type != DotsAlbumType.generalEventos) {
      throw ArgumentError.value(
        type,
        'type',
        'DotsAlbumSpreadPage.eventosClosing only supports '
            'DotsAlbumType.generalEventos.',
      );
    }
    assert(content.title.isNotEmpty);

    // Layout constants (mm) — verified against pdf13 p.3.
    const double pageWidthPt = 575.43; // dotbook default (203 mm).
    const double photoWidthPt = 66.0 * _mmToPt;
    const double photoHeightPt = 86.0 * _mmToPt;
    const double photoX = (pageWidthPt - photoWidthPt) / 2.0;
    const double photoY = 71.534 * _mmToPt;
    const double textBoxX = 44.0 * _mmToPt;
    const double textBoxWidthPt = 115.0 * _mmToPt;
    const double titleFontSize = 20.0;
    const double titleY = photoY + photoHeightPt + 5.0 * _mmToPt;
    const double subtitleY =
        titleY + titleFontSize * 1.2 + 5.0 * _mmToPt;

    final String subtitle =
        'Vivido con mucho amor por: ${content.signature1} y '
        '${content.signature2}';

    final elements = <DotsElement>[
      if (content.photoPath != null)
        DotsImageElement(
          x: photoX,
          y: photoY,
          assetPath: content.photoPath!,
          width: photoWidthPt,
          height: photoHeightPt,
        ),
      DotsTextElement(
        x: textBoxX,
        y: titleY,
        value: content.title,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextBlockElement(
        x: textBoxX,
        y: subtitleY,
        value: subtitle,
        fontSize: 9,
        width: textBoxWidthPt,
        fontFamily: 'P22 Mackinac Book',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 1.2,
        maxLines: 2,
      ),
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '$pageNumber',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  /// "Antes de empezar el viaje" decorative-circles 2-page instruction
  /// spread. Renders the title + body on the RIGHT page; the LEFT
  /// page's blue background and decorative-circles cluster (with the
  /// per-circle opacity gradients annotated in the source PDFs) are
  /// DEFERRED — `DotsDecorativeCircleElement` currently emits solid
  /// circles only.
  ///
  /// Sources (each category has its own canonical body, but title and
  /// layout are shared):
  ///   - `parejas`     — `pdf02_pareja_inicial.pdf`     p.10
  ///   - `hijos`       — `pdf08_hijos_inicial.pdf`      p.10
  ///   - `individuales`— `pdf10_individual_inicial.pdf` p.8
  ///   - `otros`       — `pdf04_otros_inicial.pdf`      p.8
  ///   - `boda`        — `pdf06_boda_inicial.pdf`       p.3
  ///   - `generalEventos`— `pdf12_general_eventos_inicial.pdf` p.3
  ///
  /// Layout (uniform):
  ///   - Title "Antes de empezar / el viaje" — two lines, P22 Mackinac
  ///     Medium 27pt (line 1) + P22 Mackinac Medium Italic 27pt (line
  ///     2). Centred on the RIGHT page, 95 mm-wide box at right-page
  ///     spread x=203+54.083.
  ///   - Body — Inter Book 9pt, 95 mm-wide centred box, 5 mm below the
  ///     title.
  ///
  /// Right-page chrome — protagonist names + "Pasad la página…" CTA:
  ///   - parejas, hijos      → CTA `"Pasad la página para empezar
  ///                            esta experiencia"` (pdf02 p.10 / pdf08 p.10).
  ///   - individuales, otros → CTA `"Pasad la página para vivir la
  ///                            experiencia"` (pdf10 p.8 / pdf04 p.8).
  ///   - boda, generalEventos → NO chrome (the source PDFs only show
  ///                            title + body on the right page).
  /// Coordinates for the chrome are best-effort from the limited
  /// annotations and may need refinement after visual QA.
  factory DotsAlbumSpreadPage.beforeJourney({
    required DotsAlbumType type,
    required int pageNumber,
    AlbumBeforeJourneyContent content = const AlbumBeforeJourneyContent(),
    String contextLabelValue = '',
  }) {
    // Per-category body copy — canonical Spanish from the source PDFs.
    final String defaultBody = switch (type) {
      DotsAlbumType.parejas =>
        // pdf02 p.10 — vosotros form.
        'Pensad que esto no son solo fotos.\nSon momentos.\n'
            'La historia de cómo ocurrió. Reviviéndola tal y como fue, '
            'en ese instante. Volviendo a veros y escucharos, tal y '
            'como erais entonces, mientras todo pasaba.\n'
            'Cerrad los ojos un instante.\nRespirad despacio.',
      DotsAlbumType.hijos =>
        // pdf08 p.10 — tú form.
        'Piensa que esto no son solo fotos.\nSon momentos.\n'
            'La historia de cómo ocurrió. Reviviéndolo tal y como fue, '
            'en ese instante. Volviendo a ver y escuchar a tus seres '
            'queridos, tal y como eran entonces, mientras todo pasaba.\n'
            'Cierra los ojos un instante.\nRespira despacio.\n'
            'Y vuelve allí.',
      DotsAlbumType.individuales || DotsAlbumType.otros =>
        // pdf10 p.8 / pdf04 p.8 — IDENTICAL tú-form body for both.
        'Piensa que esto no son solo fotos.\nSon momentos.\n'
            'Fragmentos de una historia vivida de verdad.\n'
            'Instantes que quedaron atrás, pero que siguen teniendo '
            'algo que decir.\n'
            'Aquí podrás volver a ver, escuchar y sentir parte de lo '
            'que fue esa etapa, tal y como ocurrió.\n'
            'Cierra los ojos un instante.\nRespira despacio.\n'
            'Y vuelve allí.',
      DotsAlbumType.boda =>
        // pdf06 p.3 — tú form, wedding-specific closing line.
        'Cierra los ojos un instante.\nRespira despacio.\nY vuelve allí.\n'
            'Estas fotos no las hizo una cámara. Las hizo la gente que '
            'los quiere… mientras ocurría. Por eso no son solo '
            'recuerdos: son emoción. Son miradas. Son "yo estuve '
            'contigo".\n'
            'Deja que cada página te devuelva ese día. Quédate un poco. '
            'Como si el tiempo, por fin, aflojara.\n'
            'Y cuando estes listo, vuelve al momento exacto en el que '
            'dejasteis de ser dos y empezasteis a ser un nosotros.',
      DotsAlbumType.generalEventos =>
        // pdf12 p.3 — tú form, generic closing line.
        'Cierra los ojos un instante.\nRespira despacio.\nY vuelve allí.\n'
            'Estas fotos no las hizo solo una cámara. Las hicieron las '
            'personas que estaban contigo mientras todo ocurría. Por '
            'eso no son solo recuerdos: son emoción. Son miradas. Son '
            'momentos compartidos que siguen vivos.\n'
            'Deja que cada página te lleve de vuelta. Quédate un '
            'momento. Como si el tiempo fuera un poco más lento.\n'
            'Y cuando estés listo, vuelve exactamente a ese instante '
            'que merecía quedarse para siempre.',
    };

    // Layout constants (mm) — verified against pdf02 p.10 / pdf08 p.10
    // / pdf06 p.3. Right-page spread coords (x += 203 from page-local).
    const double titleXMm = 203 + 54.083;
    const double titleWidthMm = 95;
    const double titleL1YMm = 96.2;
    // Line 2 sits 27pt × ~1.148 leading ≈ 31pt ≈ 10.94 mm below L1.
    const double titleL2YMm = titleL1YMm + 10.94;
    const double bodyXMm = 203 + 54.083;
    const double bodyWidthMm = 95;
    // Title height 19.1 mm + 5 mm gap below L2 baseline.
    const double bodyYMm = titleL1YMm + 19.1 + 5;

    final String body = content.bodyOverride ?? defaultBody;

    // Per-category right-page CTA. parejas/hijos use the "empezar"
    // wording (pdf02 p.10 / pdf08 p.10); individuales/otros use the
    // "vivir" wording (pdf10 p.8 / pdf04 p.8); boda + generalEventos
    // omit the CTA entirely (no such element in pdf06 p.3 / pdf12 p.3).
    final String? cta = switch (type) {
      DotsAlbumType.parejas || DotsAlbumType.hijos =>
        'Pasad la página para empezar esta experiencia',
      DotsAlbumType.individuales || DotsAlbumType.otros =>
        'Pasad la página para vivir la experiencia',
      DotsAlbumType.boda || DotsAlbumType.generalEventos => null,
    };

    final elements = <DotsElement>[
      // Title line 1 — "Antes de empezar" (P22 Mackinac Medium 27pt).
      const DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleL1YMm * _mmToPt,
        value: 'Antes de empezar',
        fontSize: 27,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
        lineHeight: 31 / 27,
      ),
      // Title line 2 — "el viaje" (P22 Mackinac Medium Italic 27pt).
      const DotsTextBlockElement(
        x: titleXMm * _mmToPt,
        y: titleL2YMm * _mmToPt,
        value: 'el viaje',
        fontSize: 27,
        width: titleWidthMm * _mmToPt,
        fontFamily: 'P22 Mackinac Medium Italic',
        textAlign: DotsTextAlign.center,
        lineHeight: 31 / 27,
      ),
      // Body — per-category Spanish copy.
      DotsTextBlockElement(
        x: bodyXMm * _mmToPt,
        y: bodyYMm * _mmToPt,
        value: body,
        fontSize: 9,
        width: bodyWidthMm * _mmToPt,
        fontFamily: 'Inter',
        colorHex: '#1e1e1e',
        textAlign: DotsTextAlign.center,
        lineHeight: 10.8 / 9,
      ),
      // ── Right-page chrome (parejas/hijos/individuales/otros only) ───
      // Protagonist names label + "Pasad la página…" CTA. Skipped for
      // boda and generalEventos — their source PDFs (pdf06 p.3 /
      // pdf12 p.3) only show title + body on the right page.
      if (cta != null) ...[
        // Protagonist-names line — Inter Medium 9pt, 100 mm wide,
        // centered on the right page. Falls back to "{Protagonistas}"
        // when caller passes empty contextLabelValue.
        DotsTextBlockElement(
          x: (203 + (203 - 100) / 2) * _mmToPt,
          y: 210 * _mmToPt,
          value:
              contextLabelValue.isEmpty ? '{Protagonistas}' : contextLabelValue,
          fontSize: 9,
          width: 100 * _mmToPt,
          fontFamily: 'Inter',
          textAlign: DotsTextAlign.center,
          lineHeight: 10.8 / 9,
        ),
        // CTA — P22 Mackinac Medium 15pt, 65 mm wide, centered.
        DotsTextBlockElement(
          x: (203 + (203 - 65) / 2) * _mmToPt,
          y: 220 * _mmToPt,
          value: cta,
          fontSize: 15,
          width: 65 * _mmToPt,
          fontFamily: 'P22 Mackinac Medium',
          textAlign: DotsTextAlign.center,
          lineHeight: 18 / 15,
        ),
      ],
    ];

    return DotsAlbumSpreadPage(
      pageNumber: pageNumber,
      header: DotsSpreadHeader(
        leftPageNumber: '$pageNumber',
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
        rightPageNumber: '${pageNumber + 1}',
      ),
      footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
      elements: elements,
    );
  }

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Top-of-page structural positions (left page number, centre label,
  /// right page number).
  final DotsSpreadHeader header;

  /// Bottom-of-page structural position (wordmark).
  final DotsSpreadFooter footer;

  /// Optional explicit-coordinate elements drawn on the page body, in
  /// declaration order.
  final List<DotsElement> elements;

  @override
  bool operator ==(Object other) =>
      other is DotsAlbumSpreadPage &&
      other.pageNumber == pageNumber &&
      other.header == header &&
      other.footer == footer &&
      _listEquals(other.elements, elements);

  @override
  int get hashCode => Object.hash(
        pageNumber,
        header,
        footer,
        Object.hashAll(elements),
      );
}

/// Top-level template tree consumed by the generator.
///
/// A template can describe its content two equivalent ways:
///
/// - Page-level: an ordered list of [pages]. This is the lower-level
///   model — the renderer consumes it directly.
/// - Pliego-level: an ordered list of [pliegos] (2-page spreads).
///   Each pliego is either two independent pages glued together
///   ([DotsLayoutPliego]) or a single image spanning the spread
///   ([DotsSpreadImagePliego]). The pliego-level API is the
///   recommended public input.
///
/// **At most one of `pages` and `pliegos` may be non-empty** — the
/// constructor asserts it, and the parser raises a descriptive error
/// when both are present in JSON input.
@immutable
class DotsTemplate {
  /// Creates a template.
  ///
  /// `pages` and `pliegos` are mutually exclusive: leave at least one
  /// at its default empty value. The assert below uses `identical`
  /// against compile-time sentinels because `.length` / `.isEmpty`
  /// are not const-evaluable on `List`.
  const DotsTemplate({
    required this.documentId,
    required this.pageSize,
    this.category = DotsAlbumType.generalEventos,
    this.defaultChrome,
    this.pliegos = _emptyPliegos,
  });

  static const List<DotsPliego> _emptyPliegos = <DotsPliego>[];

  /// Stable identifier used for disk paths and cache lookups.
  final String documentId;

  /// Page geometry applied to every page.
  final DotsPageSize pageSize;

  /// Category that selects mandatory front/back matter and the
  /// right-page top-center header label token.
  ///
  /// Renamed from `albumType` in Task 2 of the `final-render-refinement`
  /// series so the public vocabulary matches the JSON field. Non-nullable
  /// with default [DotsAlbumType.generalEventos] — JSON callers that omit
  /// the `category` field receive the same default (parser default — wired
  /// in PR 2).
  final DotsAlbumType category;

  /// Optional chrome applied to every interior page rendered from this
  /// template.
  ///
  /// When `null` (the default), no background, header, or footer chrome is
  /// added — preserving backward compatibility with templates authored before
  /// this field existed. When non-null, [DotsRenderer] derives per-page
  /// suppression flags from the solved layout slots and forwards a derived
  /// [DotsPageChrome] to [buildPageChrome].
  final DotsPageChrome? defaultChrome;

  /// Pliego-level (2-page-spread) content — the sole input shape for
  /// renderable templates after Task 2 of the `final-render-refinement`
  /// series. The page-level `pages` field was removed alongside the JSON
  /// `pages` key in favour of always going through pliegos.
  final List<DotsPliego> pliegos;

  /// Resolved list of pages the renderer consumes, flattened from
  /// [pliegos]. The first pliego becomes pages 1 and 2, the second 3 and
  /// 4, and so on.
  List<DotsPage> get effectivePages {
    final result = <DotsPage>[];
    var nextPageNumber = 1;
    for (final pliego in pliegos) {
      final pliegoPages = pliego.toPages(nextPageNumber);
      result.addAll(pliegoPages);
      nextPageNumber += pliegoPages.length;
    }
    return List<DotsPage>.unmodifiable(result);
  }

  /// Fast non-cryptographic hash of the template's logical content.
  ///
  /// Used as part of the cache key so that artifacts on disk are
  /// auto-invalidated whenever the template changes.
  int get contentHash => Object.hash(
        documentId,
        pageSize,
        category,
        defaultChrome,
        Object.hashAll(pliegos),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
