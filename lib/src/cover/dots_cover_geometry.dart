import 'package:meta/meta.dart';

import '../config/dots_config_exception.dart';
import 'dots_paper_substrate.dart';
import 'dots_supplier.dart';

/// One row of the page-count → spine-width lookup table.
///
/// Mirrors a single line of the "Per-part-number table" in
/// `SPECS_cover.md`. Inclusive on both [minPages] and [maxPages].
@immutable
class _SpineTier {
  const _SpineTier({
    required this.minPages,
    required this.maxPages,
    required this.spineMm,
    required this.letter,
  });

  final int minPages;
  final int maxPages;
  final double spineMm;
  final String letter;

  bool contains(final int pageCount) =>
      pageCount >= minPages && pageCount <= maxPages;
}

/// Pure-math layer for a Dotbook hard-cover layout.
///
/// Computes every millimetre dimension the cover renderer needs from
/// three inputs:
///
/// - [pageCount]: total interior page count (must be a multiple of 4
///   between [DotsSupplier.minPageCount] and the per-substrate maximum
///   — 250 for `uncoated150`, 300 for `satin170` / `gloss200` — and
///   within the per-substrate tier table).
/// - [paperSubstrate]: interior stock that selects the spine-tier table.
/// - [supplier]: print supplier that fixes the page-count floor and
///   crop-mark policy.
///
/// All exposed dimensions are in millimetres. The class is immutable
/// and value-equal, so two instances built from the same inputs compare
/// `==`.
///
/// The lookup tables are baked-in from the resolved spreadsheet rows
/// (`FileSpecs.203x254.V1.xlsx`, mirrored in `SPECS_cover.md`).
/// Validation is eager: the constructor throws [DotsConfigException]
/// rather than allowing an invalid geometry to escape.
@immutable
class DotsCoverGeometry {
  /// Creates a geometry for ([pageCount], [paperSubstrate], [supplier]).
  ///
  /// Throws [DotsConfigException] when any of the following holds:
  ///
  /// - [pageCount] is not a positive multiple of 4.
  /// - [pageCount] is below [DotsSupplier.minPageCount].
  /// - [pageCount] exceeds the per-substrate cap returned by
  ///   [maxPageCountForSubstrate] (250 for `uncoated150`, 300 for
  ///   `satin170` / `gloss200`).
  /// - [pageCount] falls outside the page range defined by the tier
  ///   table for [paperSubstrate] (e.g. 244 pages on `uncoated150`,
  ///   whose ceiling is 242).
  factory DotsCoverGeometry({
    required final int pageCount,
    required final DotsPaperSubstrate paperSubstrate,
    required final DotsSupplier supplier,
  }) {
    _validate(
      pageCount: pageCount,
      paperSubstrate: paperSubstrate,
      supplier: supplier,
    );
    final _SpineTier tier = _resolveTier(paperSubstrate, pageCount);
    return DotsCoverGeometry._(
      pageCount: pageCount,
      paperSubstrate: paperSubstrate,
      supplier: supplier,
      spineWidthMm: tier.spineMm,
      spineLetter: tier.letter,
    );
  }

  const DotsCoverGeometry._({
    required this.pageCount,
    required this.paperSubstrate,
    required this.supplier,
    required this.spineWidthMm,
    required this.spineLetter,
  });

  /// Hard cap on interior page count for `uncoated150` stock (Table 1),
  /// and the default reference value. Satin/gloss coated stock extends
  /// to [satinGlossMaxPageCount] per Table 2 of
  /// `FileSpecs.203x254.V1.xlsx`.
  static const int maxPageCount = 250;

  /// Hard cap on interior page count for `satin170` / `gloss200` coated
  /// stock (Table 2, letter F extends to 300 pages).
  static const int satinGlossMaxPageCount = 300;

  /// Maximum interior page count permitted for [substrate].
  ///
  /// `uncoated150` caps at [maxPageCount] (250; its tier ceiling is 242);
  /// `satin170` / `gloss200` cap at [satinGlossMaxPageCount] (300).
  static int maxPageCountForSubstrate(final DotsPaperSubstrate substrate) {
    switch (substrate) {
      case DotsPaperSubstrate.uncoated150:
        return maxPageCount;
      case DotsPaperSubstrate.satin170:
      case DotsPaperSubstrate.gloss200:
        return satinGlossMaxPageCount;
    }
  }

