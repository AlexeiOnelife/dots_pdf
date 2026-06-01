import 'package:meta/meta.dart';

/// Page-level geometry constants for one interior page of the Dotbook.
///
/// All values are in millimeters. The page origin is the top-left corner
/// of the trim (the bleed extends outward from the trim, not inward).
@immutable
class DotsPageGeometry {
  /// Creates a page geometry.
  const DotsPageGeometry({
    required this.pageWidthMm,
    required this.pageHeightMm,
    required this.bleedMm,
    required this.headerBandMm,
    required this.footerBandMm,
    required this.bindingInsetMm,
    this.outerMarginMm = 8,
  });

  /// Returns the Dotbook default geometry: 203 x 254 mm trim with 3 mm
  /// bleed, 12 mm header and footer bands, 23 mm binding-side inset,
  /// 8 mm outer (non-binding) margin.
  factory DotsPageGeometry.dotbookDefault() => const DotsPageGeometry(
        pageWidthMm: 203,
        pageHeightMm: 254,
        bleedMm: 3,
        headerBandMm: 12,
        footerBandMm: 12,
        bindingInsetMm: 23,
        outerMarginMm: 8,
      );

  /// Trim width of the page in millimeters.
  final double pageWidthMm;

  /// Trim height of the page in millimeters.
  final double pageHeightMm;

  /// Bleed allowance on every outer edge of the page in millimeters.
  final double bleedMm;

  /// Height of the top header band reserved for page-number, album name
  /// and context label.
  final double headerBandMm;

  /// Height of the bottom footer band reserved for the "Dots. Memories"
  /// wordmark.
  final double footerBandMm;

  /// Inside-edge inset (binding side) reserved for the header line.
  final double bindingInsetMm;

  /// Outer (non-binding) edge margin in millimetres.
  ///
  /// All photo layouts in `pdf01_general_base.pdf` (Task 3) align photos
  /// to this margin from the trim's outer edge — the side away from the
  /// book spine. On a left page that is the LEFT edge; on a right page,
  /// the RIGHT edge. The solver's `_outerAlignedX` helper resolves
  /// per-page parity.
  final double outerMarginMm;

  /// Y-coordinate (page-origin top-left) of the top edge of the live
  /// area, just below the header band.
  double get liveAreaTopMm => headerBandMm;

  /// Y-coordinate of the bottom edge of the live area, just above the
  /// footer band.
  double get liveAreaBottomMm => pageHeightMm - footerBandMm;

  /// Height of the live area in millimeters.
  double get liveAreaHeightMm => liveAreaBottomMm - liveAreaTopMm;

  /// Width of the live area in millimeters (full page width; the
  /// optional binding inset is layout-specific, not subtracted here).
  double get liveAreaWidthMm => pageWidthMm;

  @override
  bool operator ==(Object other) =>
      other is DotsPageGeometry &&
      other.pageWidthMm == pageWidthMm &&
      other.pageHeightMm == pageHeightMm &&
      other.bleedMm == bleedMm &&
      other.headerBandMm == headerBandMm &&
      other.footerBandMm == footerBandMm &&
      other.bindingInsetMm == bindingInsetMm &&
      other.outerMarginMm == outerMarginMm;

  @override
  int get hashCode => Object.hash(
        pageWidthMm,
        pageHeightMm,
        bleedMm,
        headerBandMm,
        footerBandMm,
        bindingInsetMm,
        outerMarginMm,
      );
}
