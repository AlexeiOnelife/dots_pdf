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

## Approach

### Q1 — Naming for the image rotation primitive: **N/A for slice 3**

This slice introduces `DotsPolaroidElement` (Q3 — Option A). No generic un-framed rotated-image type is added; that will be addressed by whichever future slice first needs it (likely boda p.4 halo, when source InDesign data unblocks it). Slice 3 deliberately avoids speculative type addition (YAGNI). Concretely: 1 new element type → 1 new switch arm per `_buildElement` site, not 2.

### Q2 — Coordinates for low-confidence and unknown slots: **Option C — caller-supplied unknowns** (committed)

- LOW-confidence slots (polar-4, polar-6): ship them at the documented approximations. ±1–2 mm visual drift on tilted polaroid edges is invisible at print resolution. Document them in dartdoc / spec with the confidence caveat.
- UNKNOWN slots (polar-7, polar-8): the library ships with the **6 documented slots** as the mandatory positions. The `polaroidCollage(...)` factory accepts `additionalSlots: List<PolaroidSlotPosition>` (default empty) so callers who measure the source files themselves can place additional polaroids. Stubbing them with fake coordinates risks shipping a visually wrong default; omitting them silently is worse.

**Effective ship state**: 6 polaroids by default; callers who supply 2 extra `PolaroidSlotPosition` entries get 8. Document in the spec that 6 is the data-floor and 8 is the design target.

### Q3 — Polaroid frame as a `DotsElement` or wrapper in the helper: **Option A — dedicated `DotsPolaroidElement` subtype** (committed, revised)

The polaroid is a single conceptual unit: a tilted photo card with a fixed white frame. Modelling it as `DotsRotatedImageElement(polaroid: bool, ...)` (previous proposal) leaked rendering styling onto a "generic image" data type — the boolean flag turned one type into two semantically distinct things. Modelling it as a separate `DotsPolaroidElement` keeps **data** (photo + position + rotation + bleed flags + gradient toggle) cleanly separated from **styling** (5.5/5.5/5.5/6.5 mm border widths, inner-photo corner radius = 0, white outer container) which lives in the renderer. The cost is one extra sealed switch arm across the 2 `_buildElement` sites — a worthwhile trade for a clean data model.

**`DotsPolaroidElement` shape**:

```dart
class DotsPolaroidElement extends DotsElement {
  const DotsPolaroidElement({
    required super.x,           // un-rotated outer-frame top-left, pt
    required super.y,           // un-rotated outer-frame top-left, pt
    required this.assetPath,    // inner photo
    required this.width,        // un-rotated outer frame, pt (typ. 108mm)
    required this.height,       // un-rotated outer frame, pt (typ. 134mm)
    required this.angleDegrees, // signed; positive = clockwise
    this.gradientRtl = false,   // right-to-left opacity mask on inner photo
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
  final String assetPath;
  final double width;
  final double height;
  final double angleDegrees;
  final bool gradientRtl;
  // bleed flags carried for polar-2 (bleeds off left edge at +8°).
}
```

**Hardcoded in the renderer (NOT exposed on the element)**:
- Frame border widths: left = right = top = 5.5 mm; bottom = 6.5 mm. Spec-defining for a polaroid.
- Inner-photo corner radius: 0 (classic polaroid rectangular print).
- Outer frame fill color: white.

**Concrete rendering** (inside `_buildPolaroidElement(...)`):
1. Decode `element.assetPath` via the bytes resolver.
2. Build a white outer `pw.Container(width: element.width, height: element.height)`.
3. Place inner `pw.Image` sized `(element.width − 11 mm, element.height − 12 mm)` at offset (5.5 mm, 5.5 mm) inside the outer container — derived from the hardcoded frame border widths.
4. If `element.gradientRtl`, paint a `pw.LinearGradient(begin: right, end: left, colors: [opaque, 15%-opaque])` mask over the inner photo (composed inside the un-rotated coordinate frame).
5. Wrap the whole composition in `pw.Transform.rotate(angle: element.angleDegrees * pi / 180, alignment: pw.Alignment.center)`.

No `polaroid: bool` flag anywhere. No discriminator. The element IS the polaroid.

### Q4 — Public API surface: **Option C — dedicated builder** (committed)

Slice 2's `buildSimplePagesFor` emits dedication and closing. Polaroid collage is a different shape (single spread page, photo-list-driven, no title/body/signature/subtitle), so packing it into `AlbumSimpleContent` would overload that type with unrelated concerns. Instead:

