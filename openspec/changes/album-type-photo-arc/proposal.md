# Proposal: album-type-photo-arc

**Slice:** 5 of 5 (FINAL slice in the album-type series)
**Depends on:** album-type-foundation (archived), album-type-simple-pages (archived), album-type-polaroid-collage (archived), album-type-gaussian-circles (archived)
**Status:** Proposed

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

### Element-type strategy (Q1, Q2 — committed inline)

**Q1 verdict — Option A: dedicated `DotsPhotoCircleElement` subtype.**

Rationale: slice 3 introduced `DotsPolaroidElement` instead of flagging `DotsImageElement` with a `clipShape` field, even though both alternatives were on the table. The pattern is now established: **one shape = one subtype**. Adding an `enum DotsClipShape` to `DotsImageElement` (Option B) would force every existing call site that builds a `DotsImageElement` to consider clip semantics, even though 100% of current call sites want the existing rounded-rect behaviour. Option C (composition at the factory layer) was explicitly rejected as fragile in the problem statement. Option A keeps the renderer arms small, the model trivially value-equal, and the sealed switch obviously exhaustive.

**Q2 verdict — Option A: dedicated `DotsOvalQrElement` subtype** bundling oval frame + QR + caption into one element.

Rationale: the oval-QR card is a tightly-coupled composite — the QR is centered inside the oval and the caption is positioned relative to the oval's bottom. Decomposing it (Option B) would require the caller (or factory) to manage three coupled positions. Option C (extending `DotsLayoutPage`'s `_buildQrSlot`) was rejected because `_buildQrSlot` is bound to the `DotsLayoutPage` solver and uses `DotsSlotRect` — `DotsAlbumSpreadPage` does not have a solver and does not produce slot rects. The two systems are deliberately kept apart. The QR rendering implementation will mirror `_buildQrSlot` (same `pw.BarcodeWidget` + same medium-EC default), but the new arm lives inside `album_spread_page.dart` alongside the other element builders.

### Builder + factory pattern (Q3 — committed)

**Q3 verdict — match the slice-3 / slice-4 convention exactly.** No deviation.

- `AlbumPhotoArcContent` value object carries the per-page payload (10 photo paths, 2 QR payloads, 2 optional caption overrides, title, dateSubtitle).
- `DotsAlbumSpreadPage.photoArc(type, pageNumber, contextLabelValue, content)` named constructor materializes the elements list.
- `buildPhotoArcPageFor(type, content, {pageNumber, contextLabelValue})` is the public entry point that applies per-type defaults and validates the type whitelist.

### Per-type QR caption defaults (Q4 — committed)

**Q4 verdict — Q4a: builder resolves per-type defaults; caller may override.** Consistent with slice 4's eyebrow resolution.

| Type | Left caption default | Right caption default |
|------|----------------------|-----------------------|
| parejas | "Vuestro álbum en digital" | "Todos tus hitos en un lugar" |
| hijos | "Tu album en digital" | "Todos tus hitos en un lugar" |
| individuales | "Tu album en digital" | "Todos tus hitos en un lugar" |
| otros | "Tu album en digital" | "Todos tus hitos en un lugar" |
| boda | n/a — `ArgumentError` |

`AlbumPhotoArcContent.qrCaptionLeftOverride` and `qrCaptionRightOverride` (both `String?`, default `null`) let the caller override per-render. When both are `null` for a given side, the per-type default applies.

### Title + subtitle positions (Q5 — committed)

**Q5 verdict — title and subtitle are positioned in single-page (spread-wide) coordinates.** Spec says: title top y = 43 mm, x = 19 mm; 5 mm gap; subtitle below in P22 Mackinac Book 9pt / 10.8pt.

