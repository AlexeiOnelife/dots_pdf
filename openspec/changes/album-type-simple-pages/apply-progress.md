# Apply Progress: album-type-simple-pages PR 1

**Change**: album-type-simple-pages
**PR**: 1 of 2 (feature-branch-chain)
**Mode**: Standard Mode
**Batch**: T1 + T2 (test scaffolding + element types)

## Completed Tasks

- [x] T1.1 — Created `test/render/album_spread_page_test.dart` with failing tests for dedication rendering (parejas, hijos, individuales, otros), signature rotation at 2°, body width constraint.
- [x] T1.2 — Added failing tests for closing-page rendering: title 12pt boda / 20pt others, null photoPath no-throw, photo slot 66×86 mm.
- [x] T1.3 — Added failing tests for header/footer: all four labels drawn, Inter Semibold 7pt, null fields omitted.
- [x] T1.4 — Added failing tests for DotsTextBlockElement warn behavior: body within limits / exceeding 1000 chars / exceeding 32 lines.
- [x] T1.5 — Added failing tests for isolate dispatch: useIsolate=false valid PDF / useIsolate=true valid PDF / both within 20% size tolerance.
- [x] T1.6 — Created `test/api/build_simple_pages_test.dart` with failing tests for buildSimplePagesFor: page count per type, header.centerLabel per type, partial content scenarios.
- [x] T1.7 — Created `test/config/dots_template_test.dart` with: DotsRotatedTextElement equality + hashCode (GREEN immediately), DotsTextBlockElement equality + hashCode (GREEN immediately), DotsAlbumSpreadPage.dedication/.closing smokes (RED — fail() placeholders until PR 2 T4.1/T4.2), empty elements list backwards-compat (GREEN immediately).
- [x] T2.1 — Added `enum DotsTextAlign { left, center, right }` to `lib/src/config/dots_template.dart`. No package:pdf import.
- [x] T2.2 — Added sealed `DotsRotatedTextElement extends DotsElement` with value, fontSize, angleDegrees, fontFamily?, colorHex? + == / hashCode.
- [x] T2.3 — Added sealed `DotsTextBlockElement extends DotsElement` with value, fontSize, width, fontFamily?, colorHex?, textAlign, lineHeight, maxChars?, maxLines? + == / hashCode.
- [x] T2.4 — Extended `_buildElement` in `lib/src/render/dots_renderer.dart` with two stub cases for DotsRotatedTextElement and DotsTextBlockElement (UnimplementedError). Also updated both preloadAssetBytes inner switches (DotsElementsPage + DotsAlbumSpreadPage arms) with no-op break arms.
- [x] T2.5 — Extended `_buildElement` in `lib/src/render/isolate_synthesis.dart` with the same two stub cases.
- [x] T2.6 — `flutter analyze` → 0 issues. Sealed switches exhaustive. No package:pdf leak.

## Pending Tasks

- [ ] T3.1–T3.6 — Shared render helper `lib/src/render/album_spread_page.dart` (PR 2)
- [ ] T4.1–T4.5 — Named constructors + builder (PR 2)
- [ ] T5.1–T5.4 — Public exports + full verification (PR 2)

## Test Counts

- Pre-existing tests passing: 237
- New T1 tests (RED — fail() placeholders): 50
- New T2 type-equality/compat tests (GREEN): 14
- Total: 251 pass, 50 fail

## Files Changed

| File | Action | Summary |
|------|--------|---------|
| `lib/src/config/dots_template.dart` | Modified | Added DotsTextAlign enum, DotsRotatedTextElement, DotsTextBlockElement (T2.1–T2.3) |
| `lib/src/render/dots_renderer.dart` | Modified | Added stub cases for new element types in _buildElement + preloadAssetBytes switches (T2.4) |
| `lib/src/render/isolate_synthesis.dart` | Modified | Added stub cases for new element types in _buildElement (T2.5) |
| `test/render/album_spread_page_test.dart` | Created | Failing tests for T1.1–T1.5 (rendering, warn, isolate dispatch) |
| `test/api/build_simple_pages_test.dart` | Created | Failing tests for T1.6 (buildSimplePagesFor) |
| `test/config/dots_template_test.dart` | Created | Mix of GREEN (equality) and RED (factory smokes) tests for T1.7 |
| `openspec/changes/album-type-simple-pages/tasks.md` | Modified | Marked T1.x and T2.x [x] complete |

## Notes

- T1 tests for symbols not yet created (DotsAlbumSpreadPage.dedication, .closing, buildAlbumSpreadPage, AlbumSimpleContent, buildSimplePagesFor) use fail() placeholders so the file compiles and pre-existing tests are unaffected. PR 2 replaces each fail() with real assertions.
- T2.4 also updated the two preloadAssetBytes inner switch arms to be exhaustive over the new types (no-op break for both, since neither carries an assetPath).
- DotsTextAlign is defined without any import of package:pdf, as required (D2/R5).
- flutter analyze: 0 issues throughout.
