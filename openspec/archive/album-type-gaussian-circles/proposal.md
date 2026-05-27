# Proposal: album-type-gaussian-circles (Slice 4 of 5)

## Intent

Deliver the decorative 14-Gaussian-circle cover for `DotsAlbumType.parejas` and
`DotsAlbumType.hijos` (p.1). After slices 1-3 the library can already render
dedication, closing, and polaroid-collage spreads — but the parejas/hijos books
still cannot produce their distinctive cover front page. Slice 4 closes that gap
by introducing the decorative-circle primitive, a cover factory on
`DotsAlbumSpreadPage`, and a typed `AlbumCoverContent` value object that the
caller (and slice 5's pliego builder) can drive directly.

## Scope

### In Scope
- `DotsDecorativeCircleElement` — new sealed `DotsElement` subtype carrying
  `diameter`, `colorHex`, `gaussianFadeMm`, and the four bleed flags.
- Renderer support for the new element in the shared `buildAlbumSpreadPage`
  helper, including a single new `_buildDecorativeCircleElement(...)` arm in
  the sealed switch (consistent with slice 3's pattern).
- Gaussian fade strategy: **Option A — pre-rasterize once per unique diameter**
  (see Q1 verdict).
- `AlbumCoverContent` value object: `title` (book name), `dateLine`, and
  optional `eyebrowOverride` (default resolved per album type).
- `DotsAlbumSpreadPage.cover(...)` named constructor — produces the 14-circle
  bed + the 3-line centered text block (eyebrow / title / date line).
- Top-level builder `buildCoverPageFor(DotsAlbumType, AlbumCoverContent,
  {required int pageNumber})` returning a single `DotsAlbumSpreadPage`.
- Canonical 14-circle layout shipped as a private `kCoverCircleLayout`
  constant (3 diameters × 14 anchors) derived from the parejas p.4 table.
- Export every new public symbol from `lib/dots_pdf.dart`.

### Out of Scope
- `individuales`/`otros` p.1 cover (single centered photo, no circles).
- `boda` p.1 (different cover design — radial photo halo, slice TBD).
- parejas/hijos p.2 mirror cover, p.3 spine spread, p.6 dedication-spread
  variant, p.7 instructions, p.8 "Antes de empezar", p.9 photo-circle arc.
- The "p.4 circle catalog reference page" — treated as a test fixture only
  (see Q3 verdict). No public factory.
- Per-circle opacity / gradient variations (the spec calls for a uniform
  Gaussian fade across all 14 circles).
- Slice 5 (photo-circle arc, parejas p.9 / hijos p.9).

## Capabilities

### New Capabilities
- `album-type-gaussian-circles`: introduces `DotsDecorativeCircleElement`,
  `AlbumCoverContent`, `DotsAlbumSpreadPage.cover`, `buildCoverPageFor`, and
  the parejas/hijos cover composition (14 light-blue Gaussian-faded circles
  + 3-line centered text block).

### Modified Capabilities
- None. Slice 4 is purely additive; no slice 1-3 requirements change.

## Approach

1. **Decorative-circle primitive (Q4 verdict)**. Add `DotsDecorativeCircleElement`
   as a new sealed `DotsElement` subtype with `diameter`, `colorHex`,
   `gaussianFadeMm`, and bleed flags. Coordinates in pt (matches slice 3).
2. **Gaussian rasterization (Q1 verdict: Option A)**. At first-render
   time, the renderer pre-rasterizes one PNG per **unique diameter**
   (16/28/47 mm at 300 dpi → ~3 textures total, ~500 KB combined) using
   `package:image`'s `gaussianBlur`. Textures are cached in a process-wide
   `Map<int, Uint8List>` keyed by integer-rounded diameter-in-pt.
   Per-placement the renderer draws a `pw.Image` tinted by `colorHex`. This
   keeps slice 4 dependency-free (`image: ^4.8.0` is already in pubspec) and
   pixel-true to the design source.
3. **Cover page composition (Q5 verdict: Q5a)**. Reuse `DotsAlbumSpreadPage`
   with elements = 14 decorative circles + 3 text elements (eyebrow / title /
   date). Header/footer set to NULL — the cover does NOT carry the page-number
   trio (verified against spec p.1 description).
4. **Per-type variants (Q6 verdict: Q6a + helper)**. `AlbumCoverContent`
   exposes `eyebrowOverride: String?`. `buildCoverPageFor` resolves the
   default eyebrow per type (`parejas` → `"DOTBOOK"`, `hijos` →
   `"DOTBOOK DE {NOMBREHIJO}"`) and the override wins when set. Token
   substitution remains the caller's job (slice 1 already handles it).
5. **Renderer dispatch**. A new arm in `_buildElement` calls
   `_buildDecorativeCircleElement(...)`. `dart analyze` re-verifies
   exhaustiveness automatically.

## Q1-Q6 Verdicts

| Q | Decision |
|---|----------|
| Q1 — Fade strategy | **Option A**: pre-rasterize via `package:image`. Visual fidelity matters and the cost (~500 KB / 3 PNGs / lazy) is trivial. |
| Q2 — Texture lifetime | **Q2a**: generate at first-render, cache in memory. Avoids slowing template construction and avoids shipping binary assets. |
| Q3 — Catalog page (p.4) | **Q3b**: test fixture only. No public factory. The 14-circle layout lives in a private `kCoverCircleLayout`; tests assert it directly. |
| Q4 — Element subtype | Confirmed shape: `DotsDecorativeCircleElement(x, y, diameter, colorHex, gaussianFadeMm, bleed*)`. Coordinates in pt. Value equality on all fields. |
| Q5 — Page model | **Q5a**: reuse `DotsAlbumSpreadPage` with `.cover(...)` factory. Consistent with slices 2-3. |
| Q6 — Per-type variants | **Q6a**: caller-supplied `eyebrowOverride` with a per-type default resolved inside `buildCoverPageFor`. Library owns the defaults; caller can still override. |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsDecorativeCircleElement`; add `DotsAlbumSpreadPage.cover(...)` factory. |
| `lib/src/render/album_spread_page.dart` | Modified | Add `_buildDecorativeCircleElement` switch arm + texture cache + rasterization helper. |
| `lib/src/render/dots_renderer.dart` | Modified | Mechanical: extend `_buildElement` exhaustiveness via shared helper. |
| `lib/src/api/album_cover_content.dart` | New | `AlbumCoverContent` value object. |
| `lib/src/api/build_cover_page.dart` | New | `buildCoverPageFor(...)` top-level builder + per-type default eyebrow. |
| `lib/dots_pdf.dart` | Modified | Re-export new public symbols. |
| `test/render/cover_page_test.dart` | New | Cover composition, circle catalog parity, eyebrow per-type, header/footer null. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `package:image`'s `gaussianBlur` is slow at 47 mm @ 300 dpi | Low | One-shot rasterization per process, cached. Acceptable cold-start cost. |
| Texture cache leaks between tests | Low | Expose a `@visibleForTesting` reset hook. |
| Color tinting via `pw.Image` differs from design `#CDE7F2` | Low | Bake the color into the PNG at rasterization time — no runtime tint needed. |
| Bleed flags drift between cover and catalog (slice 4 + future) | Low | Single source of truth (`kCoverCircleLayout`) consumed by both factory and tests. |
| Cover-page sealed switch regresses other element types | Very Low | `dart analyze` enforces exhaustiveness; slice 1-3 tests run unchanged. |

## Rollback Plan

Slice 4 is purely additive. To revert:
1. Remove `DotsDecorativeCircleElement` from `dots_template.dart`.
2. Remove the `_buildDecorativeCircleElement` arm from `album_spread_page.dart`.
3. Remove the `cover` factory, `AlbumCoverContent`, and `buildCoverPageFor`.
4. Remove the new exports from `lib/dots_pdf.dart`.
5. Delete `test/render/cover_page_test.dart`.

No data migrations, no JSON schema changes (`DotsAlbumSpreadPage.cover` is a
factory; nothing parses it from JSON in this slice). Slice 1-3 outputs are
byte-identical before and after rollback.

## Dependencies

- Slice 1 (`album-type-foundation`) — provides `DotsAlbumType`,
  `DotsAlbumSpreadPage`, header/footer model.
- Slice 2 (`album-type-simple-pages`) — provides the shared
  `buildAlbumSpreadPage` helper and font routing through
  `DotsFontRole.inter`, `p22MackinacMedium`.
- Slice 3 (`album-type-polaroid-collage`) — establishes the element-subtype
  + factory + builder pattern this slice mirrors.
- `package:image ^4.8.0` — already in `pubspec.yaml`.

## Success Criteria

- [x] `DotsDecorativeCircleElement` constructs, supports value equality, and
      participates in the sealed `DotsElement` switch without breaking exhaustiveness.
- [x] `DotsAlbumSpreadPage.cover(type: parejas, ...)` returns a page whose
      `elements` list contains exactly 17 entries (14 circles + 3 text elements).
- [x] Rendering the cover via both the main-isolate and worker-isolate paths
      produces a non-empty valid PDF byte buffer.
- [x] Cover for `parejas` resolves the eyebrow to `"DOTBOOK"`; for `hijos`,
      to `"DOTBOOK DE {NOMBREHIJO}"` (literal — caller substitutes the token).
- [x] `buildCoverPageFor` produces geometry-identical output for parejas and
      hijos when the same `AlbumCoverContent` is passed (only the eyebrow text differs).
- [x] All slice 1-3 tests pass unchanged.
- [x] All new public symbols are exported from `lib/dots_pdf.dart`.
