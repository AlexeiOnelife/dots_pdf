# Proposal: pliego-first-category

## Intent

The final templates (`docs/templates/final_templates/pdf02–pdf13`) establish that
**every dotbook is composed of a fixed front/back matter set selected by category,
wrapped around author-supplied body pliegos.** Today the library leaves that
composition entirely to the caller: `DotsTemplateParser` accepts `pages` OR
`pliegos` as two mutually-exclusive top-level arrays (XOR enforced at
`lib/src/config/dots_template_parser.dart:111–124`), `albumType` is a loose
optional hint (`dots_template_parser.dart:91–109`), and callers must hand-compose
covers, dedications, photo-arcs, polaroid collages, boda spreads, and closings via
the public `buildAlbumSpreadPage` family. There is **no** mandatory-page injection
anywhere in parsing and **no** category-aware validation.

In addition, the templates introduce a new sixth category — **`generalEventos`**
(`pdf12_eventos_general_inicial.pdf` / `pdf13_eventos_general_final.pdf`) — that
does not map to any existing `DotsAlbumType` value (`lib/src/api/dots_album_type.dart:33–56`).

This change is **task 2 of the 7-task `final-render-refinement` series**, building
on the just-archived task 1 (`page-template-chrome`, chrome primitive now wired via
`DotsTemplate.defaultChrome` at `dots_template.dart:2010`). Task 2 is the
**architectural shift** that the four following tasks (4–7) need: pliego-only
JSON, a `category` field that drives front/back matter, parse-time validation of
mandatory-slot inputs, and stub signatures for the new per-category factories.
Tasks 4–7 fill in the rendering geometry of those new factories — Task 2 does
NOT.

**Success looks like:** JSON requires `pliegos` and `category`; the parser injects
the category-specific mandatory initial and final pliegos around the author body;
mandatory-slot inputs are validated at parse time with precise `$.pointer`
diagnostics; `DotsAlbumType` has six values including `generalEventos`; existing
factories (`dedication`, `closing`, `photoArc`, `polaroidCollage`, `bodaCluster`,
`bodaHalo`, `cover(parejas|hijos)`) are wired where they match the category;
**new** factories ship as compiling stubs with precise signatures + content
classes — bodies land in Tasks 4–7. `contentHash` includes `category`.

## Scope

### In Scope

- **JSON contract becomes pliego-only.** Remove the `pages` branch from
  `parseMap` (`dots_template_parser.dart:147–164`). JSON without `pliegos` is a
  `DotsConfigException` at `$`. The XOR check (lines 111–124) collapses into a
  single "missing `pliegos`" check.
- **New JSON field `category`** (string, optional, default `generalEventos`).
  Replaces `albumType` as the JSON-facing field name. Values:
  `parejas`, `hijos`, `individuales`, `otros`, `boda`, `generalEventos`. Unknown
  values throw `DotsConfigException` at `$.category` listing the allowed set.
- **`DotsAlbumType.generalEventos`** enum value added
  (`lib/src/api/dots_album_type.dart`). Every exhaustive switch without a
  wildcard arm gets a new arm: `contextLabelToken` (line 19),
  `closing.titleFontSize`, `photoArc.defaultLeftCaption`, and any other switch
  surfaced by `dart analyze`. `cover.defaultEyebrow` (`dots_template.dart:1468`)
  already throws `ArgumentError` for non-parejas/hijos via its wildcard arm —
  that stays correct, since `generalEventos` does not use the circles cover.
- **Dart field rename: `DotsTemplate.albumType` → `DotsTemplate.category`.** See
  Decision 2 below for justification.
- **Parser injects mandatory pliegos** (Approach A from the explore). After
  parsing the author body pliegos, the parser **prepends** the category's
  initial pliegos and **appends** the final pliegos, then re-numbers the entire
  flat list left-to-right. The renderer is untouched.
- **Mandatory-slot validation at parse time.** Each category's mandatory pliegos
  declare which fields they need (cover title, dedication body, signature, photo
  paths per spread, QR payload, etc.). Missing or wrong-type inputs throw
  `DotsConfigException` with the precise `$.pointer` (e.g.
  `$.category.dedication.body`).
