# album-type-foundation Specification

## Purpose

Wires `DotsAlbumType` into the configuration plumbing. Adds optional
template-level `albumType` field, parse-time variable substitution for
`DotsTextElement` values, a pure context-label resolver, and a first-class
structural header/footer concept for album-spread pages.

---

## Requirements

### Requirement: R1 — albumType field on DotsTemplate

`DotsTemplate` MUST expose a nullable `albumType` field of type
`DotsAlbumType?`. The field MUST default to `null`. Its presence MUST NOT
affect any existing field or computed property on `DotsTemplate`.

#### Scenario: albumType present in JSON

- GIVEN a template JSON containing `"albumType": "boda"`
- WHEN `DotsTemplateParser.parseMap` is called
- THEN the returned `DotsTemplate.albumType` equals `DotsAlbumType.boda`

#### Scenario: albumType absent from JSON

- GIVEN a template JSON with no `albumType` key
- WHEN `DotsTemplateParser.parseMap` is called
- THEN the returned `DotsTemplate.albumType` is `null`

#### Scenario: albumType round-trip for every enum value

- GIVEN a template JSON containing `"albumType"` set to each of the strings
  `"boda"`, `"parejas"`, `"hijos"`, `"individuales"`, `"otros"`
- WHEN `DotsTemplateParser.parseMap` is called for each
- THEN the returned `albumType` equals the corresponding `DotsAlbumType` value

#### Scenario: unknown albumType string raises exception

- GIVEN a template JSON containing `"albumType": "quinceañera"`
- WHEN `DotsTemplateParser.parseMap` is called
- THEN a `DotsConfigException` is thrown
- AND `DotsConfigException.pointer` contains `$.albumType`
- AND `DotsConfigException.message` contains the offending value `"quinceañera"`

#### Scenario: albumType participates in contentHash

- GIVEN two otherwise-identical templates where one has `albumType: "boda"`
  and the other has no `albumType`
- WHEN `contentHash` is read on each
- THEN the two hash values differ

---

### Requirement: R2 — Variable substitution at parse time

`DotsTemplateParser.parse` and `parseMap` MUST accept an optional
`Map<String, String> variables` parameter (default `const {}`). Before
constructing any `DotsTextElement`, the parser MUST substitute every key in
`variables` with its value inside the raw text string. Substitution MUST be
applied per-element and MUST NOT span element boundaries. Unrecognized tokens
(keys absent from `variables`) MUST be left as literal text. No warning or
error is emitted for unmatched tokens.

Documented token identifiers (reserved for caller use):
`{NombreDelAlbum}`, `{Protagonistas}`, `{tiempojuntos}`, `{Año}`,
`{DiadeMesdeAñodeFechaDeInicio}`, `{TítuloDelAlbum}`, `{nombre firma}`,
`{Nombre}`, `{NOMBRE PROTAS}`.

#### Scenario: single token substituted

- GIVEN a template with a text element `"value": "Hola {Nombre}"`
- AND `variables` map `{"{Nombre}": "María"}`
- WHEN the template is parsed
- THEN the resulting `DotsTextElement.value` equals `"Hola María"`

#### Scenario: multiple tokens in one element substituted

- GIVEN a text element `"value": "{Protagonistas} — {Año}"`
- AND `variables` `{"{Protagonistas}": "Ana y Luis", "{Año}": "2024"}`
- WHEN the template is parsed
- THEN `DotsTextElement.value` equals `"Ana y Luis — 2024"`

#### Scenario: unmatched token left intact

- GIVEN a text element `"value": "Album de {Nombre}"`
- AND `variables` is `const {}` (empty map)
- WHEN the template is parsed
- THEN `DotsTextElement.value` equals `"Album de {Nombre}"` unchanged

#### Scenario: empty variables map is a no-op

- GIVEN any template that parses successfully today (no `albumType`, no variables)
- WHEN parsed with `variables: const {}`
- THEN all `DotsTextElement.value` fields are identical to those produced
  without the `variables` parameter

#### Scenario: substitution does not cross element boundaries

- GIVEN two adjacent text elements, first with value `"prefix {Tok"` and
  second with value `"en} suffix"`
- AND `variables` containing `"{Token}"`
- WHEN the template is parsed
- THEN neither element's value is modified (the token spans elements, so
  no substitution occurs in either)

#### Scenario: NOMBREHIJO token treated like any other token

- GIVEN a text element `"value": "Para {NOMBREHIJO}"`
- AND `variables` `{"{NOMBREHIJO}": "Sofía"}`
- WHEN the template is parsed
- THEN `DotsTextElement.value` equals `"Para Sofía"`

---

### Requirement: R3 — Context-label resolver

A pure function (or equivalent static accessor) MUST exist that maps a
`DotsAlbumType` value to the token name string used as the right-page
top-center album-spread header label. The mapping MUST be:

