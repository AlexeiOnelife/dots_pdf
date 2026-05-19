/// Visual design used to lay out the cover artwork on a [DotsCoverTemplate].
///
/// The choice of design changes which artwork inputs are consumed and how
/// they are positioned on the cover panel:
///
/// - [square]: a single front artwork sized to **80% of the front-panel
///   width and height**, anchored 10 mm above the trim bottom and 10 mm
///   left of the trim right of the front panel. The rest of the cover
///   (back panel, spine, surrounding wrap) is painted with the template's
///   background color. No back artwork is consumed.
/// - [circle]: a single front artwork rendered as a **circular clip whose
///   diameter is 50% of the front-panel height**, centred on the front
///   panel. The rest of the cover is painted with the background color.
///   No back artwork is consumed.
/// - [linen]: a single artwork rendered as a **horizontal strip spanning
///   the full cover width** (back panel + spine + front panel, including
///   wraps). The strip's vertical centerline sits at 40% from the bottom
///   of the cover; its height is derived from the source aspect ratio so
///   the image keeps its natural shape (`stripHeight = coverWidth *
///   sourceHeight / sourceWidth`). The artwork comes from
///   `DotsCoverTemplate.frontArtworkPath`; `backArtworkPath` is ignored.
///
/// Each design also carries a minimum source-image pixel size and a final
/// aspect ratio: the renderer eagerly validates incoming artworks against
/// these bounds and throws `DotsConfigException` when an image is too
/// small.
enum DotsCoverDesign {
  /// Square photo bottom-right (~80% × 80% of front panel, 10 mm inset).
  square(
    minSourceWidthPx: 2125,
    minSourceHeightPx: 2185,
    aspectRatioNumerator: 36,
    aspectRatioDenominator: 37,
  ),

  /// Circular photo centred on the front panel (50% × 50%).
  circle(
    minSourceWidthPx: 1240,
    minSourceHeightPx: 1240,
    aspectRatioNumerator: 1,
    aspectRatioDenominator: 1,
  ),

  /// Horizontal linen strip spanning both covers at 40% from the bottom.
  linen(
    minSourceWidthPx: 1181,
    minSourceHeightPx: 2397,
    aspectRatioNumerator: 2,
    aspectRatioDenominator: 1,
  );

  const DotsCoverDesign({
    required this.minSourceWidthPx,
    required this.minSourceHeightPx,
    required this.aspectRatioNumerator,
    required this.aspectRatioDenominator,
  });

  /// Minimum source-image width in pixels accepted by this design.
  final int minSourceWidthPx;

  /// Minimum source-image height in pixels accepted by this design.
  final int minSourceHeightPx;

  /// Numerator of the canonical aspect ratio expressed as a fraction.
  final int aspectRatioNumerator;

  /// Denominator of the canonical aspect ratio expressed as a fraction.
  final int aspectRatioDenominator;

  /// Canonical aspect ratio as a double (numerator / denominator).
  double get aspectRatio => aspectRatioNumerator / aspectRatioDenominator;
}