- Title rendered as `DotsTextElement` (single-line, no wrap) — P22 Mackinac Medium 23pt at `(19 mm, 43 mm)` converted to pt.
- Subtitle rendered as `DotsTextElement` at `(19 mm, 43 + 23*1.2/2.834... mm + 5 mm)` — same x, single line. Using `DotsTextElement` (not `DotsTextBlockElement`) because the date string is short and never wraps. If product later wants overflow detection, switch to `DotsTextBlockElement` is a one-line change.
- `contextLabelValue` is consumed by the header trio exactly like slices 2–4. Caller pre-resolves the variable substitution.

### Coordinate convention (Q6 — committed after verification)

**Q6 verdict — single `pw.Page` of spread width (406 mm wide), coordinates stored in mm in `kPhotoArcLayout`, converted to pt at factory time.**

**What I found when reading slice 3's polaroid code:**

`DotsAlbumSpreadPage.polaroidCollage(...)` (lines 951–1003 of `dots_template.dart`) passes `slot.x` and `slot.y` directly as PDF-pt left/top values to `DotsPolaroidElement`. The shared helper `buildAlbumSpreadPage` (in `album_spread_page.dart`) then wraps the whole page in a single `pw.Page(pageFormat: format, ...)`. The polaroid slot positions live in `polaroid_slots.dart` and are expressed in a single-page coordinate frame (x runs 0 → ~203 mm). There is **no two-page composition** anywhere in the album-spread pipeline — what the spec calls a "spread" is rendered as one `pw.Page` whose width matches the caller's `DotsTemplate.pageSize.width`.

This means slice 5 must either (a) author the photo-arc coordinates in a 406-mm-wide single-page frame, or (b) split each arc element into two halves with one rendered per page. Option (b) explodes complexity because every circle that straddles the gutter would need clip arithmetic. Option (a) is the natural fit: callers that want a true 2-page-physical book will set `DotsTemplate.pageSize.width = 406 * mmToPt` for this page; callers that want a single 406-mm-wide art board (preview) get the same code path. The 10 spec coordinates are already authored in 406 mm SPREAD coordinates, so they go in as-is.

`kPhotoArcLayout` is a `const List<({double xMm, double yMm, double diameterMm})>` with 10 entries from the spec table. The factory iterates it to build 10 `DotsPhotoCircleElement` instances.

For the 2 QR ovals, the spec says: "27 mm horizontal distance from each QR center to the gutter" (gutter at x = 203 mm in spread coords), "Top of QR captions: 20 mm above bottom of gutter". The factory computes the two QR positions from those two constants — no caller input on QR positioning.

### Type whitelist (Q7 — committed)

**Q7 verdict — `buildPhotoArcPageFor` throws `ArgumentError` for `DotsAlbumType.boda`** with a message pointing at the unimplemented radial-halo analogue. The other 4 types are all supported and produce geometry-identical output (only QR caption text varies per type).

### Renderer-side changes

Two new arms in `_buildElement` inside `album_spread_page.dart`:

```
case DotsPhotoCircleElement():
  return _buildPhotoCircleElement(element, bytesResolver, onPhotoFailure);

case DotsOvalQrElement():
  return _buildOvalQrElement(element, fontResolver);
```

`_buildPhotoCircleElement` is structurally identical to `_buildImage` except it wraps the `pw.Image` in `pw.ClipOval` instead of `pw.ClipRRect`. Sizing is `width: diameter, height: diameter`. The failure contract (silent skip + `onPhotoFailure` callback) is preserved.

`_buildOvalQrElement` composes a `pw.Stack` containing: (1) an outlined oval frame drawn via `pw.Container(decoration: BoxDecoration(borderRadius: ..., border: ...))` sized `ovalWidth × ovalHeight`, (2) a `pw.BarcodeWidget` centered inside the oval (sized to the inscribed square minus padding), and (3) a `pw.Positioned` caption text below the oval. The QR widget uses `Barcode.qrCode()` with medium error correction, matching `_buildQrSlot` in `dots_renderer.dart`. Caption font is the Inter family resolved via `DotsFontBundle.roleFromFamily('Inter')`.

