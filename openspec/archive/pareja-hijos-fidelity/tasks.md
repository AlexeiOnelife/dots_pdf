# Tasks: pareja-hijos-fidelity

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~500–540 (production ~350, tests ~170) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes by SDD heuristic; user accepted size:exception per `final-render-refinement` standing direction |
| Suggested split | Single PR — size:exception accepted by user |
| Delivery strategy | single-pr |
| Chain strategy | size:exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size:exception
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | PR | Notes |
|------|------|----|-------|
| 1 | All phases — API deltas, layout constants, factory bodies, coordinate fixes, renderer gate, tests | Single PR | size:exception accepted; branch `pareja-hijos-fidelity` already cut |

---

## Phase 1 — Foundation: Content-Class API Deltas (R7, R8)

**Strict TDD: RED test first, then implementation.**

- [x] **T1.1** `test/config/dots_album_spread_page_test.dart` — add RED group `AlbumBeforeYouStartContent — photoPaths`:
  - `photoPaths required — constructor with length-10 list succeeds`
  - `photoPaths required — omitting photoPaths is a compile error` (static; comment-only)
  - `length invariant — constructing with length 9 throws AssertionError` (assert in debug mode)
  - `length invariant — constructing with length 11 throws AssertionError`
  - `equality includes photoPaths` (two instances differing only in photoPaths are not equal)
  Satisfies R7.

- [x] **T1.2** `lib/src/api/album_before_you_start_content.dart` — add `required this.photoPaths` to const ctor; add `: assert(photoPaths.length == 10, 'photoPaths must contain exactly 10 entries')` invariant; add `final List<String> photoPaths`; extend `==` (add `other.photoPaths == photoPaths` using `listEquals` or element-wise) and `hashCode` (fold photoPaths into `Object.hashAll`); update dartdoc. Satisfies R7.
  Commit: `feat(api): add required photoPaths[10] to AlbumBeforeYouStartContent`

- [x] **T1.3** `test/config/dots_album_spread_page_test.dart` — add RED group `AlbumQrSpreadContent — bottomTextOverride`:
  - `bottomTextOverride null by default`
  - `bottomTextOverride non-null stored correctly`
  - `equality distinguishes bottomTextOverride`
  - `hashCode differs when bottomTextOverride differs`
  Satisfies R8.

- [x] **T1.4** `lib/src/api/album_qr_spread_content.dart` — add `this.bottomTextOverride` optional named param to const ctor (no `required`); add `final String? bottomTextOverride`; extend `==` and `hashCode`; update dartdoc. Satisfies R8.
  Commit: `feat(api): add optional bottomTextOverride to AlbumQrSpreadContent`

- [x] **T1.5** Run `flutter analyze` clean. Run `flutter test test/config/dots_album_spread_page_test.dart` — T1.1 + T1.3 groups GREEN (no other suites broken; no production caller of `AlbumBeforeYouStartContent` exists outside tests).

---

## Phase 2 — Foundation: `DotsOvalQrElement.drawFrame` (Design Decision 1)

**Drift risk: update `album_spread_page.dart` and `isolate_synthesis.dart` in the SAME commit.**

- [x] **T2.1** `test/config/dots_oval_qr_element_test.dart` — add RED group `DotsOvalQrElement — drawFrame`:
  - `drawFrame defaults to true`
  - `drawFrame false stored correctly`
  - `equality includes drawFrame` (two elements differing only in drawFrame are not equal)
  - `hashCode includes drawFrame`
  Satisfies Design Decision 1 contract.

- [x] **T2.2** `lib/src/config/dots_template.dart` at `DotsOvalQrElement` (lines 503–542) — add `this.drawFrame = true` named param to const ctor; add `final bool drawFrame`; extend `==` (add `other.drawFrame == drawFrame`) and `hashCode` (add `drawFrame` to `Object.hash`). Dartdoc: `"When false the elliptical border stroke is suppressed; use for the closing-QR square block where no oval frame is wanted. Defaults to true to preserve photoArc behaviour."`. Satisfies R9 partial.

