# Tasks: album-type-simple-pages (slice 2 of 5)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 550–700 (prod + tests) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 = T1 + T2 (scaffolding + element types) → PR 2 = T3 + T4 + T5 (helper + builders + exports + verification) |
| Delivery strategy | ask-on-risk |
| Chain strategy | completed via feature-branch-chain strategy |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Failing tests + new element types + exhaustiveness stubs | PR 1 | Base: main; includes T1 + T2; no rendering logic yet |
| 2 | Shared helper + named constructors + builder + exports + green run | PR 2 | Base: PR 1 branch; includes T3 + T4 + T5; all tests go green |

---

## Phase T1 — Test scaffolding (RED — write failing tests first)

- [x] T1.1 Create `test/render/album_spread_page_test.dart` — write failing tests per spec acceptance list: dedication renders title + body + signature for parejas / hijos / individuales / outros (R1 scenarios); signature present via `DotsRotatedTextElement` at 2°; body constrained to 102 mm width.
- [x] T1.2 In `test/render/album_spread_page_test.dart` — write failing tests for closing-page rendering: title is 12 pt for boda; 20 pt for parejas, hijos, individuales, outros (R2 scenarios); null `photoPath` renders without error; photo slot is 66×86 mm.
- [x] T1.3 In `test/render/album_spread_page_test.dart` — write failing tests for header/footer: all four labels drawn; Inter Semibold 7 pt; null header fields omitted without error (R3 scenarios).
- [x] T1.4 In `test/render/album_spread_page_test.dart` — write failing tests for `DotsTextBlockElement` warn behavior: body ≤ limits → no warning; body > 1000 chars → one warning; body > 32 newline-lines → one warning; both exceeded → at least one warning (R5 scenarios).
- [x] T1.5 In `test/render/album_spread_page_test.dart` — write failing tests for isolate dispatch: `useIsolate=false` produces valid non-empty PDF; `useIsolate=true` produces valid non-empty PDF; both paths produce output within 20% size tolerance (R7 scenarios).
- [x] T1.6 Create `test/api/build_simple_pages_test.dart` — write failing tests: `buildSimplePagesFor(parejas, full)` → 2 pages in dedication→closing order; `(boda, full)` → 1 page closing only; `(hijos, full)` → 2 pages; `(individuales, full)` → 2 pages; `(outros, full)` → 2 pages; header.centerLabel tokens per type (R6 scenarios); dedication-only → 1 page; closing-only → 1 page; both null → empty list.
- [x] T1.7 In `test/config/dots_template_test.dart` — add failing tests: `DotsRotatedTextElement` equality + hashCode; `DotsTextBlockElement` equality + hashCode; `DotsAlbumSpreadPage.dedication(...)` smoke (non-null, elements not empty); `DotsAlbumSpreadPage.closing(...)` smoke; `DotsAlbumSpreadPage` with empty elements list constructs without error (R8 compat scenario).

---

## Phase T2 — Element types + enum + exhaustiveness stubs

- [x] T2.1 In `lib/src/config/dots_template.dart` — add `enum DotsTextAlign { left, center, right }` (R5 / D2). Must NOT import `package:pdf`.
- [x] T2.2 In `lib/src/config/dots_template.dart` — add sealed `DotsRotatedTextElement extends DotsElement` with fields `value`, `fontSize`, `angleDegrees`, `fontFamily?`, `colorHex?` plus `==` / `hashCode` (R4 / D1).
- [x] T2.3 In `lib/src/config/dots_template.dart` — add sealed `DotsTextBlockElement extends DotsElement` with fields `value`, `fontSize`, `width`, `fontFamily?`, `colorHex?`, `textAlign`, `lineHeight`, `maxChars?`, `maxLines?` plus `==` / `hashCode` (R5 / D2).
- [x] T2.4 In `lib/src/render/dots_renderer.dart` — extend `_buildElement` switch at line 349 with `case DotsRotatedTextElement():` and `case DotsTextBlockElement():`, both throwing `UnimplementedError('rendered by buildAlbumSpreadPage — wire in T3')`. Keeps compile-time exhaustiveness (R8, R4, R5).
- [x] T2.5 In `lib/src/render/isolate_synthesis.dart` — extend `_buildElement` switch at line 279 with the same two stub cases as T2.4 (R8, R7).
- [x] T2.6 Run `flutter analyze` — confirm 0 issues (sealed switches exhaustive; no `package:pdf` leak in public types).

---

## Phase T3 — Shared render helper (GREEN for rendering tests)