```dart
// New value object.
class AlbumCollageContent {
  const AlbumCollageContent({
    required this.photoPaths,                  // 6 to 8 items
    this.applyOtrosGradient = false,           // otros p.6 only
    this.additionalSlots = const [],           // for Q2 unknown slots
  });
  final List<String> photoPaths;
  final bool applyOtrosGradient;
  final List<PolaroidSlotPosition> additionalSlots;
}

// New top-level builder.
DotsAlbumSpreadPage buildPolaroidCollagePageFor(
  DotsAlbumType type,
  AlbumCollageContent content, {
  required int pageNumber,
  required String contextLabelValue,
});

// Named constructor.
DotsAlbumSpreadPage.polaroidCollage({
  required DotsAlbumType type,
  required int pageNumber,
  required String contextLabelValue,
  required List<String> photoPaths,
  bool applyOtrosGradient = false,
  List<PolaroidSlotPosition> additionalSlots = const [],
});
```

The factory builds the `elements` list as `N × DotsPolaroidElement(...)` instances. When `applyOtrosGradient: true`, slot polar-2 is constructed with `gradientRtl: true`; all other slots stay `gradientRtl: false`. The page is dispatched through the existing shared `buildAlbumSpreadPage` helper — the helper learns one new switch arm (`DotsPolaroidElement`).

### Q5 — Right-to-left opacity gradient overlay: **Option C — spread-level flag** (committed)

The gradient is a single-album-type detail (otros only) applied to one specific slot (polar-2, the bottom-left polaroid). Adding a generic `DotsGradientOverlayElement` is over-engineering for a one-off. Adding a per-element opacity-gradient parameter on a generic image type would leak rendering detail onto unrelated callers.

Instead: the `polaroidCollage(...)` factory accepts `applyOtrosGradient: bool` at the spread level. When `true`, the factory constructs slot polar-2 with `gradientRtl: true` on its `DotsPolaroidElement`. The renderer, inside the polaroid builder, paints the gradient mask before the rotation transform. The geometry stays identical to non-otros; only the alpha mask on slot polar-2 differs. Callers pass one boolean at the spread level and the library handles the rest.

## Locked decisions carried forward from slices 1 + 2