- [x] **T2.3** `lib/src/render/album_spread_page.dart` — in `_buildOvalQrElement`: gate the `pw.Container(decoration: BoxDecoration(shape: BoxShape.circle, border: …))` block on `if (element.drawFrame)`. Keep the `BarcodeWidget` arm unchanged.

- [x] **T2.4** `lib/src/render/isolate_synthesis.dart` — apply the identical `if (element.drawFrame)` gate in the lock-step copy of `_buildOvalQrElement`. Same commit as T2.3 to prevent drift. Satisfies Design Decision 1.

- [x] **T2.5** `test/render/album_spread_page_test.dart` — add RED group `DotsOvalQrElement — drawFrame: false rendering`:
  - `drawFrame false renders BarcodeWidget without oval border` (widget-tree assertion or PDF byte inspection via `@visibleForTesting` hook).
  Satisfies Design Decision 1 render verification.
  Commit: `refactor(api): add drawFrame bool to DotsOvalQrElement; gate oval border in both renderers`

- [x] **T2.6** Run `flutter analyze` clean. Run `flutter test` — T2.1 + T2.5 groups GREEN; pre-existing oval QR tests unchanged (default `drawFrame: true`).

---

## Phase 3 — Foundation: Layout-Constant Files (R9)

- [x] **T3.1** `test/render/before_you_start_layout_test.dart` — create new file with RED tests:
  - `kBeforeYouStartPhotoSlots length equals 10`
  - per-slot `xMm`, `yMm`, `widthMm`, `heightMm` values against design table (tolerance ±0.001 mm)
  - `kBeforeYouStartTitleL1`, `kBeforeYouStartTitleL2`, `kBeforeYouStartLeftBody`, `kBeforeYouStartProtagonistLabel`, `kBeforeYouStartCta` record values match design
  Satisfies R9.

- [x] **T3.2** `lib/src/render/before_you_start_layout.dart` — create new file:
  - Library-private `typedef _SlotRectMm` and `typedef _TextRectMm`.
  - `const List<_SlotRectMm> kBeforeYouStartPhotoSlots` — 10 entries: slots 0–4 at `x ∈ [8, 43, 78, 113, 148]`, `y=36`, `w=35`, `h=46`; slots 5–9 at `x ∈ [211, 246, 281, 316, 351]`, `y=36`, `w=35`, `h=46`.
  - `kBeforeYouStartTitleL1`, `kBeforeYouStartTitleL2`, `kBeforeYouStartLeftBody`, `kBeforeYouStartProtagonistLabel`, `kBeforeYouStartCta` const singletons per design.
  - `@visibleForTesting` accessor projecting `kBeforeYouStartPhotoSlots` as a public named-record list for tests.
  Satisfies R9.

- [x] **T3.3** `test/render/closing_qr_spread_layout_test.dart` — create new file with RED tests:
  - `kClosingQrTitle`, `kClosingQrBody1`, `kClosingQrBlock`, `kClosingQrCaption`, `kClosingQrBottom` record values against design constants (tolerance ±0.001 mm)
  Satisfies R9.

- [x] **T3.4** `lib/src/render/closing_qr_spread_layout.dart` — create new file:
  - Library-private `typedef _SlotRectMm` and `typedef _TextRectMm`.
  - `kClosingQrTitle = (xMm: 30, yMm: 50.892, widthMm: 143)`.
  - `kClosingQrBody1 = (xMm: 30, yMm: 71.346, widthMm: 92)`.
  - `kClosingQrBlock = (xMm: 30, yMm: 94.081, widthMm: 35, heightMm: 35)`.
  - `kClosingQrCaption = (xMm: 62, yMm: 94.081, widthMm: 36.178)`.
  - `kClosingQrBottom = (xMm: 30, yMm: 229.420, widthMm: 143)`.
  - `@visibleForTesting` accessor.
  Satisfies R9.

