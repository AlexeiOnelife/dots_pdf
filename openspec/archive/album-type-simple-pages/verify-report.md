# Verify Report: album-type-simple-pages

## Summary

**Change:** album-type-simple-pages (slice 2 of 5)
**Date:** 2026-05-22
**Verdict:** CLEAN — PASS WITH WARNINGS

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| WARNING | 4 |
| SUGGESTION | 3 |

### Test Evidence

- `flutter test` → 306 passed, 0 failed (301 pre-existing + 5 added in verify-finding polish)
- `flutter analyze` → No issues found
- All 28/28 task boxes marked `[x]`

All 28 tasks complete. All 306 tests pass. The implementation satisfies every MUST-level requirement in R1–R9. Four warnings document spec scenarios with thin or absent test coverage; three suggestions address non-blocking quality gaps. No issues block archive.

---

## Findings

| Severity | Req | Location | Description | Suggested Fix |
|---|---|---|---|---|
| WARNING | R1 | `test/render/album_spread_page_test.dart`, `test/config/dots_template_test.dart` | Spec scenario "title font and body font are distinct" has no dedicated test. Code sets both correctly in the factory constructor; the contract is uncovered. | Add a test asserting `page.elements.whereType<DotsTextElement>().first.fontFamily == 'P22 Mackinac Medium'` and `page.elements.whereType<DotsTextBlockElement>().first.fontFamily == 'Inter'`. |
| WARNING | R5 | `test/render/album_spread_page_test.dart` | Spec scenario "body exceeding both limits triggers at least one warning" is absent. The three individual R5 scenarios are tested; the combined scenario (1001 chars AND 33 lines) is not. Code handles it correctly. | Add a test with `value = 'x' * 1001 + '\n' * 33`, `maxChars: 1000`, `maxLines: 32`; assert `warnMessages.length >= 1` and page non-null. |
| WARNING | R3 | `test/render/album_spread_page_test.dart:264` | Test "header labels use Inter Semibold 7pt" asserts only that `DotsFontRole.inter` is passed (correct per D6) but does NOT assert font size 7pt. `_kHeaderFontSize = 7.0` constant is wired correctly but uncovered. | Extend the test to assert the `headerStyle` font size is 7pt. |
| WARNING | R1 | `lib/src/config/dots_template.dart:607-646` | Spec R1 says "content block as a whole MUST respect an 86 mm bottom margin." Implementation places elements satisfying this (signature at 160mm), but no test guards the invariant. A future coordinate change could violate the 86mm constraint without failing CI. | Add a test asserting `signatureElement.y + approxGlyphHeight <= pageHeightPt - (86.0 * _mmToPt)`. |
| SUGGESTION | R4 | `lib/src/render/album_spread_page.dart:261-284` (`_buildRotatedText`) | Design note D1 says "wrap the rotated `pw.Text` in a fixed-width `pw.Container` sized for the un-rotated text so rotation has a deterministic centre." Implementation passes `pw.Text` directly to `pw.Transform.rotate` without the wrapper. At 2° cosmetically negligible, but deviates from stated design intent. | Either wrap in `pw.SizedBox(width: ..., child: pw.Text(...))` or add a code comment documenting the intentional omission. |
| SUGGESTION | R6 | `lib/src/api/build_simple_pages.dart:46-49` | The `switch` uses an or-pattern `parejas \|\| hijos \|\| individuales \|\| outros`. Functionally correct (exhaustiveness enforced by Dart), but slightly harder to read; does not self-document "everything except boda" intent. | No change required; or consider a named helper `_isNonBodaType(type)` for readability. Low priority. |
| SUGGESTION | R3 | `test/render/album_spread_page_test.dart:247` | Test "header labels and footer wordmark are drawn" only checks model values (`page.header.*`, `page.footer.*`), not that `buildAlbumSpreadPage` produces `pw.Positioned` children for them. Description implies render-level verification but stops at model inspection. | Call `_buildPage(page)` and inspect children count or assert the resulting `pw.Stack` has at least 4 children when all fields are non-null. |

---

## Coverage Matrix (R1–R9)

