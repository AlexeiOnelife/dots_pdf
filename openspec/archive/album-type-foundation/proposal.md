# Proposal: album-type-foundation

## Intent

`DotsAlbumType` is publicly exported (`lib/dots_pdf.dart:9`) but has **zero references inside the rendering pipeline** — it is dead data. The library currently cannot produce per-album-type front/back-matter spreads because no part of the template tree, parser, or renderer knows the value exists.

This slice (1 of 5) wires the enum into the configuration plumbing and introduces two foundational primitives that every later slice depends on: **variable substitution at parse time** and a **first-class header/footer concept** on album-spread pages. No decorative work, no specific spreads — only the structural foundation.

Subsequent slices (2–5) will build dedication, instructions, "Antes de empezar", "Un año lleno de recuerdos", and closing spreads on top of this foundation.

## Scope

### In Scope

- Add `albumType: DotsAlbumType?` field to `DotsTemplate` — **optional/nullable** so existing templates parse unchanged.
- Extend `DotsTemplateParser.parse` / `parseMap` to read an optional top-level JSON `albumType` string and map it to the enum.
- Add `Map<String, String> variables` parameter (default `const {}`) to `DotsTemplateParser.parse` / `parseMap`. Before constructing any `DotsTextElement`, substitute the documented tokens via `String.replaceAll`.
- Documented token list: `{NombreDelAlbum}`, `{Protagonistas}`, `{tiempojuntos}`, `{Año}`, `{DiadeMesdeAñodeFechaDeInicio}`, `{TítuloDelAlbum}`, `{nombre firma}`, `{Nombre}`, `{NOMBRE PROTAS}`.
- Introduce a first-class **structural header/footer** concept for album-spread pages (top-left page number, top-center context label, top-right page number, bottom-center "Dots. Memories" wordmark — all Inter Semibold 7pt / 8.4pt). The exact shape (new page subtype vs. optional fields on `DotsPage`) is deferred to `sdd-design`; this proposal only commits that the concept becomes first-class.
- Per-album-type **context-label resolver**: a pure function mapping `DotsAlbumType` → token name to use as the right-page top-center label (`boda`/`hijos` → `{Protagonistas}`, `parejas` → `{tiempojuntos}`, `individuales`/`otros` → `{Año}`).

### Out of Scope

- Any decorative primitive (rotation, Gaussian fade, gradients, polaroid frames, photo arcs).
- Any specific album spread (dedication, instructions, "Antes de empezar…", "Un año lleno de recuerdos", closing).
- Changes to `DotsCoverTemplate` (this slice is body/interior only).
- Retrofitting body pages (`DotsLayoutPage`) to use the new header/footer — only album-spread pages built in slices 2+ will use it.
- Library-side enforcement of voice/wording (otros voice mix stays a template-author concern).

## Capabilities

### New Capabilities

- `album-type-foundation`: declares `DotsAlbumType` as a first-class template attribute, defines parse-time variable substitution, and introduces the per-album-spread structural header/footer trio plus the per-type context-label resolver.

### Modified Capabilities

- None at the spec level. `DotsTemplate` and `DotsTemplateParser` gain additive fields/parameters that do not change existing requirements; the new behavior is fully captured by the new capability above.

## Approach

1. **Enum wiring**: add `final DotsAlbumType? albumType` to `DotsTemplate` constructor; thread through `parseMap` as an optional field. Unknown enum strings raise `DotsConfigException` pointing at `$.albumType`.
2. **Variable substitution**: add `Map<String, String> variables = const {}` to `parse` / `parseMap`. After resolving a text element's raw `value`, apply substitutions in a single pass before constructing `DotsTextElement`. Unmatched tokens are left intact (no warning) — this keeps unit tests deterministic and lets later slices add tokens without breaking older callers.
3. **`{NOMBREHIJO}` convention** (locked-in user decision): treat as an authoring leftover. The library does NOT rewrite the token in JSON; callers building `individuales` templates supply `variables['{NOMBREHIJO}']` with the same value they would give `{Nombre}`, and `otros` callers supply the same value they would give `{Protagonistas}`. This convention is documented in the dartdoc on `parse` / `parseMap`.
4. **Header/footer**: introduce the structural concept (shape to be decided in design). The context-label resolver lives next to `DotsAlbumType` and is a `switch` over the enum.

