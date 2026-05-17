/// Identifier for one of the recurring interior-page layouts documented in
/// `docs/templates/SPECS_interior.md`.
///
/// Each value names a single concrete layout. Variants of the same family
/// (L1.A, L1.B, etc.) are distinct enum values so callers can request them
/// directly without an additional configuration field.
///
/// Values are ordered to mirror the spec's "Photo-layout repertoire"
/// section.
enum DotsLayoutCode {
  /// L1 — Protagonist. One 142 x 189 mm photo centered with a side or
  /// below caption block. No bleed by default.
  l1,

  /// L1.A — One 113 x 152 mm photo in side-caption format with an 800
  /// character body cap.
  l1a,

  /// L1.B — One 175 x 238 mm photo, oversized with edge-bleed on top,
  /// bottom and outer edge.
  l1b,

  /// L1.C — One 175 x 196 mm oversized portrait photo, centered in the
  /// live area.
  l1c,

  /// L1.D — One 107 x 107 mm centered square photo, used for opening or
  /// closing intro pages.
  l1d,

  /// L1.E — One 107 x 152 mm photo with side caption.
  l1e,

  /// L2.A — Two 86 x 110 mm photos side-by-side with a 16 mm horizontal
  /// gutter, vertically centered.
  l2a,

  /// L2.B — Two 115.5 x 86 mm photos stacked vertically with a 3 mm
  /// vertical gap.
  l2b,

  /// L2.C — Two 65 x 74 mm small framed photos with a 3 mm gap.
  l2c,

  /// L3.A — Three 60.27 x 82 mm photos in a row with 3 mm horizontal
  /// gaps.
  l3a,

  /// L4.A — Four 86 x 110 mm photos in a 2x2 grid with 3 mm gaps.
  l4a,

  /// L4.B — Per-page slice of a four-photo spread (two 86 x 110 mm
  /// photos per page, with a 3 mm horizontal gap).
  l4b,

  /// L6.A — Per-page slice of a 3x2 spread (three 86 x 110 mm photos
  /// per page, arranged as two on top, one below, all with 3 mm gaps).
  l6a,

  /// L7 — Per-page slice of the four-pane caption spread (two 142 x 105
  /// mm photos stacked vertically with a 3 mm gap, each with a date and
  /// body caption beneath).
  l7,

  /// L8 — Quad-top + double-bottom. Per-page slice: two 86 x 110 mm
  /// photos on the top row with a 3 mm gap, and one 175 x 115.5 mm
  /// photo below, separated by a 3 mm vertical gap.
  l8,

  /// L_hito — Milestone text page. No photo slot. Emits a title, date,
  /// body block (122 mm wide) and a QR card (130 mm wide).
  lhito,
}
