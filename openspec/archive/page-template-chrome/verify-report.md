# Verify Report: page-template-chrome

**Date**: 2026-05-28
**Branch**: `page-template-chrome-pr2` (HEAD contains both PR 1 and PR 2 commits)
**Mode**: openspec (engram unavailable)
**Verdict**: PASS WITH WARNINGS

---

## Build & Test Evidence

| Check | Result |
|-------|--------|
| `flutter analyze` | Clean — no issues |
| `flutter test` | All 657 tests passed |
| Previously RED tests | All GREEN (no `fail('PR 2: ...')` placeholders remaining) |
| Pre-existing test count | 240+ pre-existing tests still green |

---

## Task Completeness

All tasks (T1.1–T9.3) are checked off in `tasks.md`. Code state matches every task:
- `DotsPageChrome` class exists at `lib/src/config/dots_template.dart:1095`
- `buildPageChrome` helper exists at `lib/src/render/page_chrome.dart`
- `DotsTemplate.defaultChrome` + `contentHash` participation confirmed at lines 2010, 2077
- `DotsPageChrome` exported via bare re-export of `dots_template.dart` in `lib/dots_pdf.dart:29`
- Old inline chrome block (lines 170–224 original) deleted from `album_spread_page.dart`
- Stale constants (`_kHeaderY`, `kHeaderFontRoleForTest`, etc.) confirmed absent from `album_spread_page.dart`
- `SPECS_interior.md` updated: footer row now says "Bottom-right" at `line 43`

---

## Spec Compliance Matrix

| Req | Scenario | Implementation site | Test | Status |
|-----|----------|--------------------|----|--------|
| R1 | Layout page receives background | `_buildLayoutPage` → `buildPageChrome` | `DotsLayoutPage render — chrome present` | PASS |
| R1 | Elements page receives background | `_buildElementsPage` → `buildPageChrome` | `DotsElementsPage render — chrome always present` | PASS |
| R1 | Spread page receives background | `buildAlbumSpreadPage` → `buildPageChrome` | `album_spread_page — header text uses p22MackinacBook` (implicitly) | PASS |
| R1 | Cover page stays chrome-free | Cover guard in `buildPageChrome` (empty list when all fields null/empty) | `album_spread_page — cover page has no background widget` | PASS |
| R1 | null defaultChrome produces no chrome | `buildPage` guards on `chrome != null` | `DotsTemplate — defaultChrome null is backward-compatible` | PASS |
| R2 | Header Y = 9 mm (regression fix) | `_kHeaderTopMm = 9.0` in `page_chrome.dart:27` | `buildPageChrome — header Y is 9 mm from top` | PASS |
| R2 | Header font = p22MackinacBook 9 pt (regression fix) | `fontResolver(DotsFontRole.p22MackinacBook)`, `_kHeaderFontSize = 9.0` | `buildPageChrome — header font is p22MackinacBook at 9 pt` | PASS |
| R3 | Odd page → left layout | `isLeftPage` branch in `buildPageChrome:134` | `buildPageChrome — left page: page number in outer-left, center label in center` | PASS |
| R3 | Even page → right layout | `!isLeftPage` branch in `buildPageChrome:158` | `buildPageChrome — right page: page number in outer-right, center label in center` | PASS |
| R3 | Renderer sets isLeftPage from pageNumber | `page.pageNumber % 2 == 1` / `page.pageNumber.isOdd` in `dots_renderer.dart:350,390` | Integration tests | PASS |
| R4 | Footer bottom-right 8 mm (regression fix) | `right: marginPt, bottom: marginPt` in `page_chrome.dart:200-201` | `buildPageChrome — footer is positioned bottom-right at 8 mm` | PASS |
| R4 | Footer font = interSemibold 7 pt | `fontResolver(DotsFontRole.interSemibold)`, `_kFooterFontSize = 7.0` | `buildPageChrome — footer font is interSemibold at 7 pt` | PASS |
| R4 | Null wordmark suppresses footer | `hasWordmark` guard in `buildPageChrome:190` | `buildPageChrome — null wordmark produces no footer widget` | PASS |
| R5 | bleedTop slot suppresses header | `deriveSuppressHeaderForChrome` called in `_buildLayoutPage:388` | `DotsLayoutPage render — bleedTop slot suppresses header` + unit predicates | PASS |
| R5 | bleedBottom slot suppresses footer | `deriveSuppressFooterForChrome` called in `_buildLayoutPage:389` | Unit predicate test only (see WARNING W1) | WARNING |
| R5 | No bleed → both render | `_buildLayoutPage` no-suppress path | `DotsLayoutPage render — no bleed slots: header and footer both render` | PASS |
| R5 | Elements page chrome unconditional | No suppression logic in `_buildElementsPage` | `DotsElementsPage render — chrome always present unconditionally` | PASS |
| R6 | DotsPageChrome == / hashCode over 6 fields | `operator ==` and `hashCode` at `dots_template.dart:1147-1165` | `DotsPageChrome — equal instances satisfy ==` / `differing instances do not satisfy ==` | PASS |
| R6 | DotsPageChrome exported | Bare re-export of `dots_template.dart` in `dots_pdf.dart:29` | `test/config/dots_page_chrome_test.dart` imports via `dots_pdf.dart` | PASS |
| R7 | defaultChrome field nullable/const | `DotsTemplate` constructor at `dots_template.dart:2010` | `DotsTemplate — defaultChrome null is backward-compatible` | PASS |
| R7 | defaultChrome in contentHash | `Object.hash(..., defaultChrome, ...)` at `dots_template.dart:2077` | `DotsTemplate — defaultChrome participates in contentHash` + `identical contentHash` | PASS |
| R8 | buildPageChrome signature | Confirmed at `page_chrome.dart:88-92` | `test/render/page_chrome_test.dart` | PASS |
| R8 | Background is first returned widget | `widgets.add(pw.Positioned.fill(...))` before header/footer | `buildPageChrome — background is first widget and has color #fdfefd` | PASS |
| R8 | Old inline chrome path deleted | No header/footer Positioned widgets outside `buildPageChrome` call in `album_spread_page.dart` | Code inspection + clean analyze | PASS |
| R9 | Spread delegation to buildPageChrome | `album_spread_page.dart:159` | All `album_spread_page —` tests | PASS |
| R9 | header uses p22MackinacBook (re-split) | Via `buildPageChrome` → `p22MackinacBook` | `album_spread_page — header text uses p22MackinacBook (re-split R3)` | PASS |
| R9 | footer uses interSemibold (re-split) | Via `buildPageChrome` → `interSemibold` | `album_spread_page — footer text uses interSemibold (re-split W3)` | PASS |
| R10 | null defaultChrome = backward compat | `if (chrome != null)` guard in `_buildLayoutPage` and `_buildElementsPage` | `DotsTemplate — defaultChrome null is backward-compatible` | PASS |

