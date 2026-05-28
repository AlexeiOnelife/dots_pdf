import 'package:meta/meta.dart';

import '../api/album_boda_cluster_content.dart';
import '../api/album_boda_halo_content.dart';
import '../api/album_photo_arc_content.dart';
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
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Circle diameter in PDF points.
  final double diameter;

  /// Fill colour encoded as `#RRGGBB`. Baked into the rasterized PNG;
  /// the renderer does NOT tint at runtime.
  final String colorHex;

  /// Gaussian-blur edge-feather width in millimetres. Default is 1.764 mm
  /// (spec p.4). This value is intentionally kept in mm because the spec
  /// authors in mm; the factory converts to pixels at rasterisation time.
  final double gaussianFadeMm;

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
  /// Typically the resolved value of `albumType.contextLabelToken` after
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
  /// Typically the resolved value of `albumType.contextLabelToken` after
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
    // Canonical element positions (top-left page coordinate frame, in pt).
    // x=0, y=0 is the top-left corner of the page trim.  Exact coordinates
    // are the single source of truth; the renderer places Positioned widgets
    // at these values directly.
    const double titleX = 0;
    const double titleY = 60 * _mmToPt; // ~170 pt from top
    const double bodyX = 0;
    const double bodyY = 90 * _mmToPt; // below title
    const double signatureX = 0;
    const double signatureY = 160 * _mmToPt; // below body block
    const double bodyWidthPt = 102.0 * _mmToPt; // ~289.13 pt

    final elements = <DotsElement>[
      DotsTextElement(
        x: titleX,
        y: titleY,
        value: title,
        fontSize: 23,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextBlockElement(
        x: bodyX,
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
          x: signatureX,
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

    // Canonical element positions (pt, top-left page coordinate frame).
    // Photo slot: 66×86 mm centred horizontally; pageWidth ~575 pt → offset.
    // These are reasonable layout defaults — the renderer places them as-is.
    const double pageWidthPt = 575.43; // dotbook default (203mm)
    const double photoWidthPt = 66.0 * _mmToPt; // ~187.09 pt
    const double photoHeightPt = 86.0 * _mmToPt; // ~243.78 pt
    const double photoX = (pageWidthPt - photoWidthPt) / 2.0; // centred
    const double photoY = 60.0 * _mmToPt;
    const double titleX = 0;
    const double titleY = photoY + photoHeightPt + 10.0 * _mmToPt;
    const double subtitleX = 0;
    final double subtitleY = titleY + titleFontSize * 1.5;
    const double subtitleWidthPt = 102.0 * _mmToPt;

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
        x: titleX,
        y: titleY,
        value: title,
        fontSize: titleFontSize,
        fontFamily: 'P22 Mackinac Medium',
      ),
      DotsTextBlockElement(
        x: subtitleX,
        y: subtitleY,
        value: subtitle,
        fontSize: 9,
        width: subtitleWidthPt,
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
  ///   - [DotsAlbumType.parejas] default → `"DOTBOOK"`.
  ///   - [DotsAlbumType.hijos]   default → `"DOTBOOK DE {NOMBREHIJO}"`.
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
    final String defaultEyebrow = switch (type) {
      DotsAlbumType.parejas => 'DOTBOOK',
      DotsAlbumType.hijos => 'DOTBOOK DE {NOMBREHIJO}',
      _ => throw ArgumentError.value(
          type,
          'type',
          'DotsAlbumSpreadPage.cover only supports '
              'DotsAlbumType.parejas and DotsAlbumType.hijos; got $type',
        ),
    };
    final String eyebrow = eyebrowOverride ?? defaultEyebrow;

    // Page geometry (203 × 254 mm in PDF points).
    const double pageWidthPt = 203.0 * _mmToPt;
    const double pageHeightPt = 254.0 * _mmToPt;

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
    // Positions derived from D8: block centred at pageHeight/2.
    const double eyebrowY = pageHeightPt / 2 - 12.0 * _mmToPt;
    const double titleY = pageHeightPt / 2;
    const double dateY = pageHeightPt / 2 + 18.0 * _mmToPt;

    final texts = <DotsElement>[
      DotsTextBlockElement(
        x: 0,
        y: eyebrowY,
        value: eyebrow,
        fontSize: 9,
        width: pageWidthPt,
        fontFamily: 'Inter',
        textAlign: DotsTextAlign.center,
      ),
      DotsTextBlockElement(
        x: 0,
        y: titleY,
        value: title,
        fontSize: 23,
        width: pageWidthPt,
        fontFamily: 'P22 Mackinac Medium',
        textAlign: DotsTextAlign.center,
      ),
      DotsTextBlockElement(
        x: 0,
        y: dateY,
        value: dateLine,
        fontSize: 9,
        width: pageWidthPt,
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
    this.albumType,
    this.defaultChrome,
    this.pages = _emptyPages,
    this.pliegos = _emptyPliegos,
  }) : assert(
          identical(pages, _emptyPages) ||
              identical(pliegos, _emptyPliegos),
          'DotsTemplate accepts pages OR pliegos, not both',
        );

  static const List<DotsPage> _emptyPages = <DotsPage>[];
  static const List<DotsPliego> _emptyPliegos = <DotsPliego>[];

  /// Stable identifier used for disk paths and cache lookups.
  final String documentId;

  /// Page geometry applied to every page.
  final DotsPageSize pageSize;

  /// Optional album type that selects front/back matter and the
  /// right-page top-center header label token. Defaults to `null` —
  /// absent from templates that do not use album-type spread pages.
  final DotsAlbumType? albumType;

  /// Optional chrome applied to every interior page rendered from this
  /// template.
  ///
  /// When `null` (the default), no background, header, or footer chrome is
  /// added — preserving backward compatibility with templates authored before
  /// this field existed. When non-null, [DotsRenderer] derives per-page
  /// suppression flags from the solved layout slots and forwards a derived
  /// [DotsPageChrome] to [buildPageChrome].
  final DotsPageChrome? defaultChrome;

  /// Page-level content. Empty when [pliegos] is the source of truth.
  final List<DotsPage> pages;

  /// Pliego-level (2-page-spread) content. Empty when [pages] is the
  /// source of truth.
  final List<DotsPliego> pliegos;

  /// Resolved list of pages the renderer consumes, regardless of
  /// whether the template was authored page-level or pliego-level.
  ///
  /// When [pliegos] is non-empty, each pliego is flattened into its
  /// two output pages with sequentially assigned page numbers; the
  /// first pliego becomes pages 1 and 2, the second 3 and 4, and so
  /// on. When [pages] is non-empty, the list is returned as-is.
  List<DotsPage> get effectivePages {
    if (pliegos.isEmpty) return pages;
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
        albumType,
        defaultChrome,
        Object.hashAll(pages),
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
