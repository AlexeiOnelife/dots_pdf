/// Interior paper stock used for the book block.
///
/// The substrate is the only input (besides page count) that drives the
/// spine-width tier lookup in `DotsCoverGeometry`. Heavier coated paper
/// fits fewer pages per tier than uncoated paper.
///
/// The labels mirror the `Substrate block` column from
/// `FileSpecs.203x254.V1.xlsx` as documented in `SPECS_cover.md`.
enum DotsPaperSubstrate {
  /// 150 gsm uncoated paper — source label **s44** (SPECS_cover.md Table 1).
  ///
  /// Page-tier ceiling: 242 pages (letter F).
  uncoated150,

  /// Satin 170 gsm coated paper — source label **s45** (SPECS_cover.md Table 2).
  ///
  /// Page-tier ceiling: 300 pages (letter F, 252–300), per Table 2 of
  /// `FileSpecs.203x254.V1.xlsx`.
  satin170,

  /// Gloss 200 gsm coated paper — source label **s45** (SPECS_cover.md Table 2).
  ///
  /// Shares Table 2 with [satin170]; same 300-page page-tier ceiling.
  gloss200,
}