- **Existing factories wired** where they match the category:
  `DotsAlbumSpreadPage.dedication` (all but boda),
  `.closing` (all six, including a generalEventos arm that calls the existing
  `.closing` for now and is upgraded in Task 7),
  `.photoArc` (parejas, hijos, individuales, otros — already supported),
  `.polaroidCollage` (individuales, otros),
  `.bodaCluster` and `.bodaHalo` (boda),
  `.cover` (parejas, hijos).
- **New factories STUBBED** with precise signatures + immutable content classes,
  bodies = `throw UnimplementedError('TaskN: <factory>')`. Each stub compiles,
  the parser can call it with the right inputs, and Tasks 4–7 replace the body.
  The stubs (with task targets):
    - `DotsAlbumSpreadPage.photoOnlyCover({...})` — Task 4 (individuales, otros, generalEventos).
    - `DotsAlbumSpreadPage.beforeYouStart({...})` — Task 4 ("Busca un lugar tranquilo / Más allá del papel" instruction spread; shared by 5 categories).
    - `DotsAlbumSpreadPage.welcomeJourney({...})` — Task 5 ("Bienvenido/a a tu viaje al pasado" — generalEventos only).
    - `DotsAlbumSpreadPage.openingQrSpread({...})` — Task 5 (generalEventos opening, QR left + circles right).
    - `DotsAlbumSpreadPage.closingQrSpread({...})` — Task 5 ("Porque algunos recuerdos merecen seguir vivos" — shared closing for all six categories).
    - `DotsAlbumSpreadPage.bodaCover({...})` — Task 6 (boda cover — deferred per project memory; stub throws with a "deferred" message).
    - `DotsAlbumSpreadPage.eventosClosing({...})` — Task 7 (generalEventos closing variant with photo + title + dual signature).
