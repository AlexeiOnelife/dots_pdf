# Design: album-type-foundation

## Technical Approach

Slice 1 is a strictly additive plumbing slice: thread `DotsAlbumType` through `DotsTemplate`, accept a `variables` map at parse time so `DotsTextElement.value` is rendered with tokens resolved, introduce a sibling `DotsAlbumSpreadPage` subtype that carries first-class structural `header`/`footer` data (renderer support deferred to slice 2), and expose a per-type context-label resolver as an extension on the enum. Existing templates (no `albumType`, no `{token}` text, no album-spread page) continue to parse and render byte-identically.

## Architecture Decisions

### Decision Q1: Page model — new sibling subtype `DotsAlbumSpreadPage`

| Option | Pro | Con |
|---|---|---|
| A. New sibling subtype `DotsAlbumSpreadPage` (**chosen**) | Matches existing flat sealed hierarchy (`DotsPage` has 2 siblings; `DotsElement` has 3). Dispatch in `buildPage` adds one `case`. Specialized fields stay off the base. | Slice 2-5 spread variety must be encoded inside this single subtype. |
| B. Optional `header`/`footer` on `DotsPage` base | Any future page could opt in. | Pollutes the cover-free base; `DotsLayoutPage` does not need it; null-checks everywhere. |
| C. Wrapper `DotsHeaderedPage { header, footer, inner }` | Orthogonal concern isolation. | Extra nesting; breaks the flat dispatch idiom; renderer dispatch becomes two-level. |

**Rationale**: option A matches the library's existing sealed-class idiom. Spread variety (dedication, instructions, polaroid…) is absorbed inside the subtype by giving it a `List<DotsElement> elements` body — the SAME primitive `DotsElementsPage` already uses. Slices 2-5 add new `DotsElement` subtypes (rotation, decorative shapes, polaroid frames) instead of new `DotsPage` subtypes. Header/footer becomes a small fixed struct, not an open hierarchy.

### Decision Q2: Context-label resolver — extension on `DotsAlbumType`

| Option | Pro | Con |
|---|---|---|
| Top-level function `contextLabelTokenFor(DotsAlbumType)` | Simple, easy to mock. | Does not match existing per-enum-value associated-data style. |
| Extension getter `albumType.contextLabelToken` (**chosen**) | Matches `extension DotsLayoutCodeRequirements on DotsLayoutCode` — identical idiom for the sibling enum `DotsLayoutCode`. | Slightly more boilerplate (extension wrapper). |

**Rationale**: `DotsLayoutCode` already exposes its per-value associated data as `code.requirements` via an extension (`lib/src/render/layout/dots_layout_requirements.dart:56`). The new `DotsAlbumType` resolver is the exact same shape — per-enum-value static lookup. Mirror it as `albumType.contextLabelToken` so callers see one consistent style across the public surface.

### Decision Q3: Substitution call site — per-token `String.replaceAll` loop

| Option | Pro | Con |
|---|---|---|
| Per-token loop: `for (final e in variables.entries) s = s.replaceAll(e.key, e.value)` (**chosen**) | Trivial, no regex escaping concerns (`{` `}` are regex metachars in some flavors), readable. | O(n*m) but n,m ≤ ~10. |
| Single compiled `RegExp` with alternation | One pass over the string. | Requires escaping curly braces, building the alternation pattern, choosing the right callback API; harder to read for zero perf gain. |

**Rationale**: performance is irrelevant at this scale (≤9 tokens, short text). Pick the path with fewer foot-guns. The loop is also stable under empty-map input (no allocations, no work).

### Decision: Substitution seam in the parser

The substitution happens at the **innermost site that constructs `DotsTextElement.value`** — inside `_parseElement` (the `case 'text':` branch). The `variables` map is threaded through `parseMap → _parsePage → _parseElementsPage → _parseElement` (and the layout-page caption path — see Open Questions). This mirrors the existing convention of threading the `at` JSON-pointer string through the same call chain.

**Not chosen**: post-processing the constructed `DotsTemplate` tree. That would require mutating immutable models or rebuilding them, and would also bypass the `DotsLayoutPage.captions` strings unless walked separately.

### Decision: Error semantics for unknown `albumType`

