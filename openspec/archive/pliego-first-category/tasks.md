# Tasks: pliego-first-category

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~1100–1600 (production ~500–700, tests ~600–900) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | 2-PR feature-branch-chain |
| Delivery strategy | ask-on-risk (resolved: feature-branch-chain) |
| Chain strategy | feature-branch-chain |

Decision needed before apply: No (already decided — 2-PR feature-branch-chain)
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | PR | Notes |
|------|------|----|-------|
| 1 | Enum + model rename/removal + parser scaffolding + content-class files + RED test suite | PR 1 | Branch `pliego-first-category-pr1`, off `page-template-chrome-pr2`. Tests that can pass immediately (equality, enum values, compile-time model shape) are GREEN; all validation/injection/stub-render tests use `fail('PR 2: …')`. |
| 2 | `DotsUnimplementedElement` + renderer switch arms + factory stub bodies + `categoryInputs` validation + injection helper + all tests GREEN | PR 2 | Branch `pliego-first-category-pr2`, off PR 1. Targets PR 1 branch; only the PR 1 branch merges to the `pliego-first-category` tracker and then to main. |

---

## PR 1 — Enum, Model, Parser Scaffolding, Content Classes, RED Tests

**Branch**: `pliego-first-category-pr1` (off `page-template-chrome-pr2`)
**Goal**: Ship enum addition, model rename/removal, parser skeleton (legacy-key rejection + `category` resolution; no injection yet), six content-class files, seven factory SIGNATURES with call-time `UnimplementedError` placeholders, and the full test suite — GREEN where the work lands, RED (`fail('PR 2: …')`) where the green path depends on injection/validation/renderer wiring.
**Verification**: `flutter analyze` clean (zero `public_member_api_docs` violations). `flutter test` compiles; pre-existing tests GREEN after fixture migration; new equality/enum/model/export tests GREEN; validation/injection/stub-render tests intentionally RED.
**Rollback**: `git revert` PR 1 commits; `page-template-chrome-pr2` is unaffected.
**Commit shape**: `feat(api): add DotsAlbumType.generalEventos and pliego-only model contract`

---

### Phase 1 — Enum and Exhaustive-Switch Updates (GREEN in PR 1)

- [x] **T1.1** Modify `lib/src/api/dots_album_type.dart` — add `generalEventos` as the sixth enum value with dartdoc; add it to `contextLabelToken` (line 19) grouped with `boda || hijos` → `'{Protagonistas}'`. Update the dartdoc mapping table. Satisfies R3.

- [x] **T1.2** Modify `lib/src/config/dots_template.dart` — add `generalEventos` arm to the `closing.titleFontSize` exhaustive switch at line 1299 (grouped with `parejas || hijos || individuales || otros => 20.0`). Add `generalEventos` arm to `photoArc.defaultLeftCaption` switch at line 1593 (grouped with `hijos || individuales || otros => 'Tu album en digital'`). Leave `cover.defaultEyebrow` (line 1468) unchanged — it uses a wildcard `_ => throw`. Satisfies R3.

- [x] **T1.3** Run `flutter analyze --fatal-warnings` immediately after T1.1–T1.2 to surface any additional exhaustive-switch sites that need a `generalEventos` arm beyond the three confirmed by the design. Add arms for every site the analyzer flags. Record any additional sites discovered here as a risk note for apply. Satisfies R3 acceptance test "dart analyze --fatal-warnings is clean".

- [x] **T1.4** Add tests to `test/api/dots_album_type_extension_test.dart` (or create `test/api/dots_album_type_test.dart` if absent) — all GREEN immediately:
  - `DotsAlbumType — has exactly six values including generalEventos`
  - `DotsAlbumType.generalEventos — contextLabelToken is {Protagonistas}`
  Satisfies R3.

---

### Phase 2 — DotsTemplate Model Rename and Field Removal (GREEN in PR 1)

- [x] **T2.1** Modify `lib/src/config/dots_template.dart` — rename field `albumType` → `category`; change type from `DotsAlbumType?` (nullable) to `DotsAlbumType` (non-nullable); set default `DotsAlbumType.generalEventos`. Remove `pages` field, `_emptyPages` const, and the XOR assert. Keep `_emptyPliegos` sentinel as default for `pliegos`. Simplify `effectivePages` by deleting the `if (pliegos.isEmpty) return pages` branch. Update `contentHash` at line 2073: swap `albumType` for `category`, remove `Object.hashAll(pages)`. Add dartdoc on `category`. Satisfies R4.

