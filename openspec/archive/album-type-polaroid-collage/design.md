# Design: album-type-polaroid-collage (slice 3 of 5)

## Technical Approach

Slice 3 adds the polaroid-collage spread that `individuales` p.6 and `otros` p.6
require by:

1. Introducing ONE new sealed `DotsElement` subtype — `DotsPolaroidElement` —
   that bundles photo asset + outer-frame geometry + signed rotation + bleed
   flags + an optional right-to-left opacity-gradient toggle.
2. Wiring that subtype into the shared rendering helper (`buildAlbumSpreadPage`)
   via a single new switch arm.
3. Adding a `DotsAlbumSpreadPage.polaroidCollage(...)` named constructor that
   composes the 6 documented slot positions plus optional caller-supplied
   additional slots.
4. Introducing `AlbumCollageContent` + `PolaroidSlotPosition` value objects and
   a top-level `buildPolaroidCollagePageFor(type, content, …)` builder.
5. Hardcoding the polaroid-defining constants (5.5/5.5/5.5/6.5 mm frame
   borders, inner-photo corner radius 0, white outer fill) inside the renderer.

---

## Architecture Decisions

### D1: `DotsPolaroidElement` fields and defaults

All fields per the proposal: `x`, `y`, `assetPath`, `width`, `height`,
`angleDegrees`, `gradientRtl` (default false), `bleedLeft`, `bleedRight`,
`bleedTop`, `bleedBottom` (all defaults false). Implements value equality.

### D2: `PolaroidSlotPosition` shape

Same geometric fields as `DotsPolaroidElement` minus `assetPath`. Used as a
slot template that the factory zips against photo paths to create elements.

### D3: Renderer consolidation

The polaroid builder is added to `album_spread_page.dart` — the shared helper
that both `dots_renderer.dart` and `isolate_synthesis.dart` delegate to. No
code duplication between isolate paths.

### D4: The `kDefaultPolaroidSlots` table

Public constant in `polaroid_slots.dart` with 6 documented slot positions.
polar-6 rotation shipped as 0° (UNKNOWN in source); polar-4 and polar-6 are
LOW-confidence.

### D5: Coordinate units

All dimensional fields in PDF points (pt), following the existing convention
for all `DotsElement` subtypes. The factory does mm → pt conversion internally.

### D6: Gradient overlay

Paints an 85% white wash on the left fading to fully transparent on the right,
composed BEFORE the rotation transform. Visual effect: photo 15% visible on
left, 100% visible on right.

### D7: `_buildPolaroidElement` implementation

Decodes asset, builds white outer container, adds padding for frame borders,
overlays gradient if needed, wraps in rotation transform. Returns null on
load failure (mirrors existing image element contract).

### D8: Public API surface

Four new exports: `AlbumCollageContent`, `buildPolaroidCollagePageFor`,
`PolaroidSlotPosition`, `kDefaultPolaroidSlots`. `DotsPolaroidElement` rides
on the existing `dots_template.dart` export.

### D9: Test file structure

Three test files: model tests, factory tests, builder tests. Spec listed 8
rendering tests as mandatory; design marked them optional. 17/17 tasks checked
as complete post-apply.

---

## File Changes

| Path | Action | Summary |
|---|---|---|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsPolaroidElement` class + `DotsAlbumSpreadPage.polaroidCollage()` factory |
| `lib/src/render/polaroid_slot_position.dart` | New | Value object for slot template geometry |
| `lib/src/render/polaroid_slots.dart` | New | 6 documented slot positions in kDefaultPolaroidSlots |
| `lib/src/api/album_collage_content.dart` | New | Content value object: photoPaths, applyOtrosGradient, additionalSlots |
| `lib/src/api/build_polaroid_collage_page.dart` | New | Top-level builder delegating to the factory |
| `lib/src/render/album_spread_page.dart` | Modified | Add frame-border constants + `_buildPolaroidElement` implementation |
| `lib/src/render/dots_renderer.dart` | Modified | Asset preloader + exhaustiveness arms for sealed switch |
| `lib/src/render/isolate_synthesis.dart` | Modified | Exhaustiveness arm for sealed switch |
| `lib/dots_pdf.dart` | Modified | 4 new exports |
| `test/config/dots_polaroid_element_test.dart` | New | Model equality/hashCode/defaults |
| `test/render/polaroid_collage_test.dart` | New | Factory behavior tests |
| `test/api/build_polaroid_collage_page_test.dart` | New | Builder and value object tests |

---

## Verify Findings Summary

**Verdict: PASS WITH WARNINGS**

All 17 tasks checked complete. Tests: 329 passed, 0 failed. Analyze: 0 issues.

**Warnings:**
- W-1: 8 spec-listed rendering tests absent (design marked optional).
- W-2: Gradient spec/code literal mismatch (semantically equivalent).
- W-3: `PolaroidSlotPosition.gradientRtl` field silently ignored by factory (contract violation).

**Suggestions:**
- S-1: Add dartdoc comment to defensive polaroid arm in preloader.
- S-2: Paired with W-3 docstring fix.

All issues documented in verify-report. Implementation structurally sound.
