# Proposal: pareja-hijos-fidelity

## Intent

`DotsAlbumSpreadPage.cover(parejas|hijos)`, `.dedication(parejas|hijos)`,
and `.closing(parejas|hijos)` exist in `lib/src/config/dots_template.dart`
but their hardcoded coordinates drift several millimeters from the
canonical PDF (`pdf02_pareja_inicial`, `pdf03_pareja_final`,
`pdf08_hijos_inicial`, `pdf09_hijos_final` — 26 pages ground-truthed in
`explore.md`). The cover's `parejas` eyebrow is **outright wrong**:
the canonical eyebrow is `"DOTBOOK DE {PROTAGONISTA}"` for BOTH
categories, while today `parejas` emits `'DOTBOOK'` and `hijos` emits
`'DOTBOOK DE {NOMBREHIJO}'` (wrong token).

`.beforeYouStart(...)` and `.closingQrSpread(...)` are stubs introduced
by Task 2 that throw `DotsUnimplementedElement` at render time. Task 4
fills both factory bodies with the canonical layout and ships the
parejas + hijos category-specific copy.

This is **Task 4 of 7** in the `final-render-refinement` series, after
Task 1 (`page-template-chrome`, archived), Task 2
(`pliego-first-category`, archived — established the stubs filled
here), and Task 3 (`general-body-layouts-fidelity`, archived — fixed
the body-layout solver). Tasks 5–7 fill the remaining categories'
factories. Task 4 itself unblocks the first two categories that can
emit a fully rendered album end-to-end.

**Success looks like:** rendering a parejas or hijos album produces a
cover, dedication, before-you-start spread, photoArc spread, body
pages, closing-QR spread, and closing single page whose absolute
coordinates and copy match the canonical PDFs; `flutter test` and
`flutter analyze` are clean.

## Scope

### In Scope

- **`cover(parejas|hijos)` eyebrow text fix (CRITICAL)** — both types
  emit `"DOTBOOK DE {PROTAGONISTA}"`. The `parejas` default switches
  from `'DOTBOOK'`; the `hijos` default switches from
  `'DOTBOOK DE {NOMBREHIJO}'`. `eyebrowOverride` still wins. The dartdoc
  at `dots_template.dart:1499–1502` is rewritten to match.
- **`cover` coordinate corrections** —
  text-box width = 120 mm, x = 41.5 mm (was full pageWidth, x = 0);
  eyebrow y = 110.249 mm, title y ≈ 119 mm, date y ≈ 130.7 mm
  (replaces the `pageHeight/2 ± 12/18 mm` centered block). Circles
  unchanged (`kCoverCircleLayout` already matches).
- **`dedication(parejas|hijos)` coordinate corrections** —
  text-block x = 50.53 mm (was 0); body width = 120 mm (was 102 mm);
  the title y, body y, and signature y become relatively positioned
  (body 6.5 mm below title bottom; signature 8 mm below body bottom)
  instead of the current independent fixed constants (60 / 90 /
  160 mm). Signature font/angle (Biro Script Plus 12 pt at 2°) stays.
- **`closing(parejas|hijos)` coordinate corrections** —
  photo y = 71.534 mm (was 60 mm); title y = photo_bottom + 5 mm (was
  + 10 mm); title and subtitle x = 44 mm (was 0); subtitle width =
  115 mm (was 102 mm); subtitle y = title_bottom + 5 mm.
- **`beforeYouStart(...)` factory body** — full spread (single
  `DotsAlbumSpreadPage` whose elements live in 0–406 mm spread
  coordinates, following the existing `photoArc` / `bodaCluster`
  pattern; chrome header uses `leftPageNumber = '$pageNumber'` and
  `rightPageNumber = '${pageNumber + 1}'`, matching `photoArc`).
  Emits the title L1 (Mackinac Medium 27 pt) + L2 (Medium Italic 27 pt),
  body (Inter Book 9 pt) on the left page; protagonist label + CTA on
  the right page; 10-slot photo grid (5 per page, 35 × 46 mm,
  page-local x ∈ [8, 43, 78, 113, 148] mm, y = 36 mm) using
  `DotsImageElement`; per-page Q1/Q2 cluster (NÚMERO + TITULO + TEXTO)
  below the slots. Per-category copy via `switch (type)` for parejas
  and hijos. Other supported types fall through to the parejas branch
  for forward compatibility with Tasks 5–7 (the throwing argument
  guard rejects only `boda`, which never composes `beforeYouStart`).
