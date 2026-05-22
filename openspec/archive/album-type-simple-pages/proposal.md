# Proposal: album-type-simple-pages (slice 2 of 5)

## Intent

Slice 1 wired `DotsAlbumType` and modeled `DotsAlbumSpreadPage` + `DotsSpreadHeader` + `DotsSpreadFooter`, then left rendering as `UnimplementedError` in both `dots_renderer.dart` and `isolate_synthesis.dart`. Slice 2 makes those throw-sites into REAL pixels for the two simplest, lowest-risk album-type pages — **dedication** and **closing single page** — plus the header/footer trio that every album-type spread relies on. Result: a caller can pick an album type, supply user content, and emit the dedication + closing pages of a real album.

## Scope

### In Scope
- **Dedication page renderer** (parejas p.5, hijos p.5, individuales p.2, otros p.2): TITLE (P22 Mackinac Medium 23/27.6pt, max 50 chars, 2 lines, centered), BODY block (Inter Book 9/10.8pt, centered, width 102 mm, max 1000 chars / 32 lines), SIGNATURE (Biro Script Plus Regular 12/14.4pt, rotated 2° via `pw.Transform.rotate`), 86 mm bottom margin.
- **Closing single page renderer** (parejas/hijos p.10, individuales/otros p.8, boda p.5): rounded-rect photo slot 66 × 86 mm centered, TITLE below (P22 Mackinac Medium 20/24pt for parejas/hijos/individuales/otros; 12/14pt for boda), SUBTITLE (P22 Mackinac Book 9/10.8pt, 2 lines).
- **Header/footer drawing**: actually draw the four positions slice 1 modeled — top-left page #, top-center context label, top-right page #, bottom-center wordmark. All Inter Semibold 7/8.4pt.
- **Album-type page-set builder**: typed named constructors `DotsAlbumSpreadPage.dedication(...)` and `DotsAlbumSpreadPage.closing(...)` plus a top-level `buildSimplePagesFor(DotsAlbumType, AlbumSimpleContent)` that returns the ordered dedication + closing pages for the requested type. All 5 album types supported, **boda included** (12pt closing variant).
- **Renderer dispatch**: replace `UnimplementedError` in `dots_renderer.dart:274` AND `isolate_synthesis.dart:206` by delegating both to a shared pure helper `buildAlbumSpreadPage(...)` so the main-isolate and worker-isolate paths cannot drift apart.
- **Asset preloading**: `preloadAssetBytes` already walks `DotsAlbumSpreadPage.elements` (slice 1, line 48) — keep that, no change needed.

### Out of Scope
- Cover pages (parejas/hijos p.1, individuales/otros p.1) — slice 4 (`album-type-gaussian-circles`).
- Instructions spread (5+5 photo grid) — deferred to a follow-up slice. Rationale: it requires per-page TITLE/SUBTITLE/BODY copy plus 10 photo slots; the geometry is shared across all 5 types, but the per-type voice variants (plural/singular wording) and right-page QR card make it a meaningfully larger surface than dedication/closing. Pulling it into slice 2 would double the slice size.
- "Antes de empezar el viaje" spread — deferred (decorative cluster, gradients).
- Photo-circle arc — slice 5.
- Polaroid collage — slice 3.
- Decorative shapes / gradients / Gaussian fades — slices 3-4.
- boda p.3 / p.4 / individuales p.6 with their unresolved coordinates — slices 3-5.
- Any non-2° rotation primitive — only the signature uses `pw.Transform.rotate` here.

## Capabilities

### New Capabilities
- `album-type-simple-pages`: dedication-page rendering, closing-single-page rendering, header/footer drawing, and the per-type page-set builder for the two "simple" pages.

### Modified Capabilities
- None. Slice 1's spec `album-type-foundation` already declared the page model; slice 2 only adds RENDERER behavior plus a new builder. Foundation requirements are unchanged.

## Approach

