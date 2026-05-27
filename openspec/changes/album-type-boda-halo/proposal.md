# Proposal: album-type-boda-halo (Slice 7 — boda p.4 radial photo halo)

## Intent

boda p.4 is the "Boda de Nombre&Nombre" title spread: a left-page title block plus a
right-page **radial halo of 10 tilted rounded-rect photos** arcing around the page center,
with 2 oval QR cards straddling the gutter bottom. Slices 1–6 shipped boda p.3 (cluster)
and the photo-arc for the other four types; this slice brings boda to near-parity for body
spreads. Without it, boda books cannot render their signature title spread. The 10 halo
positions are fully extracted (`extracted_coordinates.md` §2) at MEDIUM confidence — enough
to ship a decorative arc where ±2mm drift on tilted photos is invisible.

## Scope

### In Scope
- **New element** `DotsRotatedPhotoElement` — rounded-rect photo with rotation + corner radius, NO frame (see Q1).
- 10 halo slot positions as a library-private const (`kBodaHaloLayout`); 5 right-page + 5 left-page mirror.
- Left-page title (2 lines: "Boda de" / "Nombre&Nombre", P22 Mackinac Medium 23pt/27.6pt) + date subtitle (P22 Mackinac Book 9pt, 5mm below).
- 2 oval QR cards — **REUSE** slice 5's `DotsOvalQrElement` (no new type).
- `AlbumBodaHaloContent` value object + `DotsAlbumSpreadPage.bodaHalo(...)` factory + `buildBodaHaloPageFor(...)` builder.
- boda-only: `ArgumentError` for other types; `RangeError` if `photoPaths.length != 10`.
- 5 exhaustiveness arms for the new element; spread-width (≥406mm) pageSize warning.

### Out of Scope
- boda p.1 / p.2 / p.5 — separate work.
- Anchor verification against the InDesign source (unverifiable from PDF stream — see Risks).
- Non-boda album types (already covered by `photoArc`).
- Pre-rasterization cache for halo photos (slice 6 cluster pattern); not needed — 10 distinct photos.

## Capabilities

### New Capabilities
- `album-type-boda-halo`: the boda p.4 title spread — `DotsRotatedPhotoElement`, `kBodaHaloLayout`, `AlbumBodaHaloContent`, `bodaHalo` factory, `buildBodaHaloPageFor` builder, renderer dispatch.

### Modified Capabilities
- None. (Reuses `DotsOvalQrElement` from `album-type-photo-arc` unchanged; adds a sealed-switch arm but introduces no spec-level change to existing capabilities.)

## Approach

Follow the slice-5/6 factory+builder pattern exactly. `DotsRotatedPhotoElement` mirrors
`DotsPolaroidElement`'s rotation primitive (`pw.Transform.rotate` around geometric center)
but drops the white frame and adds a `cornerRadiusMm` field (rounded-rect crop). The factory
emits 10 `DotsRotatedPhotoElement` + 2 `DotsOvalQrElement` + 3 text elements (2 title lines +
date) + header trio/footer. Halo coords are right-page-relative (R-slots) and left-page-relative
(L-slots); the factory translates R-slots by +203mm to spread coordinates. The element carries
**unrotated** w/h (uniform 33.5×46.4mm = 95.0×131.4pt) + signed rotation; the layout const
converts the extracted AABB top-left to the unrotated top-left (design-phase concern — see Q3).

### Q1–Q7 verdicts (committed inline)
- **Q1 — NEW element `DotsRotatedPhotoElement`.** Option A. Consistent with the slice-3 "separate types over flags" precedent; reusing `DotsPolaroidElement` (Option B) would force a frameless mode that fights its hardcoded 5.5/6.5mm frame. Costs +5 exhaustiveness arms — accepted.
- **Q2 — Expose `cornerRadiusMm` field, default 6mm.** Spec says "rounded-rect" without a value; a field keeps callers flexible while 6mm matches other rounded-rect slots.
- **Q3 — Ship at MEDIUM confidence** with a dartdoc caveat + a deferred follow-up to verify against source. Decorative; sub-perceptual drift.
- **Q4 — Exactly 10 caller-supplied photos.** `RangeError` if `length != 10` (slice 5/6 pattern).
- **Q5 — Factory + builder** `DotsAlbumSpreadPage.bodaHalo(...)` + `buildBodaHaloPageFor(...)` with `AlbumBodaHaloContent` (photoPaths[10], title lines, date, 2 QR payloads + optional caption overrides).
- **Q6 — REUSE `DotsOvalQrElement`** for the 2 gutter QR cards. Confirmed; no new type.
- **Q7 — Single 406mm spread page** (slice 5 pattern); factory translates R-slots +203mm, L-slots unchanged.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | New | `DotsRotatedPhotoElement` sealed subtype + `bodaHalo` factory |
| `lib/src/api/album_boda_halo_content.dart` | New | `AlbumBodaHaloContent` value object |
| `lib/src/render/boda_halo_layout.dart` | New | `kBodaHaloLayout` 10-slot const |
| `lib/src/render/album_spread_page.dart` | Modified | `_buildRotatedPhotoElement` arm + `buildBodaHaloPageFor` |
| `lib/src/render/dots_renderer.dart` | Modified | 3 exhaustiveness arms (ElementsPage + 2× preload) |
| `lib/src/render/isolate_synthesis.dart` | Modified | 1 exhaustiveness arm |
| `lib/dots_pdf.dart` | Modified | Export new public symbols |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| MEDIUM-confidence coords drift visibly | Low | Decorative tilted photos; ±2mm sub-perceptual. Dartdoc caveat + deferred source verify. |
| AABB-TL ≠ rotation-pivot TL (element needs unrotated TL) | Med | Design phase converts AABB→unrotated TL using uniform 33.5×46.4mm + per-slot angle. |
| Unverifiable spec anchor (37.477, 50.388) | High (already known) | Anchor is an InDesign pre-rotation coord absent from the PDF stream; we ship extracted post-rotation AABB coords instead and document the discrepancy. |
| R5/L5 bleed below page | Low | Mark `bleedBottom: true` per extracted notes. |

## Rollback Plan

Single additive slice. Revert the slice-7 commit(s): the new element type, layout const,
content object, factory, builder, exhaustiveness arms, and exports all live in new or
clearly-scoped additions. No existing element, factory, or test is modified, so revert
restores slice-6 state cleanly. `dart analyze` + the full prior test suite confirm parity.

## Dependencies

- `album-type-photo-arc` (slice 5, archived) — provides `DotsOvalQrElement`, reused as-is.
- `album-type-polaroid-collage` (slice 3, archived) — rotation primitive reference.
- No new package dependencies (`package:pdf` rotation + existing QR widget suffice).

## Success Criteria

- [ ] `DotsAlbumSpreadPage.bodaHalo(...)` returns a page with 10 `DotsRotatedPhotoElement` + 2 `DotsOvalQrElement` + 3 text elements + header/footer.
- [ ] Factory throws `ArgumentError` for non-boda types and `RangeError` when `photoPaths.length != 10`.
- [ ] `dart analyze` reports 0 issues (all 5 exhaustiveness arms present).
- [ ] All slice-1…6 tests pass unchanged; new public symbols exported from `lib/dots_pdf.dart`.
- [ ] boda p.4 renders a non-empty PDF via both main- and worker-isolate paths.
