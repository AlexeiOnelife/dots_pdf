# Exploration: pliego-first-category

**Date:** 2026-05-28
**Change:** pliego-first-category
**Phase:** explore
**Status:** complete
**Series position:** Task 2 of 7 (final-render-refinement), building on `page-template-chrome` (Task 1, archived 2026-05-28)

---

## Current State

### 1. JSON Input Model — Two Mutually Exclusive Paths

`lib/src/config/dots_template_parser.dart`, lines 111–165:

The parser accepts either `pages` or `pliegos` as the top-level array key. The XOR is enforced at lines 111–124:

- Both present → `DotsConfigException` at `$`
- Neither present → `DotsConfigException` at `$`
- `pliegos` branch (lines 126–145): parses into `DotsLayoutPliego` or `DotsSpreadImagePliego` objects.
- `pages` branch (lines 147–165): parses into `DotsPage` objects.

`albumType` is optional (lines 91–109) and resolves via `DotsAlbumType.values.byName(...)` with the known values `boda, parejas, hijos, individuales, otros`. There is currently NO `category` field in the parser or model.

No mandatory-page injection happens anywhere in parsing. Callers compose front/back matter externally via `buildCoverPageFor`, `buildSimplePagesFor`, `buildPhotoArcPageFor`, `buildBodaClusterPageFor`, `buildBodaHaloPageFor`, `buildPolaroidCollagePageFor`.

### 2. Typed Dart Model — `DotsTemplate`

`lib/src/config/dots_template.dart`, lines 1999–2081:

```dart
class DotsTemplate {
  const DotsTemplate({
    required this.documentId,
    required this.pageSize,
    this.albumType,
    this.defaultChrome,      // added in Task 1
    this.pages = _emptyPages,
    this.pliegos = _emptyPliegos,
  }) : assert(
    identical(pages, _emptyPages) || identical(pliegos, _emptyPliegos),
    'DotsTemplate accepts pages OR pliegos, not both',
  );
  List<DotsPage> get effectivePages { ... }
  int get contentHash => Object.hash(documentId, pageSize, albumType, defaultChrome,
        Object.hashAll(pages), Object.hashAll(pliegos));
}
```

`effectivePages` (lines 2057–2067) flattens pliegos to pages and is the SOLE renderer input. `contentHash` (lines 2073–2080) already includes `albumType` and `defaultChrome`; a new `category` field would need to be included.

### 3. `DotsPliego` Sealed Hierarchy

`lib/src/config/dots_pliego.dart`: two variants (`DotsLayoutPliego`, `DotsSpreadImagePliego`), both implementing `toPages(firstPageNumber)`. Exhaustive matching in `_withPageNumber` (lines 183–205). No variant for "category mandatory" pages.

### 4. Existing Named Constructors — Factory Mapping

All in `lib/src/config/dots_template.dart`:

| Factory | Line | Supported types | Required inputs |
|---|---|---|---|
| `.cover(...)` | 1460 | `parejas`, `hijos` only | `title`, `dateLine`, optional `eyebrowOverride` |
| `.dedication(...)` | 1209 | all (boda skipped externally) | `title`, `body`, `signature` |
| `.closing(...)` | 1290 | all | `photoPath?`, `title`, `subtitle` |
| `.photoArc(...)` | 1565 | `parejas`, `hijos`, `individuales`, `otros` | `AlbumPhotoArcContent` |
| `.polaroidCollage(...)` | (factory) | all | `AlbumCollageContent` |
| `.bodaCluster(...)` | 1701 | `boda` only | `AlbumBodaClusterContent` |
| `.bodaHalo(...)` | 1819 | `boda` only | `AlbumBodaHaloContent` |

Cover factory throws `ArgumentError` for `individuales`/`otros`/`boda`. There is no centered-photo cover factory for those types.

`DotsAlbumTypeContext.contextLabelToken` (lines 19–23) is exhaustive over 5 values. Adding `generalEventos` requires a new arm here.

### 5. Album Type Enum

`lib/src/api/dots_album_type.dart`, lines 33–56:

```dart
enum DotsAlbumType { boda, parejas, hijos, individuales, otros }
```

Adding `generalEventos` is a breaking enum change. Exhaustive switches without wildcard arms include `contextLabelToken`, `closing.titleFontSize`, `photoArc.defaultLeftCaption`. The `cover.defaultEyebrow` switch uses `_` wildcard so it would NOT catch the new enum value.

### 6. Mandatory Pages per Category — PDF Ground Truth

All findings verified by reading the PDFs (pdf02–pdf13) directly.

