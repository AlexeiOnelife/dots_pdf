# Tasks: album-type-gaussian-circles (Slice 4 of 5)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~540–580 LOC across 12 files |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (T1 + T2): test scaffolding + element/layout + exhaustiveness; PR 2 (T3 + T4 + T5): rasterization + factory + builder + exports + verification |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 (T1 + T2) | RED tests + `DotsDecorativeCircleElement` + `kCoverCircleLayout` + 5 exhaustiveness arms | PR 1 | Base = `feature/album-type-gaussian-circles`; CI must reach green before PR 2 |
| 2 (T3 + T4 + T5) | Rasterizer + cache + `AlbumCoverContent` + `.cover()` factory + `buildCoverPageFor` + exports | PR 2 | Base = PR 1 branch; diff contains only the implementation that makes the RED tests pass |

---

## Phase 1: Test Scaffolding — RED (satisfies R1, R2, R3, R4, R5, R6, R7, R8, R9)

- [x] 1.1 Create `test/config/dots_decorative_circle_element_test.dart` — RED tests for `DotsDecorativeCircleElement`: construction with all named fields; equality and `hashCode` for identical instances; inequality when `diameter` differs; inequality when `colorHex` differs; all four bleed flags default to `false`. Tests must fail to compile until T2.1 lands.
- [x] 1.2 Create `test/render/cover_circles_test.dart` — RED tests for `kCoverCircleLayout`: exactly 14 entries; diameter tier set equals `{47, 28, 16}`; each entry's bleed flags match the spec table (circle #2 `bleedTop`, #3 `bleedRight`, #4 `bleedLeft`, #5 `bleedRight+bleedBottom`, #9 `bleedBottom`, #14 `bleedBottom`).
- [x] 1.3 Create `test/render/cover_page_test.dart` — RED tests for the render layer: `DotsAlbumSpreadPage.cover` emits exactly 17 elements (14 circles + 3 texts); `header` is `null`; `footer` is `null`; circle elements match `kCoverCircleLayout` positions and bleed flags; rendering via `buildAlbumSpreadPage` produces a non-empty byte buffer; rasterizer cache: single rasterization for same `(diameter, colorHex, gaussianFadeMm)` across 14 circles; `resetDecorativeCircleCacheForTest` clears state; no header-trio text in rendered output when `header == null`.
- [x] 1.4 Create `test/api/build_cover_page_test.dart` — RED tests for `buildCoverPageFor`: `parejas` default eyebrow resolves to `"DOTBOOK"`; `hijos` default eyebrow resolves to `"DOTBOOK DE {NOMBREHIJO}"`; `eyebrowOverride` wins for both types; `ArgumentError` thrown for `DotsAlbumType.individuales`, `DotsAlbumType.boda`, `DotsAlbumType.otros`; `AlbumCoverContent` equality — identical instances equal, differ when `eyebrowOverride` differs; geometry identical for `parejas` vs `hijos` given same content; `DotsDecorativeCircleElement`, `AlbumCoverContent`, `buildCoverPageFor` all exported from `lib/dots_pdf.dart`.

---

## Phase 2: Foundation — Element Type + Circle Layout + Exhaustiveness Arms (satisfies R1, R8, R9)

