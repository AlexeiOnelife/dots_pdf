import 'package:meta/meta.dart';

import 'dots_template.dart';

/// A pliego is a 2-page spread (one printer signature). The library's
/// public input model is pliego-oriented; internally each pliego
/// flattens into one or two `DotsPage`s before rendering.
///
/// Two variants exist:
///   - [DotsLayoutPliego] — two independent pages glued together.
///   - [DotsSpreadImagePliego] — one image spans both pages; the
///     library handles the split into left/right halves.
@immutable
sealed class DotsPliego {
  /// Creates a pliego.
  const DotsPliego({required this.pliegoNumber});

  /// 1-based pliego index within the template. The first pliego
  /// (`pliegoNumber: 1`) becomes output pages 1 and 2; the second
  /// becomes 3 and 4; and so on.
  final int pliegoNumber;

  /// Flattens this pliego into the two `DotsPage`s the renderer will
  /// consume, starting at the given 1-based [firstPageNumber].
  ///
  /// Always returns exactly two entries — the left page first, then
  /// the right page.
  List<DotsPage> toPages(int firstPageNumber);
}

/// A pliego whose two pages are independent: each can be any
/// `DotsPage` (elements page, layout page, …). The page numbers on
/// [left] and [right] are ignored — the parent template assigns them
/// from the pliego's position.
@immutable
class DotsLayoutPliego extends DotsPliego {
  /// Creates a layout pliego.
  const DotsLayoutPliego({
    required super.pliegoNumber,
    required this.left,
    required this.right,
  });

  /// The left-hand page of the spread.
  final DotsPage left;

  /// The right-hand page of the spread.
  final DotsPage right;

  @override
  List<DotsPage> toPages(int firstPageNumber) => <DotsPage>[
        _withPageNumber(left, firstPageNumber),
        _withPageNumber(right, firstPageNumber + 1),
      ];

  @override
  bool operator ==(Object other) =>
      other is DotsLayoutPliego &&
      other.pliegoNumber == pliegoNumber &&
      other.left == left &&
      other.right == right;

  @override
  int get hashCode => Object.hash(pliegoNumber, left, right);
}

/// A pliego whose entire 2-page surface is a single image. Callers
/// pass **one** asset path (local or URL); the renderer splits it into
/// left and right halves automatically.
///
/// The image is conceptually drawn at `(spreadWidth, height)` PDF
/// points, anchored at `(x, y)` on the LEFT page. Bleed flags apply
/// to the outer (binding-opposite) edges of each half — the inner
/// (binding) edge never bleeds because the two halves meet there.
@immutable
class DotsSpreadImagePliego extends DotsPliego {
  /// Creates a spread-image pliego.
  const DotsSpreadImagePliego({
    required super.pliegoNumber,
    required this.assetPath,
    required this.spreadWidth,
    required this.height,
    this.x = 0,
    this.y = 0,
    this.bleedTop = false,
    this.bleedBottom = false,
    this.bleedOuter = false,
  });

  /// Local file path or `http(s)://` URL of the spread image.
  final String assetPath;

  /// Total width of the image across the spread, in PDF points.
  final double spreadWidth;

  /// Height of the image, in PDF points.
  final double height;

  /// Top-left x position of the image on the LEFT page, in PDF points.
  final double x;

  /// Top-left y position of the image on the LEFT page, in PDF points.
  final double y;

  /// Whether the image extends into the bleed above its trim top edge.
  final bool bleedTop;

  /// Whether the image extends into the bleed below its trim bottom
  /// edge.
  final bool bleedBottom;

  /// Whether the image extends into the bleed beyond the outer
  /// (binding-opposite) edge of each half.
  final bool bleedOuter;

  @override
  List<DotsPage> toPages(int firstPageNumber) {
    final leftElement = DotsSpreadImageElement(
      x: x,
      y: y,
      assetPath: assetPath,
      spreadWidth: spreadWidth,
      height: height,
      half: DotsSpreadHalf.left,
      bleedTop: bleedTop,
      bleedBottom: bleedBottom,
      bleedOuter: bleedOuter,
    );
    final rightElement = DotsSpreadImageElement(
      x: x,
      y: y,
      assetPath: assetPath,
      spreadWidth: spreadWidth,
      height: height,
      half: DotsSpreadHalf.right,
      bleedTop: bleedTop,
      bleedBottom: bleedBottom,
      bleedOuter: bleedOuter,
    );
    return <DotsPage>[
      DotsElementsPage(
        pageNumber: firstPageNumber,
        elements: <DotsElement>[leftElement],
      ),
      DotsElementsPage(
        pageNumber: firstPageNumber + 1,
        elements: <DotsElement>[rightElement],
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is DotsSpreadImagePliego &&
      other.pliegoNumber == pliegoNumber &&
      other.assetPath == assetPath &&
      other.spreadWidth == spreadWidth &&
      other.height == height &&
      other.x == x &&
      other.y == y &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom &&
      other.bleedOuter == bleedOuter;

  @override
  int get hashCode => Object.hash(
        pliegoNumber,
        assetPath,
        spreadWidth,
        height,
        x,
        y,
        bleedTop,
        bleedBottom,
        bleedOuter,
      );
}

/// Returns a copy of [page] with its `pageNumber` overridden.
///
/// Used by [DotsLayoutPliego.toPages] so callers don't have to predict
/// the page-number layout when authoring pliegos.
DotsPage _withPageNumber(DotsPage page, int pageNumber) {
  switch (page) {
    case DotsElementsPage():
      return DotsElementsPage(
        pageNumber: pageNumber,
        elements: page.elements,
      );
    case DotsLayoutPage():
      return DotsLayoutPage(
        pageNumber: pageNumber,
        layoutCode: page.layoutCode,
        photoAssetPaths: page.photoAssetPaths,
        captions: page.captions,
      );
  }
}