- [x] **T2.2** Migrate all internal test fixtures that use `DotsTemplate(pages: [...])` or reference `.albumType` to `DotsTemplate(pliegos: [DotsLayoutPliego(...)])` and `.category`. Files to update (58 `pages:` occurrences across 14 test files + 18 `albumType` occurrences; also any production call sites): `test/render/whole_document_renderer_test.dart`, `test/render/pair_document_renderer_test.dart`, `test/render/layout_page_render_test.dart`, `test/render/album_spread_page_test.dart`, `test/render/polaroid_collage_test.dart`, `test/render/photo_arc_test.dart`, `test/render/spread_image_render_test.dart`, `test/render/crop_marks_test.dart`, `test/render/dots_font_bundle_test.dart`, `test/render/qr_render_test.dart`, `test/api/dots_generator_test.dart`, `test/api/dots_generator_isolate_test.dart`, `test/preview/dots_generator_preview_test.dart`, `test/config/dots_pliego_test.dart`, `test/config/dots_template_album_type_test.dart`, `test/config/dots_template_parser_test.dart`. Spot-check any fixture using `pliegoNumber: 1` on a body pliego — this is a potential collision with PR 2's below-minimum diagnostic (see Risk section). Satisfies R4 (compile-time removal of `pages` field).

- [x] **T2.3** Add tests to `test/config/dots_template_test.dart` — GREEN immediately:
  - `DotsTemplate — pages field no longer exists (compile-time)` (compile guard comment + verify no field in model)
  - `DotsTemplate — category defaults to generalEventos`
  - `DotsTemplate — category participates in contentHash`
  - `DotsTemplate — effectivePages always flattens pliegos`
  Satisfies R4.

---

### Phase 3 — Parser Scaffolding: Legacy-Key Rejection and `category` Resolution (GREEN in PR 1)

- [x] **T3.1** Modify `lib/src/config/dots_template_parser.dart` — delete the `pages` JSON branch (lines 147–165) and the XOR check (lines 111–124). Replace the `albumType` block (lines 90–109) with: (A) reject `albumType` key with `DotsConfigException` at `$.albumType` hinting `category`; (B) reject `pages` key with `DotsConfigException` at `$.pages` hinting `pliegos`; (C) resolve `category` string with default `DotsAlbumType.generalEventos` and unknown-value throw at `$.category` listing all six values; (D) require `pliegos` key with `DotsConfigException` at `$` when absent. Do NOT add `categoryInputs` parsing or injection yet — those land in PR 2. Pass `category: category` through to the `DotsTemplate` constructor (which no longer accepts `pages`). Satisfies R1 (pliego-only contract), R2 (category resolution). Parser tests for these paths are GREEN in PR 1.

- [x] **T3.2** Add tests to `test/config/dots_template_parser_test.dart` — GREEN immediately (no injection needed):
  - `DotsTemplateParser — pliegos key parses successfully`
  - `DotsTemplateParser — pages key throws DotsConfigException at $.pages with migration hint`
  - `DotsTemplateParser — both keys throw DotsConfigException at $`
  - `DotsTemplateParser — neither key throws DotsConfigException at $`
  - `DotsTemplateParser — omitted category defaults to generalEventos`
  - `DotsTemplateParser — category "parejas" resolves to DotsAlbumType.parejas`
  - `DotsTemplateParser — unknown category value throws DotsConfigException at $.category listing allowed values`
  - `DotsTemplateParser — albumType key throws DotsConfigException at $.albumType with category hint`
  Satisfies R1, R2.

---

### Phase 4 — Content Classes (GREEN in PR 1)

- [x] **T4.1** Create `lib/src/api/album_photo_only_cover_content.dart` — `@immutable AlbumPhotoOnlyCoverContent` with fields `photoPath`, `title`, `dateLine` (all `String`); hand-written `==`/`hashCode`; dartdoc on class and each field. Satisfies R7.

- [x] **T4.2** Create `lib/src/api/album_before_you_start_content.dart` — `@immutable AlbumBeforeYouStartContent` with optional `titleOverride`/`bodyOverride`. Hand-written `==`/`hashCode`; dartdoc. Satisfies R7.

