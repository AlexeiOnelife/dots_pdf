# Tasks: album-type-polaroid-collage (slice 3 of 5)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~590 (production ~345, tests ~245) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 = T1 + T2 (RED tests + element/types + exhaustiveness) · PR 2 = T3 + T4 + T5 (rendering + builder + exports + green) |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | RED tests + element types + slot table + exhaustiveness arms | PR 1 | Base = feature/album-type-polaroid-collage; ships with RED tests intentionally (accepted pattern per slice 2) |
| 2 | Rendering + builder + exports + tests go GREEN | PR 2 | Base = PR 1 branch; diff is focused rendering logic only |

---

## Phase T1: Test scaffolding — RED (write failing tests first)

Spec coverage: R1, R2, R3, R4, R5, R6, R7, R8, R9

- [x] T1.1 Create `test/config/dots_polaroid_element_test.dart` — write 5 failing tests: (a) constructs with all fields; (b) equality when all fields match; (c) hashCode equality when all fields match; (d) inequality when `angleDegrees` differs; (e) `gradientRtl` defaults to `false`. All tests import `DotsPolaroidElement` — RED until T2.1.
- [x] T1.2 Create `test/render/polaroid_collage_test.dart` — write 7 failing tests: (a) `polaroidCollage` with 6 paths emits 6 `DotsPolaroidElement` instances; (b) `additionalSlots: [a, b]` emits 8; (c) polar-2 `gradientRtl: true` when `applyOtrosGradient: true`; (d) all others `gradientRtl: false` when `applyOtrosGradient: true`; (e) `individuales` and `otros` produce identical element coordinates when gradient flag is off; (f) `gradientRtl=true` wires `pw.LinearGradient` left→right from alpha 0.85 → 0.00; (g) `gradientRtl=false` wires no gradient. RED until T3.
- [x] T1.3 Create `test/api/build_polaroid_collage_page_test.dart` — write 8 failing tests: (a) builder returns `DotsAlbumSpreadPage`; (b) `header.centerLabel` equals `contextLabelValue`; (c) `individuales` and `otros` geometry identical when `applyOtrosGradient: false`; (d) only polar-2 differs when `applyOtrosGradient: true`; (e) `pageNumber` correctly forwarded; (f) `AlbumCollageContent` equality with identical fields; (g) `PolaroidSlotPosition` constructs with all fields; (h) `photoPaths.length` mismatch throws `RangeError` (resolves design D9 open question — assert at factory entry). RED until T4.

---

## Phase T2: Foundation — element type, slot table, exhaustiveness arms

Spec coverage: R1, R6, R8, R9

- [x] T2.1 In `lib/src/config/dots_template.dart`, add `DotsPolaroidElement` as a sealed subtype of `DotsElement` after `DotsTextBlockElement`: all fields per D1 (`x`, `y`, `assetPath`, `width`, `height`, `angleDegrees`, `gradientRtl`, `bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`); const constructor with named params; `==` and `hashCode` per D1 sketch; `@immutable`. T1.1 tests now go GREEN.
- [x] T2.2 Create `lib/src/render/polaroid_slot_position.dart` — `PolaroidSlotPosition` value object per D2: same geometric fields as `DotsPolaroidElement` minus `assetPath`; `@immutable`; const constructor; `==` and `hashCode`.
- [x] T2.3 Create `lib/src/render/polaroid_slots.dart` — define `_mmToPt`, `_outerWidthPt`, `_outerHeightPt`, and `kDefaultPolaroidSlots` (public `const List<PolaroidSlotPosition>` with the 6 documented slots per D4; polar-2 `bleedLeft: true`; polar-6 `angleDegrees: 0.0` with dartdoc caveat; polar-4 and polar-6 LOW-confidence caveat in dartdoc).
- [x] T2.4 In `lib/src/render/album_spread_page.dart`, add `case DotsPolaroidElement(): return _buildPolaroidElement(...);` stub arm to `_buildElement` switch. Stub `_buildPolaroidElement` returning `null` — enough to satisfy the sealed switch; real body in T3.1. Run `dart analyze` — 0 non-exhaustive errors.
- [x] T2.5 In `lib/src/render/dots_renderer.dart`, add `case DotsPolaroidElement(): paths.add(element.assetPath);` to the `DotsElementsPage` inner element switch (~line 38–49) AND to the `DotsAlbumSpreadPage` inner element switch (~line 55–67). Add `case DotsPolaroidElement(): return null;` to `_buildElement` (~line 369).
- [x] T2.6 In `lib/src/render/isolate_synthesis.dart`, add `case DotsPolaroidElement(): return null;` to `_buildElement` (~line 288). Run `dart analyze` — 0 issues. Confirms R8 exhaustiveness scenario.

