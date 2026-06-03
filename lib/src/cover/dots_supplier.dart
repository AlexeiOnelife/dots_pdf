/// Print supplier region for a Dotbook job.
///
/// The supplier determines two things at PDF-generation time:
///
/// 1. The minimum page count accepted for the interior block
///    (see [minPageCount]).
/// 2. Whether the cover PDF carries crop / bleed marks
///    (see [drawsCropMarks]).
///
/// Cover and interior **geometry** is otherwise identical between
/// suppliers — only the marks toggle and the page-count floor change.
enum DotsSupplier {
  /// Europa region: minimum 20 interior pages, crop marks rendered.
  europa,

  /// Latam region: minimum 30 interior pages, crop marks omitted.
  latam;

  /// Smallest interior page count accepted by this supplier.
  ///
  /// Callers must additionally honour the per-substrate maximum (250
  /// pages for `uncoated150`, 300 for `satin170` / `gloss200`) and the
  /// per-substrate tier ceiling (242 pages for `uncoated150`).
  int get minPageCount {
    switch (this) {
      case DotsSupplier.europa:
        return 20;
      case DotsSupplier.latam:
        return 30;
    }
  }

  /// Whether crop / bleed marks should be drawn on the cover PDF.
  ///
  /// Europa expects crop marks; Latam expects a clean PDF without
  /// them. The flag is consumed by the cover renderer, not by the
  /// geometry layer.
  bool get drawsCropMarks {
    switch (this) {
      case DotsSupplier.europa:
        return true;
      case DotsSupplier.latam:
        return false;
    }
  }
}