**Note on font role mismatch with the spec:** The spec says caption font is "P22 Mackinac Book 8pt / 9.6pt". Slice 5 will use **P22 Mackinac Book** (already in the bundle) at 8pt with `lineHeight: 1.2`, color `#9E9E9D`. The original problem statement mentioned "Inter family for QR caption text" — that is incorrect per the spec; the proposal corrects this. Confirm in spec/design phase if there is later evidence the canonical render uses Inter instead.

### Public API exports

Append to `lib/dots_pdf.dart`:

```dart
export 'src/.../album_photo_arc_content.dart' show AlbumPhotoArcContent;
export 'src/.../build_photo_arc_page_for.dart' show buildPhotoArcPageFor;
// DotsPhotoCircleElement and DotsOvalQrElement are added to dots_template.dart
// and re-exported via the existing dots_template.dart export.
```

### Backwards compatibility

- Adding two sealed subtypes does not change any existing element's API. `dart analyze` will flag any non-exhaustive switch — slice 5 adds the two new arms in the only authoritative site (`_buildElement` in `album_spread_page.dart`).
- All slice-1/2/3/4 tests pass unchanged.
- No changes to `DotsLayoutPage`, `DotsElementsPage`, or `_buildQrSlot` in `dots_renderer.dart` (the existing QR plumbing for `DotsSlotKind.qrCard` is untouched).

---

## Risks and Open Questions

- **Spread-width page assumption**: this slice renders the photo-arc as a single 406-mm-wide `pw.Page`. If a caller binds the photo-arc page to a 203-mm `pageSize` (a single physical page), the right-half elements (x > 203 mm) will land outside the page format and silently clip. The factory cannot enforce page width from inside `DotsAlbumSpreadPage` — that's a `DotsTemplate`-level concern. Spec phase should document this assumption explicitly; design phase should consider whether the factory should accept a `pageWidthMm` parameter or throw if `pageFormat.width < 406 * mmToPt` at render time. Tentative recommendation: document in spec, defer the runtime check to a later slice.
- **QR caption font**: spec says P22 Mackinac Book 8pt, but the slice 5 prompt suggested Inter. Spec/design must reconcile. The proposal commits to P22 Mackinac Book per the canonical spec.
- **Oval border styling**: the spec doesn't give an explicit stroke colour or width for the oval frame around the QR. Design phase needs to pick a value (suggested: 0.5 pt, `#9E9E9D`).
- **Diameter uniformity**: spec "Open Question #8" notes the middle-arc circles look larger in the render. Slice 1 locked uniform 44.45 mm. If this is wrong, slice 5 will render an arc that doesn't match the canonical PDF visually — but the locked decision is documented and we honour it.
- **`pw.ClipOval` availability**: the symbol exists in `package:pdf/widgets.dart` (used in `isolate_synthesis.dart` and `dots_cover_renderer.dart`) so adding it to the album-spread helper is safe.
- **Spec ambiguity for the right-page header**: the spec says "Right-page header context: {Año}" for individuales/otros. Slice 5 puts the header context label only at the centre of the header trio (single page treatment). If a future slice splits the spread into two physical pages, the header trio will need re-thinking.

---

## Out of band — what this proposal does NOT decide

The following are deferred to spec + design phases (which may run in parallel):

- Exact pt-precision values for the 10 arc coordinates and 2 QR positions (proposal commits to "mm in `kPhotoArcLayout`, convert at factory").
- The oval frame's stroke colour, stroke width, and corner-radius authoring strategy (`pw.Container` with `BorderRadius.all` for a circle? `pw.CustomPaint` for a true ellipse? Design phase calls it).
- Whether `AlbumPhotoArcContent.photoPaths` length is enforced via `assert`, `ArgumentError`, or `RangeError` at factory time (slice 3 uses `RangeError` — leaning that direction).
- Exact wording of `ArgumentError` for `boda`.
- Acceptance-test list (spec phase writes it).
