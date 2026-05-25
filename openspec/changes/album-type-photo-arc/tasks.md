# Tasks: album-type-photo-arc (Slice 5 of 5 — FINAL)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 650–850 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (T1+T2): test scaffolding + element types + layout + exhaustiveness arms → PR 2 (T3+T4+T5): rendering + builder + exports + GREEN |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | RED tests + element types + layout + 10 exhaustiveness arms | PR 1 | Base: `add-album-type-layouts` tracker branch; all new test files fail RED; `dart analyze` is clean (arms in place); no render logic yet |
| 2 | Rendering + builder + exports; all tests turn GREEN | PR 2 | Base: PR 1 branch; renders both isolate paths; `dart analyze` clean; all prior slice tests pass |

---

## Phase 1: Test Scaffolding — RED (PR 1)

Spec: R1, R3, R5, R6, R7, R8, R9, R10, R12. All tests written before any implementation. All fail RED.

- [x] 1.1 Create `test/config/dots_photo_circle_element_test.dart` — 5 tests: construction, equality (equal), equality (diameter differs), equality (assetPath differs), bleed flags default to `false`. All fail RED (class not found). Satisfies R1 scenarios.
- [x] 1.2 Create `test/config/dots_oval_qr_element_test.dart` — 3 tests: construction, equality (equal), inequality when caption differs. All fail RED. Satisfies R3 scenarios.
- [x] 1.3 Create `test/render/photo_arc_layout_test.dart` — tests: length == 10, all `diameterMm == 44.45`, each entry's `xMm`/`yMm` matches spec table (10 assertions). All fail RED. Satisfies D6 / design table.
- [x] 1.4 Create `test/render/photo_arc_test.dart` — tests: factory produces 14 elements (10 circles + 2 ovals + 2 texts), header.centerLabel, ArgumentError for boda, RangeError for photoPaths length 9, RangeError for photoPaths length 11, no error for length 10, render via main-isolate produces non-empty buffer, render via worker-isolate produces non-empty buffer, logger warns on width < 406 mm, sealed switch is exhaustive (compile-clean). All fail RED. Satisfies R6, R9, R10, R11.
- [x] 1.5 Create `test/api/build_photo_arc_page_test.dart` — tests: returns `DotsAlbumSpreadPage`, ArgumentError for boda, parejas left caption default, hijos left caption default, individuales left caption default, otros left caption default, right caption shared by all 4 types, `qrCaptionLeftOverride` wins, `qrCaptionRightOverride` wins, geometry identical for all 4 types. All fail RED. Satisfies R7, R8.

---

## Phase 2: Foundation — Element Types + Layout + Exhaustiveness Arms (PR 1)

Spec: R1, R3, R9, R12. Establishes all compile-time contracts. No render logic.

- [x] 2.1 Add `DotsPhotoCircleElement` sealed subclass of `DotsElement` to `lib/src/config/dots_template.dart` — fields: `x`, `y`, `diameter` (pt), `assetPath`, 4 bleed bools defaulting `false`; `const` constructor; `==`/`hashCode` over all 8 fields. Satisfies R1.
- [x] 2.2 Add `DotsOvalQrElement` sealed subclass of `DotsElement` to `lib/src/config/dots_template.dart` — fields: `x`, `y`, `ovalWidth`, `ovalHeight` (pt), `qrPayload`, `caption`; `const` constructor; `==`/`hashCode` over all 6 fields. Satisfies R3.
- [x] 2.3 Create `lib/src/render/photo_arc_layout.dart` — file-private `_PhotoArcAnchor` class (fields: `xMm`, `yMm`, `diameterMm = 44.45`); `const List<_PhotoArcAnchor> kPhotoArcLayout` with the 10 spec entries. Satisfies D6, spec layout table.
- [x] 2.4 Add exhaustiveness arm 1 (site 1 — `album_spread_page.dart` `_buildElement`): `DotsPhotoCircleElement` arm calls `_buildPhotoCircleElement(element, ...)` (stub returning `pw.SizedBox.shrink()` for now); `DotsOvalQrElement` arm calls `_buildOvalQrElement(element, ...)` (same stub). Satisfies R9 site 1.
- [x] 2.5 Add exhaustiveness arms (site 2 — `dots_renderer.dart` `_buildElement` for `DotsElementsPage` path): both new types `return null;` with delegation comment. Satisfies R9 site 2.
- [x] 2.6 Add exhaustiveness arms (site 3 — `dots_renderer.dart` `preloadAssetBytes` inner switch for `DotsElementsPage`): `DotsPhotoCircleElement` → `paths.add(element.assetPath);`; `DotsOvalQrElement` → `break;`. Satisfies R9 site 3.
- [x] 2.7 Add exhaustiveness arms (site 4 — `dots_renderer.dart` `preloadAssetBytes` inner switch for `DotsAlbumSpreadPage`): `DotsPhotoCircleElement` → `paths.add(element.assetPath);`; `DotsOvalQrElement` → `break;`. Satisfies R9 site 4.
- [x] 2.8 Add exhaustiveness arms (site 5 — `isolate_synthesis.dart` `_buildElement`): both new types `return null;` with delegation comment. Satisfies R9 site 5.
- [x] 2.9 Verify `dart analyze` reports zero non-exhaustive-pattern errors. Tests 1.1–1.5 now compile; model tests (1.1, 1.2) turn GREEN; layout test (1.3) turns GREEN.