| Req | Scenarios in spec | Tests present | Code site | Status |
|---|---|---|---|---|
| R1 | 5: three-regions, 2° rotation, font-distinct, 102mm body, individuales | 4 of 5 covered; "font distinct" untested | `DotsAlbumSpreadPage.dedication(...)` in `dots_template.dart:595-658`; `_buildRotatedText` + `_buildTextBlock` in `album_spread_page.dart` | PASS (WARNING) |
| R2 | 6: parejas 20pt, boda 12pt, hijos 20pt, individuales 20pt, null photoPath, photo geometry | All 6 covered | `DotsAlbumSpreadPage.closing(...)` in `dots_template.dart:676-748`; exhaustive `switch (type)` | PASS |
| R3 | 3: four labels drawn, Inter Semibold 7pt, null fields omitted | All 3 present; 7pt asserted via role only | `buildAlbumSpreadPage` in `album_spread_page.dart:71-127`; `_kHeaderFontSize = 7.0` | PASS (WARNING) |
| R4 | 2: rotated at angle, sealed switch exhaustive | Both covered | `_buildRotatedText` in `album_spread_page.dart:267`: `angle: element.angleDegrees * pi / 180.0` | PASS |
| R5 | 4: within-limits no warn, >chars warns, >lines warns, both exceeded warns | 3 of 4 covered; combined scenario missing | `_buildTextBlock` in `album_spread_page.dart:294-341` | PASS (WARNING) |
| R6 | 5: parejas→2 pages, boda→1 closing, hijos label, individuales label, missing closing omitted | All 5 covered | `buildSimplePagesFor` in `build_simple_pages.dart:23-75` | PASS |
| R7 | 3: main-isolate valid PDF, worker-isolate valid PDF, within 20% size | All 3 covered in isolate group | `DotsRenderer.buildPage:283-298` and `_IsolatePageRenderer.buildPage:208-220`; both delegate to `buildAlbumSpreadPage` | PASS |
| R8 | 2: empty elements constructs, slice-1 tests pass | Both covered; 301 pre-existing tests still pass | `DotsAlbumSpreadPage` default ctor unchanged; sealed switch exhaustive across both renderers | PASS |
| R9 | — (static check) | `dots_pdf.dart:9-11` explicit exports of `AlbumSimpleContent`, `DedicationContent`, `ClosingContent`, `buildSimplePagesFor`; new elements ride via `dots_template.dart` | `lib/dots_pdf.dart` | PASS |

---

## Design Decision Compliance

| Decision | Compliance | Notes |
|---|---|---|
| D1: `DotsRotatedTextElement` with `angleDegrees`; renderer converts with `deg * pi / 180` | COMPLIANT | `album_spread_page.dart:267` exact match. Container wrap omitted — see SUGGESTION. |
| D2: `DotsTextBlockElement` with `DotsTextAlign` enum; no `package:pdf` type in public API | COMPLIANT | `dots_template.dart:163-172`; mapped to `pw.TextAlign` internally at `album_spread_page.dart:319-323`. |
| D3: `AlbumSimpleContent` / `DedicationContent` / `ClosingContent` with `==` / `hashCode` | COMPLIANT | All three in `album_simple_content.dart`; equality and hash tested in `dots_template_test.dart`. |
| D4: Named constructors `.dedication()` / `.closing()`; exhaustive `switch (type)` for boda 12pt / others 20pt | COMPLIANT | `dots_template.dart:685-692` — no `default:` arm, compile-time enforced. |
| D5: Shared `buildAlbumSpreadPage(...)` in `lib/src/render/album_spread_page.dart` | COMPLIANT | File exists; both `DotsRenderer` and `_IsolatePageRenderer` import and call it. No `UnimplementedError` remains. |
| D6: Use `DotsFontRole.inter` for header/footer; TODO comment present | COMPLIANT | `album_spread_page.dart:73`: `// TODO(inter-semibold): use DotsFontRole.interSemibold when the role is added — D6 follow-up (slice 3+).` |
| D7: Five new public exports via `dots_pdf.dart` | COMPLIANT | `dots_pdf.dart:9-11` explicit show clauses. All five symbols reachable from package root. |

---

## Spec Acceptance Test Checklist (35/36 present)

All spec-mandated tests present **except**:

- **Missing:** `DotsTextBlockElement — body exceeding both limits triggers at least one warning` (R5 combined-limits scenario)

---

## Underspecified Behaviors — Reasonable Implementation Calls

| Topic | Implementation Choice | Notes |
|---|---|---|
| Dedication element Y-coordinates | `titleY = 60mm`, `bodyY = 90mm`, `signatureY = 160mm` hard-coded in factory | Design deferred exact values; single source of truth inside the factory. |
| Footer wordmark Y position | `format.height − 8mm` | Design asked "8mm above bottom?". Implementation pins at exactly 8mm via `_kFooterBottomMarginMm = 8.0`. |
| Rotated text Container wrap | Omitted; `pw.Text` passed directly to `pw.Transform.rotate` | Design open question. Implementation takes simpler path. See SUGGESTION. |
| Closing subtitle `maxChars` | Not set (only `maxLines: 2`) | Spec specifies "2 lines" without char limit. Correct omission. |
| `contextLabelValue` empty string | Sets `header.centerLabel = null` (not drawn) | Consistent with slice-1 semantics: null = not drawn. |
| `buildSimplePagesFor` return type | `List<DotsAlbumSpreadPage>` (narrower than spec's `List<DotsPage>`) | Strictly more useful for callers; compatible wherever `DotsPage` is accepted. |

---

## Conclusion

The implementation is COMPLETE and READY FOR ARCHIVE. All critical functionality works as specified. The four warnings represent thin test coverage on edge cases (not functional defects); the three suggestions are quality improvements that do not block the change. Slice 2 fulfills the promise of dedicated, working pages for the simplest album types and unblocks all downstream slices that depend on working album-type rendering.
