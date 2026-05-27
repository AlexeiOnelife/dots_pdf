# Tasks: page-template-chrome

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~600–700 (production ~280, tests ~320) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | 2-PR feature-branch-chain |
| Delivery strategy | ask-on-risk (resolved: feature-branch-chain) |
| Chain strategy | feature-branch-chain |

Decision needed before apply: No (already decided — 2-PR feature-branch-chain)

### Work Units

| Unit | Goal | PR | Notes |
|------|------|----|-------|
| 1 | `DotsPageChrome` value object + `defaultChrome` + exports + full RED test suite | PR 1 | Ships on feature branch with all tests intentionally failing for unimplemented helpers |
| 2 | `buildPageChrome` helper + renderer wiring + spread delegation + doc fix | PR 2 | Turns PR 1 tests GREEN; targets PR 1 branch, then PR 1 branch merges to main |

---

## PR 1 — Model, Scaffolding, and RED Tests

**Branch**: `page-template-chrome` (feature branch; targets main but does NOT merge until PR 2 is green)
**Goal**: Ship the `DotsPageChrome` value object, the `DotsTemplate.defaultChrome` field with `contentHash` participation, public exports, and the COMPLETE test suite authored as RED placeholders where `buildPageChrome` or renderer wiring does not exist yet.
**Verification**: `flutter analyze` clean (all dartdoc present). `flutter test` compiles; pre-existing 240+ tests GREEN. New chrome-unit tests and renderer integration tests are intentionally RED (`fail('PR 2: ...')`) — isolated to the feature branch.
**Rollback**: `git revert` the PR 1 commit(s); `main` is unaffected throughout.
**Commit shape**: `feat(config): add DotsPageChrome value object and DotsTemplate.defaultChrome`

---

### Phase 1 — Test Scaffolding (write all tests RED first)

- [x] **T1.1** Create `test/render/page_chrome_test.dart` — unit tests for `buildPageChrome` covering every spec scenario. Write a `fontResolver` spy that records `DotsFontRole` calls. Each test calls `buildPageChrome(chrome, format, fontResolver)` and inspects the returned `List<pw.Widget>`. Where `buildPageChrome` does not yet exist, guard with `fail('PR 2: buildPageChrome not implemented')`. Tests to include (one test per name from the acceptance list):
  - `buildPageChrome — background is first widget and has color #fdfefd` (R1, R8)
  - `buildPageChrome — header Y is 9 mm from top` (R2)
  - `buildPageChrome — header font is p22MackinacBook at 9 pt` (R2)
  - `buildPageChrome — left page: page number in outer-left, center label in center` (R3)
  - `buildPageChrome — right page: page number in outer-right, center label in center` (R3)
  - `buildPageChrome — footer font is interSemibold at 7 pt` (R4)
  - `buildPageChrome — footer is positioned bottom-right at 8 mm from right and bottom` (R4)
  - `buildPageChrome — null wordmark produces no footer widget` (R4)
  - `buildPageChrome — suppressHeader omits header text widgets (background remains)` (R5)
  - `buildPageChrome — suppressFooter omits footer widget (background remains)` (R5)

- [x] **T1.2** Add chrome-presence group to `test/render/layout_page_render_test.dart` — integration tests for renderer wiring. Where `_buildLayoutPage` does not yet inject chrome, guard with `fail('PR 2: chrome wiring not yet implemented')`. Tests to include:
  - `DotsLayoutPage render — chrome present: background + header + footer` (R1, R2, R8)
  - `DotsLayoutPage render — bleedTop slot suppresses header; background present` (R5)
  - `DotsLayoutPage render — bleedBottom slot suppresses footer; background present` (R5)
  - `DotsLayoutPage render — no bleed slots: header and footer both render` (R5)
  - `DotsElementsPage render — chrome always present unconditionally` (R1, R5)
  - `DotsTemplate — defaultChrome null is backward-compatible; no chrome rendered` (R10)