  /// Finished book-block width in millimetres (interior trim).
  static const double bookBlockWidthMm = 203;

  /// Finished book-block height in millimetres (interior trim).
  static const double bookBlockHeightMm = 254;

  /// Bleed margin added on every outer edge of the cover artwork.
  static const double bleedMm = 3;

  /// Hinch (joint allowance) between front/back board and spine board.
  static const double hinchMm = 11;

  /// Image-wrap overhang on each cover edge.
  static const double wrapMm = 20;

  /// Board thickness for front, back and spine boards.
  static const double boardThicknessMm = 2.5;

  /// Spine-tier table for 150 gsm uncoated stock (`Substrate block` s44).
  static const List<_SpineTier> _uncoated150Tiers = <_SpineTier>[
    _SpineTier(minPages: 20, maxPages: 40, spineMm: 6.76, letter: 'A'),
    _SpineTier(minPages: 42, maxPages: 80, spineMm: 11.25, letter: 'B'),
    _SpineTier(minPages: 82, maxPages: 120, spineMm: 15.75, letter: 'C'),
    _SpineTier(minPages: 122, maxPages: 160, spineMm: 20.24, letter: 'D'),
    _SpineTier(minPages: 162, maxPages: 200, spineMm: 24.74, letter: 'E'),
    _SpineTier(minPages: 202, maxPages: 242, spineMm: 29.24, letter: 'F'),
  ];

  /// Spine-tier table for Satin 170 / Gloss 200 stock (`Substrate block` s45).
  ///
  /// Table 2 of `FileSpecs.203x254.V1.xlsx`; letter F extends to 300
  /// pages, the per-substrate cap enforced by [maxPageCountForSubstrate].
  static const List<_SpineTier> _coatedTiers = <_SpineTier>[
    _SpineTier(minPages: 20, maxPages: 50, spineMm: 6.76, letter: 'A'),
    _SpineTier(minPages: 52, maxPages: 100, spineMm: 11.25, letter: 'B'),
    _SpineTier(minPages: 105, maxPages: 150, spineMm: 15.75, letter: 'C'),
    _SpineTier(minPages: 152, maxPages: 200, spineMm: 20.24, letter: 'D'),
    _SpineTier(minPages: 202, maxPages: 250, spineMm: 24.74, letter: 'E'),
    _SpineTier(minPages: 252, maxPages: 300, spineMm: 29.24, letter: 'F'),
  ];

  /// Interior page count this geometry was built for.
  final int pageCount;

  /// Interior paper stock that drove the tier selection.
  final DotsPaperSubstrate paperSubstrate;

  /// Print supplier the geometry was built for.
  final DotsSupplier supplier;

  /// Spine stroke width in millimetres (variable `a` in SPECS_cover.md).
  final double spineWidthMm;

  /// Single-letter tier identifier (`A`..`F`) from the spreadsheet.
  final String spineLetter;

  /// Front-or-back cover width (variable `c`): finished book block minus
  /// the 4 mm fold-loss.
  double get frontBackWidthMm => bookBlockWidthMm - 4;

  /// Front-or-back cover width including the hinch joint (variable `k`).
  double get frontBackWidthInclHinchMm => frontBackWidthMm + hinchMm;

  /// Total cover width including wrap, excluding bleed (variable `g`).
  double get totalCoverWidthExclBleedMm =>
      (frontBackWidthMm + wrapMm + hinchMm) * 2 + spineWidthMm;

  /// Total cover height including wrap, excluding the outer bleed
  /// (variable `h` in SPECS_cover.md).
  ///
  /// Per the spec formula `h = d + 2·f`, where `d` is the
  /// front/back-cover height **including** the inner top/bottom bleed
  /// (i.e. `m + 2·bleed = 260`), and `f` is the wrap allowance. This
  /// is why the value is 300 mm, not 294 mm — the spec's "excl. bleed"
  /// label refers only to the outer 2·bleed added by [totalCoverHeightInclBleedMm].
  double get totalCoverHeightExclBleedMm =>
      bookBlockHeightInclBleedMm + 2 * wrapMm;

