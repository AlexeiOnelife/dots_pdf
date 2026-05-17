/// Selects whether the generator emits a single whole-document PDF
/// or one PDF per 2-page pair.
enum DotsOutputMode {
  /// Single PDF containing every page of the document.
  whole,

  /// One PDF per consecutive 2-page pair. The final pair may contain a
  /// single page when the document has an odd page count; no blank
  /// padding page is inserted.
  pairs,
}