**parejas (pdf02 inicial / pdf03 final):**
- Inicial p.1: Cover — `DotsAlbumSpreadPage.cover(type: parejas)` (existing, circles + eyebrow).
- Inicial p.2 (right page): "Busca un lugar tranquilo" / "Más allá del papel" interior-instruction spread with 10 photo slot area. **NEW FACTORY**.
- Inicial p.3: `dedication(parejas)` (existing).
- Inicial p.4–5: `photoArc(parejas)` (existing).
- Final p.1: "Porque algunos recuerdos merecen seguir vivos" closing-QR spread. **NEW FACTORY**.
- Final p.2: `closing(parejas)` (existing).

**hijos (pdf08 inicial / pdf09 final):** Structurally identical to parejas with `DOTBOOK DE {PROTAGONISTA}` eyebrow and `{Protagonista}` header token.

**individuales (pdf10 inicial / pdf11 final):**
- Inicial p.1: Photo-only cover (no decorative circles), 66×86 mm photo, `{NombreDelAlbum}` title, `{DiadeMesdeAñodeFechaDeInicio}` date. **NEW FACTORY**.
- Inicial p.2: "Busca / Más allá" instruction spread. **NEW FACTORY** (shared with other categories).
- Inicial p.3: `dedication(individuales)` (existing).
- Inicial p.4–5: `polaroidCollage(individuales)` (existing).
- Final p.1: shared closing QR spread.
- Final p.2: `closing(individuales)` (existing).

**otros (pdf04 inicial / pdf05 final):** Same as individuales but with the `applyOtrosGradient` overlay on the polaroid collage.

**boda (pdf06 inicial / pdf07 final):**
- Inicial p.1: Boda cover — boda cover layout NOT clearly rendered in the PDFs read. Open question.
- Inicial p.3: `bodaCluster(boda)` (existing).
- Inicial p.4–5: `bodaHalo(boda)` (existing).
- Final p.1: shared closing QR spread.
- Final p.2: `closing(boda)` (existing — fixed title text, no subtitle).

**generalEventos — NEW (pdf12 inicial / pdf13 final):**
- Inicial p.1: "Porque algunos recuerdos…" opening spread (QR block on LEFT, circles scatter on RIGHT). **NEW FACTORY** (distinct from the closing version).
- Inicial p.2: Photo-only cover (generalEventos variant — `{TítuloDelAlbum}` token). **NEW FACTORY**.
- Inicial p.3: "Bienvenido/a a tu viaje al pasado" instruction spread, fixed text. **NEW FACTORY**.
- Inicial p.4–5: "Busca / Más allá" spread (shared NEW FACTORY).
- Final p.1: shared closing QR spread.
- Final p.2: closing variant for generalEventos — photo + `{TítuloDelAlbum}` + "Vivido con mucho amor por: {Firma} y {Firma}". **NEW FACTORY OR EXTENSION**.

`generalEventos` initial block is 4 pliegos (8 pages), one more than the other categories.

### 7. Task 1 Chrome Integration

`DotsTemplate.defaultChrome` (line 2041) is already wired. Mandatory pages this change injects are `DotsAlbumSpreadPage` instances; `buildAlbumSpreadPage` already routes chrome via Task 1's delegation. No additional chrome wiring needed.

---

## Affected Areas

- `lib/src/config/dots_template_parser.dart` — remove `pages` JSON branch; add `category` parsing; inject mandatory pliegos; validate mandatory-slot fields.
- `lib/src/config/dots_template.dart` — model constructor/contentHash; potentially `pages` field deprecation.
- `lib/src/api/dots_album_type.dart` — add `generalEventos` + `contextLabelToken` arm.
- `lib/src/config/dots_pliego.dart` — no change under Approach A.
- `lib/src/render/dots_renderer.dart` — no change under Approach A.
- `lib/dots_pdf.dart` — export any new public types.
- New factories: shared closing QR spread; "Busca/Más allá" instruction spread; "Bienvenido/a" instruction spread; photo-only cover.
- Test files: per TDD norm, new RED tests in PR 1 across parser, album-spread-page, and category test files.

---

## Approaches

### Approach A — Inject mandatory pliegos at parse time (recommended)

Parser resolves `category` → injected `DotsPliego` instances → prepends initial pliegos + appends final pliegos to user body pliegos. `DotsTemplate` stores ONE flat `pliegos` list. Renderer unchanged.

**Pros:** minimal model changes; renderer untouched; validation centralized; `contentHash` automatic; `pages` JSON path removal is the only breaking change.

**Cons:** mandatory pages not distinguishable in the model at runtime.

**Effort:** Medium. New parser logic + 6 category branches + new factories (3–4 genuinely new) — but factories can be **stubbed** here and implemented in Tasks 4–7.