- [x] **T4.3** Create `lib/src/api/album_welcome_journey_content.dart` — `@immutable AlbumWelcomeJourneyContent` with optional `titleOverride`/`bodyOverride`. Hand-written `==`/`hashCode`; dartdoc. Satisfies R7.

- [x] **T4.4** Create `lib/src/api/album_qr_spread_content.dart` — `enum AlbumQrSpreadPlacement { opening, closing }` and `@immutable AlbumQrSpreadContent` with `qrPayload`, `placement`, optional `captionOverride`. Hand-written `==`/`hashCode` (placement-sensitive). Dartdoc. Satisfies R7.

- [x] **T4.5** Create `lib/src/api/album_eventos_closing_content.dart` — `@immutable AlbumEventosClosingContent` with optional `photoPath`, required `title`, `signature1`, `signature2`. Hand-written `==`/`hashCode`; dartdoc. Satisfies R7.

- [x] **T4.6** Create `lib/src/api/album_boda_cover_content.dart` — `@immutable AlbumBodaCoverContent` stub placeholder with optional `title`/`dateLine`; dartdoc noting fields are TBD in Task 6. Hand-written `==`/`hashCode`. Satisfies R7, R8.

- [x] **T4.7** Add tests to `test/api/album_content_classes_test.dart` (create file) — GREEN immediately:
  - `AlbumPhotoOnlyCoverContent — equal instances satisfy == and share hashCode`
  - `AlbumBeforeYouStartContent — equal instances satisfy == and share hashCode`
  - `AlbumWelcomeJourneyContent — equal instances satisfy == and share hashCode`
  - `AlbumQrSpreadContent — opening and closing placements are not equal`
  - `AlbumQrSpreadContent — identical instances satisfy == and share hashCode`
  - `AlbumEventosClosingContent — equal instances satisfy == and share hashCode`
  - `AlbumBodaCoverContent — equal instances satisfy == and share hashCode`
  Satisfies R7.

---

### Phase 5 — Factory Stub Signatures (call-time `UnimplementedError` in PR 1; render-time in PR 2)

- [x] **T5.1** Modify `lib/src/config/dots_template.dart` — add seven named factory constructors to `DotsAlbumSpreadPage`, each with a call-time `throw UnimplementedError('PR 2: <name> stub not wired')` body as the temporary PR 1 placeholder. The final PR 2 body uses `DotsUnimplementedElement` (not yet created). Factory signatures exactly per the design Interfaces section:
  - `DotsAlbumSpreadPage.photoOnlyCover({required int pageNumber, required AlbumPhotoOnlyCoverContent content})`
  - `DotsAlbumSpreadPage.beforeYouStart({required int pageNumber, required String contextLabelValue, required AlbumBeforeYouStartContent content})`
  - `DotsAlbumSpreadPage.welcomeJourney({required int pageNumber, required String contextLabelValue, required AlbumWelcomeJourneyContent content})`
  - `DotsAlbumSpreadPage.openingQrSpread({required int pageNumber, required String contextLabelValue, required AlbumQrSpreadContent content})`
  - `DotsAlbumSpreadPage.closingQrSpread({required int pageNumber, required String contextLabelValue, required AlbumQrSpreadContent content})`
  - `DotsAlbumSpreadPage.bodaCover({required int pageNumber, required AlbumBodaCoverContent content})`
  - `DotsAlbumSpreadPage.eventosClosing({required int pageNumber, required String contextLabelValue, required AlbumEventosClosingContent content})`
  Add dartdoc on each factory and each parameter. Add required imports for the six content-class files. Satisfies R7, R8.

- [x] **T5.2** Create `test/config/album_spread_stubs_test.dart` — write one test per stub factory; each test is RED in PR 1 (guards with `fail('PR 2: stub render-time throw not wired')`). Test names must match the acceptance list:
  - `DotsAlbumSpreadPage.photoOnlyCover — throws UnimplementedError with Task 4 message`
  - `DotsAlbumSpreadPage.beforeYouStart — throws UnimplementedError with Task 4 message`
  - `DotsAlbumSpreadPage.welcomeJourney — throws UnimplementedError with Task 5 message`
  - `DotsAlbumSpreadPage.openingQrSpread — throws UnimplementedError with Task 5 message`
  - `DotsAlbumSpreadPage.closingQrSpread — throws UnimplementedError with Task 5 message`
  - `DotsAlbumSpreadPage.bodaCover — throws UnimplementedError with Task 6 boda-deferred message`
  - `DotsAlbumSpreadPage.eventosClosing — throws UnimplementedError with Task 7 message`
  - `DotsTemplate boda — render fails with UnimplementedError at bodaCover containing Task 6`
  Satisfies R7, R8 (RED scaffold for PR 2).

