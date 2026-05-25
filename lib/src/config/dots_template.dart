import 'package:meta/meta.dart';

import '../api/dots_album_type.dart';
import '../render/layout/dots_layout_code.dart';
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
  ///         rightPageNumber = null (single page — no facing).
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
        rightPageNumber: null,
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
  ///         rightPageNumber = null.
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
      DotsAlbumType.otros =>
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
        rightPageNumber: null,
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
  /// Header: `centerLabel` = [contextLabelValue].
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
        centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
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
    this.albumType,
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
