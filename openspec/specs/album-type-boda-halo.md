# Main Specification: album-type-boda-halo

**Status:** Approved & Archived
**Change:** album-type-boda-halo (Slice 7)
**Archive Date:** 2026-05-27
**Delta Spec Source:** `openspec/archive/album-type-boda-halo/spec.md`

---

## Purpose

Delivers the "Boda de Nombre&Nombre" radial halo title spread for `DotsAlbumType.boda` (p.4). Introduces `DotsRotatedPhotoElement`, `kBodaHaloLayout` (10-slot library-private const), `AlbumBodaHaloContent`, `DotsAlbumSpreadPage.bodaHalo(...)`, and `buildBodaHaloPageFor(...)`. Reuses `DotsOvalQrElement` from slice 5 for the 2 gutter QR cards.

---

## Requirements (R1–R9)

### R1 — DotsRotatedPhotoElement Model

`DotsRotatedPhotoElement` is a sealed subtype of `DotsElement` with the following fields:

- `x` (double, pt) — unrotated top-left x
- `y` (double, pt) — unrotated top-left y
- `assetPath` (String) — photo asset path
- `width` (double, pt) — unrotated bounding width
- `height` (double, pt) — unrotated bounding height
- `angleDegrees` (double) — clockwise rotation in degrees (signed)
- `cornerRadiusMm` (double, default `6.0`) — corner radius in mm via rounded-rect clip
- `bleedLeft` (bool, default `false`)
- `bleedRight` (bool, default `false`)
- `bleedTop` (bool, default `false`)
- `bleedBottom` (bool, default `false`)

Implements value equality (`==` and `hashCode`) over all fields. Constructible via single named-parameter constructor.

**Scenarios:** S1 (constructor all fields), S2 (equality), S3 (inequality on angleDegrees), S4 (cornerRadiusMm default), S5 (bleed defaults)

---

### R2 — Rotated Photo Rendering

For any `DotsRotatedPhotoElement` in `DotsAlbumSpreadPage.elements`:

1. Decode photo from `assetPath` via `bytesResolver`
2. Clip to rounded rectangle via `pw.ClipRRect` with `borderRadius` = `element.cornerRadiusMm` in pt
3. Wrap in `pw.Transform.rotate` with angle = `element.angleDegrees * pi / 180` around `pw.Alignment.center`
4. Position at `(element.x, element.y)` in pt, sized `element.width × element.height`

On decode failure: silently skip and invoke `onPhotoFailure(assetPath)`. No frame or border applied.

**Scenarios:** S6 (positive angle), S7 (negative angle), S8 (corner radius), S9 (decode failure)

---

### R3 — kBodaHaloLayout 10-Slot Const

Library-private const with exactly 10 entries. Each carries unrotated top-left `(x, y)` in pt, uniform dimensions `width=95.0 pt`, `height=131.4 pt`, signed `angleDegrees`, and per-slot bleed flags.

**Slot Definitions:**
- R1–R5: right-page-relative (x from gutter); factory adds 203 mm when composing spread coords
- L1–L5: left-page-relative (x from left trim edge); used without translation

**Right-page angles** (positive): +3.2°, +20.7°, +37.2°, +55.2°, +68.3°
**Left-page angles** (negated mirrors): −3.2°, −20.7°, −37.2°, −55.2°, −68.3°

**Coordinates** (unrotated top-left, pre-computed from AABB via center-preserving rotation D1):

| Slot | x (pt) | y (pt) | angle | bleedBottom |
|------|--------|--------|-------|-------------|
| R1   | 37.4   | 266.2  | +3.2  | false |
| R2   | 157.1  | 303.8  | +20.7 | false |
| R3   | 264.7  | 386.1  | +37.2 | false |
| R4   | 345.5  | 507.0  | +55.2 | false |
| R5   | 398.2  | 648.1  | +68.3 | true  |
| L1   | 431.4  | 260.0  | −3.2  | false |
| L2   | 314.7  | 295.6  | −20.7 | false |
| L3   | 184.8  | 377.7  | −37.2 | false |
| L4   | 37.7   | 497.5  | −55.2 | false |
| L5   | 18.7   | 651.0  | −68.3 | true  |

MEDIUM-confidence data (±0.5 mm). Dartdoc caveat and deferred InDesign source verification.

**Scenarios:** S10 (10 entries), S11 (uniform dimensions), S12 (R-slot positive angles), S13 (L-slot negated angles), S14 (R5/L5 bleedBottom true)

---

### R4 — AlbumBodaHaloContent Value Object

Immutable value object with:
- `photoPaths` (`List<String>`, exactly 10 enforced at factory)
- `titleLine1` (String, default `'Boda de'`)
- `titleLine2` (String, e.g. "Nombre&Nombre")
- `dateSubtitle` (String)
- `qrPayloadLeft` (String)
- `qrPayloadRight` (String)
- `qrCaptionLeftOverride` (String?, default `null`)
- `qrCaptionRightOverride` (String?, default `null`)

Implements value equality with list equality on `photoPaths`.

**Scenarios:** S15 (constructs with defaults), S16 (equality), S17 (inequality when photoPaths differ)

---

### R5 — DotsAlbumSpreadPage.bodaHalo Factory

Named factory accepting `DotsAlbumType`, `int pageNumber`, `String contextLabelValue`, `AlbumBodaHaloContent`.

