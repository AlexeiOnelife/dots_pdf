# Design: album-type-boda-halo (Slice 7 — boda p.4 radial photo halo)

**Series:** Album-type body-page closeout — boda p.4 title spread
**Depends on:** slices 1–6 (all archived). Reuses slice 5's `DotsOvalQrElement` and slice 3's rotation primitive.
**Status:** Approved
**Date Archived:** 2026-05-27

---

## Technical Approach

Add a new sealed `DotsElement` subtype `DotsRotatedPhotoElement` — a rounded-rect photo crop with
signed rotation, NO white frame (unlike slice 3's `DotsPolaroidElement`). It mirrors the polaroid
rotation primitive exactly: `pw.Positioned(left: x, top: y)` → `pw.Transform.rotate(angle, alignment: center)`
→ `pw.ClipRRect` → `pw.Image`. The 10 halo positions live in a NEW library-private const
`kBodaHaloLayout` (`lib/src/render/boda_halo_layout.dart`), each storing the **unrotated top-left**
(not the AABB top-left from `extracted_coordinates.md` §2). Photos are caller-supplied via
`AlbumBodaHaloContent.photoPaths` (length-10 enforced). Public API mirrors slices 5/6:
`buildBodaHaloPageFor(...)` + `DotsAlbumSpreadPage.bodaHalo(...)`, boda-only (`ArgumentError`),
`RangeError` when `length != 10`. The 2 gutter QR cards REUSE slice 5's `DotsOvalQrElement` unchanged.
Single 406 mm spread; factory translates R-slots by +203 mm, L-slots unchanged.

---

## Architecture Decisions

### D1 — AABB → unrotated-geometry conversion (THE critical decision)

**Problem:** `extracted_coordinates.md` §2 reports **post-rotation axis-aligned bounding box (AABB)**
top-lefts with per-slot AABB dimensions. But `DotsRotatedPhotoElement` stores **unrotated** geometry
(uniform 33.5 × 46.4 mm) + a signed angle, then rotates around the rect's geometric center. Storing
the AABB top-left would mis-place every photo, because the AABB grows as the rectangle tilts — the
AABB top-left ≠ the unrotated rect top-left.

**Choice:** Pre-compute the 10 unrotated top-lefts ONCE and HARDCODE them in `kBodaHaloLayout`. Do
NOT do the AABB conversion at runtime. Rotation is **center-preserving**, so:

```
center        = (aabbX + aabbW/2,  aabbY + aabbH/2)
unrotatedTL   = (center_x − 33.5/2,  center_y − 46.4/2)
            = (aabbX + aabbW/2 − 16.75,  aabbY + aabbH/2 − 23.2)
```

The renderer positions the unrotated 33.5×46.4 mm rect at `unrotatedTL`, then `pw.Transform.rotate`
spins it around its own center (`pw.Alignment.center`). Because rotation preserves the center, the
rotated rect's AABB reproduces the original extracted AABB top-left and dimensions — placement is exact.

**Worked conversion table** (all values mm; `uX = aabbX + aabbW/2 − 16.75`, `uY = aabbY + aabbH/2 − 23.2`):

| Slot | AABB x | AABB y | AABB w | AABB h | center_x | center_y | unrotated x | unrotated y | angle° |
|------|--------|--------|--------|--------|----------|----------|-------------|-------------|--------|
| R1 | 13.2  | 93.9  | 37.7 | 48.5 | 32.05  | 118.15 | **15.30**  | **94.95**  | +3.2  |
| R2 | 55.4  | 107.2 | 49.3 | 54.6 | 80.05  | 134.50 | **63.30**  | **111.30** | +20.7 |
| R3 | 93.4  | 136.2 | 56.2 | 56.0 | 121.50 | 164.20 | **104.75** | **141.00** | +37.2 |
| R4 | 121.8 | 178.8 | 57.9 | 52.6 | 150.75 | 205.10 | **134.00** | **181.90** | +55.2 |
| R5 | 140.5 | 228.6 | 56.1 | 46.7 | 168.55 | 251.95 | **151.80** | **228.75** | +68.3 |
| L1 | 152.2 | 91.7  | 37.7 | 51.4 | 171.05 | 117.40 | **154.30** | **94.20**  | −3.2  |
| L2 | 111.0 | 104.2 | 49.3 | 55.6 | 135.65 | 132.00 | **118.90** | **108.80** | −20.7 |
| L3 | 65.2  | 133.2 | 56.2 | 57.0 | 93.30  | 161.70 | **76.55**  | **138.50** | −37.2 |
| L4 | 13.3  | 175.5 | 57.9 | 53.6 | 42.25  | 202.30 | **25.50**  | **179.10** | −55.2 |
| L5 | 6.6   | 229.6 | 56.1 | 47.8 | 34.65  | 253.50 | **17.90**  | **230.30** | −68.3 |

These bold **unrotated x / unrotated y / angle** triples are the literal contents of `kBodaHaloLayout`.
R-slots are right-page-relative (factory adds +203 mm); L-slots are left-page-relative (no offset).
R5/L5 tilt the rect partly below the page → `bleedBottom: true` (cosmetic flag; `pw.Stack` does not clip).

**Confidence:** MEDIUM (per Q3). Dartdoc caveat on the const + a deferred follow-up to verify against
the InDesign source. ±2 mm drift on a tilted decorative photo is sub-perceptual.

**Alternative rejected:** runtime AABB→unrotated conversion in the factory. Rejected — the arithmetic
is fixed for the 10 fixed slots; computing it at runtime adds branching and a failure surface for zero
benefit. Hardcoding keeps the layout const a pure data table testable against this worked table.

### D2 — `DotsRotatedPhotoElement` shape + rounded-rect rendering

**Choice:** New sealed subtype; uniform unrotated w/h supplied per-element (95.0 × 131.4 pt = 33.5 × 46.4 mm);
`cornerRadiusMm` default 6.0; 4 bleed flags. Full `==` / `hashCode`.

```dart
@immutable
class DotsRotatedPhotoElement extends DotsElement {
  const DotsRotatedPhotoElement({
    required super.x,            // unrotated top-left, pt
    required super.y,
    required this.assetPath,
    required this.width,         // unrotated, pt
    required this.height,        // unrotated, pt
    required this.angleDegrees,  // signed
    this.cornerRadiusMm = 6.0,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
}
```

**Render** (new `_buildRotatedPhotoElement`, async, mirrors `_buildPolaroidElement` minus the frame):

```
pw.Positioned(left: x, top: y,
  child: pw.Transform.rotate(angle: angleDegrees * pi/180, alignment: pw.Alignment.center,
    child: pw.ClipRRect(
      horizontalRadius: cornerRadiusMm * _kMmToPt,
      verticalRadius:   cornerRadiusMm * _kMmToPt,
      child: pw.Image(image, width: width, height: height, fit: pw.BoxFit.cover))))
```

On decode failure: call `onPhotoFailure(assetPath, error)`, return `null` (same contract as `_buildImage`/`_buildPolaroidElement`).

**`pw.ClipRRect` confirmed available** in pinned `pdf ^3.11.1` — already used at `album_spread_page.dart:889`
(`_buildImage`) with `horizontalRadius` / `verticalRadius` named params. No new API risk.

**Alternative rejected:** reuse `DotsPolaroidElement` with a frameless flag (Q1). Its 5.5/5.5/5.5/6.5 mm
frame borders are renderer-side constants; a frameless mode fights that hardcoding and pollutes a shipped
primitive. Separate types over flags is the slice-3 precedent. Cost: +5 exhaustiveness arms (accepted).

### D3 — `kBodaHaloLayout` location and shape

**Choice:** Library-private const in NEW file `lib/src/render/boda_halo_layout.dart`, mirroring
`photo_arc_layout.dart` (slice 5) and `boda_cluster_layout.dart` (slice 6). File-private `_BodaHaloAnchor`
with `xMm`, `yMm`, `angleDegrees`, `bleedBottom`. Uniform `widthMm = 33.5` / `heightMm = 46.4` as class
constants (not per-anchor fields). 10 entries with the D1 pre-computed unrotated coords. A
`@visibleForTesting` record projection `kBodaHaloLayoutForTest` exposes the table for assertion against D1.

**Alternative rejected:** put the const in `album_spread_page.dart` — already ~1100 lines; a dedicated
layout file keeps the render module focused (slice 5/6 precedent).

### D4 — `DotsAlbumSpreadPage.bodaHalo(...)` factory

**Choice:** Named factory composing 10 `DotsRotatedPhotoElement` + 2 `DotsOvalQrElement` + 3
`DotsTextElement` (title line 1, title line 2, date) + standard header trio + footer. Total: 15 elements
plus header/footer. R-slots (indices 0–4): `x = anchor.xMm * _kMmToPt + 203 mm`. L-slots (indices 5–9):
`x = anchor.xMm * _kMmToPt` (left-page origin). Validates `RangeError` when `photoPaths.length != 10`
BEFORE element construction.

- **Title:** two lines, P22 Mackinac Medium 23 pt / 27.6 pt leading, left page at (19 mm, 43 mm); line 2 5 mm below.
- **Date subtitle:** P22 Mackinac Book 9 pt, 5 mm below line 2.
- **QR ovals (reuse slice 5 geometry):** oval 25.841 × 43.127 mm, y = 190.87 mm; 27 mm either side of gutter
  center (x = 203 mm) → left x = 176 mm, right x = 230 mm. Captions resolved by the builder (D5).

**Alternative rejected:** two separate `pw.Page`s for left/right. Single 406 mm spread is the slice-5
pattern; one page with a +203 mm translate is simpler and matches the extracted spread MediaBox.

### D5 — `AlbumBodaHaloContent` value object + `buildBodaHaloPageFor` builder

**Choice:** Immutable value object + top-level builder, symmetric with slice 5's `AlbumPhotoArcContent` /
`buildPhotoArcPageFor`.

```dart
@immutable
class AlbumBodaHaloContent {
  const AlbumBodaHaloContent({
    required this.photoPaths,                // List<String>, exactly 10
    required this.qrPayloadLeft,
    required this.qrPayloadRight,
    this.qrCaptionLeftOverride,              // String?, default null
    this.qrCaptionRightOverride,
    this.titleLine1 = 'Boda de',
    this.titleLine2 = 'Nombre&Nombre',
    required this.dateSubtitle,
  });
  // value equality incl. list equality on photoPaths.
}

DotsAlbumSpreadPage buildBodaHaloPageFor(
  DotsAlbumType type,
  AlbumBodaHaloContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type != DotsAlbumType.boda) {
    throw ArgumentError.value(type, 'type',
      'buildBodaHaloPageFor only supports DotsAlbumType.boda');
  }
  return DotsAlbumSpreadPage.bodaHalo(...);
}
```

Builder resolves boda QR caption defaults (overrides win) and dispatches to the factory. Factory enforces
`photoPaths.length == 10` (`RangeError`).

### D6 — Exhaustiveness: 5 sites for `DotsRotatedPhotoElement`

`DotsOvalQrElement` is ALREADY handled at all sites (slice 5) — no change there. The new element adds
exactly 5 arms:

| # | Site | Arm |
|---|------|-----|
| 1 | `album_spread_page.dart` `_buildElement` | `_buildRotatedPhotoElement(...)` |
| 2 | `dots_renderer.dart` `_buildElement` (ElementsPage, ~line 423) | `return null;` |
| 3 | `dots_renderer.dart` `preloadAssetBytes` (DotsElementsPage, ~line 57) | `paths.add(element.assetPath);` |
| 4 | `dots_renderer.dart` `preloadAssetBytes` (DotsAlbumSpreadPage, ~line 89) | `paths.add(element.assetPath);` |
| 5 | `isolate_synthesis.dart` `_buildElement` (~line 313) | `return null;` |

`dart analyze` must report 0 non-exhaustive errors after these are added.

### D7 — Public API surface

**Choice:** New exports in `lib/dots_pdf.dart`: `AlbumBodaHaloContent` (new file
`lib/src/api/album_boda_halo_content.dart`), `buildBodaHaloPageFor` (new file
`lib/src/api/build_boda_halo_page.dart`). `DotsRotatedPhotoElement` rides the existing
`export 'src/config/dots_template.dart'` barrel. `kBodaHaloLayout` stays library-private (not exported).

### D8 — Test files

| File | Purpose |
|---|---|
| `test/config/dots_rotated_photo_element_test.dart` | Model: constructor, all-field `==`/`hashCode`, inequality per field, `cornerRadiusMm` default 6.0, bleed defaults. |
| `test/render/boda_halo_layout_test.dart` | `kBodaHaloLayoutForTest`: 10 entries; unrotated x/y/angle match the D1 worked table within ±0.001 mm; R5/L5 `bleedBottom` true. |
| `test/render/boda_halo_test.dart` | Render via main + worker isolate (non-empty PDF); `ArgumentError` (non-boda); `RangeError` (length != 10); decode-failure skip. |
| `test/api/build_boda_halo_page_test.dart` | Builder: rejects 4 non-boda types; default title lines; caption overrides; `photoPaths` propagated; header trio populated. |

---

## Data Flow

    AlbumBodaHaloContent (photoPaths × 10, title×2, date, 2 QR payloads + caption overrides)
            │
            ▼
    buildBodaHaloPageFor(type, content, pageNumber, contextLabel)
            │  validates type == boda  → ArgumentError
            ▼
    DotsAlbumSpreadPage.bodaHalo(...)
            │  validates photoPaths.length == 10  → RangeError
            │  zips photoPaths against kBodaHaloLayout (unrotated TLs)
            │  R-slots +203mm; L-slots no offset
            ▼
    DotsAlbumSpreadPage(header trio + 10 DotsRotatedPhotoElement
                        + 2 DotsOvalQrElement + 3 DotsTextElement + footer)
            │
            ▼
    buildAlbumSpreadPage(...) → _buildElement switch
            ├─ DotsRotatedPhotoElement → _buildRotatedPhotoElement
            │        → pw.Positioned → Transform.rotate(center) → ClipRRect → Image
            ├─ DotsOvalQrElement       → _buildOvalQrElement (slice 5, unchanged)
            └─ DotsTextElement         → _buildText

---

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/config/dots_template.dart` | Modify | Add `DotsRotatedPhotoElement` sealed subtype (`==`/`hashCode`) + `DotsAlbumSpreadPage.bodaHalo` factory. |
| `lib/src/render/boda_halo_layout.dart` | Create | `_BodaHaloAnchor` + `kBodaHaloLayout` (10 entries, D1 coords) + `@visibleForTesting` projection. |
| `lib/src/render/album_spread_page.dart` | Modify | Add `_buildRotatedPhotoElement`; new `_buildElement` arm. |
| `lib/src/render/dots_renderer.dart` | Modify | 3 exhaustiveness arms (`_buildElement` + 2× `preloadAssetBytes`). |
| `lib/src/render/isolate_synthesis.dart` | Modify | 1 exhaustiveness arm (`_buildElement`). |
| `lib/src/api/album_boda_halo_content.dart` | Create | `AlbumBodaHaloContent` value object. |
| `lib/src/api/build_boda_halo_page.dart` | Create | `buildBodaHaloPageFor` builder. |
| `lib/dots_pdf.dart` | Modify | Export `AlbumBodaHaloContent`, `buildBodaHaloPageFor`. |
| `test/config/dots_rotated_photo_element_test.dart` | Create | Model tests. |
| `test/render/boda_halo_layout_test.dart` | Create | Layout-const tests vs D1 table. |
| `test/render/boda_halo_test.dart` | Create | Render + validation + isolate-parity. |
| `test/api/build_boda_halo_page_test.dart` | Create | Builder + factory validation tests. |

---

## Interfaces / Contracts

- `DotsRotatedPhotoElement` — see D2.
- `AlbumBodaHaloContent` — see D5.
- `buildBodaHaloPageFor(DotsAlbumType, AlbumBodaHaloContent, {required int pageNumber, required String contextLabelValue})` — see D5.
- `DotsAlbumSpreadPage.bodaHalo({required DotsAlbumType type, required int pageNumber, required String contextLabelValue, required AlbumBodaHaloContent content})` — named factory.

---

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Model `==`/`hashCode`/inequality per field; `cornerRadiusMm` default; bleed defaults | `dots_rotated_photo_element_test.dart` |
| Unit | `kBodaHaloLayout` 10 entries match D1 worked table within ±0.001 mm; R5/L5 bleedBottom | `boda_halo_layout_test.dart` |
| Integration | Factory `RangeError` (length != 10); builder `ArgumentError` (4 non-boda types) | `boda_halo_test.dart` + `build_boda_halo_page_test.dart` |
| Integration | Main vs worker isolate produce non-empty byte buffers (slice-2 parity pattern) | `boda_halo_test.dart` |
| Integration | Rendered PDF non-empty; header trio + title lines present; 10 rotated photos + 2 ovals | end-to-end render test |

---

## Migration / Rollout

No migration required. Purely additive: new element type, layout const, content object, factory, builder,
5 exhaustiveness arms, 2 exports. No existing element/factory/test modified — revert restores slice-6 state
cleanly. All slice-1…6 tests must pass unchanged.

---

## Open Questions

- [ ] Visual QA: confirm MEDIUM-confidence halo coords against the InDesign source (Q3 deferred follow-up).
      ±2 mm drift on tilted photos is sub-perceptual; ship now, verify later.
- [ ] Visual QA: confirm 6 mm corner radius reads correctly against the source render; `cornerRadiusMm`
      is a field, so a caller/builder tweak needs no model change.
- [ ] Confirm title baseline anchor (19 mm, 43 mm) and 23 pt size against the source — same risk class as
      slice 6 D3 (inline callout vs table).

---

## References

- Proposal: `openspec/changes/album-type-boda-halo/proposal.md`
- Slot coordinates: `docs/templates/extracted_coordinates.md` § 2
- Rotation primitive: `lib/src/render/album_spread_page.dart` `_buildPolaroidElement` (lines 1037–1097)
- `ClipRRect` precedent: `lib/src/render/album_spread_page.dart` `_buildImage` (line 889)
- Oval QR reuse: `openspec/specs/album-type-photo-arc.md` R3/R4 + `_buildOvalQrElement`
- Slice 6 design format: `openspec/archive/album-type-boda-cluster/design.md`