---

## Phase T3: Polaroid rendering

Spec coverage: R2, R3, R8

- [x] T3.1 In `lib/src/render/album_spread_page.dart`, add the 4 frame-border constants near `_kHeaderLeftX`: `_kPolaroidFrameLeftBorderMm = 5.5`, `_kPolaroidFrameRightBorderMm = 5.5`, `_kPolaroidFrameTopBorderMm = 5.5`, `_kPolaroidFrameBottomBorderMm = 6.5`. Replace the T2.4 stub `_buildPolaroidElement` with the full implementation per D7: (1) decode `element.assetPath` via `bytesResolver`; (2) build white `pw.Container` at `element.width × element.height`; (3) add `pw.Padding` with LTRB from the 4 constants × `_kMmToPt`; (4) inner `pw.Stack` with `pw.Image(image, fit: pw.BoxFit.cover)` and conditional `pw.Positioned.fill` gradient overlay per D6; (5) wrap in `pw.Transform.rotate(angle: element.angleDegrees * pi / 180, alignment: pw.Alignment.center)`; (6) return as `pw.Positioned(left: element.x, top: element.y)`. On load failure: call `onPhotoFailure` and return `null` (mirrors `_buildImage` contract). T1.2 rendering tests now go GREEN.

---

## Phase T4: Builder and value objects

Spec coverage: R4, R5, R7, D9 (photoPaths validation)

- [x] T4.1 Create `lib/src/api/album_collage_content.dart` — `AlbumCollageContent` immutable value object: fields `photoPaths` (List\<String\>), `applyOtrosGradient` (bool, default `false`), `additionalSlots` (List\<PolaroidSlotPosition\>, default `const []`); `@immutable`; `==` and `hashCode`.
- [x] T4.2 In `lib/src/config/dots_template.dart`, add `DotsAlbumSpreadPage.polaroidCollage(...)` named constructor after `.closing(...)`: accepts `type`, `pageNumber`, `contextLabelValue`, `photoPaths`, `applyOtrosGradient = false`, `additionalSlots = const []`. Add entry-point assert: `assert(photoPaths.length == kDefaultPolaroidSlots.length + additionalSlots.length, ...)` plus a `RangeError` throw in non-debug builds for the same length mismatch (resolves design open question D9). Zip `photoPaths` against `kDefaultPolaroidSlots + additionalSlots`; when `applyOtrosGradient: true`, set `gradientRtl: true` on the element at index 1 (polar-2). Returns `DotsAlbumSpreadPage` with `elements` list of `DotsPolaroidElement` instances.
- [x] T4.3 Create `lib/src/api/build_polaroid_collage_page.dart` — top-level function `buildPolaroidCollagePageFor(DotsAlbumType type, AlbumCollageContent content, {required int pageNumber, required String contextLabelValue})`. Delegates to `DotsAlbumSpreadPage.polaroidCollage(...)`. Returns a single `DotsAlbumSpreadPage`. T1.3 builder tests now go GREEN.

---

## Phase T5: Public exports and verification

Spec coverage: R8, R9

- [x] T5.1 In `lib/dots_pdf.dart`, add 4 new exports after the existing slice-2 exports: `export 'src/api/album_collage_content.dart' show AlbumCollageContent;`, `export 'src/api/build_polaroid_collage_page.dart' show buildPolaroidCollagePageFor;`, `export 'src/render/polaroid_slot_position.dart' show PolaroidSlotPosition;`, `export 'src/render/polaroid_slots.dart' show kDefaultPolaroidSlots;`. (`DotsPolaroidElement` rides on the existing `dots_template.dart` export — no extra line needed.)
- [x] T5.2 Run `flutter test` — all T1.1, T1.2, T1.3 tests pass GREEN; all slice-1 and slice-2 tests pass unmodified.
- [x] T5.3 Run `flutter analyze` — 0 issues; sealed `DotsElement` switch exhaustive everywhere.
- [x] T5.4 Backwards-compat smoke: call `import 'package:dots_pdf/dots_pdf.dart'` and reference `DotsPolaroidElement`, `AlbumCollageContent`, `PolaroidSlotPosition`, `buildPolaroidCollagePageFor`, `kDefaultPolaroidSlots` — no import error. Mirrors R9 scenario.