---

### Phase 6 — Public Exports (GREEN in PR 1)

- [x] **T6.1** Modify `lib/dots_pdf.dart` — add `show` exports for all six new content classes: `AlbumPhotoOnlyCoverContent`, `AlbumBeforeYouStartContent`, `AlbumWelcomeJourneyContent`, `AlbumQrSpreadContent`, `AlbumEventosClosingContent`, `AlbumBodaCoverContent`. Also export `AlbumQrSpreadPlacement`. `DotsAlbumType.generalEventos` is available transitively via the existing bare `export 'src/api/dots_album_type.dart'`. The seven new factory stubs are reachable via the existing `export 'src/config/dots_template.dart'`. Add a smoke-import test to `test/api/album_content_classes_test.dart` asserting no compile errors:
  - `lib/dots_pdf.dart — all new content classes and factory stubs are exported`
  Satisfies R7.

---

### Phase 7 — PR 1 RED Tests for Injection and Validation (intentional RED)

- [x] **T7.1** Add tests to `test/config/dots_template_parser_test.dart` — each uses `fail('PR 2: injection not wired')`. Test names from the acceptance list:
  - `DotsTemplateParser — parejas: 2 body pliegos → 7 total pliegos`
  - `DotsTemplateParser — generalEventos: 1 body pliego → 7 total pliegos`
  - `DotsTemplateParser — all categories: pliegos renumbered from 1 contiguously`
  - `DotsTemplateParser — body pliegoNumber in JSON is overwritten by injection position`
  - `DotsTemplateParser — body pliegoNumber below category minimum emits diagnostic`
  Satisfies R5 (RED scaffold).

- [x] **T7.2** Add mandatory-slot validation tests to `test/config/dots_template_parser_test.dart` — each uses `fail('PR 2: categoryInputs validation not wired')`. Test names from the acceptance list:
  - `DotsTemplateParser — missing dedication.body throws DotsConfigException at $.categoryInputs.dedication.body`
  - `DotsTemplateParser — missing photoArc.photoPaths throws DotsConfigException at $.categoryInputs.photoArc.photoPaths`
  - `DotsTemplateParser — wrong-type photoArc.photoPaths throws DotsConfigException at $.categoryInputs.photoArc.photoPaths`
  - `DotsTemplateParser — complete parejas categoryInputs passes validation`
  - `DotsTemplateParser — missing closingQr.qrPayload throws DotsConfigException at $.categoryInputs.closingQr.qrPayload`
  - `DotsTemplateParser — boda category parses without error`
  Satisfies R6, R8 (RED scaffold).

---

### Phase 8 — PR 1 Verification

- [x] **T8.1** Run `flutter analyze` — must be clean. Confirm zero `public_member_api_docs` violations on all new public symbols. Confirm no missing exhaustive-switch arms (this is the moment to catch any switch site beyond the three confirmed in the design; see Risk section).

- [x] **T8.2** Run `flutter test` — pre-existing tests GREEN after T2.2 migration. Enum and model tests (T1.4, T2.3) GREEN. Parser scaffold tests (T3.2) GREEN. Content-class equality tests (T4.7) GREEN. Export smoke test (T6.1) GREEN. RED tests (T5.2, T7.1, T7.2) compile and fail with intentional `fail('PR 2: …')` messages — not unexpected errors.

**PR 1 ships here.** Open PR targeting `pliego-first-category` tracker branch. Do NOT merge until PR 2 is green.

---

## PR 2 — DotsUnimplementedElement, Renderer Arms, Injection, Validation, GREEN Tests

