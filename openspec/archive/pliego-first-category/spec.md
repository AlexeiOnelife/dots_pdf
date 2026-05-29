# pliego-first-category Specification

## Purpose

Establishes the pliego-only JSON contract, the `category` field with six values,
parser-time mandatory-pliego injection per category, parse-time mandatory-slot
validation, the `DotsAlbumType.generalEventos` enum value, seven new stub factory
signatures with immutable content classes, and the model renames/removals that
Tasks 4–7 build on.

**Breaking change status:** this is a multi-axis hard break (pre-1.0). No
backward compatibility is provided for JSON `pages`, JSON `albumType`, Dart
`DotsTemplate.pages`, or Dart `DotsTemplate.albumType`.

**Render status after Task 2:** NO category renders end-to-end. Every category
requires at least one stub factory body (Tasks 4–7). Tests assert that
construction/parsing succeed; render-time `UnimplementedError` from stub
factories is EXPECTED and covered by tests.

---

## Requirements

### Requirement: R1 — Pliego-only JSON contract

The parser MUST require the `pliegos` top-level key. JSON that contains `pages`
instead of or in addition to `pliegos` MUST throw `DotsConfigException`. The
`pages` → `pliegos` XOR logic (parser lines 111–124) MUST be replaced with a
single "missing `pliegos`" check.

| JSON state | Expected outcome |
|---|---|
| `pliegos` present, `pages` absent | Parses normally |
| `pages` present, `pliegos` absent | `DotsConfigException` at `$.pages` with hint "use `pliegos`" |
| Both present | `DotsConfigException` at `$` |
| Neither present | `DotsConfigException` at `$` |

#### Scenario: valid pliegos-only JSON parses

- GIVEN a JSON map with `pliegos` and no `pages` key
- WHEN `DotsTemplateParser.parseMap` is called
- THEN a `DotsTemplate` is returned with a non-empty `pliegos` list

#### Scenario: JSON with pages key throws

- GIVEN a JSON map containing a `pages` key (with or without `pliegos`)
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown referencing `$.pages`
- AND the message contains a migration hint pointing to `pliegos`

#### Scenario: JSON with neither key throws at root

- GIVEN a JSON map with neither `pages` nor `pliegos`
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown at pointer `$`

---

### Requirement: R2 — `category` JSON field with six values and default

The parser MUST accept `category` as a top-level string field with allowed values:
`parejas`, `hijos`, `individuales`, `otros`, `boda`, `generalEventos`. When
`category` is omitted, the parser MUST default to `generalEventos`. An unknown
value MUST throw `DotsConfigException` at `$.category` listing the allowed set.
JSON containing the legacy `albumType` key MUST throw `DotsConfigException` at
`$.albumType` with a hint to use `category`.

#### Scenario: omitted category defaults to generalEventos

- GIVEN a JSON map with `pliegos` and no `category` key
- WHEN `DotsTemplateParser.parseMap` is called
- THEN the returned `DotsTemplate.category` equals `DotsAlbumType.generalEventos`

#### Scenario: valid category value resolves correctly