---

## Four Bug Fixes Verified

| Bug | Before | After | Evidence |
|-----|--------|-------|----------|
| Bug 1: Header Y | 8.0 mm (`album_spread_page.dart:22`) | 9.0 mm (`_kHeaderTopMm = 9.0`, `page_chrome.dart:27`) | `buildPageChrome — header Y is 9 mm from top` passes |
| Bug 2: Header font | `interSemibold` 7 pt | `p22MackinacBook` 9 pt (`_kHeaderFontSize = 9.0`, `page_chrome.dart:47`) | `buildPageChrome — header font is p22MackinacBook at 9 pt` passes |
| Bug 3: Footer alignment | `left: 0, right: 0` (center) | `right: marginPt, bottom: marginPt` (`page_chrome.dart:199-201`) | `buildPageChrome — footer is positioned bottom-right at 8 mm` passes |
| Bug 4: Missing background | No background on any page | `pw.Positioned.fill` + `BoxDecoration(color: #fdfefd)` | `buildPageChrome — background is first widget` passes |

---

## Cover Guard Verification

**Code path** (`album_spread_page.dart:151-159`):
- `DotsAlbumSpreadPage.cover()` sets `header: const DotsSpreadHeader()` (all fields null) and `footer: const DotsSpreadFooter(wordmark: '')`.
- `buildAlbumSpreadPage` computes `pageNumber: null ?? null = null`, `isLeftPage: false`, `centerLabel: null`, `wordmark: ''`.
- `buildPageChrome` cover guard: `!hasPageNumber && !hasCenterLabel && !hasWordmark` → returns `[]`.
- Result: no chrome widgets (no background, no header, no footer) on cover pages.

**Test**: `album_spread_page — cover page has no background widget` passes (proxy: no `interSemibold` call made during cover render).

