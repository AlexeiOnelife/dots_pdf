# Proposal: album-type-boda-cluster (Slice 6)

**Series:** Album-type body-page closeout for `DotsAlbumType.boda`
**Depends on:** slices 1-5 (all archived)
**Picks up:** boda p.3 work deferred from slice 1 (coordinates extracted post-hoc; see `docs/templates/extracted_coordinates.md` §1).

---

## Intent

boda is missing two body-page spreads (p.3 cluster + p.4 radial halo). With p.3 + p.4 wired, boda reaches feature parity with parejas/hijos/individuales/otros for body-page output.

Slice 6 ships **p.3 — "Antes de empezar el viaje"**: a 406 mm spread whose left page is header-only, and whose right page carries a title, body, and a **7-photo decorative cluster** with per-photo opacity gradients and edge feathers. The CLUSTER LAYOUT (slot positions, sizes, per-slot opacity gradient parameters) is library-locked; the PHOTO CONTENT is caller-supplied — matching slice 3 (polaroid) and slice 5 (photo arc) patterns. All 7 cluster coordinates are HIGH confidence (extracted from `mutool show` content stream, cross-verified against spec right-edge callouts within ±0.2 mm).

Slice 7 (separate proposal) will deliver p.4 radial halo.

## Scope

### In Scope

- New sealed `DotsElement` subtype `DotsClusterPhotoElement` carrying: x, y (inherited), `assetPath` (String, caller-supplied), width, height (pt), `opacityGradientStart`, `opacityGradientEnd` (double 0..1), `opacityGradientDirection` (TBD by design — enum or simple top-to-bottom assumption), `gaussianFadeMm` (double, default 1.764), and 4 bleed flags (`bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`, default `false`).
- Library-private const `kBodaClusterLayout` (7 slots) parallel to `kCoverCircleLayout` / `kPhotoArcLayout`. Each entry carries the slot's x, y, width, height, per-slot opacity gradient parameters, and bleed flags — i.e. everything except `assetPath`.
- New named factory `DotsAlbumSpreadPage.bodaCluster(...)` that zips caller `photoPaths` against `kBodaClusterLayout` to produce 7 `DotsClusterPhotoElement` instances.
- New top-level builder `buildBodaClusterPageFor(DotsAlbumType type, AlbumBodaClusterContent content, {required int pageNumber, required String contextLabelValue})` — accepts `DotsAlbumType` for **API consistency with slice 5** (Q6); throws `ArgumentError` for any non-boda type.
- New immutable `AlbumBodaClusterContent` carrying: `photoPaths` (List\<String\>, exactly 7 items enforced at factory), `title` (String, defaults to `"Antes de empezar"`), `titleItalicLine` (String, defaults to `"el viaje"`), `body` (String, Inter Book 9pt block, 95 mm wide).
- Title rendered as **two separate `DotsTextElement` instances** (line 1 medium, line 2 medium italic) — see Q5.
- Header trio (`{Protagonistas}` for boda) drawn by `buildAlbumSpreadPage`; left page empty body, right page carries text + cluster.
- 5-site exhaustiveness arms for `DotsClusterPhotoElement` (album_spread_page.dart `_buildElement`, dots_renderer.dart `_buildElement` + `preloadAssetBytes` for ElementsPage and AlbumSpreadPage, isolate_synthesis.dart `_buildElement`).
- Re-export `DotsClusterPhotoElement`, `AlbumBodaClusterContent`, `buildBodaClusterPageFor` from `lib/dots_pdf.dart`.

### Out of Scope

- **boda p.4 radial halo** — separate slice 7 (10 halo slots, MEDIUM confidence on rotation anchors).
- boda p.1 (intro single page), p.2 (instructions spread), p.5 (closing single page) — separate future work.
- Library-bundled cluster placeholder photos. Callers supply the 7 photo paths (matches slice 3 / slice 5 patterns). The spec's "not user-replaceable" language refers to the END USER (the couple receiving the album) being unable to customize, not to the LIBRARY refusing photo paths. Bundled placeholders would render every boda album with identical photos, which is visually nonsensical for a wedding-album library.
- Caller-controlled cluster layout (slot positions, sizes, per-slot opacity gradient parameters). These are library-locked via `kBodaClusterLayout` — the cluster IS the signature element; the layout is fixed.
- A `DotsRichTextElement` with per-line style runs — explicitly deferred in favour of the two-element approach (Q5).
- Widow / no-word-break rules (still deferred from slice 2).

## Capabilities

### New Capabilities