**Q1 — Page model strategy: Option B (reuse `DotsAlbumSpreadPage`).** Dedication and closing are configurations of `DotsAlbumSpreadPage.elements`, not new subtypes. New `DotsAlbumSpreadPage.dedication(...)` and `DotsAlbumSpreadPage.closing(...)` named constructors take typed parameters (title/body/signature OR photo/title/subtitle) and assemble the correct `elements` list internally. The renderer reads `elements` like it does for `DotsElementsPage`. Rationale: slice 1's design decision Q1 explicitly chose to absorb spread variety inside `DotsAlbumSpreadPage` via its `elements` list, with new `DotsElement` subtypes — NOT new page subtypes. Adding `DotsDedicationPage` / `DotsClosingPage` would re-introduce the exhaustiveness tax (4-5 switch sites) that slice 1 just paid down. Option C (mutex typed fields on the page) would clutter the model and trade compile-time safety for runtime checks. The text-rendering constraints (width 102 mm, 2° rotation, multi-line wrap) are handled by INTRODUCING two new `DotsElement` subtypes — `DotsRotatedTextElement` (angle in radians) and `DotsTextBlockElement` (multi-line block with max width, max lines, alignment). This matches slice 1's pattern.

**Q2 — Page-set builder API: Option A + Option C combined.** Library style is named constructors on immutable data classes (see `DotsCoverTemplate`, `DotsAlbumSpreadPage` constructor). Provide BOTH (a) per-page named constructors `DotsAlbumSpreadPage.dedication(type:, pageNumber:, title:, body:, signature:)` and `DotsAlbumSpreadPage.closing(type:, pageNumber:, photoPath:, title:, subtitle:)` for fine-grained authoring, AND (b) a top-level `List<DotsPage> buildSimplePagesFor(DotsAlbumType type, AlbumSimpleContent content)` for the common "give me dedication + closing for this type" call. Rejected Option B (builder/fluent) — no existing public surface uses it.

**Q3 — Multi-line text enforcement: WARN via logger, render anyway.** The library already logs via `DotsLogger`. Throwing on 1001 chars or 33 lines would be hostile to authors iterating on copy; silent clipping (current `pw.Text` behavior) hides errors. Mirror this in `DotsTextBlockElement`: when `value.length > maxChars` or computed line count > `maxLines`, emit `logger.warn(...)` with the page number and offending count, then render the full text (let `pw.Paragraph`/`pw.Text` clip if it overflows). The widow rule (min 3 words on the last line) and "no word-breaks" rules are **deferred to a future slice** — they require either a custom line-breaker or post-layout inspection, which is non-trivial. Document this gap explicitly in the spec.

**Q4 — boda in scope: YES, including the 12pt closing variant.** boda's closing page (p.5) is in the SAME geometry family as parejas/hijos p.10 (66 × 86 mm photo + TITLE + standard footer), differing only in TITLE font size (12pt vs 20pt) and copy. `DotsAlbumSpreadPage.closing(type: DotsAlbumType.boda, ...)` selects the 12pt size via a `switch` on `type` inside the constructor. boda has no dedication page in the spec, so `buildSimplePagesFor(boda, ...)` returns only the closing page. boda's OTHER pages (p.3 cluster, p.4 halo) remain deferred — confidence on coordinates is MEDIUM/LOW and those belong to later slices anyway.