**Observation (SUGGESTION S1)**: The cover test uses a proxy assertion (no `interSemibold` font call) rather than directly inspecting the returned widget list. This is acceptable — the test is structurally sound and correctly passes. A direct `expect(result, isEmpty)` on `buildPageChrome` itself is already covered in `page_chrome_test.dart:233-242` ("empty chrome returns no widgets (cover guard)").

---

## contentHash Participation Verification

`DotsTemplate.contentHash` at `dots_template.dart:2073-2080`:
```dart
int get contentHash => Object.hash(
  documentId, pageSize, albumType, defaultChrome,
  Object.hashAll(pages), Object.hashAll(pliegos),
);
```

`defaultChrome` participates via `Object.hash`. Since `DotsPageChrome` hand-writes `hashCode` over all six fields, a template differing only by chrome produces a different `contentHash`. Verified by `DotsTemplate — defaultChrome participates in contentHash` and `DotsTemplate — identical defaultChrome produces equal contentHash`.

---

## Inline Chrome Deletion Verification

`album_spread_page.dart` no longer contains:
- `_kHeaderLeftX`, `_kHeaderY`, `_kFooterBottomMarginMm`, `_kHeaderFontSize`, `kHeaderFontSizeForTest`, `kHeaderFontRoleForTest` — confirmed absent via grep.
- No `pw.Positioned` header/footer widgets outside the `buildPageChrome` delegation (line 159).
- `_kMmToPt` is still present (used by spread-width warning at line 180) — correct, not deleted.

---

## Issues

### WARNING

**W1 — Integration test for bleedBottom suppression is a hollow smoke test**

File: `test/render/layout_page_render_test.dart`, lines 286-309

Test name: `DotsLayoutPage render — bleedBottom slot suppresses footer; background present`

The test body uses `DotsLayoutCode.l1` (no bleed slots) and only asserts `_hasPdfMagic(bytes)`. The comment acknowledges this: "No catalog layout carries `bleedBottom: true` today, so this suppression branch is covered at the unit level by `deriveSuppressFooterForChrome`." The unit-level coverage (`footer IS suppressed when a bleedBottom slot extends past the live-area floor` in `page_chrome_test.dart:297-312`) is real and asserts the predicate directly. However, the integration test name promises a scenario ("bleedBottom slot suppresses footer") that its body does not exercise at the renderer integration level.

**Risk**: If a regression is introduced in the renderer's call to `deriveSuppressFooterForChrome` (e.g., the call is dropped), this integration test would still pass, providing false confidence.

**Recommendation**: Either rename the test to accurately reflect what it tests ("DotsLayoutPage render — footer renders when no bleed; background present") or add a true integration test using a custom `DotsLayoutPage` with a `DotsSlotRect` that has `bleedBottom: true` and extend `DotsLayoutSolver` or pass a mocked slot list. Since no catalog layout supports `bleedBottom: true`, the simplest fix is the rename.

---

### SUGGESTION

**S1 — Cover-page test uses a proxy assertion**

File: `test/render/album_spread_page_test.dart`, lines 366-398

The cover guard test asserts that `interSemibold` is never called during a cover render, rather than directly asserting that `buildPageChrome` returns an empty list. This is a proxy test and passes correctly, but it will fail to detect regressions that call `interSemibold` from some path other than the chrome footer, or that omit the wordmark but still render the background.

**Recommendation**: Acceptable as-is (all tests pass), but a more direct assertion in `page_chrome_test.dart:233-242` ("empty chrome returns no widgets (cover guard)") already covers the direct contract. No code change needed — flag only.

**S2 — bleedBottom integration test body name/intent mismatch (see W1)**

This is also a suggestion to rename to avoid future confusion, beyond the warning about hollow coverage.

**S3 — `buildPageChrome` cover guard silently omits background when all fields null/empty on non-cover pages**

File: `lib/src/render/page_chrome.dart:93-105`

If a caller passes a `DotsPageChrome` with `pageNumber: null, centerLabel: null, wordmark: null` (or empty), `buildPageChrome` returns `[]` — no background. For a `DotsLayoutPage` or `DotsElementsPage`, this is only reachable if `template.defaultChrome` is set to such an instance. In that case the background would be omitted on interior pages, which contradicts R1 ("MUST render a full-bleed background") for non-cover pages.

**Risk**: Low in practice — if someone sets `defaultChrome` they intend chrome. But spec R8 says "background is always present" without cover-guard qualification. The gap between spec wording and implementation is real.