- `album-type-boda-cluster`: decorative 7-photo cluster spread for `DotsAlbumType.boda` (p.3 of the boda template). Introduces `DotsClusterPhotoElement` primitive with per-photo opacity gradients (caller-supplied photos, library-locked layout), `AlbumBodaClusterContent`, the `bodaCluster` factory, and `buildBodaClusterPageFor` builder.

### Modified Capabilities

None. Slices 1-5 specs are archived and remain frozen.

## Approach

### Q-verdicts (committed in proposal; design may refine renderer details)

- **Q1 — photo content: CALLER-SUPPLIED `photoPaths`.** `AlbumBodaClusterContent.photoPaths` is a `List<String>` of exactly 7 entries; factory throws `RangeError` if length differs (matches slice 3 / slice 5 enforcement). The CLUSTER LAYOUT remains library-locked via `kBodaClusterLayout`. Rationale: the spec's "decorative, not user-replaceable" wording targets the END USER (couple receiving the album); a wedding-album library cannot ship every album with identical bundled photos. API consistency with slice 3 (`DotsPolaroidElement.assetPath`) and slice 5 (`DotsPhotoCircleElement.assetPath`) wins.
- **Q2 — opacity model: NEW SEALED SUBTYPE `DotsClusterPhotoElement` with public `assetPath`.** Mirrors slice 3 (`DotsPolaroidElement`) and slice 5 (`DotsPhotoCircleElement`). Per-photo opacity gradient parameters (`opacityGradientStart`, `opacityGradientEnd`, `opacityGradientDirection`) sit on the element directly — exactly as slice 3 put `gradientRtl` on `DotsPolaroidElement`. Accepts the +5 exhaustiveness sites as the cost of model purity.
- **Q3 — edge feather: REUSE slice 4's `gaussianFadeMm` pattern via pre-rasterisation cache.** Spec calls out 1.764 mm feather (same value used by `DotsDecorativeCircleElement`). The existing cache hook (`@visibleForTesting` reset) can be generalised to key on `(assetPath, width, height, opacityStart, opacityEnd, opacityDirection, gaussianFadeMm)`.
- **Q4 — page geometry: SINGLE `pw.Page` of 406 mm spread width.** Mirrors slice 5 photo-arc. The cluster coordinates from `extracted_coordinates.md` §1 are right-page-relative (gutter origin); the factory translates them to spread coordinates by adding 203 mm. Caller MUST set `DotsTemplate.pageSize.width >= 406 mm`; runtime warning emitted if violated (same pattern as slice 5).
- **Q5 — mixed-style title: TWO SEPARATE `DotsTextElement` instances.** Line 1 `title` (default "Antes de empezar", P22 Mackinac medium 23pt/27.6pt), line 2 `titleItalicLine` (default "el viaje", P22 Mackinac medium italic 23pt/27.6pt). Stays consistent with existing element model, no new `DotsRichTextElement` subtype, no per-line style runs on `DotsTextBlockElement`. Spec callout reads 23pt/27.6pt per the inline numbers; the larger 27pt/31pt option (which the spec text mentions as a hypothesis) is rejected — design will lock 23pt to match boda's stated values.
- **Q6 — builder signature: `buildBodaClusterPageFor(DotsAlbumType type, ...)` mirroring slice 5 `buildPhotoArcPageFor`.** Accepts type for symmetry; throws `ArgumentError` for non-boda. Avoids one-off API shape inside the family.

### Implementation outline