### Approach B — New `DotsPliego` variant

`DotsCategoryMandatoryPliego` (or split init/final) as new sealed variants. Renderer recognizes the variant.

**Pros:** mandatory pages structurally distinguishable.

**Cons:** sealed-hierarchy expansion (every switch needs new arms); renderer changes; validation surface split.

**Effort:** High.

### Comparison

| Dimension | A | B |
|---|---|---|
| Model changes | Low | High |
| Renderer changes | None | Medium |
| Validation surface | Single (parser) | Split |
| Effort | Medium | High |
| Risk | Low | Medium-High |

**Recommendation: Approach A.**

---

## Mandatory Pages per Category — Factory Mapping Summary

### Initial

| Category | Pliegos (sequential) |
|---|---|
| parejas | `cover(parejas)` → "Busca/Más allá" [NEW] → `dedication(parejas)` + `photoArc(parejas)` |
| hijos | `cover(hijos)` → "Busca/Más allá" [NEW] → `dedication(hijos)` + `photoArc(hijos)` |
| individuales | photo-only cover [NEW] → "Busca/Más allá" [NEW] → `dedication(individuales)` + `polaroidCollage(individuales)` |
| otros | photo-only cover [NEW] → "Busca/Más allá" [NEW] → `dedication(otros)` + `polaroidCollage(otros, gradient)` |
| boda | boda cover [NEW or extend existing] → [blank?] → `bodaCluster(boda)` + `bodaHalo(boda)` |
| generalEventos | "Porque algunos recuerdos…" opening [NEW] → photo-only cover (generalEventos variant) [NEW] → "Bienvenido/a" [NEW] → "Busca/Más allá" [NEW] |

### Final

| Category | Pliegos (sequential) |
|---|---|
| All six | shared "Porque algunos recuerdos…" closing QR spread [NEW] → `closing(<type>)` (existing for parejas, hijos, individuales, otros, boda; new variant for generalEventos) |

---

## Breaking Changes

1. **JSON `pages` key removed.** Hard semver-major.
2. **`generalEventos` added to `DotsAlbumType`.** Minor semver-breaking (exhaustive switches in consumer code).
3. **`albumType` ↔ `category` relationship** must be resolved in the proposal.

---

## Open Questions for Spec/Design

1. Does `category` fully replace `albumType` in JSON, or do both coexist?
2. Add `DotsAlbumType.generalEventos` enum value, or keep generalEventos as "albumType: null with category: generalEventos"?
3. Exact `contextLabelToken` for `generalEventos`?
4. `pages` JSON key — immediate hard removal, or soft deprecation (warn + accept) for one release?
5. Mandatory-slot validation timing — parse-time throw (preferred) or render-time warn?
6. `{Main characters' names}` / `{Protagonistas}` token on closing QR spread — resolve via existing token?
7. Boda cover exact layout — deferred per existing project memory; bring in or keep deferred?
8. Keep `DotsTemplate.pages` Dart field or purge it?
9. Exact JSON shape for mandatory-spread inputs (nested per spread vs flat keys on category)?
10. `{DotbookName}` vs `{NombreDelAlbum}` — same thing?

---

## Risks

1. **Factory explosion.** 4+ new spread factories. Largest LOC driver if implemented in Task 2.
2. **JSON breaking change.** Removing `pages:` from JSON is semver-major.
3. **Enum exhaustiveness cascade** when adding `generalEventos`.
4. **Mandatory-photo count coupling.** photoArc=10, bodaCluster=7, bodaHalo=10. Validation must point at the right JSON pointer.
5. **`generalEventos` has 4 initial pliegos** (others have 3) — explicit in page-number assignment.
6. **Test budget.** Definitely >400 LOC; chained PRs required.

---

## Scope Note for Proposal

Task 2 in the parent 7-task series is the **architectural shift**: pliego-only JSON, category attachment mechanism, parser validation, model wiring. The per-category **factory implementations** (the 4+ new factories enumerated here) belong to Tasks 4–7. The proposal should scope Task 2 to:

- Pliego-only JSON contract.
- `category` field + injection mechanism.
- `generalEventos` decision.
- Mandatory-slot validation framework.
- **Stubs / placeholders** for the new factories — body code lands in Tasks 4–7.
- Existing factories (`dedication`, `closing`, `photoArc`, `polaroidCollage`, `bodaCluster`, `bodaHalo`, `cover(parejas|hijos)`) ARE wired up by Task 2 since they exist; their content can flow through immediately.

**Ready for Proposal:** Yes, with the scope narrowing above and open questions resolved before spec.