- GIVEN a JSON map with `category: "parejas"`
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsTemplate.category` equals `DotsAlbumType.parejas`

#### Scenario: unknown category value throws

- GIVEN a JSON map with `category: "quinceañera"`
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown at `$.category`
- AND the message lists all six allowed values

#### Scenario: legacy albumType key throws with hint

- GIVEN a JSON map containing an `albumType` key
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown at `$.albumType`
- AND the message suggests using `category` instead

---

### Requirement: R3 — `DotsAlbumType.generalEventos` enum value

`DotsAlbumType` MUST declare a sixth value `generalEventos`. Every exhaustive
switch without a wildcard arm MUST add a `generalEventos` arm. `dart analyze
--fatal-warnings` MUST be clean after this change. Specifically:

| Switch location | New arm value |
|---|---|
| `DotsAlbumTypeContext.contextLabelToken` | `'{Protagonistas}'` (grouped with `boda` and `hijos`) |
| `closing.titleFontSize` switch | value per existing convention |
| `photoArc.defaultLeftCaption` switch | value per existing convention |

`cover.defaultEyebrow` uses a wildcard arm — no change required.

#### Scenario: generalEventos is a valid enum value

- GIVEN `DotsAlbumType.values`
- WHEN the list is inspected
- THEN `generalEventos` is present and the total count is six

#### Scenario: contextLabelToken for generalEventos is {Protagonistas}

- GIVEN `DotsAlbumType.generalEventos`
- WHEN `.contextLabelToken` is called
- THEN the result is `'{Protagonistas}'`

#### Scenario: dart analyze is clean

- GIVEN the updated source after adding `generalEventos`
- WHEN `dart analyze --fatal-warnings` is run
- THEN exit code is zero (no missing-arm errors, no warnings)

---

### Requirement: R4 — `DotsTemplate` model rename and field removal

`DotsTemplate.albumType` MUST be renamed to `DotsTemplate.category`. The field
MUST be non-nullable of type `DotsAlbumType`, defaulting to
`DotsAlbumType.generalEventos`. `DotsTemplate.pages` MUST be removed. The
`_emptyPages` sentinel and the XOR assert MUST be deleted. `effectivePages` MUST
always flatten `pliegos` (the `if (pliegos.isEmpty) return pages` branch is
deleted). `contentHash` MUST include `category` in place of `albumType` and MUST
NOT include `pages`.

#### Scenario: DotsTemplate constructor no longer accepts pages

- GIVEN source code that passes `pages: [...]` to the `DotsTemplate` constructor
- WHEN compiled
- THEN a compile-time error is produced (field does not exist)

#### Scenario: category field is non-nullable with default

- GIVEN a `DotsTemplate` constructed without supplying `category`
- WHEN `.category` is read
- THEN the value is `DotsAlbumType.generalEventos`

#### Scenario: category participates in contentHash

- GIVEN two `DotsTemplate` instances identical except for `category`
- WHEN `contentHash` is read on each
- THEN the two values differ

#### Scenario: effectivePages always flattens pliegos

- GIVEN a `DotsTemplate` with a non-empty `pliegos` list
- WHEN `effectivePages` is called
- THEN it returns the flattened page list without checking for a `pages` field

---

### Requirement: R5 — Mandatory-pliego injection and renumbering

After parsing the author body pliegos, the parser MUST prepend the category's
initial pliegos and append the final pliegos, then renumber the entire
concatenated list contiguously from `pliegoNumber: 1`. Author-supplied
`pliegoNumber` values on body pliegos are overwritten. The parser MUST still
require the `pliegoNumber` field on body pliego JSON objects for shape validity.

**Mandatory pliego counts per category:**

| Category | Initial pliegos | First body pliego # | Final pliegos |
|---|---|---|---|
| parejas | 3 | 4 | 2 |
| hijos | 3 | 4 | 2 |
| individuales | 3 | 4 | 2 |
| otros | 3 | 4 | 2 |
| boda | 3 | 4 | 2 |
| generalEventos | 4 | 5 | 2 |

**Mandatory pliego sequence per category:**

| Category | Initial sequence | Final sequence |
|---|---|---|
| parejas | `cover(parejas)` → `beforeYouStart` [stub] → `dedication(parejas)` + `photoArc(parejas)` | `closingQrSpread` [stub] → `closing(parejas)` |
| hijos | `cover(hijos)` → `beforeYouStart` [stub] → `dedication(hijos)` + `photoArc(hijos)` | `closingQrSpread` [stub] → `closing(hijos)` |
| individuales | `photoOnlyCover` [stub] → `beforeYouStart` [stub] → `dedication(individuales)` + `polaroidCollage(individuales)` | `closingQrSpread` [stub] → `closing(individuales)` |
| otros | `photoOnlyCover` [stub] → `beforeYouStart` [stub] → `dedication(otros)` + `polaroidCollage(otros, gradient)` | `closingQrSpread` [stub] → `closing(otros)` |
| boda | `bodaCover` [stub, deferred] → (pliego 2 empty/blank) → `bodaCluster(boda)` + `bodaHalo(boda)` | `closingQrSpread` [stub] → `closing(boda)` |
| generalEventos | `openingQrSpread` [stub] → `photoOnlyCover` [stub] → `welcomeJourney` [stub] → `beforeYouStart` [stub] | `closingQrSpread` [stub] → `eventosClosing` [stub] |

#### Scenario: injection count is correct for parejas

- GIVEN a parejas template JSON with 2 body pliegos
- WHEN parsed
- THEN `DotsTemplate.pliegos.length` equals 7 (3 initial + 2 body + 2 final)

#### Scenario: injection count is correct for generalEventos

- GIVEN a generalEventos template JSON with 1 body pliego
- WHEN parsed
- THEN `DotsTemplate.pliegos.length` equals 7 (4 initial + 1 body + 2 final)

#### Scenario: pliegos are renumbered contiguously from 1

- GIVEN any category with N body pliegos
- WHEN parsed
- THEN `DotsTemplate.pliegos[i].pliegoNumber == i + 1` for every index `i`

#### Scenario: body pliegoNumber in JSON is overwritten

- GIVEN a body pliego JSON object with `pliegoNumber: 99`
- WHEN parsed with category `parejas`
- THEN that pliego's `pliegoNumber` in the model is 4 (first body slot), not 99

#### Scenario: parser warns when body pliegoNumber is below category minimum

- GIVEN a body pliego JSON with `pliegoNumber: 1` and `category: "parejas"`
- WHEN parsed
- THEN a `DotsConfigException` or diagnostic is emitted noting that body pliegos
  do not control their absolute number

---

### Requirement: R6 — `categoryInputs` JSON object and mandatory-slot validation

The parser MUST read a top-level `categoryInputs` object from JSON. Per category,
specific sub-objects and fields within `categoryInputs` are MANDATORY. Missing or
wrong-type fields MUST throw `DotsConfigException` with the precise `$.pointer`.

**Mandatory fields by category (required sub-objects and fields):**

| Category | Required categoryInputs sub-objects and fields |
|---|---|
| parejas | `cover.title`, `cover.dateLine`; `dedication.title`, `dedication.body`, `dedication.signature`; `photoArc.photoPaths` (array, 10 entries); `closingQr.qrPayload`; `closing.photoPath?`, `closing.title`, `closing.subtitle` |
| hijos | same as parejas |
| individuales | `cover.title`, `cover.dateLine`; `dedication.title`, `dedication.body`, `dedication.signature`; `polaroidCollage` (per `AlbumCollageContent` fields); `closingQr.qrPayload`; `closing.photoPath?`, `closing.title`, `closing.subtitle` |
| otros | same as individuales |
| boda | `dedication` N/A (boda skips dedication); `bodaCluster` (per `AlbumBodaClusterContent` — 7 photo paths); `bodaHalo` (per `AlbumBodaHaloContent` — 10 photo paths); `closingQr.qrPayload`; `closing.title` (fixed text, no subtitle for boda) |
| generalEventos | `cover.title`, `cover.dateLine`; `openingQr.qrPayload`; `closingQr.qrPayload`; `eventosClosing.photoPath?`, `eventosClosing.title`, `eventosClosing.signature1`, `eventosClosing.signature2` |

#### Scenario: missing mandatory field throws with precise pointer

- GIVEN a parejas JSON where `categoryInputs.dedication.body` is absent
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown with pointer `$.categoryInputs.dedication.body`

#### Scenario: missing photoArc.photoPaths throws

- GIVEN a parejas JSON where `categoryInputs.photoArc.photoPaths` is absent
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown with pointer `$.categoryInputs.photoArc.photoPaths`

#### Scenario: wrong-type field throws with precise pointer

- GIVEN a parejas JSON where `categoryInputs.photoArc.photoPaths` is a string
  instead of an array
- WHEN `DotsTemplateParser.parseMap` is called
- THEN `DotsConfigException` is thrown at `$.categoryInputs.photoArc.photoPaths`

#### Scenario: valid categoryInputs for parejas passes validation

- GIVEN a complete and correctly typed parejas `categoryInputs` object
- WHEN `DotsTemplateParser.parseMap` is called
- THEN no exception is thrown during input validation

---

### Requirement: R7 — Stub factory signatures and content classes

Seven new named constructors on `DotsAlbumSpreadPage` MUST be added. Each MUST
compile, have precise signatures, and throw `UnimplementedError('TaskN: <name>')`
at call time. Each MUST be paired with an immutable content class with hand-written
`==`/`hashCode` and dartdoc. All MUST be exported from `lib/dots_pdf.dart`.

| Factory | Stub message | Task | Content class |
|---|---|---|---|
| `DotsAlbumSpreadPage.photoOnlyCover(...)` | `'Task 4: photoOnlyCover'` | 4 | `AlbumPhotoOnlyCoverContent` |
| `DotsAlbumSpreadPage.beforeYouStart(...)` | `'Task 4: beforeYouStart'` | 4 | `AlbumBeforeYouStartContent` |
| `DotsAlbumSpreadPage.welcomeJourney(...)` | `'Task 5: welcomeJourney'` | 5 | `AlbumWelcomeJourneyContent` |
| `DotsAlbumSpreadPage.openingQrSpread(...)` | `'Task 5: openingQrSpread'` | 5 | `AlbumQrSpreadContent` |
| `DotsAlbumSpreadPage.closingQrSpread(...)` | `'Task 5: closingQrSpread'` | 5 | `AlbumQrSpreadContent` |
| `DotsAlbumSpreadPage.bodaCover(...)` | `'Task 6: boda cover — deferred per album-type series'` | 6 | _(boda-specific fields TBD in design)_ |
| `DotsAlbumSpreadPage.eventosClosing(...)` | `'Task 7: eventosClosing'` | 7 | `AlbumEventosClosingContent` |

`AlbumQrSpreadContent` is reused for both `openingQrSpread` and `closingQrSpread`
with a `placement` discriminator (`opening` | `closing`).

#### Scenario: stub factory throws UnimplementedError at call time

- GIVEN a call to any of the seven new named constructors with valid arguments
- WHEN the returned `DotsAlbumSpreadPage` is asked to render
- THEN `UnimplementedError` is thrown with a message identifying the task number
  and factory name

#### Scenario: stub factory compiles and is callable

- GIVEN source code that calls `DotsAlbumSpreadPage.photoOnlyCover(content: ...)`
  with the correct argument types
- WHEN the project is compiled
- THEN no compile-time error occurs

#### Scenario: content class equality works

- GIVEN two `AlbumPhotoOnlyCoverContent` instances with identical fields
- WHEN `==` is evaluated
- THEN the result is `true` and `hashCode` values match

#### Scenario: stub factories are exported

- GIVEN `lib/dots_pdf.dart`
- WHEN inspected for exports
- THEN all five new content classes and seven new factory names are accessible
  to consumers

---

### Requirement: R8 — Boda cover is deferred; boda category parses but does not render

`DotsAlbumSpreadPage.bodaCover` MUST ship as a stub per the project memory
decision to defer boda p.1/p.2/p.5. The boda category MUST pass `parseMap`
validation successfully. Attempting to render any boda template MUST fail with
`UnimplementedError` at the `bodaCover` render step, not at parse time.

#### Scenario: boda template parses without error

- GIVEN a complete boda JSON with all required `categoryInputs` fields
- WHEN `DotsTemplateParser.parseMap` is called
- THEN a `DotsTemplate` is returned with no exception

#### Scenario: boda render fails at bodaCover

- GIVEN a parsed boda `DotsTemplate`
- WHEN the renderer processes the first (cover) pliego
- THEN `UnimplementedError` is thrown with message containing `'Task 6'` and
  `'boda cover'`

---

## Out of Scope

The following MUST NOT be implemented in Task 2:

| Deferred item | Target task |
|---|---|
| `DotsAlbumSpreadPage.photoOnlyCover` render geometry | Task 4 |
| `DotsAlbumSpreadPage.beforeYouStart` render geometry | Task 4 |
| `applyOtrosGradient` polaroid overlay refinements | Task 4 |
| `DotsAlbumSpreadPage.welcomeJourney` render geometry | Task 5 |
| `DotsAlbumSpreadPage.openingQrSpread` render geometry | Task 5 |
| `DotsAlbumSpreadPage.closingQrSpread` render geometry | Task 5 |
| `DotsAlbumSpreadPage.bodaCover` render geometry | Task 6 |
| `DotsAlbumSpreadPage.eventosClosing` render geometry | Task 7 |
| Caller-side JSON migration tooling | Not planned |
| Custom mandatory-page overrides / skip flags | Not planned |
| Page-number user overrides | Not planned |

---

## Acceptance Test List

The following test names MUST exist in `test/` to satisfy this spec:

**Parser — pliego-only contract (R1)**
- `DotsTemplateParser — pliegos key parses successfully`
- `DotsTemplateParser — pages key throws DotsConfigException at $.pages with migration hint`
- `DotsTemplateParser — both keys throw DotsConfigException at $`
- `DotsTemplateParser — neither key throws DotsConfigException at $`

**Parser — category field (R2)**
- `DotsTemplateParser — omitted category defaults to generalEventos`
- `DotsTemplateParser — category "parejas" resolves to DotsAlbumType.parejas`
- `DotsTemplateParser — unknown category value throws DotsConfigException at $.category listing allowed values`
- `DotsTemplateParser — albumType key throws DotsConfigException at $.albumType with category hint`

**Enum (R3)**
- `DotsAlbumType — has exactly six values including generalEventos`
- `DotsAlbumType.generalEventos — contextLabelToken is {Protagonistas}`
- `DotsAlbumType — dart analyze --fatal-warnings is clean`

**Model (R4)**
- `DotsTemplate — pages field no longer exists (compile-time)`
- `DotsTemplate — category defaults to generalEventos`
- `DotsTemplate — category participates in contentHash`
- `DotsTemplate — effectivePages always flattens pliegos`

**Injection and renumbering (R5)**
- `DotsTemplateParser — parejas: 2 body pliegos → 7 total pliegos`
- `DotsTemplateParser — generalEventos: 1 body pliego → 7 total pliegos`
- `DotsTemplateParser — all categories: pliegos renumbered from 1 contiguously`
- `DotsTemplateParser — body pliegoNumber in JSON is overwritten by injection position`
- `DotsTemplateParser — body pliegoNumber below category minimum emits diagnostic`

**Mandatory-slot validation (R6)**
- `DotsTemplateParser — missing dedication.body throws DotsConfigException at $.categoryInputs.dedication.body`
- `DotsTemplateParser — missing photoArc.photoPaths throws DotsConfigException at $.categoryInputs.photoArc.photoPaths`
- `DotsTemplateParser — wrong-type photoArc.photoPaths throws DotsConfigException at $.categoryInputs.photoArc.photoPaths`
- `DotsTemplateParser — complete parejas categoryInputs passes validation`
- `DotsTemplateParser — missing closingQr.qrPayload throws DotsConfigException at $.categoryInputs.closingQr.qrPayload`

**Stubs and content classes (R7)**
- `DotsAlbumSpreadPage.photoOnlyCover — throws UnimplementedError with Task 4 message`
- `DotsAlbumSpreadPage.beforeYouStart — throws UnimplementedError with Task 4 message`
- `DotsAlbumSpreadPage.welcomeJourney — throws UnimplementedError with Task 5 message`
- `DotsAlbumSpreadPage.openingQrSpread — throws UnimplementedError with Task 5 message`
- `DotsAlbumSpreadPage.closingQrSpread — throws UnimplementedError with Task 5 message`
- `DotsAlbumSpreadPage.bodaCover — throws UnimplementedError with Task 6 boda-deferred message`
- `DotsAlbumSpreadPage.eventosClosing — throws UnimplementedError with Task 7 message`
- `AlbumPhotoOnlyCoverContent — equal instances satisfy == and share hashCode`
- `AlbumQrSpreadContent — opening and closing placements are not equal`
- `lib/dots_pdf.dart — all new content classes and factory stubs are exported`

**Boda deferral (R8)**
- `DotsTemplateParser — boda category parses without error`
- `DotsTemplate boda — render fails with UnimplementedError at bodaCover containing Task 6`