- **New content classes** (immutable, dartdoc'd, exported via `lib/dots_pdf.dart`):
  `AlbumPhotoOnlyCoverContent`, `AlbumBeforeYouStartContent`,
  `AlbumWelcomeJourneyContent`, `AlbumQrSpreadContent` (reused for opening and
  closing — `placement: opening|closing`), `AlbumEventosClosingContent`.
- **`DotsTemplate.contentHash`** (`dots_template.dart:2073–2080`) includes
  `category` (replacing the now-renamed `albumType` slot).
- **`DotsTemplate.pages` Dart field — REMOVED.** See Decision 4.
- **`lib/dots_pdf.dart` exports** updated for new public symbols.
- **Tests**: per strict-TDD, RED tests ship in PR 1 across parser, album-type
  enum exhaustiveness, mandatory-slot validation, and category injection;
  GREEN in PR 2.

### Out of Scope (explicit — deferred to Tasks 4–7)

- **Rendering geometry of the 7 new factories.** Coordinates from
  `final_templates/pdf04–pdf13` land per-category in Tasks 4–7. The Task 2 stubs
  throw `UnimplementedError` until then.
- **Boda cover layout.** Project memory marks boda p.1/p.2/p.5 as deferred from
  the album-type series; `DotsAlbumSpreadPage.bodaCover` ships as a stub that
  throws a clear "boda cover deferred — see Task 6" message until Task 6
  picks it up.
- **`applyOtrosGradient` polaroid overlay refinements.** Existing flag
  (`album_collage_content.dart:35`, `polaroid_slot_position.dart:46`) keeps its
  current behavior. Refinements (if any) belong to Task 4 polaroid work.
- **Caller-side migration tooling.** Removing JSON `pages` is breaking for
  consumers; we do not provide a JSON migrator. Pre-1.0 contract change — see
  Decision 1.
- **Custom mandatory-page overrides.** Categories cannot opt out of their
  mandatory pliegos; that is the entire point of category injection. No "skip"
  flag.
- **Page-number user overrides.** With injection, body pliegos receive their
  pliego number from their position post-injection; any
  `pliegoNumber` in the author-supplied JSON for a body pliego is **ignored**
  by the renumberer (it remains required by the parser for shape, but is
  overwritten). See Decision 6.

## Capabilities

> Researched `openspec/specs/` — the directory is empty (no per-capability
> specs exist yet). All entries below are new.

### New Capabilities

- `template-category`: the category field on JSON templates, the
  `DotsAlbumType.generalEventos` enum value, the `category → DotsAlbumType`
  resolution rule, and the default-when-omitted policy.
- `mandatory-pliego-injection`: the parser-side mechanism that prepends initial
  pliegos and appends final pliegos per category, the renumbering convention,
  and the per-category mandatory pliego inventory.
- `mandatory-slot-validation`: the parse-time validation surface — which fields
  each category requires for each mandatory pliego, the `$.pointer` taxonomy,
  and the `DotsConfigException` contract.
- `category-factory-stubs`: the public stub signatures + immutable content
  classes for the seven NEW factories (`photoOnlyCover`, `beforeYouStart`,
  `welcomeJourney`, `openingQrSpread`, `closingQrSpread`, `bodaCover`,
  `eventosClosing`) — bodies deferred to Tasks 4–7.

### Modified Capabilities

- None. No per-capability specs exist in `openspec/specs/` yet, so there is
  nothing to delta against.

## Approach

**Approach A from the explore (parser-time injection).** Confirmed.

The parser:
1. Reads `documentId`, `pageSize`, **`category`** (replacing `albumType` as the
   JSON key — but resolving to a `DotsAlbumType` value internally).
2. Requires `pliegos` (the old `pages` branch is deleted).
3. Parses the author's body pliegos into a `List<DotsPliego>`.
4. Reads a `category` object whose nested shape carries the mandatory-slot
   inputs (cover title, dedication body, signature, photo paths, QR payload,
   etc. — see "JSON shape (high level)" below).
5. **Validates** every mandatory-slot field for the resolved category, throwing
   `DotsConfigException` with the precise `$.pointer` for any missing/wrong-type
   input.
6. **Builds** the category's initial pliegos and final pliegos from those
   inputs, calling the existing or stubbed factories.
7. **Concatenates** `[...initial, ...body, ...final]`, **renumbers** them so the
   first pliego is `pliegoNumber: 1` and pliego numbers are contiguous, and
   constructs `DotsTemplate(pliegos: …)`.

The renderer is unchanged: `DotsTemplate.effectivePages`
(`dots_template.dart:2057–2067`) already flattens any flat `pliegos` list into
pages. The new mandatory pliegos look identical to user-authored pliegos at the
model level.

**Why Approach A and not B (new `DotsPliego` variant):** B forces the sealed
hierarchy to grow, every exhaustive switch over `DotsPliego` needs new arms,
the renderer learns about "mandatory vs body" pages, and validation splits
between parser and runtime. A keeps the model flat, the renderer untouched, and
validation centralized in the parser. The trade-off — mandatory pages are not
distinguishable in the model at runtime — does not matter for Task 2's
deliverables: we never need to tell user-pliego from mandatory-pliego after
parsing, because chrome and rendering are uniform thanks to Task 1.

### JSON shape (high level — exhaustive in the spec phase)

```json
{
  "documentId": "...",
  "pageSize": { ... },
  "category": "parejas",
  "categoryInputs": {
    "cover":      { "title": "...", "dateLine": "..." },
    "dedication": { "title": "...", "body": "...", "signature": "..." },
    "photoArc":   { "photoPaths": ["...", ...] },
    "closingQr":  { "qrPayload": "..." },
    "closing":    { "photoPath": "...", "title": "...", "subtitle": "..." }
  },
  "pliegos": [ /* body pliegos */ ]
}
```

The nested-per-spread shape is preferred over flat keys because it keeps the
JSON pointer diagnostics readable (`$.categoryInputs.dedication.body`) and
matches how the parser walks the structure. Per category, only the relevant
sub-objects are required. The spec phase enumerates every (category × pliego ×
field) requirement.

### Page numbering convention

With mandatory initial pliegos prepended and final pliegos appended,
**body pliegos start at pliego N** where N depends on category:

| Category        | Initial pliegos | First body pliego # | Final pliegos |
|-----------------|-----------------|---------------------|---------------|
| parejas         | 3               | 4                   | 2             |
| hijos           | 3               | 4                   | 2             |
| individuales    | 3               | 4                   | 2             |
| otros           | 3               | 4                   | 2             |
| boda            | 3               | 4                   | 2             |
| generalEventos  | 4               | 5                   | 2             |

The parser **always renumbers** the concatenated list contiguously starting at
1; any `pliegoNumber` value in author-supplied body pliegos is preserved as
the parser still requires the field for shape validity, but the final
`DotsPliego.pliegoNumber` value is reassigned during concatenation. This is the
only honest convention: with auto-injection, user-chosen numbers cannot survive
without divergence between JSON and rendered output.

### Public API delta

**New:**
- `DotsAlbumType.generalEventos` (`lib/src/api/dots_album_type.dart`).
- `DotsAlbumSpreadPage.photoOnlyCover(...)` — stub (Task 4).
- `DotsAlbumSpreadPage.beforeYouStart(...)` — stub (Task 4).
- `DotsAlbumSpreadPage.welcomeJourney(...)` — stub (Task 5).
- `DotsAlbumSpreadPage.openingQrSpread(...)` — stub (Task 5).
- `DotsAlbumSpreadPage.closingQrSpread(...)` — stub (Task 5).
- `DotsAlbumSpreadPage.bodaCover(...)` — stub (Task 6, deferred message).
- `DotsAlbumSpreadPage.eventosClosing(...)` — stub (Task 7).
- `AlbumPhotoOnlyCoverContent`, `AlbumBeforeYouStartContent`,
  `AlbumWelcomeJourneyContent`, `AlbumQrSpreadContent`,
  `AlbumEventosClosingContent` — immutable content classes,
  hand-written `==`/`hashCode`, dartdoc'd, exported from `lib/dots_pdf.dart`.

**Modified:**
- `DotsTemplate.albumType` → renamed to `DotsTemplate.category`
  (`dots_template.dart:2031`). Non-nullable. Defaults to
  `DotsAlbumType.generalEventos` when JSON omits the field.
- `DotsTemplate.contentHash` swaps `albumType` for `category`.
- `DotsTemplateParser.parseMap` — pliego-only, mandatory injection, mandatory-slot
  validation.

**Removed:**
- `DotsTemplate.pages` field (Dart-side). Pliego-only model end-to-end.
- `_emptyPages` sentinel and the assert that uses it (constructor simplifies).
- `effectivePages` keeps its name and semantics but its `if (pliegos.isEmpty)
  return pages;` branch is deleted — it now always flattens pliegos.
- JSON `pages` key — `DotsConfigException` if present.
- JSON `albumType` key — `DotsConfigException` if present, with a hint to use
  `category` instead (one-release courtesy diagnostic; the field itself is
  gone).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/api/dots_album_type.dart` | Modified | Add `generalEventos`; add `contextLabelToken` arm (`{Protagonistas}` — see Decision 3). |
| `lib/src/config/dots_template.dart` | Modified | Rename `albumType` → `category`; default to `generalEventos`; remove `pages` field and `_emptyPages`; simplify constructor; update `contentHash`; add 7 new factory stubs on `DotsAlbumSpreadPage`. |
| `lib/src/config/dots_template_parser.dart` | Modified | Delete `pages` branch (lines 147–164); parse `category` (replacing `albumType`); parse `categoryInputs` object; validate mandatory-slot inputs; inject initial + final pliegos; renumber. |
| `lib/src/api/album_*_content.dart` (new files) | New | 5 immutable content classes for the new stub factories. |
| `lib/dots_pdf.dart` | Modified | Export `DotsAlbumType.generalEventos` (transitive), new factory stubs, and new content classes. |
| `lib/src/config/dots_pliego.dart` | Unchanged | Approach A leaves the sealed hierarchy alone. |
| `lib/src/render/dots_renderer.dart` | Unchanged | Approach A leaves the renderer alone. |
| `test/config/dots_template_parser_test.dart` | Modified + new tests | Drop `pages` JSON tests; add `category` parsing tests, `categoryInputs` validation tests (one per (category × field) missing case), injection tests (count + order + numbering). |
| `test/api/dots_album_type_test.dart` | New / extended | `generalEventos` value present; `contextLabelToken` arm; exhaustive switch coverage. |
| `test/config/dots_template_test.dart` | Modified | `contentHash` differs when category differs; constructor no longer accepts `pages`. |

## Breaking Changes

1. **JSON `pages` key removed.** Templates that used the page-level JSON path
   no longer parse. Hard-removal — see Decision 1.
2. **JSON `albumType` key removed**; replaced by `category` (broader name to
   accommodate the new `generalEventos` value, which is an "event type", not an
   "album type"). The parser emits a precise `DotsConfigException` when
   `albumType` is present, suggesting `category`.
3. **`DotsAlbumType.generalEventos` added.** Downstream code with exhaustive
   switches that lack wildcard arms must add a new arm. Internal switches are
   covered in this change.
4. **`DotsTemplate.albumType` Dart field renamed to `category`.** Downstream
   code that reads the field must be updated.
5. **`DotsTemplate.pages` Dart field removed.** Programmatic callers that built
   templates with `pages: [...]` must switch to `pliegos: [...]`. See
   Decision 4.
6. **`category` is non-nullable; defaults to `generalEventos`** when omitted
   from JSON. Templates that previously omitted `albumType` (and got `null`)
   now get a concrete category and the parser injects mandatory pliegos. This
   IS a behavior change for callers who relied on null-album-type semantics.

## Decisions (the 6 the brief required + a 7th tie-up)

1. **`pages` JSON removal — HARD.** Immediate removal, no soft-deprecate. The
   library is pre-1.0; the category injection itself is already a hard breaking
   change (templates without the new `categoryInputs` will fail), so layering a
   soft-deprecate on the `pages` key would only add carry-over branches to
   delete next release. The parser emits a precise `DotsConfigException` at
   `$.pages` saying "use `pliegos`" so the migration path is obvious.

2. **Dart field rename: `albumType` → `category`.** The JSON key is `category`;
   keeping the Dart field named `albumType` would create a permanent
   impedance mismatch in dartdoc, IDE autocomplete, and test setup. The
   single-rename diff is mechanical and `dart analyze` catches every consumer
   site at compile time. Worth the noisy diff to land a consistent vocabulary.
   *Internally*, the parser still resolves the string to a `DotsAlbumType`
   value — the *type* keeps its existing name because renaming the enum would
   touch far more code (the album-type series archive directory, every test).

3. **`generalEventos.contextLabelToken = '{Protagonistas}'`.** Verified by
   reading `final_templates/pdf12_eventos_general_inicial.pdf` and
   `pdf13_eventos_general_final.pdf`: the right-page top-center label uses the
   `{Protagonistas}` token, identical to `hijos`/`boda`. The existing
   `contextLabelToken` switch (`dots_album_type.dart:19–23`) already groups
   `hijos || boda` to `{Protagonistas}`; we add `generalEventos` to that arm.

4. **`DotsTemplate.pages` Dart field — REMOVED.** Three sub-options were on the
   table: keep silent, deprecate, remove. Remove wins for the same reason as
   Decision 1: pre-1.0, the cache-key change forces consumer updates anyway,
   and the field's only remaining role would be programmatic test fixtures.
   Test fixtures will be migrated to `pliegos: [DotsLayoutPliego(...)]` (a
   `DotsLayoutPliego` IS two pages — same expressive power, slightly more
   typing). The benefit: a single source of truth for "what a template
   contains", no more `effectivePages` branching, no more `identical(pages,
   _emptyPages)` assert.

5. **Mandatory-slot validation surface — nested `categoryInputs` object.** The
   JSON shape sketched in the Approach section groups mandatory inputs by
   spread (`cover`, `dedication`, `photoArc`, `closingQr`, `closing`, etc.)
   rather than flattening them onto the category. Rationale:
   - JSON pointer diagnostics stay readable
     (`$.categoryInputs.dedication.body`).
   - Adding a new mandatory spread (Tasks 4–7) is a nested addition, not a
     new top-level key.
   - The parser code mirrors the JSON structure 1:1 — easy to read, easy to
     test. The spec phase enumerates the exact required field set per category.

6. **Page numbering — auto-renumber, ignore body `pliegoNumber`.** Confirmed
   convention in the table above. parejas/hijos/individuales/otros/boda start
   their body at pliego 4 (3 initial + body + 2 final). generalEventos starts
   body at pliego 5 (4 initial + body + 2 final, per pdf12/pdf13). The parser
   renumbers `[...initial, ...body, ...final]` contiguously from 1; any
   `pliegoNumber` on body pliegos in the input JSON is overwritten. The parser
   still **requires** the field on body pliegos for shape validity (it's a
   required JSON field of the pliego object, not an optional one) but its
   value is ignored. The spec phase adds a clarifying error message if a body
   pliego's input `pliegoNumber` ≤ 3 (4 for generalEventos), to flag obvious
   author confusion.

7. **(Tie-up) Boda cover stays deferred.** The boda cover (`pdf06` p.1) was
   not rendered in the album-type series and project memory flags p.1/p.2/p.5
   for boda as deferred. `DotsAlbumSpreadPage.bodaCover` ships as a stub that
   throws `UnimplementedError('Task 6: boda cover — deferred per album-type
   series')`. The boda category parses, validates everything else, injects
   `bodaCluster` + `bodaHalo` + closings, and explodes loudly the moment a
   caller actually tries to render the cover. This is honest: parsing works,
   rendering fails fast at the deferred point.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **Hard JSON breaking change** (`pages` removal + `albumType` → `category`) lands at the same time as mandatory-injection — consumers face a multi-axis migration. | High (by design) | Parser emits explicit diagnostics at `$.pages` ("use `pliegos`") and `$.albumType` ("use `category`") so the migration path is mechanical. CHANGELOG and `archive-report` document every breaking change. |
| **Enum exhaustiveness cascade**: adding `generalEventos` triggers `dart analyze` errors at every non-wildcard switch. | Medium | We resolve every analyzer error during this change. `dart analyze --fatal-warnings` is part of the verify gate. Explore identified the affected switches; spec/design enumerate the full list. |
| **Stub factories accidentally render output** if a caller invokes them before Tasks 4–7. | Low | Each stub throws `UnimplementedError('TaskN: <name>')` — fail fast, loud message, task pointer for the migration. Parser does NOT call stubs during parsing for categories whose mandatory pliegos are stub-only (`generalEventos` opening, photoOnlyCover, etc.) — instead it parses the inputs and stores them in the content class; the throw happens at render time. This bounds the blast radius to "categories whose body factories are stubbed", not "any template with a stub". |
| **Mandatory-input validation incomplete** — a missing field slips through and crashes at render time instead of parse time. | Medium | One unit test per (category × pliego × required field) missing-case. The spec enumerates them; tasks-phase mechanically lists each. |
| **`DotsTemplate.pages` field removal breaks downstream tests.** | High (certain in our own test suite) | Migrate all internal fixtures to `pliegos: [DotsLayoutPliego(...)]` in PR 1 as part of the RED phase. External consumers get a one-release breaking entry in the CHANGELOG. |
| **Page-number user surprise**: a caller authoring `pliegoNumber: 1` on a body pliego does not see "1" in the output (it becomes 4 or 5). | Medium | Parser emits an informational error when `pliegoNumber` on a body pliego is below the category's first-body number, suggesting that body pliegos do not control the absolute number. |
| **Test budget**: explore flagged >400 LOC certain. With stubs (small), validation tests (many), and migration of `pages` fixtures, this is squarely a chained-PR change. | High | Tasks phase splits along the obvious boundary: PR 1 = enum + model + parser + RED tests; PR 2 = factory stubs + content classes + injection wiring + GREEN tests. See Size Estimate. |

## Rollback Plan

All changes ship as conventional commits on the `final-render-refinement`
branch. Rollback = `git revert` the slice commits. Specifically:

- The `DotsAlbumType.generalEventos` addition is the only revert-painful change
  (every internal switch arm reverts with it). It is mechanical.
- The parser changes are self-contained; reverting restores the old `pages`
  branch and the old `albumType` parsing.
- The model changes (rename + field removal) revert cleanly because the rename
  is mechanical and `pages` is restored with its sentinel.
- The new factory stubs and content classes are additive; reverting drops the
  files.

Cache invalidation happens automatically because `contentHash` changes (it
swaps `albumType` for `category`); no manual cache wipe required.

## Dependencies

- **Task 1 (`page-template-chrome`)** is archived as of 2026-05-28. Mandatory
  pages this change injects are `DotsAlbumSpreadPage` instances and
  automatically inherit Task 1's chrome via `DotsTemplate.defaultChrome` →
  `buildPageChrome` wiring. No additional chrome work needed.
- Tasks 4–7 depend on Task 2's factory stub signatures being stable; the spec
  phase locks them in.

## Success Criteria

- [ ] Public JSON requires `pliegos`. Templates without `pliegos` throw a
      precise `DotsConfigException` at `$`.
- [ ] Public JSON accepts `category` (one of six values). Defaults to
      `generalEventos` when omitted.
- [ ] Public JSON `pages` and `albumType` keys are removed; parser emits
      migration-pointing exceptions when they appear.
- [ ] `DotsAlbumType` has six values; `dart analyze --fatal-warnings` is clean.
- [ ] `DotsTemplate.category` is the non-nullable field; `albumType` and `pages`
      Dart fields no longer exist.
- [ ] Parser injects the per-category initial + final pliegos and renumbers
      contiguously; tests verify count, order, and numbering for every
      category.
- [ ] Mandatory-slot validation throws `DotsConfigException` with precise
      `$.pointer` for every required field; tests cover one missing-case per
      field per category.
- [ ] Seven NEW factory stubs compile, are exported from `lib/dots_pdf.dart`,
      throw `UnimplementedError('TaskN: <name>')`, and are reachable through
      the parser for their owning category.
- [ ] `DotsTemplate.contentHash` differs when `category` differs.
- [ ] `flutter analyze` and `flutter test` pass; new tests have RED → GREEN
      coverage in the chained PR pair.

## Size Estimate (for the Review Workload Guard)

Rough order-of-magnitude, before tasks decomposition:

- `DotsAlbumType.generalEventos` + switch-arm updates: ~30–50 LOC.
- 5 new content classes (with `==`/`hashCode`/dartdoc): ~250–350 LOC.
- 7 new factory stubs (signatures + `UnimplementedError` body + dartdoc):
  ~150–200 LOC.
- `DotsTemplate` rename + field removal + constructor simplification +
  `contentHash`: ~40–60 LOC (net).
- `DotsTemplateParser`: delete `pages` branch (~−25 LOC), add `category` +
  `categoryInputs` parsing + validation + injection + renumber: ~250–350 LOC.
- `lib/dots_pdf.dart` exports + dartdoc: ~20 LOC.
- Test migrations (remove `pages` fixtures): ~−50 to ~+50 LOC.
- New parser tests (validation matrix + injection): ~400–550 LOC.
- New album-type / model tests: ~80–120 LOC.

**Estimated total ≈ 1100–1600 LOC**, heavily test-skewed. This is **well above
the 400-line budget** — chained PRs are mandatory. Per project memory
(2-PR chained splits for >400 LOC), the obvious cut is:

- **PR 1 (RED + skeleton)**: enum + `DotsTemplate` rename + `pages` removal +
  parser scaffolding for `category` parsing + RED tests for all
  validation/injection cases + content class signatures with stub `==`. No
  injection logic yet, no factory stubs yet (they fail compile until PR 2 or
  ship as `throw UnimplementedError` from PR 1 — see tasks phase).
- **PR 2 (GREEN)**: factory stubs (the 7), full `categoryInputs` parsing,
  validation, injection, renumber, content class implementations, all tests
  green.

The tasks phase commits to the exact split — flagging here so the Review
Workload Guard can plan.