  /// Total cover width including wrap and bleed (variable `i`).
  ///
  /// This is the flat PDF width the supplier expects.
  double get totalCoverWidthInclBleedMm =>
      totalCoverWidthExclBleedMm + 2 * bleedMm;

  /// Total cover height including wrap and bleed (variable `j`).
  ///
  /// This is the flat PDF height the supplier expects.
  double get totalCoverHeightInclBleedMm =>
      totalCoverHeightExclBleedMm + 2 * bleedMm;

  /// Book-block width including bleed margin on both edges.
  double get bookBlockWidthInclBleedMm => bookBlockWidthMm + 2 * bleedMm;

  /// Book-block height including bleed margin on both edges.
  double get bookBlockHeightInclBleedMm => bookBlockHeightMm + 2 * bleedMm;

  static void _validate({
    required final int pageCount,
    required final DotsPaperSubstrate paperSubstrate,
    required final DotsSupplier supplier,
  }) {
    if (pageCount <= 0 || pageCount % 4 != 0) {
      throw DotsConfigException(
        'pageCount must be a positive multiple of 4 (got $pageCount).',
        pointer: r'$.pageCount',
      );
    }
    final int minPages = supplier.minPageCount;
    if (pageCount < minPages) {
      throw DotsConfigException(
        'pageCount $pageCount is below the ${supplier.name} '
        'supplier minimum of $minPages.',
        pointer: r'$.pageCount',
      );
    }
    final int maxPages = maxPageCountForSubstrate(paperSubstrate);
    if (pageCount > maxPages) {
      throw DotsConfigException(
        'pageCount $pageCount exceeds the ${paperSubstrate.name} '
        'cap of $maxPages.',
        pointer: r'$.pageCount',
      );
    }
    final List<_SpineTier> tiers = _tiersFor(paperSubstrate);
    final int tierMin = tiers.first.minPages;
    final int tierMax = tiers.last.maxPages;
    if (pageCount < tierMin || pageCount > tierMax) {
      throw DotsConfigException(
        'pageCount $pageCount falls outside the ${paperSubstrate.name} '
        'tier table ($tierMin–$tierMax).',
        pointer: r'$.pageCount',
      );
    }
    for (final _SpineTier tier in tiers) {
      if (tier.contains(pageCount)) {
        return;
      }
    }
    throw DotsConfigException(
      'pageCount $pageCount falls inside a gap between tiers for '
      '${paperSubstrate.name}.',
      pointer: r'$.pageCount',
    );
  }

  static List<_SpineTier> _tiersFor(final DotsPaperSubstrate substrate) {
    switch (substrate) {
      case DotsPaperSubstrate.uncoated150:
        return _uncoated150Tiers;
      case DotsPaperSubstrate.satin170:
      case DotsPaperSubstrate.gloss200:
        return _coatedTiers;
    }
  }

  static _SpineTier _resolveTier(
    final DotsPaperSubstrate substrate,
    final int pageCount,
  ) {
    for (final _SpineTier tier in _tiersFor(substrate)) {
      if (tier.contains(pageCount)) {
        return tier;
      }
    }
    // _validate guarantees a hit; this is defensive.
    throw DotsConfigException(
      'No spine tier resolved for pageCount $pageCount on '
      '${substrate.name}.',
      pointer: r'$.pageCount',
    );
  }

  @override
  bool operator ==(final Object other) =>
      other is DotsCoverGeometry &&
      other.pageCount == pageCount &&
      other.paperSubstrate == paperSubstrate &&
      other.supplier == supplier &&
      other.spineWidthMm == spineWidthMm &&
      other.spineLetter == spineLetter;

  @override
  int get hashCode => Object.hash(
        pageCount,
        paperSubstrate,
        supplier,
        spineWidthMm,
        spineLetter,
      );

  @override
  String toString() =>
      'DotsCoverGeometry(pageCount: $pageCount, '
      'paperSubstrate: ${paperSubstrate.name}, '
      'supplier: ${supplier.name}, '
      'spineLetter: $spineLetter, '
      'spineWidthMm: $spineWidthMm, '
      'totalCoverWidthInclBleedMm: $totalCoverWidthInclBleedMm, '
      'totalCoverHeightInclBleedMm: $totalCoverHeightInclBleedMm)';
}