- [x] **T1.3** Add `DotsPageChrome` equality/hash group to `test/render/page_chrome_test.dart` (or a new `test/config/dots_page_chrome_test.dart` if preferred) — these tests are GREEN immediately once T2.1 ships the type:
  - `DotsPageChrome — equal instances satisfy == and share hashCode` (R6)
  - `DotsPageChrome — differing instances do not satisfy ==` (R6)

- [x] **T1.4** Add `contentHash` group to `test/config/dots_template_test.dart` — GREEN once T2.2 ships the field:
  - `DotsTemplate — defaultChrome participates in contentHash` (R7)
  - `DotsTemplate — identical defaultChrome produces equal contentHash` (R7)

- [x] **T1.5** Modify `test/render/album_spread_page_test.dart` — re-split the R3/W3 assertions. The existing test at line 265 (`AlbumSpreadPage — header labels use Inter Semibold 7pt`) currently asserts `everyElement(equals(DotsFontRole.interSemibold))` over all resolved roles; this is now FALSE by design. Split into two separate tests:
  - `album_spread_page — header text uses p22MackinacBook (re-split R3)` — asserts header role is `p22MackinacBook`; guard with `fail('PR 2: font re-split not yet wired')` (R9)
  - `album_spread_page — footer text uses interSemibold (re-split W3)` — asserts footer role is `interSemibold`; guard with `fail('PR 2: font re-split not yet wired')` (R9)
  - `album_spread_page — header Y is 9 mm (regression)` — asserts `top == 9 * mmToPt`; guard with `fail('PR 2: regression not yet fixed')` (R2, R9)
  - `album_spread_page — footer is bottom-right 8 mm from edge (regression)` — asserts `right == 8 * mmToPt` and `bottom == 8 * mmToPt`; guard with `fail('PR 2: regression not yet fixed')` (R4, R9)
  - `album_spread_page — cover page has no background widget` — asserts cover produces no `#fdfefd` background; guard with `fail('PR 2: chrome delegation not yet wired')` (R1)
  - Leave the PASSING tests (`null header fields`, constructor equality, JSON parsing) unchanged.

---

### Phase 2 — DotsPageChrome Value Object (GREEN immediately)

- [x] **T2.1** Modify `lib/src/config/dots_template.dart` — add `@immutable class DotsPageChrome` following the existing `DotsSpreadHeader`/`DotsSpreadFooter` pattern. Six fields (all nullable or bool with default): `pageNumber`, `centerLabel`, `wordmark`, `isLeftPage` (default `true`), `suppressHeader` (default `false`), `suppressFooter` (default `false`). Hand-write `==` and `hashCode` over all six fields. Add full dartdoc on the class and every field (required by `public_member_api_docs` — build failure if omitted). Satisfies R6. Makes T1.3 GREEN.

- [x] **T2.2** Modify `lib/src/config/dots_template.dart` — add nullable `DotsPageChrome? defaultChrome` parameter to the `DotsTemplate` `const` constructor with default `null`; add the corresponding `final` field; add `defaultChrome` to `int get contentHash` at lines 1977–1983 (`Object.hash(documentId, pageSize, albumType, defaultChrome, Object.hashAll(pages), Object.hashAll(pliegos))`). No existing constructor call breaks — the parameter is optional. Add dartdoc on the field. Satisfies R7. Makes T1.4 GREEN.

---

### Phase 3 — Public Export

- [x] **T3.1** Modify `lib/dots_pdf.dart` — add `DotsPageChrome` to the `show` clause of the existing `export 'src/config/dots_template.dart'` line (or append a separate show if the export is a bare re-export). Confirm dartdoc is present on the symbol (already added in T2.1). Satisfies R6 export requirement. Run `flutter analyze` to confirm no `public_member_api_docs` violations.

---

### Phase 4 — PR 1 Verification

- [x] **T4.1** Run `flutter analyze` — must be clean. Confirm every new public symbol (`DotsPageChrome`, all its fields, `defaultChrome`) carries dartdoc. Zero new warnings beyond the pre-existing `prefer_initializing_formals` entries.