Returns `DotsAlbumSpreadPage` with exactly 15 elements:
- 10 `DotsRotatedPhotoElement` (assetPath = `content.photoPaths[i]`, geometry from `kBodaHaloLayout[i]`, R-slots +203 mm)
- 2 `DotsOvalQrElement` (gutter QR cards, 25.841×43.127 mm, left at x=176mm, right at x=230mm, y=190.87mm)
  - Left caption default: `'Vuestro álbum en digital'`
  - Right caption default: `'Escanea el QR para volver a ver el álbum y los vídeos'`
  - Caption overrides from content win when non-null
- 3 `DotsTextElement`:
  - Title line 1: P22 Mackinac Medium 23 pt / 27.6 pt leading, left at (19 mm, 43 mm)
  - Title line 2: same style, 27.6 pt below line 1
  - Date subtitle: P22 Mackinac Book 9 pt / 10.8 pt leading, 5 mm below line 2

**Header:** `leftPageNumber = '$pageNumber'`, `rightPageNumber = '${pageNumber + 1}'`, `centerLabel = contextLabelValue`

**Validation:**
- Throws `ArgumentError` if `type != DotsAlbumType.boda`
- Throws `RangeError` if `content.photoPaths.length != 10` (before element construction)

**Scenarios:** S18–S24 (15 elements, assetPath mapping, header, type/length validation, caption overrides)

---

### R6 — buildBodaHaloPageFor Builder

Top-level function with defense-in-depth validation:
```dart
buildBodaHaloPageFor(
  DotsAlbumType type,
  AlbumBodaHaloContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) → DotsAlbumSpreadPage
```

Throws `ArgumentError` for non-boda type; throws `RangeError` for `photoPaths.length != 10`. Delegates to `DotsAlbumSpreadPage.bodaHalo(...)`.

**Scenarios:** S25–S27 (returns page, rejects non-boda types, rejects length mismatch)

---

### R7 — Renderer Dispatch (5 Exhaustiveness Arms)

Five sealed-switch arms for `DotsRotatedPhotoElement`:

1. **`album_spread_page.dart` `_buildElement`** → calls `_buildRotatedPhotoElement(...)`
2. **`dots_renderer.dart` `_buildElement` (ElementsPage)** → returns `null`
3. **`dots_renderer.dart` `preloadAssetBytes` (DotsElementsPage)** → adds `element.assetPath` to paths list
4. **`dots_renderer.dart` `preloadAssetBytes` (DotsAlbumSpreadPage)** → adds `element.assetPath` to paths list
5. **`isolate_synthesis.dart` `_buildElement`** → returns `null`

After all 5 arms: `dart analyze` reports 0 non-exhaustive pattern-match errors.

`DotsOvalQrElement` already handled (slice 5); no new arms needed.

**Scenarios:** S28 (main-isolate render), S29 (worker-isolate parity), S30 (exhaustiveness), S31 (preloadAssetBytes)

---

### R8 — Spread-Width PageSize Contract

When `DotsAlbumSpreadPage` contains `DotsRotatedPhotoElement` and `DotsTemplate.pageSize.width < 406 mm`, renderer MUST emit a logger warning.

**Scenario:** S32 (warning emitted for insufficient width)

---

### R9 — Backwards Compatibility & Public Exports

All slice-1…6 tests pass unchanged. `DotsRotatedPhotoElement` does not affect existing element types.

Public exports from `lib/dots_pdf.dart`:
- `DotsRotatedPhotoElement` (via `src/config/dots_template.dart`)
- `AlbumBodaHaloContent` (new export from `src/api/album_boda_halo_content.dart`)
- `buildBodaHaloPageFor` (new export from `src/api/build_boda_halo_page.dart`)

**Scenarios:** S33 (all prior tests pass), S34 (new symbols importable)

---

## 10-Slot Canonical Layout Reference

**Source:** `extracted_coordinates.md` §2 AABB post-rotation positions.
**Confidence:** MEDIUM (±0.5 mm).
**Conversion:** Pre-computed unrotated top-left via center-preserving rotation (design D1).

All slots use uniform unrotated dimensions: `w = 33.5 mm` (95.0 pt), `h = 46.4 mm` (131.4 pt), `cornerRadiusMm = 6.0`.

See design D1 worked table for full AABB→unrotated conversion detail.

---

## Known Deferred Items

- **Anchor verification** (37.477, 50.388 mm) — InDesign coordinate absent from PDF stream; deferred pending source file access
- **boda p.1, p.2, p.5** — separate work, out of scope
- **Visual QA on MEDIUM-confidence coords** — deferred follow-up; ±2 mm drift on tilted decorative photos sub-perceptual

---

## Deliverables

- New sealed type: `DotsRotatedPhotoElement`
- New layout const: `kBodaHaloLayout` (10 unrotated positions)
- New content VO: `AlbumBodaHaloContent`
- New factory: `DotsAlbumSpreadPage.bodaHalo(...)`
- New builder: `buildBodaHaloPageFor(...)`
- 5 renderer exhaustiveness arms
- 2 new public exports
- 4 new test suites (122 scenarios total)

---

## Test Evidence

- 622 total tests pass (all slices 1–7)
- 0 failures
- `dart analyze`: 0 issues
- All 9 requirements (R1–R9) covered by 34 scenarios across 4 test files
- D1 geometric correctness verified to ±0.001 mm per slot

---

## Archive Information

**Archived:** 2026-05-27
**PR Chain:** Feature-branch-chain (PR 1: scaffolding + model + layout; PR 2: render + factory + builder + exports)
**Status:** Complete, all tasks `[x]`, verify PASS
**Verification Report:** `openspec/archive/album-type-boda-halo/verify-report.md`

