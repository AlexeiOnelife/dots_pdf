# Proposal: album-type-polaroid-collage (slice 3 of 5)

## Intent

Slice 1 wired `DotsAlbumType` + `DotsAlbumSpreadPage` plus parse-time variable substitution. Slice 2 turned the simplest two pages (dedication + closing) into real pixels, added `DotsRotatedTextElement` and `DotsTextBlockElement`, and extracted the shared `buildAlbumSpreadPage` helper. Slice 3 delivers the **polaroid collage spread** — the distinctive design of `individuales` p.6 and `otros` p.6: eight tilted polaroid-style photo cards (white frame + inner photo) arranged across a 2-page spread, with rotations at ±2.5°, ±3.5°, +4°, +8°, and one extra right-to-left opacity falloff overlay on a single card for `otros`. After this slice, a caller targeting `individuales` or `otros` can render the dedication, the polaroid collage, AND the closing page — three of the eight body-pages of those templates.

## Scope

### In Scope

- **Polaroid element type**: new sealed `DotsElement` subtype `DotsPolaroidElement` that bundles photo + rotation + (hardcoded) frame border widths into a single, self-describing data type. Coordinate semantics mirror `DotsRotatedTextElement`: `(x, y)` is the **un-rotated outer-frame top-left**, `(width, height)` is the un-rotated outer frame in pt (typically 108 × 134 mm in slice 3), `angleDegrees` is signed (positive = clockwise), rotated around the geometric centre via `pw.Transform.rotate`.
- **Polaroid frame composition (hardcoded in renderer)**: the polaroid is "white container 108 × 134 mm + inner photo 97 × 122 mm with 5.5/5.5/5.5/6.5 mm frame border widths, the whole thing rotated as one unit". Frame border widths and inner-photo corner radius are NOT exposed on the data type; they are renderer-side constants because they are polaroid-defining (a "polaroid with different borders" is no longer a polaroid). See Q3 for rationale.
- **Right-to-left opacity gradient overlay**: a `gradientRtl: bool` field on `DotsPolaroidElement` (default `false`). When `true`, the renderer paints a horizontal linear-gradient mask (right edge 100% → left edge 15%) over the inner photo BEFORE applying the rotation transform. Used by the bottom-left polaroid in `otros` p.6 only.
- **8-polaroid collage spread renderer**: a new `DotsAlbumSpreadPage.polaroidCollage(...)` factory that returns a configured spread with slots placed at the fixed coordinates extracted in `docs/templates/extracted_coordinates.md` § 3. Rendering goes through the existing shared `buildAlbumSpreadPage` helper — slice 3 only adds one new `_buildElement` arm (`DotsPolaroidElement`).
- **Page-set builder extension**: extend slice 2's typed content model with `AlbumCollageContent { List<String> photoPaths, bool applyOtrosGradient, List<PolaroidSlotPosition> additionalSlots }` and surface it via a new top-level builder `buildPolaroidCollagePageFor(type, content, {required pageNumber, required contextLabelValue})`.
- **Coordinate table is hard-coded**: the 5 MEDIUM-confidence slots ship at their extracted positions. LOW (polar-4, polar-6) ship at extracted approximations with a documented confidence caveat. UNKNOWN slots (polar-7, polar-8) — see Q2.
- **Scope is individuales p.6 AND otros p.6 ONLY**: identical geometry, otros differs only by the gradient overlay flag on slot polar-2.

### Out of Scope

- **Generic un-framed rotated image primitive (`DotsRotatedImageElement`)**: slice 3 has zero un-framed rotated images. YAGNI — see Q1.
- **boda p.3 decorative cluster** (7 non-rotated photos with per-photo opacity gradients): coordinates are HIGH-confidence but the visual primitive is different (no polaroid frame, no rotation, per-photo edge feather + radial opacity). Belongs to a later slice.
- **boda p.4 radial halo** (10 rotated photos around a page-centre arc): coordinates are MEDIUM but stored post-rotation AABB — rendering requires pre-rotation positions not in the PDF stream. Out of scope; needs source InDesign access. When that slice lands, it will introduce its own un-framed rotated-image type (or extend the model then).
- **Gaussian-fade decorative circles** — slice 4.
- **Photo-circle arc on "Un año lleno de recuerdos"** — slice 5.
- **Cover pages** — slice 4.
- **Body content INSIDE the polaroids** beyond the user-supplied photo: the polaroid is a slot, not a caption-bearing container. No text, no QR.
- **Per-polaroid edge feather / Gaussian blur**: spec for p.6 does not call for it.
- **Authoring the 3 missing coordinates from source files**: documentation / data task, not engineering.
- **Customizable frame border widths or inner-photo corner radius**: polaroid-defining constants; not exposed.

## Capabilities

### New Capabilities

- `album-type-polaroid-collage`: polaroid element type (bundled photo + rotation + frame), 8-slot collage spread renderer, optional right-to-left gradient overlay on individual slots, and the per-type page builder for the collage spread.

### Modified Capabilities

- `album-type-foundation` and `album-type-simple-pages` are NOT modified. Slice 3 only ADDS — a new `DotsElement` subtype (the sealed switch grows ONE arm), a new named constructor on `DotsAlbumSpreadPage`, a new content type, and a new top-level builder. Slice 2's living spec stays intact.