- [x] **T4.2** Run `flutter test` — pre-existing tests (240+) must be GREEN. New tests from T1.1–T1.5 must compile; RED tests must fail with the intentional `fail('PR 2: ...')` messages, not with unexpected errors. Confirm the `DotsPageChrome` equality tests (T1.3) and `contentHash` tests (T1.4) are GREEN.

**PR 1 ships here.** Commit and push the feature branch. Open PR targeting `main` (do NOT merge yet — PR 2 depends on this branch and will turn all RED tests GREEN before the feature branch itself merges to main).

---

## PR 2 — Implementation (turn all RED tests GREEN)

**Branch**: child branch off `page-template-chrome` (PR 2 targets `page-template-chrome`, not `main`; after PR 2 merges, PR 1 / the feature branch merges to main)
**Goal**: Implement `buildPageChrome`, wire it into `_buildLayoutPage` and `_buildElementsPage`, delegate `buildAlbumSpreadPage` to it, delete the old inline chrome block, and update `SPECS_interior.md`.
**Verification**: `flutter analyze` clean. `flutter test` fully GREEN including all previously-RED chrome tests.
**Rollback**: Revert PR 2 commits; PR 1 state (model + RED tests) is unaffected on the feature branch.
**Commit shape**: `feat(render): implement buildPageChrome helper and wire chrome into all interior pages`

---

### Phase 5 — buildPageChrome Helper

- [ ] **T5.1** Create `lib/src/render/page_chrome.dart` — define the module-private constant `_kMmToPt = 2.834645669` and the chrome geometry constants (annotated `@visibleForTesting` where re-exported for test inspection):
  - `_kBackgroundColor = PdfColor(0xFD / 255, 0xFE / 255, 0xFD / 255)` — `#fdfefd`
  - `_kHeaderTopMm = 9.0` — Y from top (fixes bug 1)
  - `_kHeaderBandHeightMm = 3.0`
  - `_kOuterMarginMm = 8.0` — outer X margin and footer bottom/right margin
  - `_kOuterColRatio = 0.27585` — left/right column widths as fraction of page width
  - `_kCenterColRatio = 0.4483`
  - `_kHeaderFontSize = 9.0` (fixes bug 2; header uses p22MackinacBook 9 pt)
  - `_kHeaderLineHeight = 1.2`
  - `_kFooterFontSize = 7.0` (footer stays interSemibold 7 pt)
  - `_kFooterLineHeight = 1.2`

- [ ] **T5.2** Implement `buildPageChrome` in `lib/src/render/page_chrome.dart` with signature:
  ```
  List<pw.Widget> buildPageChrome(
    DotsPageChrome chrome,
    PdfPageFormat format,
    pw.Font? Function(DotsFontRole) fontResolver,
  )
  ```
  Return order (background FIRST — required by R8):
  1. `pw.Positioned.fill(child: pw.Container(color: _kBackgroundColor))` — always present regardless of suppression flags (R1, R5).
  2. If `!chrome.suppressHeader` and header fields are non-null/non-empty: three `pw.Positioned` header widgets placed via `_kOuterColRatio`, `_kCenterColRatio`, `_kOuterMarginMm` with font `DotsFontRole.p22MackinacBook` at `_kHeaderFontSize`. Left page (`isLeftPage == true`): page number at outer-LEFT (`left: 8*mmToPt`), center label at `left: outerColWidth`. Right page: page number at outer-RIGHT (`right: 8*mmToPt`), center label at `left: outerColWidth`. (R2, R3)
  3. If `!chrome.suppressFooter` and `chrome.wordmark` is non-null and non-empty: one `pw.Positioned` footer widget with `right: 8*mmToPt`, `bottom: 8*mmToPt`, font `DotsFontRole.interSemibold` at `_kFooterFontSize`, `textAlign: pw.TextAlign.right`. (R4)
  Satisfies R8. Turns T1.1 GREEN.

- [ ] **T5.3** Add import of `page_chrome.dart` in `lib/src/render/dots_renderer.dart` — import the new helper so it is available for T6.1 and T6.2.

---

### Phase 6 — Renderer Wiring