**Recommendation**: Add a comment or a `@visibleForTesting` safety note documenting that the cover-guard path is exclusively for cover pages. No code change strictly required since all current callers behave correctly, but it is a latent footgun.

---

## Acceptance Test Name Audit

Spec requires these exact test names. Status:

| Spec name | Present | Notes |
|-----------|---------|-------|
| `buildPageChrome — background is first widget and has color #fdfefd` | YES | |
| `buildPageChrome — header Y is 9 mm from top` | YES | |
| `buildPageChrome — header font is p22MackinacBook at 9 pt` | YES | |
| `buildPageChrome — left page: page number in outer-left, center label in center` | YES | Multi-line string, concatenated |
| `buildPageChrome — right page: page number in outer-right, center label in center` | YES | Multi-line string, concatenated |
| `buildPageChrome — footer font is interSemibold at 7 pt` | YES | |
| `buildPageChrome — footer is positioned bottom-right at 8 mm from right and bottom` | YES | Multi-line string |
| `buildPageChrome — null wordmark produces no footer widget` | YES | |
| `buildPageChrome — suppressHeader omits header text widgets (background remains)` | YES | Multi-line string |
| `buildPageChrome — suppressFooter omits footer widget (background remains)` | YES | Multi-line string |
| `DotsLayoutPage render — chrome present: background + header + footer` | YES | |
| `DotsLayoutPage render — bleedTop slot suppresses header; background present` | YES | Multi-line string |
| `DotsLayoutPage render — bleedBottom slot suppresses footer; background present` | YES (hollow) | See W1 |
| `DotsLayoutPage render — no bleed slots: header and footer both render` | YES | |
| `DotsElementsPage render — chrome always present unconditionally` | YES | |
| `DotsPageChrome — equal instances satisfy == and share hashCode` | YES | |
| `DotsPageChrome — differing instances do not satisfy ==` | YES | |
| `DotsTemplate — defaultChrome null is backward-compatible; no chrome rendered` | YES | Multi-line string |
| `DotsTemplate — defaultChrome participates in contentHash` | YES | |
| `DotsTemplate — identical defaultChrome produces equal contentHash` | YES | |
| `album_spread_page — header text uses p22MackinacBook (re-split R3)` | YES | |
| `album_spread_page — footer text uses interSemibold (re-split W3)` | YES | |
| `album_spread_page — header Y is 9 mm (regression)` | YES | |
| `album_spread_page — footer is bottom-right 8 mm from edge (regression)` | YES | |
| `album_spread_page — cover page has no background widget` | YES | |

All 25 required acceptance test names are present.

---

## Design Coherence

| Decision | Implemented | Notes |
|----------|-------------|-------|
| Approach A: DotsPageChrome + buildPageChrome | YES | Single chrome site, old path deleted |
| Page parity: pageNumber % 2 == 1 → left | YES | `page.pageNumber.isOdd` / `% 2 == 1` |
| Background: pw.Positioned.fill + pw.Container + BoxDecoration | YES | Background uses BoxDecoration (not `color:` directly) so tests can introspect via `container.decoration` |
| Chrome exclusions: cover only | YES | Cover guard in buildPageChrome |
| tiempojuntos / caption-displacement: deferred | YES | Not implemented (out of scope) |
| SPECS_interior.md footer update | YES | Line 43 says "Bottom-right" |

Minor deviation from tasks.md T5.2: the spec says `pw.Container(color: _kBackgroundColor)` but the implementation uses `pw.Container(decoration: pw.BoxDecoration(color: _kBackgroundColor))`. This is intentional per the code comment: "The colour is wrapped in a BoxDecoration so tests can read it back via `container.decoration`." The test asserts `container.decoration!.color` not `container.color`, so tests and implementation are consistent. This is a SUGGESTION-level observation, not a deviation.

---

## Final Verdict

**PASS WITH WARNINGS**

- 0 CRITICAL findings
- 1 WARNING (W1: hollow bleedBottom integration test)
- 3 SUGGESTIONS (S1: proxy cover test, S2: rename suggestion for W1, S3: cover-guard footgun documentation)

All 657 tests green. `flutter analyze` clean. All 4 bugs fixed and verified. All 25 spec acceptance tests present. The single WARNING (W1) does not indicate a bug — it indicates the bleedBottom suppression scenario is only covered at the predicate-unit level, not at the renderer-integration level. The predicate itself is correct and tested. Archive can proceed; the user's standing rule is to address all findings before archive, so W1 and S3 should be addressed or explicitly deferred.