- [x] 2.1 In `lib/src/config/dots_template.dart` — add `DotsDecorativeCircleElement` as a `sealed` subtype of `DotsElement` with fields: `double diameter` (pt), `String colorHex`, `double gaussianFadeMm` (default `1.764`), `bool bleedLeft/bleedRight/bleedTop/bleedBottom` (all default `false`). Implement `==` and `hashCode` over all 9 fields (including inherited `x` and `y`). Add `const` constructor with named parameters.
- [x] 2.2 Create `lib/src/render/cover_circles.dart` — add file-private `_CoverCircleAnchor` class (`@immutable`, fields: `diameterMm`, `xMm`, `yMm`, four bleed bools all defaulting `false`) and library-private `const List<_CoverCircleAnchor> kCoverCircleLayout` with the 14 anchors from the spec table (5 × 47 mm, 4 × 28 mm, 5 × 16 mm; bleed flags per locked decision #5). Do NOT export `kCoverCircleLayout` from `lib/dots_pdf.dart`.
- [x] 2.3 In `lib/src/render/album_spread_page.dart` — add exhaustiveness arm to the `_buildElement` sealed switch: `case DotsDecorativeCircleElement(): return _buildDecorativeCircleElement(element);`. Stub `_buildDecorativeCircleElement` to throw `UnimplementedError` so analysis passes; the real implementation lands in T3.2.
- [x] 2.4 In `lib/src/render/dots_renderer.dart` — add three exhaustiveness arms: (a) `case DotsDecorativeCircleElement(): return null;` in `_buildElement` for the `DotsElementsPage` path; (b) `case DotsDecorativeCircleElement(): break; // no-op: decorative circles have no asset path` in `preloadAssetBytes` for the `DotsElementsPage` arm; (c) same no-op `break` in `preloadAssetBytes` for the `DotsAlbumSpreadPage` arm.
- [x] 2.5 In `lib/src/render/isolate_synthesis.dart` — add exhaustiveness arm to `_buildElement` switch: `case DotsDecorativeCircleElement(): return null;`.

---

## Phase 3: Rasterization + Cache (satisfies R2, R3, R8)

- [ ] 3.1 In `lib/src/render/album_spread_page.dart` — add the `_CircleCacheKey` record typedef `({double diameterPt, String colorHex, double gaussianFadeMm})` and the file-private `final Map<_CircleCacheKey, Uint8List> _circleCache = {}`. Add `@visibleForTesting void resetDecorativeCircleCacheForTest()` that calls `_circleCache.clear()`.
- [ ] 3.2 In `lib/src/render/album_spread_page.dart` — add `Uint8List _rasterizeFadedCircle({required double diameterPt, required PdfColor color, required double gaussianFadeMm})`. Pipeline: (1) `fadePx = gaussianFadeMm / 25.4 * 300`; (2) `canvasPx = ceil(diameterPx + 2 * fadePx * 3)` where `diameterPx = diameterPt / 72 * 300`; (3) `img.Image(width: canvasPx, height: canvasPx, numChannels: 4)` with transparent fill; (4) `img.fillCircle(antialias: true, radius: diameterPx ~/ 2)`; (5) `img.gaussianBlur(radius: fadePx.round())`; (6) return `img.encodePng(...)`. Diameter rounded to 4 decimals at call site before cache lookup: `(diameterPt * 10000).round() / 10000.0`.
- [ ] 3.3 In `lib/src/render/album_spread_page.dart` — replace the `UnimplementedError` stub in `_buildDecorativeCircleElement` with the real implementation: parse `colorHex` to `PdfColor`, build `_CircleCacheKey`, call `_circleCache[key] ??= _rasterizeFadedCircle(...)`, wrap bytes in `pw.MemoryImage`, compute `haloPt = gaussianFadeMm / 25.4 * 72 * 3`, render `pw.Image(memImage, width: canvasPt, height: canvasPt)` at `Positioned(left: element.x - haloPt, top: element.y - haloPt)`. When a bleed flag is set, extend the position past the page boundary on that edge without clipping.

---

## Phase 4: Cover Factory + Builder (satisfies R4, R5, R6, R7)

- [ ] 4.1 Create `lib/src/api/album_cover_content.dart` — add `@immutable class AlbumCoverContent` with `const` constructor: `required String title`, `required String dateLine`, `String? eyebrowOverride` (defaults to `null`). Implement `==` and `hashCode` over all three fields.
- [ ] 4.2 In `lib/src/config/dots_template.dart` — add `factory DotsAlbumSpreadPage.cover({required DotsAlbumType type, required int pageNumber, required String title, required String dateLine, String? eyebrowOverride})`. Logic: resolve eyebrow (switch on `type`: `parejas` → `"DOTBOOK"`, `hijos` → `"DOTBOOK DE {NOMBREHIJO}"`, else throw `ArgumentError`; override wins when non-null); map `kCoverCircleLayout` to 14 `DotsDecorativeCircleElement` instances (converting mm→pt via `_mmToPt`); emit 3 `DotsTextBlockElement` entries with positions per locked decision #9 (eyebrow at `pageHeight/2 - 12 mm`, title at `pageHeight/2`, date at `pageHeight/2 + 18 mm`; all `x=0, width=pageWidthPt, textAlign: center`); set `header: DotsSpreadHeader()` with all trio fields `null`, `footer: DotsSpreadFooter(wordmark: '')`.
- [ ] 4.3 Create `lib/src/api/build_cover_page.dart` — add `DotsAlbumSpreadPage buildCoverPageFor(DotsAlbumType type, AlbumCoverContent content, {required int pageNumber})`. Guard: throw `ArgumentError.value(type, 'type', '...')` when type is not `parejas` or `hijos`. Delegate to `DotsAlbumSpreadPage.cover(type: type, pageNumber: pageNumber, title: content.title, dateLine: content.dateLine, eyebrowOverride: content.eyebrowOverride)`.

---

## Phase 5: Public Exports + Verification (satisfies R9)

- [ ] 5.1 In `lib/dots_pdf.dart` — add two new export directives: `export 'src/api/album_cover_content.dart';` and `export 'src/api/build_cover_page.dart';`. (`DotsDecorativeCircleElement` and `.cover()` ride the existing `dots_template.dart` export.)
- [ ] 5.2 Run `flutter analyze` — confirm 0 issues, no non-exhaustive pattern-match errors, no unused imports.
- [ ] 5.3 Run `flutter test` — all new tests pass (GREEN); all slice-1/2/3 test files pass unchanged. Confirm `test/config/dots_decorative_circle_element_test.dart`, `test/render/cover_circles_test.dart`, `test/render/cover_page_test.dart`, and `test/api/build_cover_page_test.dart` all green.

---

## Spec Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| R1 — DotsDecorativeCircleElement model | T1.1, T2.1 |
| R2 — Decorative-circle rendering | T1.3, T3.2, T3.3 |
| R3 — Pre-rasterization caching | T1.3, T3.1, T3.2 |
| R4 — AlbumCoverContent value object | T1.4, T4.1 |
| R5 — DotsAlbumSpreadPage.cover factory | T1.3, T4.2 |
| R6 — Per-type eyebrow resolution | T1.4, T4.2, T4.3 |
| R7 — buildCoverPageFor builder | T1.4, T4.3 |
| R8 — Renderer dispatch | T2.3, T2.4, T2.5, T3.3 |
| R9 — Backwards compatibility + public exports | T2.4, T2.5, T5.1, T5.3 |

---

## PR Boundary (feature-branch-chain)

- **PR 1** — base: `feature/album-type-gaussian-circles`; contains T1 + T2 (RED tests compile with stubs; `dart analyze` clean; exhaustiveness arms in place; `kCoverCircleLayout` data complete). Tests fail at runtime until PR 2.
- **PR 2** — base: PR 1 branch; contains T3 + T4 + T5 (rasterizer, cache, factory, builder, exports; all tests GREEN). Reviewer sees only the implementation diff with no repeated PR 1 changes.