- [ ] **T6.1** Modify `lib/src/render/dots_renderer.dart` — update `_buildLayoutPage` (currently lines 354–392):
  - Accept `DotsPageChrome? chrome` as a parameter (passed from `buildPage`).
  - After `solver.solve(...)` produces `slots`, derive suppression flags if `chrome != null`:
    ```
    suppressHeader = slots.any((s) => s.bleedTop && s.yMm < geometry.headerBandMm);
    suppressFooter = slots.any((s) => s.bleedBottom && s.yMm + s.heightMm > geometry.liveAreaBottomMm);
    ```
  - Derive `isLeftPage = (page.pageNumber ?? 0) % 2 == 1`.
  - Produce a derived chrome: `chrome.copyWith(isLeftPage: isLeftPage, suppressHeader: suppressHeader, suppressFooter: suppressFooter)` OR construct a new `DotsPageChrome` with those overrides (no `copyWith` method is required — constructing inline is fine and avoids adding `copyWith` to the public API).
  - Prepend `buildPageChrome(derivedChrome, format, fontFor)` to `children` BEFORE the slot loop, AFTER defining `children`.
  - When `chrome == null`, skip all chrome logic — backward-compatible path (R10).
  Satisfies R1, R5. Turns `DotsLayoutPage` render tests (T1.2) GREEN.

- [ ] **T6.2** Modify `lib/src/render/dots_renderer.dart` — update `_buildElementsPage` (currently lines 338–352):
  - Accept `DotsPageChrome? chrome` as a parameter.
  - Derive `isLeftPage = (page.pageNumber ?? 0) % 2 == 1` (use `DotsElementsPage.pageNumber` if the field exists; verify field name against actual model before writing).
  - Prepend `buildPageChrome(chrome.copyWith(isLeftPage: isLeftPage), format, fontFor)` (or inline construction) to `children` when `chrome != null`. No suppression derivation — elements pages render chrome unconditionally (R5).
  - When `chrome == null`, skip chrome. Satisfies R1, R5. Turns `DotsElementsPage render` test (T1.2) GREEN.

- [ ] **T6.3** Modify `lib/src/render/dots_renderer.dart` — update `buildPage` (lines 309–335) to read `template.defaultChrome` and pass it to both `_buildLayoutPage` and `_buildElementsPage`. The `DotsAlbumSpreadPage` branch already calls `buildAlbumSpreadPage` which will be updated in T7. Satisfies R7 flow. Enables T6.1 and T6.2.

---

### Phase 7 — Album-Spread Delegation and Cleanup

- [ ] **T7.1** Modify `lib/src/render/album_spread_page.dart` — delete the inline chrome block (lines 170–224 in the current file: header font setup, three `pw.Positioned` header children, footer child). Replace with:
  1. Build a `DotsPageChrome` from the spread page's header/footer:
     - `pageNumber`: `page.header.leftPageNumber ?? page.header.rightPageNumber`
     - `isLeftPage`: `page.header.leftPageNumber != null`
     - `centerLabel`: `page.header.centerLabel`
     - `wordmark`: `page.footer.wordmark` (empty string treated as null by `buildPageChrome`)
     - `suppressHeader`: `false` (spread pages never suppress)
     - `suppressFooter`: `false`
  2. Prepend `buildPageChrome(chrome, format, fontResolver)` to `children` at the top of `buildAlbumSpreadPage` BEFORE the elements loop (line 227 onwards), in the same position the old header block occupied.
  3. Import `page_chrome.dart` in this file.
  Satisfies R8 (single chrome site), R9. Turns the album_spread_page re-split tests (T1.5) GREEN.

- [ ] **T7.2** Modify `lib/src/render/album_spread_page.dart` — delete the now-stale constants: `_kHeaderLeftX`, `_kHeaderY`, `_kFooterBottomMarginMm`, `_kHeaderFontSize`, `kHeaderFontSizeForTest`, `kHeaderFontRoleForTest` (lines 18–38). Remove the `_kHeaderLineHeight` constant if it was used only by the deleted block. Do NOT delete `_kMmToPt` if it is used elsewhere in the file (verify before deletion — the footer Y computation at line 213 uses it; after T7.1 this computation moves to `page_chrome.dart`). Verify that the re-split tests in T1.5 no longer import `kHeaderFontRoleForTest`; update their imports to use the equivalent constant from `page_chrome.dart` if one is exported `@visibleForTesting`, or remove the constant-based assertion entirely in favour of spy-based role inspection. Satisfies R8 (old path deleted), R9 cleanup.