**Shared rendering helper.** Extract the `DotsAlbumSpreadPage` rendering into a top-level `Future<pw.Page> buildAlbumSpreadPage({required PdfPageFormat format, required DotsAlbumSpreadPage page, required DotsFontBundle? fontBundle, required Map<String, Uint8List> assetBytes, ...})` in a new file `lib/src/render/album_spread_page.dart`. Both `DotsRenderer.buildPage` and `isolate_synthesis.buildPage` call it. This eliminates the drift risk between the two switch sites that slice 1's design flagged.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsAlbumSpreadPage.dedication(...)` and `.closing(...)` named constructors. Add `DotsRotatedTextElement` and `DotsTextBlockElement` as new sealed siblings of `DotsElement` (updates the sealed `switch` in renderer's `_buildElement`). |
| `lib/src/api/album_simple_content.dart` | New | `AlbumSimpleContent` immutable value object: dedication (title, body, signature), closing (photoPath, title, subtitle). All optional — `buildSimplePagesFor` emits only the pages whose content is supplied. |
| `lib/src/api/build_simple_pages.dart` | New | Top-level `List<DotsPage> buildSimplePagesFor(DotsAlbumType, AlbumSimpleContent, {required int firstPageNumber})`. |
| `lib/src/render/album_spread_page.dart` | New | Pure `buildAlbumSpreadPage(...)` helper. Renders header trio, footer, and dispatches over `elements` (text / image / rotated text / text block). |
| `lib/src/render/dots_renderer.dart` | Modified | Replace `UnimplementedError` at `:274` with delegation to `buildAlbumSpreadPage`. Extend `_buildElement` switch for the two new `DotsElement` subtypes. |
| `lib/src/render/isolate_synthesis.dart` | Modified | Replace `UnimplementedError` at `:206` with the same delegation. |
| `lib/dots_pdf.dart` | Modified | Re-export `AlbumSimpleContent`, `buildSimplePagesFor`, `DotsRotatedTextElement`, `DotsTextBlockElement`. |
| `test/render/album_spread_page_test.dart` | New | Golden-style tests on the produced `pw.Page` tree (widget shape, not pixel match) for dedication and closing per album type. |
| `test/api/build_simple_pages_test.dart` | New | Asserts `buildSimplePagesFor` emits expected page count + types for each `DotsAlbumType`. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `pw.Transform.rotate` clips the rotated signature when its bounding box exceeds the parent | Med | Wrap in a fixed-size `pw.SizedBox` sized to the un-rotated signature's measured width + small padding; the 2° angle adds <1 mm of vertical excursion at 12pt text. |
| `pw.Text` line-count detection at layout time is not exposed by the `pdf` package | Med | Approximate via `value.split('\n').length` + heuristic char-per-line for the warn-only check. The warn is best-effort; the actual rendered glyph layout decides clipping. |
| Drift between `dots_renderer` and `isolate_synthesis` rendering paths | Low | Both call the same `buildAlbumSpreadPage` helper. A single test file exercises the shared helper. |
| 102 mm body width vs the `pw.Container(width:)` semantics in `pdf` package | Low | Convert mm→pt via the existing `_mmToPt` constant in renderer; wrap text block in `pw.Container(width: 102 * _mmToPt)` with `pw.Center` alignment. |
| Closing-page TITLE font size selection (12pt for boda, 20pt elsewhere) lives in a constructor — caller could pass wrong type | Low | The named constructor takes `DotsAlbumType type` and resolves font size internally via exhaustive `switch`. Caller cannot override. |

## Rollback Plan

- Revert the commits that introduce `album_spread_page.dart`, `album_simple_content.dart`, `build_simple_pages.dart`, and the two new `DotsElement` subtypes.
- Restore the `UnimplementedError` throws in `dots_renderer.dart:274` and `isolate_synthesis.dart:206`.
- The new constructors on `DotsAlbumSpreadPage` are additive; removing them does not break slice 1's foundation API.
- Drop the new test files. Existing slice-1 tests remain valid.

## Dependencies

- Slice 1 (`album-type-foundation`) — completed and archived. Provides `DotsAlbumSpreadPage`, `DotsSpreadHeader`, `DotsSpreadFooter`, `DotsAlbumType.contextLabelToken`, and parse-time variable substitution.
- `pdf` package's `pw.Transform.rotate` (verified to exist in slice 1's explore).
- `DotsFontBundle` for P22 Mackinac (Medium, Book), Inter (Book, Semibold), Biro Script Plus (Regular). Slice 1 assumes these are available — slice 2 actually uses them.

## Success Criteria

- [ ] `DotsAlbumSpreadPage` renders without throwing in both the main-isolate and worker-isolate paths.
- [ ] `buildSimplePagesFor(parejas, content)` emits 2 pages: dedication then closing, in that order.
- [ ] `buildSimplePagesFor(boda, content)` emits 1 page: closing (no dedication).
- [ ] Closing-page TITLE is 12pt for `boda`, 20pt for the other 4 types — asserted by unit test.
- [ ] Signature renders at 2° rotation (verified by inspecting the produced `pw.Transform` widget tree).
- [ ] Header trio (left page #, center context label, right page #) and footer wordmark draw at the four canonical positions, Inter Semibold 7pt.
- [ ] Logger emits a warn when dedication body exceeds 1000 chars or 32 newline-counted lines.
- [ ] `dart analyze` passes (sealed switches remain exhaustive after adding `DotsRotatedTextElement` and `DotsTextBlockElement`).
- [ ] All existing tests from slice 1 still pass unchanged.