| `DotsAlbumType` | Returned token |
|-----------------|----------------|
| `boda`          | `{Protagonistas}` |
| `hijos`         | `{Protagonistas}` |
| `parejas`       | `{tiempojuntos}` |
| `individuales`  | `{Año}` |
| `otros`         | `{Año}` |

The function MUST be exhaustive — all 5 enum values MUST be covered and
MUST return a non-null, non-empty string.

#### Scenario: boda → Protagonistas

- GIVEN `DotsAlbumType.boda`
- WHEN the context-label resolver is called
- THEN it returns `"{Protagonistas}"`

#### Scenario: parejas → tiempojuntos

- GIVEN `DotsAlbumType.parejas`
- WHEN the context-label resolver is called
- THEN it returns `"{tiempojuntos}"`

#### Scenario: hijos → Protagonistas

- GIVEN `DotsAlbumType.hijos`
- WHEN the context-label resolver is called
- THEN it returns `"{Protagonistas}"`

#### Scenario: individuales → Año

- GIVEN `DotsAlbumType.individuales`
- WHEN the context-label resolver is called
- THEN it returns `"{Año}"`

#### Scenario: outros → Año

- GIVEN `DotsAlbumType.otros`
- WHEN the context-label resolver is called
- THEN it returns `"{Año}"`

---

### Requirement: R4 — Structural header/footer concept

The page model MUST provide a first-class structural concept for album-spread
pages that allows a page to declare:

- A left-side page number position
- A right-side page number position
- A top-center context label position
- A bottom-center wordmark position ("Dots. Memories")

The concrete shape (new page subtype vs. optional fields on an existing page
type) is determined by design. This spec requires only that the CONCEPT
be representable in the typed page model — any album-spread page MUST be able
to carry all four positions. Renderer support for drawing these positions is
out of scope for slice 1.

#### Scenario: album-spread page can declare all four header/footer positions

- GIVEN an album-spread page model instance (whatever concrete type the
  design introduces)
- WHEN it is constructed with a left page number, right page number, context
  label, and wordmark
- THEN all four values are accessible from the model without loss

---

### Requirement: R5 — Backwards compatibility

Existing templates that contain neither `albumType` nor any variable tokens
MUST parse identically before and after this slice. The `variables` parameter
defaults to `const {}`, and omitting `albumType` from JSON yields `null` with
no error. Existing test fixtures MUST continue to pass without modification.

#### Scenario: template without albumType parses unchanged

- GIVEN any existing test fixture JSON (no `albumType` key)
- WHEN parsed with the updated parser
- THEN the result equals the result produced by the previous parser
- AND no exception is thrown

#### Scenario: template without variables map parses unchanged

- GIVEN any existing test fixture JSON with text elements containing literal
  strings (no variable tokens)
- WHEN `parseMap` is called without the `variables` argument
- THEN every `DotsTextElement.value` is identical to its JSON source string

---

### Requirement: R6 — Public API export

Any new public symbol introduced by this slice (context-label resolver,
new page concept type, or enum-adjacent utility) MUST be re-exported from
`lib/dots_pdf.dart`.

---

## Acceptance Test List

The following tests MUST exist in `test/` to satisfy this spec:

- `DotsTemplateParser — parses albumType "boda" correctly`
- `DotsTemplateParser — parses albumType "parejas" correctly`
- `DotsTemplateParser — parses albumType "hijos" correctly`
- `DotsTemplateParser — parses albumType "individuales" correctly`
- `DotsTemplateParser — parses albumType "otros" correctly`
- `DotsTemplateParser — albumType absent yields null`
- `DotsTemplateParser — unknown albumType raises DotsConfigException at $.albumType`
- `DotsTemplateParser — albumType participates in contentHash`
- `DotsTemplateParser — variable substitution replaces single token in text element`
- `DotsTemplateParser — variable substitution replaces multiple tokens in one element`
- `DotsTemplateParser — unmatched token left as literal text`
- `DotsTemplateParser — empty variables map is a no-op`
- `DotsTemplateParser — substitution does not cross element boundaries`
- `DotsTemplateParser — NOMBREHIJO substituted like any other token`
- `DotsAlbumType contextLabel — boda returns {Protagonistas}`
- `DotsAlbumType contextLabel — parejas returns {tiempojuntos}`
- `DotsAlbumType contextLabel — hijos returns {Protagonistas}`
- `DotsAlbumType contextLabel — individuales returns {Año}`
- `DotsAlbumType contextLabel — outros returns {Año}`
- `DotsAlbumType contextLabel — exhaustive (all enum values covered)`
- `album-spread page — can be constructed with all four header/footer positions`
- `DotsTemplateParser — existing fixture parses unchanged after slice (backwards compat)`