---

## Phase 3: Rendering — Photo Circle + Oval QR (PR 2)

Spec: R2, R4, R11.

- [ ] 3.1 Add 6 file-private renderer constants to `lib/src/render/album_spread_page.dart`: `_kOvalQrCaptionFontSize`, `_kOvalQrCaptionLineHeight`, `_kOvalQrCaptionColor`, `_kOvalQrCaptionGapMm`, `_kOvalBorderWidthPt`, `_kOvalBorderColor`, `_kQrInsetMm`. Satisfies D2 constants.
- [ ] 3.2 Implement `_buildPhotoCircleElement` in `album_spread_page.dart` — loads bytes via `bytesResolver`; on null/failure calls `onPhotoFailure(assetPath)` and returns null; on success wraps `pw.Image` in `pw.ClipOval(width: diameter, height: diameter)` inside `pw.Positioned(left: x, top: y)`. Satisfies R2.
- [ ] 3.3 Implement `_buildOvalQrElement` in `album_spread_page.dart` — `pw.Positioned(left: x, top: y, child: pw.Stack([ovalFrame, qrWidget, captionWidget]))`. Oval frame: `pw.Container(BoxDecoration(shape: BoxShape.circle, border: Border.all(_kOvalBorderColor, _kOvalBorderWidthPt)))`. QR: `pw.BarcodeWidget(BarcodeQRCorrectionLevel.medium, drawText: false)` sized to `qrSidePt` via inscribed-square-minus-inset formula. Caption: `pw.Text` centered, `P22 Mackinac Book`, `_kOvalQrCaptionFontSize`, `_kOvalQrCaptionColor`, positioned at `ovalHeight + _kOvalQrCaptionGapMm * mmToPt`. Satisfies R4.
- [ ] 3.4 Replace the Phase 2 stubs in `_buildElement` site 1 with the real helpers implemented in 3.2 and 3.3.
- [ ] 3.5 Add render-time width warning in `buildAlbumSpreadPage` — after elements are collected, before `pw.Page` is built: if any element is `DotsPhotoCircleElement` or `DotsOvalQrElement` AND `format.width < 406 mm − 1 pt`, call `logger.warn(...)`. Satisfies D10 / R11.

---

## Phase 4: Builder — Content + Factory + Top-Level Function (PR 2)

Spec: R5, R6, R7, R8, R10.

- [ ] 4.1 Create `lib/src/api/album_photo_arc_content.dart` — `@immutable AlbumPhotoArcContent` with 7 fields (`photoPaths`, `qrPayloadLeft`, `qrPayloadRight`, `title` defaulting to `"Un año lleno de recuerdos"`, `dateSubtitle`, `qrCaptionLeftOverride?`, `qrCaptionRightOverride?`); `const` constructor; `==`/`hashCode` with list equality on `photoPaths`. Dumb container — no validation. Satisfies R5.
- [ ] 4.2 Add `DotsAlbumSpreadPage.photoArc(...)` named factory to `lib/src/config/dots_template.dart` — (a) `ArgumentError` for boda; (b) `RangeError` if `content.photoPaths.length != kPhotoArcLayout.length`; (c) resolves per-type QR captions via `switch (type)`; (d) builds 10 `DotsPhotoCircleElement` from `kPhotoArcLayout × photoPaths`; (e) builds 2 `DotsOvalQrElement` at gutter positions with constants `_kPhotoArcOvalWidthMm = 50`, `_kPhotoArcOvalHeightMm = 45`; (f) builds title `DotsTextElement` at (19 mm, 43 mm) P22 Mackinac Medium 23pt; (g) builds date subtitle `DotsTextElement` at (19 mm, ≈57.74 mm) P22 Mackinac Book 9pt; (h) populates header trio and footer `'Dots. Memories'`. Satisfies R6, R7, R10.
- [ ] 4.3 Create `lib/src/api/build_photo_arc_page.dart` — top-level `buildPhotoArcPageFor(type, content, {required int pageNumber, required String contextLabelValue})` with dartdoc caller contract for 406 mm page width; `ArgumentError` for boda (defense-in-depth); delegates to `.photoArc(...)`. Satisfies R8, D9.

---

## Phase 5: Exports + Verification (PR 2)

Spec: R12.

- [ ] 5.1 Add imports for `album_photo_arc_content.dart` and `build_photo_arc_page.dart` to `lib/src/config/dots_template.dart` (needed for factory) and ensure `photo_arc_layout.dart` is imported there too.
- [ ] 5.2 Add two new exports to `lib/dots_pdf.dart`: `export 'src/api/album_photo_arc_content.dart';` and `export 'src/api/build_photo_arc_page.dart';`. Satisfies R12 public API.
- [ ] 5.3 Run `dart analyze` — zero errors expected. Confirms R9 scenario "sealed switch is exhaustive after slice 5".
- [ ] 5.4 Run full test suite — all 5 new test files GREEN; all prior slice-1/2/3/4 tests unchanged and passing. Satisfies R12 backwards-compatibility scenario.