Unknown enum string raises `DotsConfigException` with `pointer: r'$.albumType'` and message:

    unknown albumType "{raw}" (expected one of: boda, parejas, hijos, individuales, otros)

Mirrors the existing `_decodeLayoutCode` error format (`lib/src/config/dots_template_parser.dart:329`).

## Data Flow

    JSON source                          variables map (caller)
         │                                       │
         ▼                                       ▼
    DotsTemplateParser.parse(source, variables: {...})
         │
         ▼
    parseMap ─── reads optional "albumType" → DotsAlbumType?
         │
         ├──→ _parsePage(json, at, variables)
         │         │
         │         ├──→ _parseElementsPage / _parseLayoutPage / _parseAlbumSpreadPage
         │         │         │
         │         │         ▼
         │         │     _parseElement(json, at, variables)
         │         │         │
         │         │         ▼  case 'text':
         │         │     value = _substitute(_requireString('value'), variables)
         │         │         │
         │         │         ▼
         │         │     DotsTextElement(value: value, …)
         │
         ▼
    DotsTemplate(albumType: …, pages/pliegos: …)

At render time (slice 2+), the renderer reads `template.albumType` and uses `template.albumType?.contextLabelToken` to populate the top-center label on right pages of `DotsAlbumSpreadPage`.

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/api/dots_album_type.dart` | Modify | Add `extension DotsAlbumTypeContext on DotsAlbumType { String get contextLabelToken; }` returning the token name per the SPECS table (boda/hijos → `{Protagonistas}`, parejas → `{tiempojuntos}`, individuales/otros → `{Año}`). |
| `lib/src/config/dots_template.dart` | Modify | (a) Add `final DotsAlbumType? albumType` to `DotsTemplate` constructor + equality + `contentHash`. (b) Add new sibling subtype `DotsAlbumSpreadPage extends DotsPage` with fields: `pageNumber`, `header` (`DotsSpreadHeader` value object), `footer` (`DotsSpreadFooter` value object), `elements: List<DotsElement>`. (c) Add the two small value objects: `DotsSpreadHeader { String? leftPageNumber; String? centerLabel; String? rightPageNumber; }` and `DotsSpreadFooter { String wordmark; }` — both `@immutable`, all fields are resolved strings (substitution already applied at parse time). |
| `lib/src/config/dots_template_parser.dart` | Modify | (a) Add `variables` param to `parse` / `parseMap` (default `const {}`). (b) Parse optional `albumType` JSON field, decode via `DotsAlbumType.values.byName` wrapped in try/catch → `DotsConfigException`. (c) Thread `variables` through `_parsePage`/`_parseElement`. (d) Add private `_substitute(String, Map<String,String>)` helper. (e) Add `case 'albumSpread':` in `_parsePage` dispatch when JSON has a `header` / `footer` object (exact JSON shape: `{ "pageNumber": N, "type": "albumSpread", "header": {...}, "footer": {...}, "elements": [...] }`). |
| `lib/dots_pdf.dart` | Modify | No new exports needed: `DotsAlbumType` is already exported; the extension lives in the same file and rides along; `DotsTemplate`, `DotsPage`, and any new sibling subtype are already re-exported via `dots_template.dart`. |
| `test/config/dots_template_parser_test.dart` | Modify/new cases | Add tests: (1) round-trip `albumType` for each enum value, (2) unknown `albumType` raises with pointer `$.albumType`, (3) variable substitution applies to text-element `value` when supplied, (4) absent `variables` leaves tokens literal, (5) `NOMBREHIJO` convention round-trip (caller maps it), (6) backwards-compat: existing fixture without `albumType` parses unchanged. |
| `test/api/dots_album_type_test.dart` | New | Unit test the resolver returns the right token name for every enum value. |

## Interfaces / Contracts

```dart
// lib/src/api/dots_album_type.dart
extension DotsAlbumTypeContext on DotsAlbumType {
  /// Token name to render in the top-center of right-page headers
  /// on album-spread pages. The caller's variable map must map
  /// this token to a concrete string at parse time.
  String get contextLabelToken => switch (this) {
        DotsAlbumType.boda || DotsAlbumType.hijos => '{Protagonistas}',
        DotsAlbumType.parejas => '{tiempojuntos}',
        DotsAlbumType.individuales || DotsAlbumType.otros => '{Año}',
      };
}