- **`closingQrSpread(...)` factory body — LEFT PAGE ONLY** — title
  (Mackinac Medium 23 pt), body-1 (Inter Book 9 pt), QR block
  (27 × 27 mm at x = 30 mm, y = 94.081 mm), QR caption (Mackinac
  Medium 9 pt), bottom variable text (Inter Book 9 pt at y = 229.42 mm,
  uses `{Protagonistas}` substitution via `captionOverride` /
  `bottomTextOverride`). RIGHT PAGE renders header / footer chrome only
  (no decorative circles — deferred). The factory emits one
  `DotsAlbumSpreadPage` covering the spread.
- **`AlbumBeforeYouStartContent.photoPaths`** — new `required` field of
  type `List<String>` with length 10 (5 left + 5 right page). Existing
  `titleOverride` / `bodyOverride` remain optional.
- **`AlbumQrSpreadContent.bottomTextOverride`** — new optional field
  of type `String?` for the `{Protagonistas}, disfruta de está última
  experiencia.` bottom line. The default is the literal Spanish copy
  with `{Protagonistas}` left as a template token for the caller to
  pre-resolve (matching the existing `contextLabelValue` convention).
- **New layout constants** —
  `lib/src/render/before_you_start_layout.dart` exporting
  `kBeforeYouStartLeftLayout`, `kBeforeYouStartRightLayout`, and
  `kBeforeYouStartPhotoSlots` (10 `({double xMm, double yMm, double
  widthMm, double heightMm})` records). `lib/src/render/
  closing_qr_spread_layout.dart` exporting
  `kClosingQrSpreadLeftLayout` (title/body/QR/caption/bottom records).
- **Test fixtures** — `test/config/dots_album_spread_page_cover_test.dart`,
  `..._dedication_test.dart`, `..._closing_test.dart`,
  `..._before_you_start_test.dart` (new), `..._closing_qr_spread_test.dart`
  (new) — each covering parejas + hijos explicitly.

### Out of Scope (deferred)

- **Dedication left-page solid `#CDE7F2` background** — needs a new
  per-page background mechanism (extend `_blankAlbumSpread` or emit a
  full-page rectangle). Deferred per Decision Q2 in `explore.md`.
- **`beforeYouStart` photo-slot rounded corners** — `DotsImageElement`
  has no `cornerRadiusMm`. Use sharp-corner rectangles for Task 4;
  defer adding corner-radius support to a follow-up. (Decision Q6.)
- **`closingQrSpread` right-page decorative circles** — 27 positions
  extracted in `explore.md` but the PDFs do not annotate diameters.
  Right page ships chrome-only; circles deferred. (Decision Q4.)
- **`photoArc` fidelity verification** — `kPhotoArcLayout`'s source-PDF
  attribution comment refers to an older revision (current parejas p.9
  is `beforeYouStart`, not the arc). Cosmetic comment update only;
  no geometry change. (Decision Q1.)
- **`individuales` / `otros` / `boda` / `generalEventos` factories** —
  Tasks 5–7 own those categories.
- **Q1 / Q2 labels on `beforeYouStart`** — design annotations only,
  not rendered. (Decision Q8.)
- **`closing` single-page header parity** — already handled by
  Task 1's chrome predicate (`isLeftPage = pageNumber.isOdd` resolves
  at the renderer); no factory change. (Decision Q7.)

## Capabilities