**Branch**: `pliego-first-category-pr2` (off `pliego-first-category-pr1`)
**Goal**: Land `DotsUnimplementedElement`, add it to all five exhaustive switch sites, replace PR 1 factory stub bodies with the proper `DotsUnimplementedElement` pattern, implement `_parseCategoryInputs` + `_injectCategoryMandatoryPliegos` + `_renumberContiguously` + `_blankAlbumSpread`, and turn every RED test GREEN.
**Verification**: `flutter analyze` clean. `flutter test` fully GREEN including all previously-RED tests. Confirm injection counts and renumbering for all six categories manually.
**Rollback**: Revert PR 2 commits; PR 1 state is intact.
**Commit shape**: `feat(render): wire DotsUnimplementedElement and category injection`

---

### Phase 9 — DotsUnimplementedElement Sealed Variant

- [x] **T9.1** Modify `lib/src/config/dots_template.dart` — add `@immutable final class DotsUnimplementedElement extends DotsElement` with `taskTag` and `factoryName` fields; hand-written `==`/`hashCode`; dartdoc. The constructor must pass `x: 0, y: 0` to `super` (required by `DotsElement`). Satisfies R7 design decision.

- [x] **T9.2** Add `DotsUnimplementedElement` to every exhaustive `switch (element)` site. The design identifies five confirmed sites — add the arm to each, in this order:
  1. `lib/src/render/dots_renderer.dart` — preload loop `switch (element)` in `preloadAssetBytes`, `DotsElementsPage` branch (line ~40): `case DotsUnimplementedElement(): break;` (no asset path to collect).
  2. `lib/src/render/dots_renderer.dart` — preload loop `switch (element)` in `preloadAssetBytes`, `DotsAlbumSpreadPage` branch (line ~80): `case DotsUnimplementedElement(): break;`.
  3. `lib/src/render/dots_renderer.dart` — `_buildElement` switch at line ~443: `case DotsUnimplementedElement(): throw UnimplementedError('${element.taskTag}: ${element.factoryName} body not yet implemented');`
  4. `lib/src/render/album_spread_page.dart` — `_buildElement` function switch at line ~224: render-time throw with same message.
  5. `lib/src/render/isolate_synthesis.dart` — `_buildElement` switch at line ~289: render-time throw with same message.
  Run `flutter analyze --fatal-warnings` after each file edit to confirm no remaining missing-arm errors. Satisfies R7, R8.

- [x] **T9.3** Replace the PR 1 temporary `throw UnimplementedError('PR 2: …')` factory bodies in `lib/src/config/dots_template.dart` with the proper `DotsAlbumSpreadPage(pageNumber: pageNumber, header: ..., footer: ..., elements: [DotsUnimplementedElement(taskTag: '...', factoryName: '...')])` pattern per the design Interfaces section. Task tags and factory names per spec R7 table:
  - `photoOnlyCover` → `taskTag: 'Task 4'`
  - `beforeYouStart` → `taskTag: 'Task 4'`
  - `welcomeJourney` → `taskTag: 'Task 5'`
  - `openingQrSpread` → `taskTag: 'Task 5'`
  - `closingQrSpread` → `taskTag: 'Task 5'`
  - `bodaCover` → `taskTag: 'Task 6'`, `factoryName: 'bodaCover (deferred per album-type series)'`
  - `eventosClosing` → `taskTag: 'Task 7'`
  Satisfies R7, R8.

---

### Phase 10 — Parser: `categoryInputs` Validation

- [x] **T10.1** Modify `lib/src/config/dots_template_parser.dart` — add private records `_CategoryInputsParejas`, `_CategoryInputsHijos`, `_CategoryInputsIndividuales`, `_CategoryInputsOtros`, `_CategoryInputsBoda`, `_CategoryInputsGeneralEventos` (or a sealed `_CategoryInputs` hierarchy). Each carries only the fields its category needs.

- [x] **T10.2** Implement `_parseCategoryInputs(Map json, String pointer, DotsAlbumType category)` — switches on `category`, reads the `categoryInputs` sub-object, and calls per-category parsing helpers. Each helper reads the mandatory sub-objects (`cover`, `dedication`, `photoArc`, `closingQr`, `closing`, `bodaCluster`, `bodaHalo`, `openingQr`, `eventosClosing`) and throws `DotsConfigException` with the precise `$.categoryInputs.X.Y` pointer for any missing or wrong-type field. Mandatory field matrix per spec R6 table (e.g. parejas: `cover.title`, `cover.dateLine`, `dedication.title`, `dedication.body`, `dedication.signature`, `photoArc.photoPaths` (array, not string), `closingQr.qrPayload`, `closing.title`, `closing.subtitle`; boda: no dedication; generalEventos: `openingQr.qrPayload`, `closingQr.qrPayload`, `eventosClosing.title`, etc.). Satisfies R6.