- [x] T3.1 Create `lib/src/render/album_spread_page.dart` — define `buildAlbumSpreadPage({required PdfPageFormat format, required DotsAlbumSpreadPage page, required pw.Font? Function(DotsFontRole) fontResolver, required Future<Uint8List> Function(String) bytesResolver, required DotsLogger logger, required void Function(String, Object) onPhotoFailure, required bool drawCropMarks})` (D5).
- [x] T3.2 In `album_spread_page.dart` — implement header/footer drawing: read `page.header` fields; draw non-null `leftPageNumber`, `centerLabel`, `rightPageNumber` at canonical top-left/top-center/top-right positions; draw non-null `footer.wordmark` at bottom-center. All via `DotsFontRole.inter` at 7 pt / 8.4 pt. Add `// TODO(inter-semibold): use DotsFontRole.interSemibold when the role is added — D6 follow-up` near the font resolution call (R3, D6).
- [x] T3.3 In `album_spread_page.dart` — implement element dispatch: iterate `page.elements`; handle `DotsTextElement` (positioned text), `DotsImageElement` (positioned image with `onPhotoFailure` on decode error), `DotsRotatedTextElement` (`pw.Transform.rotate(angle: angleDegrees * pi / 180)` wrapping a fixed-width `pw.Container`), `DotsTextBlockElement` (`pw.SizedBox(width:)` + `pw.Text` with `textAlign` + `lineHeight`; call `logger.warn` when `value.length > maxChars` or `value.split('\n').length > maxLines`) (R4, R5, D1, D2).
- [x] T3.4 In `lib/src/render/dots_renderer.dart` — replace the `DotsAlbumSpreadPage` `UnimplementedError` at `:274` with `return buildAlbumSpreadPage(format: format, page: page, fontResolver: fontFor, bytesResolver: (p) async => loader.load(p), logger: log, onPhotoFailure: onPhotoSlotFailure, drawCropMarks: drawCropMarks)` (R7). Remove the T2.4 stub cases from `_buildElement`; the switch is now fully handled in `buildAlbumSpreadPage`.
- [x] T3.5 In `lib/src/render/isolate_synthesis.dart` — replace the `DotsAlbumSpreadPage` `UnimplementedError` at `:206` with the same helper call using the isolate's `_fontFor`, `_bytesFor`, `_NoOpLogger()` / `photoFailures` (R7). Remove the T2.5 stub cases correspondingly.
- [x] T3.6 Run `flutter test test/render/album_spread_page_test.dart` — all rendering and warn tests pass (GREEN for T1.1–T1.5).

---

## Phase T4 — Named constructors + builder (GREEN for model + builder tests)

- [x] T4.1 In `lib/src/config/dots_template.dart` — add `factory DotsAlbumSpreadPage.dedication({required DotsAlbumType type, required int pageNumber, required String contextLabelValue, required String title, required String body, required String signature})`: assembles `header` (leftPageNumber: '$pageNumber', centerLabel: contextLabelValue, rightPageNumber: null), footer wordmark "Dots. Memories", and elements list [DotsTextElement(TITLE, P22 Mackinac Medium 23 pt), DotsTextBlockElement(BODY, Inter Book 9 pt, width=102 mm in pts, center, lineHeight 1.2, maxChars 1000, maxLines 32), DotsRotatedTextElement(SIGNATURE, Biro Script Plus 12 pt, angleDegrees 2.0)]; skips rotated element when `signature.isEmpty` (R1, D4).
- [x] T4.2 In `lib/src/config/dots_template.dart` — add `factory DotsAlbumSpreadPage.closing({required DotsAlbumType type, required int pageNumber, required String contextLabelValue, required String? photoPath, required String title, required String subtitle})`: title font size via exhaustive `switch (type) { case boda: 12.0; case parejas || hijos || individuales || outros: 20.0; }` (no default — compile-time exhaustive); assembles photo element (if photoPath non-null), DotsTextElement(TITLE, P22 Mackinac Medium, computed size), DotsTextBlockElement(SUBTITLE, P22 Mackinac Book 9 pt, 2 lines), header and footer (R2, D4).
- [x] T4.3 Create `lib/src/api/album_simple_content.dart` — define `@immutable class AlbumSimpleContent`, `@immutable class DedicationContent`, `@immutable class ClosingContent` with `==` / `hashCode` per existing library style (D3).
- [x] T4.4 Create `lib/src/api/build_simple_pages.dart` — implement `List<DotsPage> buildSimplePagesFor(DotsAlbumType type, AlbumSimpleContent content, {required int firstPageNumber, required String contextLabelValue})`: for boda emit only closing (if content.closing != null); for all other types emit dedication (if non-null) then closing (if non-null); pass `contextLabelValue` straight through to named constructors — it is a pre-resolved string, NOT a token substitution call (R6, D4, D3). Note: the caller is responsible for resolving `type.contextLabelToken` from the variable map before passing `contextLabelValue`; this function does not perform token substitution.
- [x] T4.5 Run `flutter test test/api/build_simple_pages_test.dart test/config/dots_template_test.dart` — all builder and model tests pass (GREEN for T1.6–T1.7).

---

## Phase T5 — Public exports + full verification

- [x] T5.1 In `lib/dots_pdf.dart` — add `export 'src/api/album_simple_content.dart' show AlbumSimpleContent, DedicationContent, ClosingContent;` and `export 'src/api/build_simple_pages.dart' show buildSimplePagesFor;`. Confirm `DotsRotatedTextElement`, `DotsTextBlockElement`, `DotsTextAlign`, and the new named constructors are reachable transitively via the existing `dots_template.dart` export (R9, D7).
- [x] T5.2 Run `flutter analyze` — 0 issues; confirm sealed `DotsElement` switch is exhaustive; confirm no `package:pdf` types leak into public symbols.
- [x] T5.3 Run `flutter test` — ALL tests pass (pre-existing slice-1 suite unmodified + all new T1 tests green); assert existing test count ≥ 237 (R8).
- [x] T5.4 Backwards-compat smoke: instantiate `DotsAlbumSpreadPage` with an empty elements list (slice-1 style) and confirm no exception is thrown and `dart analyze` is still clean (R8).