- [x] **T3.5** Run `flutter test test/render/before_you_start_layout_test.dart test/render/closing_qr_spread_layout_test.dart` — GREEN.
  Commit: `feat(render): add before_you_start_layout + closing_qr_spread_layout constant files`

---

## Phase 4 — Core: Cover + Dedication + Closing Coordinate Fixes (R1–R4)

**Each sub-task: update test fixture first (RED), then production code (GREEN).**

- [x] **T4.1** `test/config/dots_album_spread_page_test.dart` — add/update group `cover — parejas and hijos`:
  - Both types: eyebrow element value == `'DOTBOOK DE {PROTAGONISTA}'`.
  - `eyebrowOverride` wins over default.
  - Text-box `x = 41.5 mm * _mmToPt`, `width = 120 mm * _mmToPt`.
  - Eyebrow `y ≈ 110.249 mm * _mmToPt` (tolerance ±0.5 pt).
  - Title `y ≈ 119 mm * _mmToPt`, date `y ≈ 130.7 mm * _mmToPt`.
  Satisfies R1, R2.

- [x] **T4.2** `lib/src/config/dots_template.dart` — `cover` factory (lines 1505–~1588):
  - Rewrite eyebrow `switch`: both `parejas` and `hijos` default to `'DOTBOOK DE {PROTAGONISTA}'`.
  - Replace centered text block with `x = 41.5 mm`, `width = 120 mm`; eyebrow `y = 110.249 mm`, title `y ≈ 119 mm`, date `y ≈ 130.7 mm` (all in pt via `_mmToPt`).
  - Rewrite dartdoc lines 1499–1502 to reflect new defaults.
  Satisfies R1, R2.
  Commit: `fix(render): cover(parejas|hijos) — correct eyebrow text + geometry`

- [x] **T4.3** `test/config/dots_album_spread_page_test.dart` — add/update group `dedication — parejas and hijos`:
  - Title `x = 50.53 mm * _mmToPt`.
  - Body `width = 120 mm * _mmToPt`.
  - Body `y = titleY + titleHeight + 6.5 mm * _mmToPt` (relative, computed from constants).
  - Signature `y = bodyY + bodyHeight + 8 mm * _mmToPt`.
  Satisfies R3.

