# Proposal: album-type-photo-arc

**Slice:** 5 of 5 (FINAL slice in the album-type series)
**Depends on:** album-type-foundation (archived), album-type-simple-pages (archived), album-type-polaroid-collage (archived), album-type-gaussian-circles (archived)
**Status:** Completed & Archived

---

## Intent

### What problem are we solving?

After slices 1–4 the library can render every "easy" album-type page (dedication, closing, polaroid collage, parejas/hijos cover). The one remaining page that is shared by **4 of 5 album types** (parejas p.9, hijos p.9, individuales p.7, otros p.7) is the **"Un año lleno de recuerdos" photo-arc spread**: 10 circular-cropped photos in a symmetric arc straddling the gutter, plus 2 oval-framed QR cards centered at the gutter bottom. Without slice 5 the album-type pipeline is one feature short of producing complete books for parejas/hijos/individuales/otros (only boda's analogue, p.4 radial halo, remains blocked on missing coordinate data — out of scope per slice 1's `boda` carve-out).

### Why now?

This is the **final slice** of the planned album-type series. Slices 2–4 have proven the structural foundation (sealed `DotsElement` hierarchy, shared `buildAlbumSpreadPage` helper, factory + builder pattern on `DotsAlbumSpreadPage`, per-type defaults resolved by builders). The photo-arc reuses every one of those mechanisms. Delaying it leaves the album-type API visibly incomplete and forces consumers to author this spread by hand with raw element lists.

### What does success look like?

- 4 album types (parejas / hijos / individuales / otros) can produce a publication-ready photo-arc page via a single `buildPhotoArcPageFor(type, content, pageNumber: ...)` call.
- 10 photos render as **circular crops** at the 10 documented coordinates, all at 44.45 mm uniform diameter (locked in slice 1).
- 2 oval QR card frames render at the bottom-center of the gutter region, each containing a real `pw.BarcodeWidget` QR plus a caption line below it. Caption text varies per type (parejas: "Vuestro álbum en digital"; others: "Tu album en digital"); second caption "Todos tus hitos en un lugar" is identical for all 4 types.
- Title ("Un año lleno de recuerdos") and date subtitle render on the left half of the page.
- Standard header trio (Nº página / context label / Nº página) renders via the slice-2 helper. Context label varies per type and is resolved exactly the way slices 3 & 4 resolve it (caller passes pre-resolved `contextLabelValue`).
- `boda` raises `ArgumentError` (boda has its own p.4 radial halo, blocked on coord gaps).
- All slice-1/2/3/4 tests pass unchanged. Sealed `DotsElement` switch remains exhaustive after `dart analyze`.

---

## Scope

### In scope

- **`DotsPhotoCircleElement`** — new sealed subtype of `DotsElement` carrying `assetPath`, `diameter` (pt), and `(x, y)` (pt top-left of the bounding square). Renderer wraps a `pw.Image` in `pw.ClipOval`.
- **`DotsOvalQrElement`** — new sealed subtype carrying `(x, y)` (pt top-left), `ovalWidth` (pt), `ovalHeight` (pt), `qrPayload` (String), `caption` (String), and styling fields (`captionFontSize`, `captionColorHex`). Renderer paints an outlined oval, a centered QR via `pw.BarcodeWidget`, and the caption text below.
- **`DotsAlbumSpreadPage.photoArc(...)`** — named factory matching the slice-3/4 pattern. Builds the 10 photo-circle elements at the 10 documented coordinates, builds the 2 oval-QR elements at the bottom-center of the gutter, plus 2 text elements (title + date subtitle) and the standard header trio.
- **`AlbumPhotoArcContent`** — immutable value object with: `photoPaths: List<String>` (length 10 enforced), `qrPayloadLeft`, `qrPayloadRight`, `qrCaptionLeftOverride: String?`, `qrCaptionRightOverride: String?`, `title: String` (default "Un año lleno de recuerdos"), `dateSubtitle: String`. Value-equality and `hashCode` per field.
- **`buildPhotoArcPageFor(DotsAlbumType type, AlbumPhotoArcContent content, {required int pageNumber, required String contextLabelValue})`** — top-level builder. Resolves per-type QR caption defaults, dispatches to the factory, throws `ArgumentError` for `DotsAlbumType.boda`.
- **Renderer dispatch** — two new arms in `_buildElement` inside `buildAlbumSpreadPage`: `_buildPhotoCircleElement` (`pw.ClipOval` over a `pw.Image`) and `_buildOvalQrElement` (oval frame + QR + caption). Sealed-switch remains exhaustive.
- **Public API exports** — `DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`, `buildPhotoArcPageFor` all re-exported from `lib/dots_pdf.dart`.
- **Coordinate normalization** — the 10 photo-arc coordinates in the spec are 406-mm-wide SPREAD coordinates (x runs 29.59 → 376.17 mm). Slice 5 stores them in mm in a `kPhotoArcLayout` constant and converts to pt at factory time. The page itself is still rendered as a single `pw.Page` whose `pageFormat.width` is the spread width (set by the caller's `DotsTemplate.pageSize`).

### Out of scope

- **boda p.4 radial halo** — coordinate data missing in the spec ("Open questions" section); slice 1 explicitly carved boda out of the album-type series.
- **Cover designs other than parejas/hijos** — slice 4 already shipped these two; individuales/otros/boda covers are separate work.
- **Spine title spread, instructions spread (5+5 photo grid), "Antes de empezar" spread, dedication-spread wide variant.**
- **Additional decorative primitives** — only the two new element types this slice strictly requires are added.
- **Tapered diameters** — the spec has an open question on whether middle-arc circles are larger than 44.45 mm. Slice 1 locked all 10 at uniform 44.45 mm. Slice 5 does not revisit that decision.

---

## Approach

- **Element types:** Dedicated `DotsPhotoCircleElement` and `DotsOvalQrElement` sealed subtypes (one shape = one subtype pattern from slice 3).
- **Builder + factory pattern:** Match the slice-3 / slice-4 convention exactly.
- **Per-type QR caption defaults:** Builder resolves defaults; caller may override via `qrCaptionLeftOverride` and `qrCaptionRightOverride`.
- **Title + subtitle positions:** Single-page (spread-wide) coordinates; title at (19 mm, 43 mm), subtitle at (19 mm, 57.74 mm).
- **Coordinate convention:** Single `pw.Page` of spread width (406 mm wide); coordinates stored in mm in `kPhotoArcLayout`, converted to pt at factory time.
- **Type whitelist:** `buildPhotoArcPageFor` throws `ArgumentError` for `DotsAlbumType.boda`; other 4 types supported.
- **Renderer:** Two new arms in `_buildElement` inside `album_spread_page.dart`: `_buildPhotoCircleElement` and `_buildOvalQrElement`.

---

## Acceptance Criteria

- All 4 album types (parejas/hijos/individuales/otros) render publication-ready photo-arc spreads
- 10 photos render at circular-crop locations per `kPhotoArcLayout`
- 2 QR ovals render at bottom-gutter positions with per-type captions
- Title and date subtitle render on the left half of the page
- Header trio renders with context label per type
- `boda` rejects with `ArgumentError`
- All slice-1/2/3/4 tests pass unchanged
- `dart analyze` reports zero non-exhaustive-pattern errors
