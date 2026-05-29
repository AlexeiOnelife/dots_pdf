# Spec: pareja-hijos-fidelity

**Change:** pareja-hijos-fidelity
**Series:** Task 4 of 7 (`final-render-refinement`)
**Delivery:** single PR

---

## Capabilities

### New Capabilities

| Capability | Spec file |
|---|---|
| `category-render-fidelity-parejas-hijos` | `openspec/specs/category-render-fidelity-parejas-hijos.md` |

### Modified Capabilities

| Capability | Delta spec |
|---|---|
| `pliego-first-category` | `openspec/changes/pareja-hijos-fidelity/specs/pliego-first-category/spec.md` |

---

## Summary

### New: `category-render-fidelity-parejas-hijos`

Full spec defining the canonical render contract for the `parejas` and `hijos`
categories across all in-scope spreads.

| Req | Subject | Key constraint |
|---|---|---|
| R1 | Cover eyebrow | Both types MUST emit `"DOTBOOK DE {PROTAGONISTA}"` |
| R2 | Cover geometry | x=41.5 mm, width=120 mm; eyebrow y=110.249 mm |
| R3 | Dedication geometry | All text x=50.53 mm; body width=120 mm; relative y offsets |
| R4 | Closing geometry | Photo y=71.534 mm; title/subtitle x=44 mm, width=115 mm |
| R5 | `beforeYouStart` spread | One spread page; 10 photo slots; per-category copy |
| R6 | `closingQrSpread` left page | 5 elements; right page chrome-only |
| R7 | `AlbumBeforeYouStartContent.photoPaths` | Required; length 10; `RangeError` otherwise |
| R8 | `AlbumQrSpreadContent.bottomTextOverride` | Optional `String?`; defaults to null |
| R9 | Layout-constant files | Two new `lib/src/render/*.dart` files |
| R10 | Test fixtures | Updated existing + two new test files |

### Modified: `pliego-first-category`

Delta to R7 only: `beforeYouStart(parejas|hijos)` and `closingQrSpread` no
longer throw `UnimplementedError`. Two new ADDED requirements (R-delta-A,
R-delta-B) document the caller-contract additions to the content models.

---

## Deferred (explicit)

| Item | Reason |
|---|---|
| Dedication left-page `#CDE7F2` background | New per-page background mechanism needed |
| Photo-slot corner radius | `DotsImageElement` has no `cornerRadiusMm` |
| `closingQrSpread` right-page circles | Diameters not annotated in PDFs |
| `photoArc` fidelity verification | Source PDF attribution unclear |
| `individuales`/`otros`/`boda`/`generalEventos` factory bodies | Tasks 5–7 |