---

### Phase 8 — Documentation Fix

- [ ] **T8.1** Modify `docs/templates/SPECS_interior.md` — update the footer alignment description from "center" (or "bottom-center") to "bottom-right, 8 mm from the right edge and 8 mm from the bottom edge." This aligns the spec document with the ground-truth PDF and the `buildPageChrome` implementation. Satisfies R4 (footer spec correctness).

---

### Phase 9 — PR 2 Verification

- [ ] **T9.1** Run `flutter analyze` — must be clean. Confirm no orphaned imports in `album_spread_page.dart`. Confirm no `public_member_api_docs` violations on any new or modified exported symbol. Zero new warnings.

- [ ] **T9.2** Run `flutter test` — ALL tests GREEN, including every test written RED in PR 1 phases 1 and 5. Confirm test names match the acceptance list in the spec exactly (copy-paste comparison). Confirm the pre-existing 240+ tests still pass. Satisfies R10 (backward compatibility).

- [ ] **T9.3** Confirm cover page safety — verify manually (or via the existing cover test) that `DotsAlbumSpreadPage.cover()` pages still render without any `#fdfefd` background. The `buildAlbumSpreadPage` delegation in T7.1 will pass `wordmark: ''` and `pageNumber: null`; `buildPageChrome` will render ONLY the background widget. Confirm this is acceptable per the spec (R1 says cover MUST NOT receive a background from the chrome helper). If the `cover()` factory path must be excluded, add a guard in T7.1 before calling `buildPageChrome` (`if (!page.isCover)` or equivalent — verify the cover discriminator field name in `dots_template.dart`). Update this task accordingly before apply. Satisfies R1 (cover exclusion).

**PR 2 ships here.** Merge PR 2 into `page-template-chrome` feature branch. Then merge `page-template-chrome` into `main`. All tests are GREEN on main from this point.

---

## Dependency Graph

```
T1.1 → T4.1, T4.2 (analysis must be clean before verifying)
T1.2 → T4.2
T1.3 → [T2.1] → T3.1 → T4.1
T1.4 → [T2.2] → T4.2
T1.5 → T4.2

T5.1 → T5.2 → T6.1, T6.2, T7.1
T6.3 → T6.1, T6.2
T7.1 → T7.2 → T9.1, T9.2, T9.3
T8.1 (independent — can run any time in PR 2)

PR 1 must be open before PR 2 branch is cut.
PR 2 must be merged into feature branch before feature branch merges to main.
```

**Parallel work within each PR**: T1.1 through T1.5 are independent and can be written in any order. T2.1 and T2.2 are independent. T5.1 must precede T5.2; all others in Phase 6–7 can run after T5.2 ships.

---

## Requirement Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| R1 — Background on all interior pages | T1.1, T1.2, T5.2, T6.1, T6.2, T7.1, T9.3 |
| R2 — Header geometry and typography | T1.1, T5.1, T5.2 |
| R3 — Page parity and header position | T1.1, T5.2, T6.1, T6.2 |
| R4 — Footer geometry and typography | T1.1, T5.2, T8.1 |
| R5 — Photo-overlap suppression (layout) | T1.2, T6.1 |
| R6 — DotsPageChrome value object | T1.3, T2.1, T3.1 |
| R7 — DotsTemplate.defaultChrome + contentHash | T1.4, T2.2, T6.3 |
| R8 — buildPageChrome API surface | T1.1, T5.1, T5.2, T7.1, T7.2 |
| R9 — Album-spread delegation (re-split) | T1.5, T7.1, T7.2 |
| R10 — Backward compatibility | T1.2, T6.1, T6.2, T9.2 |