1. Add `DotsClusterPhotoElement` (sealed) to `dots_template.dart` with value equality over all fields including `assetPath`.
2. Add `kBodaClusterLayout` const (7 entries, derived from `extracted_coordinates.md` §1 table) inside the renderer module — carries layout + per-slot opacity gradient parameters, no `assetPath`.
3. Add `AlbumBodaClusterContent` value object (`photoPaths`, `title`, `titleItalicLine`, `body`) + value equality.
4. Add `DotsAlbumSpreadPage.bodaCluster(...)` factory: validates `photoPaths.length == 7` (throws `RangeError`), validates `type == DotsAlbumType.boda` (throws `ArgumentError`), zips `photoPaths` against `kBodaClusterLayout` into 7 `DotsClusterPhotoElement` instances, composes title-line-1 + title-line-2 + body, populates header trio from `pageNumber` + `contextLabelValue`.
5. Add `buildBodaClusterPageFor` top-level builder that dispatches to the factory.
6. Add `_buildClusterPhotoElement(...)` private helper to `album_spread_page.dart`; wire 5-site exhaustiveness arms.
7. Re-export from `lib/dots_pdf.dart`.
8. Tests: model equality/inequality (incl. `assetPath`), layout const matches extracted coords, factory element count + positions + `assetPath` propagation, `photoPaths.length != 7` rejection, builder type-rejection for non-boda, geometry round-trip, render-without-error via main + worker isolates.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsClusterPhotoElement` sealed arm with public `assetPath` |
| `lib/src/render/album_spread_page.dart` | Modified | Add `_buildClusterPhotoElement`, `kBodaClusterLayout` |
| `lib/src/render/dots_renderer.dart` | Modified | 2 exhaustiveness arms (`_buildElement` + `preloadAssetBytes`); preload `element.assetPath` |
| `lib/src/render/isolate_synthesis.dart` | Modified | 1 exhaustiveness arm (`_buildElement`) |
| `lib/src/album_types/album_boda_cluster.dart` | New | `AlbumBodaClusterContent`, `buildBodaClusterPageFor` |
| `lib/dots_pdf.dart` | Modified | Re-export new symbols |
| `test/album_types/album_boda_cluster_test.dart` | New | Slice 6 tests |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Per-photo opacity gradient renders inconsistently across main/worker isolate paths | Med | Reuse slice 4 pre-rasterisation cache + parity test (both paths produce comparable byte sizes) |
| Title size disagreement (23pt vs 27pt per spec callout vs spec text) | Low | Lock 23pt per inline callout; design phase records the decision; future visual review can adjust |
| Cluster slot 1 at y=−7.8 mm bleeds above trim — bleed flag handling | Low | Slot 1 carries `bleedTop: true`; renderer already handles bleed via slice 4 conventions |
| `opacityGradientDirection` representation (enum vs simple bool/assumed direction) under-specified | Med | Design phase decides; spec calls out two distinct patterns (bottom→top for slot 1; top→bottom for slots 5–7). A 2-value enum (`bottomToTop`, `topToBottom`) plus start/end opacity covers all 7 slots without over-engineering |
| +5 exhaustiveness sites (10th element subtype) increase switch noise | Low | Already the established pattern; slices 2-5 paid the same tax; design enumerates the 5 sites explicitly |

## Rollback Plan

If slice 6 breaks production:

1. Revert the slice 6 PR (single PR or chained — TBD by tasks phase guard).
2. `DotsAlbumType.boda` returns to its post-slice-5 state: closing page + cover work fine, body-page spreads (p.3, p.4) remain absent — same condition as the day slice 5 archived.
3. No data migration. No public-API removal needed if the builder was only just shipped; if downstream code already calls `buildBodaClusterPageFor`, those call-sites compile-error but don't corrupt state.
4. No bundled assets to clean up (Q1 reversed — none ship).

## Dependencies

- Slices 1-5 (all archived) — `DotsAlbumType`, `DotsAlbumSpreadPage`, `buildAlbumSpreadPage`, header trio rendering, sealed `DotsElement` hierarchy, pre-rasterisation cache pattern from slice 4, `assetPath`-on-element pattern from slices 3 + 5.
- `package:pdf` ^3.11.1 (already in pubspec).
- `package:image` ^4.x (already in pubspec; used by slice 4 for Gaussian-blur rasterisation).

## Success Criteria

- [ ] `DotsClusterPhotoElement` constructs with caller-supplied `assetPath`, supports value equality, has 7 cluster coordinates matching `extracted_coordinates.md` §1.
- [ ] `AlbumBodaClusterContent` constructs with 7-entry `photoPaths`, supports value equality (incl. list equality on `photoPaths`).
- [ ] `buildBodaClusterPageFor(DotsAlbumType.boda, ...)` returns a `DotsAlbumSpreadPage` with 7 cluster elements + title-line-1 + title-line-2 + body element; each cluster element's `assetPath` matches the corresponding `photoPaths[i]`.
- [ ] `buildBodaClusterPageFor` throws `ArgumentError` for `parejas`, `hijos`, `individuales`, `otros`.
- [ ] Factory throws `RangeError` if `photoPaths.length != 7`.
- [ ] Rendered PDF contains "Antes de empezar", "el viaje", and the body text; cluster elements are visible at the documented positions; per-photo opacity gradients render correctly.
- [ ] Main-isolate and worker-isolate renders produce byte buffers within 20% size tolerance (parity check, slice 2 pattern).
- [ ] `dart analyze` reports 0 issues; all slice-1/2/3/4/5 tests pass unchanged.
- [ ] All 7 cluster slot positions verified against `extracted_coordinates.md` §1 within ±0.2 mm.
- [ ] `lib/dots_pdf.dart` re-exports `DotsClusterPhotoElement`, `AlbumBodaClusterContent`, `buildBodaClusterPageFor`.