> Researched `openspec/specs/` — contains `pliego-first-category.md`
> (Task 2's spec). Task 4 modifies the category-spread render contract
> previously stubbed there; per the SDD persistence convention, the
> Task 2 spec is the right capability to delta against.

### New Capabilities

- `category-render-fidelity-parejas-hijos`: the per-category render
  contract for `parejas` and `hijos` — covers each of the seven
  spreads' coordinate truth (cover, dedication, beforeYouStart,
  photoArc unchanged, closingQrSpread left, closing, body-layout
  pages from Task 3) plus the per-type copy / token substitutions.

### Modified Capabilities

- `pliego-first-category`: the `beforeYouStart` and `closingQrSpread`
  stub-throwing contract changes from "renders `DotsUnimplementedElement`
  at render time" to "renders the canonical layout with the
  caller-supplied content" for the parejas and hijos types. Other
  categories' stub behavior stays. The spec also gains the
  `AlbumBeforeYouStartContent.photoPaths` and
  `AlbumQrSpreadContent.bottomTextOverride` field additions in the
  caller-contract section.

## Approach

**Approach A from the explore — confirmed** (in-place coordinate
corrections + new factory bodies, layout constants extracted to two
new files mirroring `kCoverCircleLayout` / `kPhotoArcLayout`).

1. Add `photoPaths` to `AlbumBeforeYouStartContent` as `required
   List<String>` (length 10 asserted at factory entry); add
   `bottomTextOverride` to `AlbumQrSpreadContent` as `String?`.
2. Create `lib/src/render/before_you_start_layout.dart` and
   `lib/src/render/closing_qr_spread_layout.dart` exporting
   `const` record lists with the canonical mm coordinates from
   `explore.md`.
3. Rewrite `cover(parejas|hijos)`'s eyebrow `switch` and the three
   text positions; keep `kCoverCircleLayout` untouched.
4. Rewrite `dedication(parejas|hijos)`'s text-block positions in
   relative terms (title → body offset → signature offset).
5. Rewrite `closing(parejas|hijos)`'s photo y, title/subtitle
   positions, and subtitle width.
6. Implement `beforeYouStart(...)` body using the layout-constant
   files. Per-category copy via `switch (type)` covering parejas and
   hijos with shared per-category fallbacks for individuales / otros /
   generalEventos (those branches return the parejas copy with a
   `// TODO(task-5-7): per-category copy` marker — the throwing
   `boda` guard already exists).
7. Implement `closingQrSpread(...)` LEFT-PAGE body using the
   layout-constant file; right-page emits chrome only.
8. Update test fixtures and add new test files. Explicit parejas
   + hijos coverage per factory.
9. Cosmetic: update `kPhotoArcLayout`'s source attribution comment.

**Why not Approach B (extract a shared `_alignedTextBlock` helper):**
premature abstraction across three factories with diverging element
counts and per-page layouts; revisit if Tasks 5–7 expose the same
pattern.

**Why not Approach C (push fixed copy into
`AlbumBeforeYouStartContent`):** the PDF marks all body / Q1 / Q2 /
CTA / title copy as NOT EDITABLE (design-owned). The current
`titleOverride` / `bodyOverride` API is for testing + localisation
only; expanding it conflicts with the "design-owned copy" contract.

### Public API delta

**New:**
- `AlbumBeforeYouStartContent.photoPaths` — `final List<String>`;
  constructor now requires it. **Hard break** for any production
  caller that constructs the type today (Task 2 added the type, no
  production wiring yet; only test files).
- `AlbumQrSpreadContent.bottomTextOverride` — `final String?`;
  constructor adds it as an OPTIONAL named parameter (no break).
- `before_you_start_layout.dart` and `closing_qr_spread_layout.dart`
  layout-constant files (additive).

**Modified:**
- `DotsAlbumSpreadPage.cover(...)` — eyebrow defaults change for
  BOTH supported types; behavioral break for any caller asserting
  on the literal `'DOTBOOK'` / `'DOTBOOK DE {NOMBREHIJO}'` strings.