Concrete shape choices (page subtype vs. extended `DotsPage` fields, exact substitution call site, header-footer asset model) are intentionally deferred to `sdd-design`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | Modified | Adds `albumType` field to `DotsTemplate`. New page concept or extension TBD by design. |
| `lib/src/config/dots_template_parser.dart` | Modified | Adds optional `variables` parameter, parses `albumType`, applies substitution before building `DotsTextElement`. |
| `lib/src/api/dots_album_type.dart` | Modified | Adds context-label resolver function alongside enum. |
| `lib/dots_pdf.dart` | Modified | Re-exports anything new that should be part of the public API. |
| `test/` | New tests | Unit tests for parser (album type round-trip, variable substitution, unknown token, missing variables map, NOMBREHIJO convention). |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Existing templates that happen to contain `{` `}` in literal text get accidentally substituted. | Low | Tokens are explicit and start with `{` plus a recognizable identifier; document the reserved set; substitution is only triggered when caller passes a non-empty `variables` map. |
| Design picks the wrong page-model shape (new subtype vs. extended `DotsPage`) and slices 2–5 have to refactor. | Medium | Defer the shape decision to `sdd-design` with both alternatives evaluated; choose only after slice-2 spread requirements are sketched. |
| `DotsAlbumType` value names (`boda`, `parejas`, etc.) leak Spanish into the public API forever. | Low | Already shipped publicly; renaming is a separate breaking change, not in this slice. |
| Caller forgets to pass `variables` and ends up with `{NombreDelAlbum}` rendered literally in the PDF. | Medium | Document clearly in dartdoc; verify-phase test renders a sample to catch the regression. |

## Rollback Plan

All changes are additive: the new field is nullable, the new parameter has a default, and the header/footer concept is only used by album-spread pages that don't exist yet. Rollback = revert the slice's commits. Existing templates parse and render identically before and after this slice.

## Dependencies

- None external. Builds entirely on existing primitives (`DotsTemplate`, `DotsTemplateParser`, `DotsTextElement`, `DotsConfigException`).

## Decisions captured (for downstream slices)

These are user-locked decisions that this slice does NOT implement but later slices MUST honor:

- **`{NOMBREHIJO}`** → authoring leftover. Library does not rewrite; caller's per-type variable map maps it to `{Nombre}` value (individuales) or `{Protagonistas}` value (otros).
- **"Antes de empezar el viaje" title size** → unified at **27pt across all album types**. The 23pt callout in `boda` (`docs/templates/SPECS_album_types.md`, p.3 inline callout) is a spec bug and must be ignored. Applied in slice 3+.
- **Photo-circle arc diameter** → uniform **44.45 mm** across all album types. Applied in slice 4+.
- **otros voice mix** → deferred to template author; library does not enforce wording. Applied wherever `otros` differs from `individuales` in slices 2–5.

## Success Criteria

- [x] `DotsTemplate` accepts and exposes an optional `albumType`; the field is nullable and defaults to `null`.
- [x] `DotsTemplateParser` parses the JSON `albumType` field when present; unknown values raise `DotsConfigException` with a precise pointer.
- [x] `DotsTemplateParser.parse` / `parseMap` accept a `variables` map and apply token substitution to every `DotsTextElement.value`.
- [x] All 9 documented tokens substitute correctly when provided; missing tokens are left as literal text.
- [x] Per-album-type context-label resolver returns the right token name for every enum value.
- [x] A structural header/footer concept exists in the page model — exact shape decided in design; **renderer support for actually drawing it is out of scope for slice 1** (will be wired in slice 2 alongside the first real album spread).
- [x] Existing fixtures and golden tests for templates without `albumType` pass unchanged (backwards compatibility).
- [x] Public exports in `lib/dots_pdf.dart` are updated for any new public symbol.