- Variable substitution at parse time — available for any spread page carrying text (not used in slice 3 since the collage spread has no body text).
- Header/footer trio drawn by `buildAlbumSpreadPage` — the polaroid spread carries the same header/footer payload (`{Año}` for both individuales and otros per slice 1's R3 mapping).
- `pw.Transform.rotate` is the rotation primitive (verified in slice 2).
- Rotation around geometric centre (`alignment: pw.Alignment.center`) — same semantics as `DotsRotatedTextElement`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsPolaroidElement` as a new sealed sibling of `DotsElement`. Add `DotsAlbumSpreadPage.polaroidCollage(...)` named constructor. The sealed switch in the renderer's `_buildElement` grows one arm. |
| `lib/src/api/album_collage_content.dart` | New | `AlbumCollageContent` and `PolaroidSlotPosition` value objects. |
| `lib/src/api/build_polaroid_collage_page.dart` | New | Top-level `DotsAlbumSpreadPage buildPolaroidCollagePageFor(...)`. |
| `lib/src/render/album_spread_page.dart` | Modified | Add `_buildPolaroidElement(...)` private builder. Composes white frame + inner image + optional R→L gradient + rotation transform; uses hardcoded 5.5/5.5/5.5/6.5 mm border constants. |
| `lib/src/render/polaroid_slots.dart` | New | Internal table of the 6 documented slot positions (polar-1 … polar-6) with their rotations and inferred page assignments. File-private to the spread factory. |
| `lib/dots_pdf.dart` | Modified | Re-export `DotsPolaroidElement`, `AlbumCollageContent`, `PolaroidSlotPosition`, `buildPolaroidCollagePageFor`. |
| `test/render/polaroid_collage_test.dart` | New | Widget-tree assertions: 6 polaroid elements emitted by default, +N when `additionalSlots` supplied, slot polar-2 carries `gradientRtl: true` iff `applyOtrosGradient: true`. |
| `test/api/build_polaroid_collage_page_test.dart` | New | Builder returns a single `DotsAlbumSpreadPage` with header `{Año}` for both `individuales` and `otros`; identical geometry across both types except gradient flag on polar-2. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `pw.Transform.rotate` does not propagate clipping correctly when nested inside a `pw.ClipRRect` for the inner photo | Med | Compose `pw.Stack { image, gradient_overlay }` BEFORE wrapping in `Transform.rotate` so clipping happens in the un-rotated coordinate frame. Same pattern slice 2 used for `DotsRotatedTextElement`. |
| Slot polar-2 bleeds off the left edge of the left page — at +8° its rotated AABB extends further than the unrotated 108×134 box | Med | Carry `bleedLeft: true` on the `DotsPolaroidElement` and ensure the page format includes the 3 mm bleed band; the `pw.Transform` allows rotated geometry to extend past the page where the bleed is configured. |
| The 3 unknown slots produce a visually incomplete spread until callers measure them | Low | Document explicitly in spec + dartdoc that the default ships 6 slots; reference `additionalSlots` for the rest. Follow-up task (NOT slice 3) extracts the missing coordinates from source files. |
| Drift between main-isolate and worker-isolate paths re-emerges if either bypasses the shared helper | Low | Both call `buildAlbumSpreadPage`; slice 2 already consolidated this. Slice 3 only edits the shared helper. |
| `applyOtrosGradient: true` accidentally enabled for `individuales` (which has no gradient) | Low | The factory accepts the flag for both types, but a spec test asserts the typical `individuales` call leaves it `false`. A linter-style warning when both `individuales` AND `applyOtrosGradient: true` are set is deferred (over-engineering for a one-off). |
| `pw.LinearGradient` mask interaction with `pw.MemoryImage` not previously exercised | Med | Verify with a 10-line spike during apply phase; fallback is `pw.CustomPaint` with a programmatic alpha gradient. |
| `DotsPolaroidElement` is single-purpose — would need restructuring if we ever want framed-but-unrotated polaroids OR un-framed rotated images | Low | Acceptable. The type is YAGNI-aligned: it solves exactly the slice-3 problem. If a future need emerges (e.g., boda p.4 wants un-framed rotation), introduce `DotsRotatedImageElement` THEN, keep `DotsPolaroidElement` as the framed-and-rotated specialization. The sealed-`DotsElement` hierarchy is open to extension under that pattern. |
| Polaroid frame border widths (5.5/5.5/5.5/6.5 mm) produce a subtly asymmetric inner photo bottom-versus-top gap | Low | `108 − 97 = 11 = 2 × 5.5` (sides); `134 − 122 = 12 = 5.5 + 6.5`. The 1 mm asymmetry is visually negligible at print resolution; matches the spec callout. Documented in the renderer's hardcoded constants. |

## Rollback Plan

- Revert the commits introducing `album_collage_content.dart`, `build_polaroid_collage_page.dart`, `polaroid_slots.dart`, and the `DotsPolaroidElement` element type.
- Restore the `_buildElement` switch in `album_spread_page.dart` to the slice-2 arm set.
- The named constructor on `DotsAlbumSpreadPage` is additive — removing it does not break slice 1/2 callers.
- Drop the new test files; existing slice-2 tests remain valid.

## Dependencies

- Slice 2 (`album-type-simple-pages`) — completed and archived. Provides `buildAlbumSpreadPage`, the shared rendering helper, the sealed-`DotsElement` extension pattern, and `DotsRotatedTextElement` as the rotation-semantics reference.
- Slice 1 (`album-type-foundation`) — provides `DotsAlbumType.contextLabelToken` for the `{Año}` header on both `individuales` and `otros`.
- `pdf` package's `pw.Transform.rotate` (slice 2 verified working), `pw.LinearGradient`, `pw.Container` with explicit colour, `pw.Stack`, and `pw.MemoryImage`.
- Extracted coordinates table in `docs/templates/extracted_coordinates.md` § 3 — authoritative source for the 6 documented slot positions.

## Success Criteria

- [ ] `DotsPolaroidElement` is renderable; sealed `DotsElement` switch is exhaustive after the addition; `dart analyze` passes.
- [ ] `DotsAlbumSpreadPage.polaroidCollage(type: DotsAlbumType.individuales, photoPaths: [...6 paths...])` emits 6 `DotsPolaroidElement` instances at the documented coordinates with `gradientRtl: false` everywhere.
- [ ] Same call with `applyOtrosGradient: true` and `type: DotsAlbumType.otros` emits 6 elements; slot polar-2 carries `gradientRtl: true`, all others `gradientRtl: false`.
- [ ] `additionalSlots: [PolaroidSlotPosition(...), PolaroidSlotPosition(...)]` extends the spread to 8 polaroids.
- [ ] Header carries `{Año}` (or the caller-supplied resolved value of that token) for both album types.
- [ ] All existing slice-1 and slice-2 tests pass unmodified.
- [ ] The polaroid frame composition (white outer + inner photo at hardcoded 5.5/5.5/5.5/6.5 mm offsets + optional R→L gradient + rotation) is encapsulated in the shared `buildAlbumSpreadPage` helper — no rendering code duplicated between main-isolate and worker-isolate paths.
- [ ] Output PDFs from both rendering paths are within 20% byte-size tolerance for identical input (mirrors slice 2's R7 scenario).