// lib/src/config/dots_template.dart
@immutable
class DotsSpreadHeader {
  const DotsSpreadHeader({this.leftPageNumber, this.centerLabel, this.rightPageNumber});
  final String? leftPageNumber;
  final String? centerLabel;
  final String? rightPageNumber;
  // == and hashCode follow existing pattern in the file.
}

@immutable
class DotsSpreadFooter {
  const DotsSpreadFooter({required this.wordmark});
  final String wordmark; // e.g. "Dots. Memories"
}

class DotsAlbumSpreadPage extends DotsPage {
  const DotsAlbumSpreadPage({
    required super.pageNumber,
    required this.header,
    required this.footer,
    this.elements = const <DotsElement>[],
  });
  final DotsSpreadHeader header;
  final DotsSpreadFooter footer;
  final List<DotsElement> elements;
}

// lib/src/config/dots_template.dart (DotsTemplate constructor)
const DotsTemplate({
  required this.documentId,
  required this.pageSize,
  this.albumType,          // ← new, nullable
  this.pages = _emptyPages,
  this.pliegos = _emptyPliegos,
});
final DotsAlbumType? albumType;

// lib/src/config/dots_template_parser.dart
DotsTemplate parse(String source, {Map<String, String> variables = const {}});
DotsTemplate parseMap(Map<String, dynamic> json, {Map<String, String> variables = const {}});
```

Documented token set (in dartdoc on `parse` / `parseMap`):
`{NombreDelAlbum}`, `{Protagonistas}`, `{tiempojuntos}`, `{Año}`, `{DiadeMesdeAñodeFechaDeInicio}`, `{TítuloDelAlbum}`, `{nombre firma}`, `{Nombre}`, `{NOMBRE PROTAS}`. Also document the `{NOMBREHIJO}` convention: callers building `individuales` map it to the `{Nombre}` value; `otros` callers map it to the `{Protagonistas}` value.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit (parser) | albumType round-trip per enum value; unknown value error; substitution applied to `DotsTextElement.value`; empty map leaves tokens literal; existing fixtures unchanged | `DotsTemplateParser().parse(..., variables: {...})` over inline JSON strings; `expect` on the typed tree. |
| Unit (resolver) | Every `DotsAlbumType` value returns the correct token name | Parameterised `test` over enum values. |
| Unit (model) | `DotsAlbumSpreadPage` equality + `DotsSpreadHeader`/`Footer` equality | Mirror existing `==` / `hashCode` tests for `DotsLayoutPage`. |
| Integration | None this slice — renderer support for `DotsAlbumSpreadPage` is deferred to slice 2. | Add a top-of-file note in `dots_renderer.dart` ONLY if the `switch` over `DotsPage` becomes non-exhaustive at compile time (see Open Questions). |

## Migration / Rollout

No migration. All fields nullable / default. Existing templates parse byte-identically. Rollback = revert commits.

## Open Questions

- [x] **Renderer exhaustiveness**: adding `DotsAlbumSpreadPage` makes the `switch (page)` in `DotsRenderer.buildPage` (line 258) non-exhaustive. Slice 1 MUST either (a) add a `case DotsAlbumSpreadPage():` that throws `UnimplementedError('album spread rendering lands in slice 2')` to keep the switch exhaustive, or (b) add it and leave the page rendering blank with a logger warning. Chosen: option (a) — explicit `UnimplementedError`. This keeps `dart analyze` clean and gives a precise failure message if a template author tries to render an album spread before slice 2 lands.
- [x] **`preloadAssetBytes`** in `dots_renderer.dart:25` also switches on `DotsPage`. Same exhaustiveness issue. Chosen: add a `case DotsAlbumSpreadPage():` that walks `page.elements` with the same body the `DotsElementsPage` arm uses (image asset paths only — no decorative shapes exist yet in slice 1).
- [x] **JSON discriminator for the new page type**: chosen as `"type": "albumSpread"` inside the page object (existing pages use `"layout"` vs `"elements"` *key presence* as discriminator, not a `type` field). To stay consistent with the existing convention, the alternative is "page has `header` key" → albumSpread. Chosen: `type: "albumSpread"` route because spread pages do not always need `header` (cover-adjacent intros), and key-presence dispatch starts to mis-fire when slices 2-5 add variants.