- [x] **T10.3** Wire `_parseCategoryInputs` into `parseMap` — call it with the `categoryInputs` sub-map before parsing `pliegos`. Satisfies R6.

---

### Phase 11 — Parser: Injection, Renumbering, and Diagnostic

- [x] **T11.1** Add `_blankAlbumSpread({required int pageNumber, required String? contextLabel})` private helper to `DotsTemplateParser` — returns an empty-elements `DotsAlbumSpreadPage` with placeholder chrome (wordmark `''`, no header numbers). Satisfies design packing convention.

- [x] **T11.2** Implement `_injectCategoryMandatoryPliegos({required DotsAlbumType category, required _CategoryInputs inputs, required List<DotsPliego> userBodyPliegos})` — constructs the `[...initial, ...userBody, ...final]` list using the per-category mandatory pliego inventory from the design. Per-category mandatory pliegos (pageNumber placeholder `0` before renumbering):
  - **parejas/hijos**: initial: `cover + beforeYouStart [STUB]`; `blank + dedication`; `blank + photoArc`; final: `closingQrSpread [STUB] + blank`; `blank + closing`.
  - **individuales/otros**: initial: `photoOnlyCover [STUB] + beforeYouStart [STUB]`; `blank + dedication`; `blank + polaroidCollage` (otros: `applyOtrosGradient: true`); final: same closing shape.
  - **boda**: initial: `bodaCover [STUB] + blank`; `blank + blank` (intentional — spec R5 "pliego 2 empty/blank"); `bodaCluster + bodaHalo`; final: same closing shape. NOTE: apply phase must verify that "boda pliego 2 blank" is correct per the templates — design notes this as confirmed but calls it out for verification.
  - **generalEventos**: initial: `openingQrSpread [STUB] + photoOnlyCover [STUB]`; `blank + welcomeJourney [STUB]`; `beforeYouStart [STUB] + blank`; `blank + blank` (body entry spread); final: `closingQrSpread [STUB] + blank`; `blank + eventosClosing [STUB]`.
  Satisfies R5.

- [x] **T11.3** Implement `_renumberContiguously(List<DotsPliego> pliegos)` — returns an unmodifiable list where each pliego's `pliegoNumber` is `i + 1`. Satisfies R5.

- [x] **T11.4** Modify `_parsePliego` call site in `parseMap` — add the below-minimum-pliegoNumber diagnostic: if a parsed body pliego's `pliegoNumber` is less than the category's `firstBodyNumber` (4 for most, 5 for `generalEventos`), throw `DotsConfigException` with a message explaining the injection convention. Satisfies R5.

- [x] **T11.5** Wire `_injectCategoryMandatoryPliegos` and `_renumberContiguously` into `parseMap` — replace the direct `DotsTemplate(pliegos: bodyPliegos)` call with injection + renumber result. Satisfies R5.

---

### Phase 12 — Turn All RED Tests GREEN

- [x] **T12.1** Replace all `fail('PR 2: injection not wired')` guards in `test/config/dots_template_parser_test.dart` (T7.1) with real assertions. Verify: parejas 2-body → 7 total; generalEventos 1-body → 7 total; contiguous renumber; body `pliegoNumber: 99` overwritten; body `pliegoNumber: 1` on parejas throws diagnostic. Satisfies R5.

- [x] **T12.2** Replace all `fail('PR 2: categoryInputs validation not wired')` guards in `test/config/dots_template_parser_test.dart` (T7.2) with real assertions. Satisfies R6.

- [x] **T12.3** Replace all `fail('PR 2: stub render-time throw not wired')` guards in `test/config/album_spread_stubs_test.dart` (T5.2) with real assertions: construct the stub, check `page.elements.single is DotsUnimplementedElement`, then call a render helper that exercises the element switch and verify `UnimplementedError` is thrown containing the correct task tag and factory name. Satisfies R7, R8.

---

### Phase 13 — PR 2 Verification

- [x] **T13.1** Run `flutter analyze` — must be clean. Zero missing exhaustive-switch arms. Zero `public_member_api_docs` violations. Confirm the five switch sites all have `DotsUnimplementedElement` arms.

