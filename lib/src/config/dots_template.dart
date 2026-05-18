import 'package:meta/meta.dart';

import '../render/layout/dots_layout_code.dart';
import '../render/layout/dots_slot_rect.dart';
import 'dots_pliego.dart';

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