- [x] **T4.4** `lib/src/config/dots_template.dart` — `dedication` factory (lines 1253–1316):
  - Replace `const double titleX = 0` → `x = 50.53 * _mmToPt`.
  - Replace `const double bodyX = 0` → same `x`.
  - Replace `const double bodyWidthPt = 102.0 * _mmToPt` → `120.0 * _mmToPt`.
  - Replace absolute `titleY = 60 mm`, `bodyY = 90 mm`, `signatureY = 160 mm` with relative offsets: `bodyY = titleY + titleElement.estimatedHeightPt + 6.5 * _mmToPt`; `signatureY = bodyY + bodyElement.estimatedHeightPt + 8 * _mmToPt`. (Where height is estimated from font metrics or stored as a constant matching the design's approach.)
  Satisfies R3.
  Commit: `fix(render): dedication(parejas|hijos) — correct x/width/relative-y`

- [x] **T4.5** `test/config/dots_album_spread_page_test.dart` — add/update group `closing — parejas and hijos`:
  - Photo `y = 71.534 mm * _mmToPt`.
  - Title and subtitle `x = 44 mm * _mmToPt`.
  - Subtitle `width = 115 mm * _mmToPt`.
  - Title `y = photoY + photoHeightPt + 5 mm * _mmToPt`.
  - Subtitle `y = titleY + titleFontSize * lineHeightFactor + 5 mm * _mmToPt`.
  Satisfies R4.

- [x] **T4.6** `lib/src/config/dots_template.dart` — `closing` factory (lines 1334–1407):
  - `photoY = 71.534 * _mmToPt` (was `60.0 * _mmToPt`).
  - `titleX = 44 * _mmToPt` (was `0`); `subtitleX = 44 * _mmToPt` (was `0`).
  - `titleY = photoY + photoHeightPt + 5 * _mmToPt` (was `+ 10 mm`).
  - `subtitleWidthPt = 115.0 * _mmToPt` (was `102.0 * _mmToPt`).
  - `subtitleY = titleY + titleFontSize * 1.5 + 5 * _mmToPt` (add the 5 mm gap).
  Satisfies R4.
  Commit: `fix(render): closing(parejas|hijos) — correct photo y, title/subtitle x/width/gap`

- [x] **T4.7** Run `flutter analyze` clean. Run `flutter test test/config/dots_album_spread_page_test.dart` — all T4 groups GREEN; remaining test suite unchanged.

---

## Phase 5 — Core: `beforeYouStart` Factory Body (R5)

**Strict TDD: test assertions precede factory implementation.**

- [x] **T5.1** `test/config/dots_album_spread_page_test.dart` — add group `beforeYouStart — parejas and hijos`:
  - Zero `DotsUnimplementedElement` instances in elements list.
  - Total element count ≈ 22 (10 `DotsImageElement` + ~12 text elements).
  - `header.leftPageNumber == '$pageNumber'`, `header.rightPageNumber == '${pageNumber + 1}'`.
  - `footer.wordmark == 'Dots. Memories'`.
  - Parejas-specific title L2 string differs from hijos-specific title L2 string.
  - Per-category body string present.
  - Q1 and Q2 cluster: 3 text elements (NÚMERO, TITULO, TEXTO) per page = 6 total.
  - `AssertionError` when `photoPaths.length != 10`.
  - All 10 photo slots have `widthMm == 35 mm * _mmToPt` and `heightMm == 46 mm * _mmToPt` (converted).
  Satisfies R5, R7.

- [x] **T5.2** `lib/src/config/dots_template.dart` — `beforeYouStart` factory (lines 2047–2070): replace stub with real body:
  - Exhaustive `switch (type)` for `parejas` + `hijos` copy; `individuales`, `outros`, `generalEventos` fall through to parejas copy with `// TODO(task-5-7)` marker; `boda` throws `ArgumentError`.
  - Import/use `kBeforeYouStartPhotoSlots`, `kBeforeYouStartTitleL1`, `kBeforeYouStartTitleL2`, `kBeforeYouStartLeftBody`, `kBeforeYouStartProtagonistLabel`, `kBeforeYouStartCta` from `before_you_start_layout.dart`.
  - Emit 10 `DotsImageElement` from `content.photoPaths` using slot rects (spread coords).
  - Emit title L1 (P22 Mackinac Medium 27 pt), L2 (Medium Italic 27 pt), body (Inter Book 9 pt) on left page.
  - Emit protagonist label + CTA on right page.
  - Q1/Q2 cluster per page: NÚMERO + TITULO + TEXTO at `x = 55.309 mm`, `width = 93 mm`; first NÚMERO `y = 89.5 mm` (photo bottom 82 mm + 7.5 mm gap); right-page cluster mirrors at `x += 203 mm`.
  - Header: `leftPageNumber = '$pageNumber'`, `rightPageNumber = '${pageNumber + 1}'`.
  Satisfies R5.
  Commit: `feat(render): implement beforeYouStart factory body (parejas + hijos)`

- [x] **T5.3** Run `flutter test test/config/dots_album_spread_page_test.dart` — T5.1 group GREEN; no regressions.

---

## Phase 6 — Core: `closingQrSpread` Factory Body (R6)

**Strict TDD: test assertions precede factory implementation.**

- [x] **T6.1** `test/config/dots_album_spread_page_test.dart` — add group `closingQrSpread — parejas and hijos`:
  - Exactly 5 elements on the left page (title, body-1, QR, QR-caption, bottom).
  - Zero elements at `x >= 203 mm * _mmToPt` (right half of spread).
  - `header.leftPageNumber == '$pageNumber'`, `header.rightPageNumber == '${pageNumber + 1}'`.
  - `footer.wordmark == 'Dots. Memories'`.
  - The `DotsOvalQrElement` has `drawFrame == false`.
  - QR element `ovalWidth == ovalHeight == 35 mm * _mmToPt` (square bbox).
  - Bottom text element: `content.bottomTextOverride ?? '{Protagonistas}, disfruta de está última experiencia.'`.
  - `assert(content.placement == AlbumQrSpreadPlacement.closing)` fires if wrong placement.
  Satisfies R6, R8.

- [x] **T6.2** `lib/src/config/dots_template.dart` — `closingQrSpread` factory (lines 2134–2157): replace stub with real body:
  - Import/use `kClosingQrTitle`, `kClosingQrBody1`, `kClosingQrBlock`, `kClosingQrCaption`, `kClosingQrBottom` from `closing_qr_spread_layout.dart`.
  - Emit title `DotsTextElement` (P22 Mackinac Medium 23 pt) at `kClosingQrTitle` position.
  - Emit body-1 `DotsTextBlockElement` (Inter Book 9 pt) at `kClosingQrBody1` position.
  - Emit `DotsOvalQrElement(ovalWidth=35mm, ovalHeight=35mm, drawFrame: false, caption: '', qrPayload: content.qrPayload)` at `kClosingQrBlock` position.
  - Emit QR-caption `DotsTextElement` (Mackinac Medium 9 pt) at `kClosingQrCaption` position (text = `content.captionOverride ?? 'Escanea el QR y vuelve…'`).
  - Emit bottom `DotsTextBlockElement` (Inter Book 9 pt) at `kClosingQrBottom` position (text = `content.bottomTextOverride ?? '{Protagonistas}, disfruta de está última experiencia.'`).
  - Right half: no body elements (chrome-only per Decision 2).
  - Header: `leftPageNumber = '$pageNumber'`, `rightPageNumber = '${pageNumber + 1}'`.
  Satisfies R6.
  Commit: `feat(render): implement closingQrSpread factory body LEFT page (parejas + hijos)`

- [x] **T6.3** Run `flutter test test/config/dots_album_spread_page_test.dart` — T6.1 group GREEN; no regressions.

---

## Phase 7 — Cleanup + Documentation (R10, cosmetic)

- [x] **T7.1** `lib/src/render/photo_arc_layout.dart` — update the source-attribution comment for `kPhotoArcLayout` to reflect that parejas p.9 is now `beforeYouStart`, not the arc. Cosmetic only; no geometry change. Satisfies proposal Decision Q1.

- [x] **T7.2** Confirm `lib/dots_pdf.dart` exports `AlbumBeforeYouStartContent` and `AlbumQrSpreadContent`. Layout-constant files (`before_you_start_layout.dart`, `closing_qr_spread_layout.dart`) remain library-private — NOT exported. No change needed if exports already exist; otherwise add them.
  Commit: `docs(render): update kPhotoArcLayout source comment; verify public exports`

---

## Phase 8 — Final Verification (R10)

- [x] **T8.1** Run `flutter analyze` — zero warnings or errors. Confirm:
  - No `public_member_api_docs` violations on new fields.
  - Exhaustive `switch (type)` in `beforeYouStart` covers all `DotsAlbumType` values.
  - No dangling reference to old `content.titleOverride`-only ctor in tests.

- [x] **T8.2** Run `flutter test` — ALL tests GREEN. Confirm:
  - Phase 1 content-class groups GREEN.
  - Phase 2 `drawFrame` groups GREEN.
  - Phase 3 layout-constant tests GREEN.
  - Phase 4 coordinate fix groups GREEN (cover, dedication, closing).
  - Phase 5 `beforeYouStart` group GREEN.
  - Phase 6 `closingQrSpread` group GREEN.
  - Full pre-existing suite unbroken.
  Commit: `test(all): verify full suite green — pareja-hijos-fidelity`

---

## Dependency Graph

```
T1.1 → T1.2 → T1.5    (content-class API — no deps)
T1.3 → T1.4 → T1.5    (content-class API — no deps)
T2.1 → T2.2 → T2.3 → T2.4 → T2.5 → T2.6   (drawFrame: sequential; T2.3+T2.4 same commit)
T3.1 → T3.2 → T3.5    (before_you_start_layout)
T3.3 → T3.4 → T3.5    (closing_qr_spread_layout; parallel with T3.1–T3.2)
T1.2, T3.2 → T5.1 → T5.2 → T5.3   (beforeYouStart needs photoPaths + layout consts)
T1.4, T2.2, T3.4 → T6.1 → T6.2 → T6.3  (closingQrSpread needs bottomTextOverride + drawFrame + layout consts)
T4.1 → T4.2 → T4.7    (cover fix; independent of T5/T6)
T4.3 → T4.4 → T4.7    (dedication fix; parallel with cover)
T4.5 → T4.6 → T4.7    (closing fix; parallel with cover/dedication)
T7.1, T7.2 → T8.1 → T8.2   (cleanup after all phases)
```

Phases 1 and 2 are independent and can proceed in parallel. Phase 3 constants are independent and can proceed after Phase 2. Phases 4, 5, and 6 may proceed in parallel once their Phase 1/3 dependencies land, but all three must be GREEN before Phase 7.

---

## Requirement Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| R1 — Cover eyebrow `"DOTBOOK DE {PROTAGONISTA}"` | T4.1, T4.2 |
| R2 — Cover geometry (x=41.5, width=120, eyebrow y=110.249) | T4.1, T4.2 |
| R3 — Dedication geometry (x=50.53, body width=120, relative y) | T4.3, T4.4 |
| R4 — Closing geometry (photo y=71.534, title/subtitle x=44, sub width=115) | T4.5, T4.6 |
| R5 — `beforeYouStart` spread (10 photo slots, per-category copy) | T5.1, T5.2, T5.3 |
| R6 — `closingQrSpread` left page (5 elements; right chrome-only) | T6.1, T6.2, T6.3 |
| R7 — `AlbumBeforeYouStartContent.photoPaths` required; length 10 | T1.1, T1.2, T1.5 |
| R8 — `AlbumQrSpreadContent.bottomTextOverride` optional String? | T1.3, T1.4, T1.5 |
| R9 — Two new layout-constant files | T3.1, T3.2, T3.3, T3.4, T3.5 |
| R10 — Tests updated + new; analyze + test clean | T2.1, T2.5, T5.1, T6.1, T8.1, T8.2 |
| Design Decision 1 — `DotsOvalQrElement.drawFrame` | T2.1–T2.6 |

---

## Risks

| Risk | Tasks | Mitigation |
|------|-------|------------|
| `AlbumBeforeYouStartContent.photoPaths` required breaks all existing instantiations | T1.2 | Only test files construct it today; analyzer surfaces every break at T1.5. |
| `_buildOvalQrElement` drift between `album_spread_page.dart` and `isolate_synthesis.dart` | T2.3, T2.4 | Both files updated in the same commit; T2.5 tests the rendered output. |
| `dedication` relative-y math requires knowing title/body element heights | T4.4 | Design pins `bodyY = titleY + titleHeight + 6.5 mm`; use font-metric constant or empirical pt value matching the explore table. Add a constant comment with derivation. |
| Q1/Q2 cluster first-NÚMERO absolute y=89.5 mm is a design estimate, not PDF-confirmed | T5.2 | Design explicitly documents `numero_y = photo_bottom_y + 7.5 mm = 89.5 mm` as the working default. Constant is named and commented for Task 5–7 revision. |
| `closingQrSpread` task comment says "Task 5" in the current stub | T6.2 | Overwriting the stub replaces the comment entirely; no residue. |
| size:exception — single large PR is harder to review | all | User direction; mitigated by per-phase commit discipline. |
