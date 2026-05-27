# Tasks: album-type-foundation

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~350 (production ~150, tests ~200) |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Full slice 1 foundation | PR 1 | All tasks below in a single PR; ~350 lines stays under budget |

---

## Phase 1: Test Scaffolding (write failing tests first)

- [x] 1.1 Create `test/config/dots_template_album_type_test.dart` — failing tests for all 5 R1 scenarios: parse each enum value round-trip, absent `albumType` yields null, unknown string raises `DotsConfigException` at `$.albumType`, and `contentHash` differs when `albumType` differs. Reference spec scenarios in R1.
- [x] 1.2 Create `test/config/dots_template_variables_test.dart` — failing tests for all 6 R2 scenarios: single token, multiple tokens in one element, unmatched token left intact, empty map is no-op, substitution does not cross element boundaries, `{NOMBREHIJO}` treated like any token.
- [x] 1.3 Create `test/config/dots_album_spread_page_test.dart` — failing tests for R4: `DotsAlbumSpreadPage` can be constructed with all four header/footer positions and values are accessible without loss; equality and `hashCode` for `DotsSpreadHeader` and `DotsSpreadFooter`; JSON discriminator parses `"type": "albumSpread"` correctly; ambiguous page (explicit type AND legacy key) raises `DotsConfigException`.
- [x] 1.4 Create `test/api/dots_album_type_extension_test.dart` — failing tests for all 5 R3 scenarios: each `DotsAlbumType` value returns the correct token name; exhaustiveness (parameterised loop over `DotsAlbumType.values` confirms no value throws).
- [x] 1.5 Add backwards-compat group to `test/config/dots_template_parser_test.dart` — two failing tests for R5: existing fixture parses unchanged when `albumType` absent; existing fixture parses unchanged when `variables` omitted.

---

## Phase 2: Foundation Types

- [x] 2.1 Modify `lib/src/config/dots_template.dart` — add `@immutable class DotsSpreadHeader` with `String? leftPageNumber`, `String? centerLabel`, `String? rightPageNumber`; implement `==` and `hashCode` following the file's existing pattern.
- [x] 2.2 Modify `lib/src/config/dots_template.dart` — add `@immutable class DotsSpreadFooter` with `required String wordmark`; implement `==` and `hashCode`.
- [x] 2.3 Modify `lib/src/config/dots_template.dart` — add `class DotsAlbumSpreadPage extends DotsPage` with `required DotsSpreadHeader header`, `required DotsSpreadFooter footer`, `List<DotsElement> elements = const []`; implement `==` and `hashCode`.
- [x] 2.4 Modify `lib/src/config/dots_template.dart` — add `final DotsAlbumType? albumType` to `DotsTemplate` constructor (nullable, defaults to `null`); thread into `contentHash` as an additional `Object.hash` term; add import for `dots_album_type.dart`.

---

## Phase 3: Extension and Parser

- [x] 3.1 Modify `lib/src/api/dots_album_type.dart` — add `extension DotsAlbumTypeContext on DotsAlbumType` with getter `String get contextLabelToken` using an exhaustive `switch`: `boda`/`hijos` → `'{Protagonistas}'`, `parejas` → `'{tiempojuntos}'`, `individuales`/`otros` → `'{Año}'`.
- [x] 3.2 Modify `lib/src/config/dots_template_parser.dart` — add private `String _substitute(String raw, Map<String, String> variables)` helper: iterate `variables.entries` and apply `String.replaceAll`; return raw unchanged when map is empty.
- [x] 3.3 Modify `lib/src/config/dots_template_parser.dart` — add `Map<String, String> variables = const {}` parameter to `parse` and `parseMap`; in `parse` forward it to `parseMap`; update dartdoc to document all 9 reserved token names plus the `{NOMBREHIJO}` convention.
- [x] 3.4 Modify `lib/src/config/dots_template_parser.dart` — in `parseMap`, after reading `documentId`/`pageSize`, read the optional `albumType` JSON field; decode via `DotsAlbumType.values.byName` in a try/catch; throw `DotsConfigException(pointer: r'$.albumType', ...)` for unknown values mirroring the `_decodeLayoutCode` error format; pass the nullable result into `DotsTemplate(albumType: ...)`.
- [x] 3.5 Modify `lib/src/config/dots_template_parser.dart` — thread `variables` through `_parsePage` → `_parseElementsPage` → `_parseElement`; in `_parseElement`'s `case 'text':` branch, replace the raw `_requireString('value', …)` call with `_substitute(_requireString('value', …), variables)`.
- [x] 3.6 Modify `lib/src/config/dots_template_parser.dart` — add `_parseAlbumSpreadPage` private method: require `header` and `footer` objects, parse `DotsSpreadHeader` and `DotsSpreadFooter` from them, parse optional `elements` array (re-use existing element-parsing loop with `variables`), return `DotsAlbumSpreadPage`.
- [x] 3.7 Modify `lib/src/config/dots_template_parser.dart` — update `_parsePage` discriminator logic: first check `pageJson['type'] == 'albumSpread'` (new explicit discriminator); if true AND (`hasLayout` OR `hasElements`) throw `DotsConfigException` for ambiguous page; otherwise call `_parseAlbumSpreadPage`. Existing `hasLayout`/`hasElements` key-presence branches are unchanged.

---

## Phase 4: Renderer Exhaustiveness

- [x] 4.1 Modify `lib/src/render/dots_renderer.dart` — in `buildPage` (line 258) add `case DotsAlbumSpreadPage():` that throws `UnimplementedError('DotsAlbumSpreadPage rendering is part of slice 2 — not yet implemented')` to keep the `switch` exhaustive and `dart analyze` clean.
- [x] 4.2 Modify `lib/src/render/dots_renderer.dart` — in top-level `preloadAssetBytes` (lines 33-49), add `case DotsAlbumSpreadPage():` that walks `page.elements` with the same asset-collection body used for `DotsElementsPage` (handles `DotsImageElement` and `DotsSpreadImageElement` paths; ignores `DotsTextElement`).

---

## Phase 5: Exports and Verification

- [x] 5.1 Modify `lib/dots_pdf.dart` — verify `DotsAlbumSpreadPage`, `DotsSpreadHeader`, `DotsSpreadFooter`, and `DotsAlbumTypeContext` are reachable via existing barrel exports; add explicit re-exports only for symbols not already covered by `dots_template.dart` and `dots_album_type.dart` re-exports. Satisfies R6.
- [x] 5.2 Run `flutter test` — confirm all 208+ pre-existing tests pass and all new tests in phases 1-4 now pass (green).
- [x] 5.3 Run `flutter analyze` — confirm no new warnings beyond the pre-existing 6 `prefer_initializing_formals` entries.
- [x] 5.4 Backwards-compat smoke check — parse an existing fixture template (without `albumType`, without variable tokens) with the updated parser and assert output equals the previous parser's output; confirm no exception is thrown. (Covered by T1.5; this task records manual verification.)