- `DotsAlbumSpreadPage.dedication(...)` — element x / y coordinates
  change; behavioral break for any test asserting on absolute
  positions.
- `DotsAlbumSpreadPage.closing(...)` — same — coordinate break.
- `DotsAlbumSpreadPage.beforeYouStart(...)` — no longer emits a
  `DotsUnimplementedElement`; now emits ≈ 22 real elements per
  spread. Header chrome moves from `pageNumber.isOdd`-parity to the
  spread pattern (`leftPageNumber = '$pageNumber'`, `rightPageNumber =
  '${pageNumber + 1}'`) matching `photoArc`.
- `DotsAlbumSpreadPage.closingQrSpread(...)` — same as above;
  emits ≈ 5 real elements on the left half, chrome only on the right.

**Removed:** None.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/api/album_before_you_start_content.dart` | Modified | Add `required List<String> photoPaths` + length-10 invariant + equality / hash updates. |
| `lib/src/api/album_qr_spread_content.dart` | Modified | Add optional `bottomTextOverride` + equality / hash updates. |
| `lib/src/config/dots_template.dart` | Modified (heavy) | Rewrite `cover` (lines ≈1499–1588), `dedication` (≈1247–1316), `closing` (≈1318–1407), `beforeYouStart` (≈2047–2070), `closingQrSpread` (≈2134–2157) bodies. |
| `lib/src/render/before_you_start_layout.dart` | New | Canonical mm-coordinate records for the spread. |
| `lib/src/render/closing_qr_spread_layout.dart` | New | Canonical mm-coordinate records for the left-page layout. |
| `lib/src/render/photo_arc_layout.dart` (or wherever `kPhotoArcLayout` lives) | Modified (cosmetic) | Update source-attribution comment per Decision Q1. |
| `lib/dots_pdf.dart` | Maybe modified | Export the two new layout-constant files if the convention is to expose them; otherwise leave private. Spec phase to decide. |
| `test/config/dots_album_spread_page_cover_test.dart` | Modified (heavy) | New expected eyebrow / coords for parejas + hijos. |
| `test/config/dots_album_spread_page_dedication_test.dart` | Modified | New expected coords; relative positioning. |
| `test/config/dots_album_spread_page_closing_test.dart` | Modified | New expected coords. |
| `test/config/dots_album_spread_page_before_you_start_test.dart` | New | Parejas + hijos coverage; element count, positions, copy assertions. |
| `test/config/dots_album_spread_page_closing_qr_spread_test.dart` | New | Parejas + hijos coverage; left-page elements + right-page chrome-only assertion. |
| `test/api/album_before_you_start_content_test.dart` | Modified | `photoPaths` is now required; length-10 invariant tested. |
| `test/api/album_qr_spread_content_test.dart` | Modified | Add `bottomTextOverride` coverage. |
| `docs/templates/SPECS_interior.md` | Maybe modified | If the spec doc tracks per-spread layouts, add the corrected coordinates for the parejas + hijos spreads. Spec phase to decide. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **`AlbumBeforeYouStartContent.photoPaths` required arg breaks every existing instantiation.** | High by design | Only test files construct it today (Task 2 left the type stubbed). Analyzer surfaces every break; the spec phase enumerates updates. |
| **Cover eyebrow change is a hard behavioral break.** Any production caller that relied on the literal `'DOTBOOK'` default sees a different cover. | Medium | The current `parejas` cover renders an empty eyebrow text after token substitution if the caller had `{tiempojuntos}` mapped; the new behavior is canonical-correct. Document the change in the PR description; spec phase asserts the new default explicitly. |
| **Coordinate changes break existing layout tests.** | High by design | Same strict TDD pattern as Task 3 — spec phase enumerates the new expected coords; tasks phase commits RED → GREEN per slice. |
| **`beforeYouStart` and `closingQrSpread` chrome semantics flip** from `pageNumber.isOdd`-parity (stub) to spread-style (`leftPageNumber` + `rightPageNumber = pageNumber + 1`). | Medium | The stub never rendered (it threw at draw). The new chrome matches `photoArc` / `bodaCluster`. Renderer support already exists; no chrome-predicate change needed. Test asserts the chrome shape explicitly. |
| **Per-category copy for individuales / otros / generalEventos in `beforeYouStart` is parejas-copy stub-forward.** | Low | Tasks 5–7 own those branches; the parejas-fallback with a `TODO(task-N)` marker is explicit. The `boda` guard already throws. |
| **`{Protagonistas}` token substitution** — bottom line of closingQrSpread takes a pre-resolved string OR keeps the literal token. | Low | Follow the existing `contextLabelValue` convention: caller pre-resolves. `bottomTextOverride` lets the caller pass the resolved string; the default leaves the literal token (rendered for debugging only). Spec phase locks the contract. |
| **`closing` single-page chrome parity** — closing is a single right page, not a spread. The header today emits both `leftPageNumber` and `rightPageNumber` set to `$pageNumber`. | Low | Task 1's chrome predicate handles parity at draw time. No factory change; verify in test. (Decision Q7.) |
| **LOC estimate (~520) under one PR.** | Medium | User has removed the 400-line PR-size guardrail for this branch. Single PR per their direction. Reviewer load mitigated by per-factory commit splits inside the PR. |

## Rollback Plan

All changes land on the `pareja-hijos-fidelity` branch (already cut off
Task 3's tip per the brief). Single PR per the user's removed
PR-size guardrail. Rollback = `git revert` the slice commits in
reverse order. Specifically:

- `AlbumBeforeYouStartContent.photoPaths` addition is a hard revert
  (analyzer flags any caller still passing it).
- `AlbumQrSpreadContent.bottomTextOverride` revert is clean
  (optional param).
- Cover / dedication / closing coordinate reverts restore the
  pre-Task-4 (and intentionally wrong) hardcoded constants.
- `beforeYouStart` / `closingQrSpread` factory bodies revert to the
  `DotsUnimplementedElement` stubs from Task 2.
- New layout-constant files are purely additive — revert deletes them.
- Test fixture reverts pair with the production code (commit-paired).

No cache invalidation needed — page elements are computed from inputs
every render, not memoized across config versions.

## Dependencies

- **Task 1 (`page-template-chrome`)** — archived. Provides the
  `isLeftPage = pageNumber.isOdd` chrome derivation. We rely on it
  for the closing single-page header.
- **Task 2 (`pliego-first-category`)** — archived. Established the
  factory stubs and the `AlbumBeforeYouStartContent` /
  `AlbumQrSpreadContent` types that this change fills and extends.
- **Task 3 (`general-body-layouts-fidelity`)** — archived. Provides
  the corrected body-layout solver that body pages between the
  category spreads now consume. Not directly touched by Task 4.
- Tasks 5–7 will fill the remaining categories' factories. They
  depend on the `AlbumBeforeYouStartContent.photoPaths` schema
  Task 4 introduces (10-slot grid is shared across all categories).

## Success Criteria

- [ ] `cover(parejas|hijos)` emits `"DOTBOOK DE {PROTAGONISTA}"` as the
      default eyebrow for BOTH types; `eyebrowOverride` still wins.
- [ ] `cover(parejas|hijos)` text positions match the PDF: text-box
      width 120 mm at x = 41.5 mm; eyebrow y = 110.249 mm; title and
      date positioned per the explore mismatch table.
- [ ] `dedication(parejas|hijos)` text positions are relative
      (title → body → signature) and match the PDF (x = 50.53 mm,
      body width 120 mm).
- [ ] `closing(parejas|hijos)` photo y = 71.534 mm; title and subtitle
      x = 44 mm; subtitle width 115 mm.
- [ ] `beforeYouStart(parejas|hijos)` renders the canonical spread
      (title L1+L2, body, protagonist label, CTA, 10 photo slots,
      Q1/Q2 cluster on each page) using the caller's `photoPaths`.
- [ ] `closingQrSpread(parejas|hijos)` LEFT page renders title, body-1,
      QR block, QR caption, bottom variable line. Right page renders
      chrome-only.
- [ ] `AlbumBeforeYouStartContent.photoPaths` is a required field of
      length 10; the factory rejects any other length with `RangeError`.
- [ ] `AlbumQrSpreadContent.bottomTextOverride` is optional and the
      default leaves the literal token.
- [ ] `flutter analyze` clean; `flutter test` passes (existing fixtures
      updated + new ones GREEN).
- [ ] All parejas + hijos render paths reach the renderer without
      throwing `UnimplementedError` on the spreads in scope.

## Decisions (from the brief, pre-resolved)

1. **Layout-constant files live at `lib/src/render/`** alongside the
   existing `cover_circles.dart` and `photo_arc_layout.dart` (one
   precedent per major spread). Two new files:
   `before_you_start_layout.dart` and `closing_qr_spread_layout.dart`.
   Spec phase decides whether to export them through `lib/dots_pdf.dart`.

2. **`AlbumBeforeYouStartContent.photoPaths` is `required`**, mirroring
   `AlbumPhotoArcContent.photoPaths` (which is also required and
   length-asserted). Caller cannot omit photos — the layout is a photo
   grid.

3. **`AlbumQrSpreadContent.bottomTextOverride` is an OPTIONAL field**
   (`String?` default `null`). The default bottom text is
   `'{Protagonistas}, disfruta de está última experiencia.'` with the
   literal `{Protagonistas}` token; the caller passes the
   pre-resolved string via `bottomTextOverride`. `captionOverride`
   keeps its existing meaning (the QR caption beside the block, not
   the bottom line).

4. **Single-page-vs-spread output: ONE `DotsAlbumSpreadPage` covering
   the spread**, following the established `photoArc` / `bodaCluster`
   pattern. Elements live in spread-relative 0–406 mm coordinates;
   right-page elements are positioned at `x ≥ 203 mm`. No
   `whichPage` enum, no twin factories. Header chrome:
   `leftPageNumber = '$pageNumber'`, `rightPageNumber = '${pageNumber + 1}'`.
   This RESOLVES the brief's question Decision #4 — the existing
   pattern handles it natively, and the current stub's
   `pageNumber.isOdd`-parity chrome was wrong and gets replaced.

5. **`DotsTemplateParser` mandatory-pliego packing does NOT need
   adjustment for parejas/hijos.** The spec at
   `openspec/specs/pliego-first-category.md` lines 189–190 already
   sequences `beforeYouStart` as a SINGLE entry between `cover` and
   `dedication` (matching the single-spread shape). The parser packs
   it as a two-page mandatory pliego using one `beforeYouStart` call —
   the same way it packs `photoArc`. No parser change needed in
   Task 4; verify in test.

## Size Estimate

~520 LOC, single PR per the user's standing direction.

| Slice | LOC |
|---|---|
| `cover(parejas\|hijos)` rewrite | ~30 |
| `dedication(parejas\|hijos)` rewrite | ~40 |
| `closing(parejas\|hijos)` rewrite | ~30 |
| `beforeYouStart(...)` body | ~80 |
| `closingQrSpread(...)` body | ~60 |
| `before_you_start_layout.dart` constants | ~50 |
| `closing_qr_spread_layout.dart` constants | ~30 |
| `AlbumBeforeYouStartContent.photoPaths` | ~15 |
| `AlbumQrSpreadContent.bottomTextOverride` | ~10 |
| New + updated tests | ~150 |
| Cosmetic `kPhotoArcLayout` comment | ~5 |
| **Total** | **~500** |

Tasks phase emits the Review Workload Forecast with
`Chained PRs recommended: No`, `400-line budget risk: High` (~500 LOC
straddles the threshold), `Decision needed before apply: No` (user
has pre-resolved single-PR delivery).