- [x] **T13.2** Run `flutter test` — ALL tests GREEN. Confirm test names match the spec acceptance list exactly. Confirm pre-existing tests (240+) still pass. Confirm no fixture accidentally uses a `pliegoNumber: 1` body pliego that trips the new below-minimum diagnostic (spot-check was flagged in T2.2; fix any such fixtures now).

**PR 2 ships here.** Merge PR 2 into `pliego-first-category-pr1` branch. Then merge PR 1 (feature) into the `pliego-first-category` tracker branch. Tracker merges to main when Tasks 3+ are ready.

---

## Dependency Graph

```
T1.1 → T1.2 → T1.3          (enum must precede switch-arm updates)
T1.4 → T8.2                  (enum test; GREEN in PR 1)
T2.1 → T2.2 → T2.3           (model rename before fixture migration)
T3.1 → T3.2                  (parser scaffold before parser tests)
T4.1–T4.6 (independent, parallel)
T4.7 → T6.1 → T8.2           (content class tests need exports)
T5.1 → T5.2                  (factory sigs before stub tests)
T7.1, T7.2 (independent RED tests — can be written in parallel)
T8.1 after T1.3, T2.1, T3.1, T5.1, T6.1
T8.2 after T8.1

PR 2:
T9.1 → T9.2 → T9.3           (element variant before renderer arms before factory bodies)
T10.1 → T10.2 → T10.3        (record types before parser helpers before wiring)
T11.1 → T11.2 → T11.5        (blank helper before injection helper before wiring)
T11.3 → T11.5
T11.4 (can parallel with T11.1–T11.3 once T3.1 is done)
T12.1–T12.3 after T9.3, T11.5
T13.1 after T12.1–T12.3
T13.2 after T13.1
```

---

## Risks

| Risk | Task(s) | Mitigation |
|------|---------|------------|
| Additional exhaustive-switch sites beyond the three confirmed in the design | T1.3 | Run `flutter analyze --fatal-warnings` immediately after adding `generalEventos`; fix every site before PR 1 ships. Record any extras discovered. |
| Five `switch (element)` sites for `DotsUnimplementedElement` — one missed site crashes at run time, not compile time | T9.2 | Add arm file-by-file and run `flutter analyze` after each file to get compile-time coverage; the exhaustive-switch enforcement is the verification surface. |
| Boda pliego 2 "blank" may not be correct | T11.2 | Apply phase must re-read `docs/templates/final_templates/pdf06_boda_*.pdf` (page 3/4) to confirm the double-blank intent before committing the boda initial pliegos. Flag for the apply executor. |
| Pre-existing fixtures using `pliegoNumber: 1` on a body pliego may trip the new below-minimum diagnostic | T2.2, T13.2 | Spot-check all 58 migrated `pages:` fixture sites during T2.2; verify no body pliegos declare `pliegoNumber` below 4 (5 for generalEventos). Fix proactively; confirm in T13.2. |
| `DotsTemplate.pages` removal breaks 14 test files (58 occurrences) — large migration scope | T2.2 | All migrations happen atomically in T2.2; the compile error from field removal surfaces every site. Run `flutter analyze` immediately after T2.1 to get the full list before writing migrations. |
| `categoryInputs` validation coverage gap — a required field is omitted from the R6 matrix and slips to render time | T10.2 | Implement validation tests (T7.2) before implementation (T10.2); the RED-first discipline catches specification gaps before code gaps. |

---

## Requirement Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| R1 — Pliego-only JSON contract | T3.1, T3.2 |
| R2 — `category` field with six values and default | T3.1, T3.2 |
| R3 — `DotsAlbumType.generalEventos` enum value | T1.1, T1.2, T1.3, T1.4 |
| R4 — `DotsTemplate` model rename and field removal | T2.1, T2.2, T2.3 |
| R5 — Mandatory-pliego injection and renumbering | T7.1, T11.1, T11.2, T11.3, T11.4, T11.5, T12.1 |
| R6 — `categoryInputs` JSON object and mandatory-slot validation | T7.2, T10.1, T10.2, T10.3, T12.2 |
| R7 — Stub factory signatures and content classes | T4.1–T4.7, T5.1, T5.2, T6.1, T9.1, T9.3, T12.3 |
| R8 — Boda cover deferred; boda parses but does not render | T5.1, T5.2, T9.2, T9.3, T12.3 |
