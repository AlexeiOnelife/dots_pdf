# Design: album-type-polaroid-collage (slice 3 of 5)

## Technical Approach

Slice 3 adds the polaroid-collage spread that `individuales` p.6 and `otros` p.6
require. It does so by:

1. Introducing ONE new sealed `DotsElement` subtype — `DotsPolaroidElement` —
   that bundles photo asset + outer-frame geometry + signed rotation + bleed
   flags + an optional right-to-left opacity-gradient toggle.
2. Wiring that subtype into the shared rendering helper
   (`buildAlbumSpreadPage`) via a single new switch arm, and into the asset
   preloader / two `_buildElement` switches that currently exist in
   `dots_renderer.dart` and `isolate_synthesis.dart`.
3. Adding a `DotsAlbumSpreadPage.polaroidCollage(...)` named constructor that
   composes the 6 documented slot positions (`polar-1` … `polar-6`) plus
   optional caller-supplied `additionalSlots` into a `List<DotsElement>`.
4. Introducing `AlbumCollageContent` + `PolaroidSlotPosition` value objects and
   a top-level `buildPolaroidCollagePageFor(type, content, …)` builder that
   mirrors slice 2's `buildSimplePagesFor` shape.
5. Hardcoding the polaroid-defining constants (5.5/5.5/5.5/6.5 mm frame
   borders, inner-photo corner radius 0, white outer fill) inside the renderer
   — NOT on the data type — so the model stays free of styling concerns.

All decisions below are concrete enough that `/sdd-tasks` can break them into a
checklist.

---

## Architecture Decisions

### Decision D1: `DotsPolaroidElement` field types and defaults

**Chosen**: the proposal's sketch, refined for pt units (D5).

```dart
class DotsPolaroidElement extends DotsElement {
  const DotsPolaroidElement({
    required super.x,            // un-rotated outer-frame top-left, pt
    required super.y,            // un-rotated outer-frame top-left, pt
    required this.assetPath,     // inner photo
    required this.width,         // un-rotated outer frame, pt (typ. 108 mm × _mmToPt)
    required this.height,        // un-rotated outer frame, pt (typ. 134 mm × _mmToPt)
    required this.angleDegrees,  // signed; positive = clockwise
    this.gradientRtl = false,    // right-to-left opacity mask on inner photo
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
  final bool bleedLeft;
  final bool bleedRight;
  final bool bleedTop;
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is DotsPolaroidElement &&
      other.x == x &&
      other.y == y &&
      other.assetPath == assetPath &&
      other.width == width &&
      other.height == height &&
      other.angleDegrees == angleDegrees &&
      other.gradientRtl == gradientRtl &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x, y, assetPath, width, height, angleDegrees,
        gradientRtl, bleedLeft, bleedRight, bleedTop, bleedBottom,
      );
}
```

**Rationale**: identical defaults shape to `DotsImageElement` (bleed flags
default `false`), `gradientRtl` defaults `false` because only one slot in one
album type uses it. `@immutable`, equality and `hashCode` follow the existing
slice-2 pattern for all `DotsElement` subtypes — they are value objects.

### Decision D2: `PolaroidSlotPosition` shape

**Chosen**: same fields as `DotsPolaroidElement` MINUS `assetPath`, named with
clear naming so the slot table reads as positions, not as half-built elements.

```dart
@immutable
class PolaroidSlotPosition {
  const PolaroidSlotPosition({
    required this.x,             // un-rotated outer-frame top-left, pt
    required this.y,             // un-rotated outer-frame top-left, pt
    required this.width,         // outer frame width, pt
    required this.height,        // outer frame height, pt
    required this.angleDegrees,
    this.gradientRtl = false,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double angleDegrees;
  final bool gradientRtl;
  final bool bleedLeft;
  final bool bleedRight;
  final bool bleedTop;
  final bool bleedBottom;

  // Equality + hashCode follow the same pattern as DotsPolaroidElement.
}
```

**Rationale**: this is the "slot template" — geometry plus pre-determined
overlay flag, but no photo. The factory zips a `List<String> photoPaths`
against the slot list to produce `DotsPolaroidElement` instances. Keeping it
as a separate type (instead of `DotsPolaroidElement` with a sentinel `null`
asset) preserves "asset-required" semantics on the rendered element.

### Decision D3: Where the polaroid renderer + constants live

**Chosen**: extend the existing shared helper in `album_spread_page.dart` —
this is the slice-2 consolidation point. Both `dots_renderer.dart` and
`isolate_synthesis.dart` delegate `DotsAlbumSpreadPage` rendering to it; the
new arm rides for free in both paths.

Specifically, `lib/src/render/album_spread_page.dart`:

```dart
// Top-level private constants (added near _kHeaderLeftX).
const double _kPolaroidFrameLeftBorderMm   = 5.5;
const double _kPolaroidFrameRightBorderMm  = 5.5;
const double _kPolaroidFrameTopBorderMm    = 5.5;
const double _kPolaroidFrameBottomBorderMm = 6.5;

// In _buildElement (line ~176 of the current file), add ONE arm:
case DotsPolaroidElement():
  return _buildPolaroidElement(
    element: element,
    bytesResolver: bytesResolver,
    onPhotoFailure: onPhotoFailure,
  );
```

**Asset preloader updates** (NOT element rendering — these scan for
`assetPath` only):

- `lib/src/render/dots_renderer.dart` line ~55–67 (`case DotsAlbumSpreadPage()`
  inner element switch): add `case DotsPolaroidElement(): paths.add(element.assetPath);`
- `lib/src/render/dots_renderer.dart` line ~38–49 (`case DotsElementsPage()`
  inner element switch): same arm; on an elements page a polaroid is not
  expected but the sealed switch must still be exhaustive — add the arm and
  push to `paths` (defensive; mirrors how `DotsImageElement` is treated there).

**`_buildElement` on the two legacy renderers** (NOT used for spreads, but the
sealed switch must remain exhaustive):

- `lib/src/render/dots_renderer.dart` line ~369: `case DotsPolaroidElement(): return null;` (same pattern as `DotsRotatedTextElement` on line 377 — only valid inside `DotsAlbumSpreadPage` and rendered there).
- `lib/src/render/isolate_synthesis.dart` line ~288: same `case DotsPolaroidElement(): return null;`.

**Rationale**: slice 2 made `buildAlbumSpreadPage` THE single rendering path
for spreads. Adding the polaroid builder there is the same pattern slice 2
used for `_buildRotatedText` and `_buildTextBlock`. The two stale
`_buildElement` switches still exist on `DotsRenderer` and
`_IsolatePageRenderer` because they handle non-spread pages
(`DotsElementsPage`); they get cheap no-op arms to keep the sealed switch
exhaustive and `dart analyze` clean. Same for the asset preloader scans.

### Decision D4: The `polaroid_slots.dart` table

**Chosen**: a new file `lib/src/render/polaroid_slots.dart` exporting a public
top-level constant `kDefaultPolaroidSlots`.

```dart
import '../config/dots_template.dart' show DotsPolaroidElement;
import 'polaroid_slot_position.dart' show PolaroidSlotPosition;

const double _mmToPt = 2.834645669;
const double _outerWidthPt  = 108.0 * _mmToPt;  // ~306.14 pt
const double _outerHeightPt = 134.0 * _mmToPt;  // ~379.84 pt

/// The 6 documented slot positions for the polaroid-collage spread.
///
/// Order is significant — entries are zipped against the caller-supplied
/// photo paths in that order. `polar-1` first, then `polar-2`, …, `polar-6`.
/// Confidence per slot:
/// - polar-1, polar-3, polar-5: MEDIUM (spec-callout + render cross-checked)
/// - polar-2: MEDIUM (bleeds off left page edge at +8°)
/// - polar-4: LOW (~±2 mm visual drift)
/// - polar-6: LOW geometry, UNKNOWN rotation (defaulted to 0°)
const List<PolaroidSlotPosition> kDefaultPolaroidSlots = <PolaroidSlotPosition>[
  PolaroidSlotPosition(
    x: 21.0 * _mmToPt,
    y: 18.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -2.5,
  ),
  PolaroidSlotPosition(
    x: 0.0,
    y: 120.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 8.0,
    bleedLeft: true, // bleeds off left page edge at +8°
  ),
  PolaroidSlotPosition(
    x: -5.0 * _mmToPt,
    y: 18.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 4.0,
  ),
  PolaroidSlotPosition(
    x: -5.0 * _mmToPt,
    y: 35.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -2.5,
  ),
  PolaroidSlotPosition(
    x: 48.5 * _mmToPt,
    y: 69.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -3.5,
  ),
  PolaroidSlotPosition(
    x: 95.0 * _mmToPt,
    y: 120.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 0.0, // polar-6 rotation UNKNOWN in extracted_coordinates.md;
                       // shipped as 0° per D4 verdict (safest default).
  ),
];
```

`PolaroidSlotPosition` itself lives in
`lib/src/render/polaroid_slot_position.dart` (separate file, exported via
`lib/dots_pdf.dart`). It does NOT live next to `DotsPolaroidElement` in
`dots_template.dart` because it is a render-time positioning helper, not a
page-model primitive. Element types belong to the model; slot tables belong
to the renderer.

**Public/private decision**: `kDefaultPolaroidSlots` is **public** and
re-exported. Callers may inspect, slice, or replace slots via the factory's
`additionalSlots` parameter. Documenting it publicly also serves as the
authoritative coordinate reference.

**polar-6 default rotation verdict**: **0°**. The extracted coordinates file
flags polar-6's rotation as UNKNOWN. The cluster's visual rhythm (alternating
± angles) does not suggest a single safe non-zero default. 0° is the only
defensible choice — any other angle would be a fabricated guess. Documented
in dartdoc and called out in the spec so a downstream measurement pass can
correct it.

### Decision D5: Coordinate units — mm vs pt

**Verdict: pt.** Every existing `DotsElement` subtype uses PDF points:

- `DotsTextElement.fontSize` — pt
- `DotsImageElement.width / height` — pt (dartdoc line 114: "Render width in
  PDF points")
- `DotsTextBlockElement.width` — pt (dartdoc line 254: "Maximum width of the
  text block in PDF points. The caller converts millimetres to points")
- `DotsElement.x / y` — pt (dartdoc line 47–49: "in PDF points")

**`DotsPolaroidElement` follows the same convention**: `x`, `y`, `width`,
`height` are all in pt. The factory does the mm → pt conversion using the
existing `_mmToPt = 2.834645669` constant (already present in
`dots_template.dart` line 13 and in `album_spread_page.dart` line 38).

`PolaroidSlotPosition` follows the same convention — all dimensional fields
are pt.

**Spec authoring convention**: the dartdoc comments and inline coordinates in
`kDefaultPolaroidSlots` express values as `21.0 * _mmToPt` (literal mm × the
conversion constant) so reviewers can map them to the extracted-coordinates
table by inspection without doing arithmetic in their head. Identical pattern
to slice 2's `DotsAlbumSpreadPage.dedication` factory (lines 608–613 of
`dots_template.dart`).

### Decision D6: Gradient overlay direction and composition

**The photo is opaque on the RIGHT and 15%-visible on the LEFT.** So the
overlay must paint a near-opaque WHITE wash on the LEFT, fading to fully
transparent on the RIGHT. The `pw.LinearGradient` is therefore:

```dart
pw.LinearGradient(
  begin: pw.Alignment.centerLeft,    // start of stop list
  end: pw.Alignment.centerRight,     // end of stop list
  colors: <PdfColor>[
    PdfColor(1, 1, 1, 0.85),         // left edge: 85% white wash → photo 15% visible
    PdfColor(1, 1, 1, 0.00),         // right edge: fully transparent → photo 100% visible
  ],
)
```

**Composition order inside `_buildPolaroidElement`** (un-rotated coordinate
frame, BEFORE the `pw.Transform.rotate` wrapper):

```
pw.Container(
  width: outerWidthPt,
  height: outerHeightPt,
  color: PdfColors.white,            // outer frame fill
  child: pw.Padding(
    padding: pw.EdgeInsets.fromLTRB(
      _kPolaroidFrameLeftBorderMm   * _mmToPt,
      _kPolaroidFrameTopBorderMm    * _mmToPt,
      _kPolaroidFrameRightBorderMm  * _mmToPt,
      _kPolaroidFrameBottomBorderMm * _mmToPt,
    ),
    child: pw.Stack(
      children: <pw.Widget>[
        pw.Image(innerPhoto, fit: pw.BoxFit.cover),  // bottom layer
        if (element.gradientRtl)
          pw.Positioned.fill(child: pw.Container(
            decoration: pw.BoxDecoration(gradient: <the gradient above>),
          )),
      ],
    ),
  ),
)
```

Then wrap the whole `pw.Container` in `pw.Transform.rotate(angle: …,
alignment: pw.Alignment.center, child: …)`, and the rotated whole in a
`pw.Positioned(left: element.x, top: element.y, …)`.

**Rationale**:
- `pw.Padding` is the cleanest way to encode the asymmetric 5.5/5.5/5.5/6.5
  frame borders. `pw.Stack` + manual `pw.Positioned` would work but yields
  more code with no benefit.
- The gradient stack lives INSIDE the padding (the inner-photo coordinate
  frame), so the gradient bounds match the inner photo exactly with no need
  to compute pixel offsets.
- Rotation wraps the ENTIRE container so the polaroid is one rigid unit —
  matches the proposal's R5 risk mitigation.
- `pw.BoxFit.cover` matches the existing `DotsImageElement` behaviour (line
  432 in `dots_renderer.dart`) so photo cropping semantics are identical to
  the closing-page photo slot.

### Decision D7: `_buildPolaroidElement` signature and skeleton

```dart
Future<pw.Widget?> _buildPolaroidElement({
  required DotsPolaroidElement element,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required void Function(String assetPath, Object error) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null; // silently skip — same contract as _buildImage
  }

  final angleRadians = element.angleDegrees * pi / 180.0;

  // Polaroid body — un-rotated.
  final body = pw.Container(
    width: element.width,
    height: element.height,
    color: PdfColors.white,
    child: pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(
        _kPolaroidFrameLeftBorderMm   * _kMmToPt,
        _kPolaroidFrameTopBorderMm    * _kMmToPt,
        _kPolaroidFrameRightBorderMm  * _kMmToPt,
        _kPolaroidFrameBottomBorderMm * _kMmToPt,
      ),
      child: pw.Stack(
        children: <pw.Widget>[
          pw.Image(image, fit: pw.BoxFit.cover),
          if (element.gradientRtl)
            pw.Positioned.fill(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight,
                    colors: <PdfColor>[
                      PdfColor(1, 1, 1, 0.85),
                      PdfColor(1, 1, 1, 0.00),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Transform.rotate(
      angle: angleRadians,
      alignment: pw.Alignment.center,
      child: body,
    ),
  );
}
```

**Bleed flags**: slice 3 does NOT expand the rendered geometry for bleed —
unlike `DotsImageElement`. The bleed flags on `DotsPolaroidElement` exist to
declare INTENT (polar-2 bleeds off the left edge at +8°), which the factory
uses to set up the slot, and which a future enhancement (or a test asserting
"polar-2 carries `bleedLeft: true`") can read. The rotation transform
already lets the rotated rectangle extend past the page edge naturally — the
PDF `pw.Page` only clips to the page format, and the renderer's page format
includes the 3 mm bleed band by construction. Documenting this clearly in
the dartdoc avoids confusion vs `_buildImage`'s explicit bleed math.

### Decision D8: Public API surface

New public symbols exported from `lib/dots_pdf.dart`:

```dart
// In lib/dots_pdf.dart — added after the existing slice-2 exports.
export 'src/api/album_collage_content.dart'
    show AlbumCollageContent;
export 'src/api/build_polaroid_collage_page.dart'
    show buildPolaroidCollagePageFor;
export 'src/render/polaroid_slot_position.dart'
    show PolaroidSlotPosition;
export 'src/render/polaroid_slots.dart'
    show kDefaultPolaroidSlots;
// DotsPolaroidElement is automatically re-exported via
// 'src/config/dots_template.dart' (already in the export list).
```

The new `polaroidCollage` named constructor on `DotsAlbumSpreadPage` rides
along automatically — it is added to the existing class in
`dots_template.dart`.

### Decision D9: Tests file structure

**Chosen**: keep the proposal's two test files PLUS a third focused on the
model class itself.

| Path | Scope |
|---|---|
| `test/config/dots_polaroid_element_test.dart` | Pure model: equality, hashCode, defaults, sealed-switch exhaustiveness (`dart analyze` smoke test via a `switch` block) |
| `test/render/polaroid_collage_test.dart` | `DotsAlbumSpreadPage.polaroidCollage(...)` factory: emits 6 elements by default; `additionalSlots: [a, b]` emits 8; `applyOtrosGradient: true` sets `gradientRtl: true` on slot index 1 (polar-2) and `false` on all others; geometry matches `kDefaultPolaroidSlots` |
| `test/api/build_polaroid_collage_page_test.dart` | Builder behavior across album types: header carries `{Año}` for both `individuales` and `otros`; identical geometry across both types except the gradient flag on polar-2; `pageNumber` correctly forwarded |

**Optional**: a render-smoke test under `test/render/` that drives a single
spread end-to-end through `buildAlbumSpreadPage` with a stub bytes-resolver
to verify the widget tree contains a `pw.Transform.rotate` per polaroid and
no exceptions. This may be deferred to `sdd-apply` if the existing test
patterns make it trivial.

---

## File-by-File Plan

| Path | Action | Notes |
|---|---|---|
| `lib/src/config/dots_template.dart` | Modified | Add `DotsPolaroidElement` class (after `DotsTextBlockElement`, before `DotsSpreadHalf`). Add `DotsAlbumSpreadPage.polaroidCollage(...)` factory after the existing `.closing(...)` factory. |
| `lib/src/render/polaroid_slot_position.dart` | New | `PolaroidSlotPosition` value object (~50 LOC including equality). |
| `lib/src/render/polaroid_slots.dart` | New | Top-level `kDefaultPolaroidSlots` list with the 6 documented positions. Imports `PolaroidSlotPosition` from the file above. |
| `lib/src/api/album_collage_content.dart` | New | `AlbumCollageContent` value object: `photoPaths`, `applyOtrosGradient`, `additionalSlots`. Equality + hashCode. |
| `lib/src/api/build_polaroid_collage_page.dart` | New | Top-level `buildPolaroidCollagePageFor(type, content, *, pageNumber, contextLabelValue)`. Returns `DotsAlbumSpreadPage`. |
| `lib/src/render/album_spread_page.dart` | Modified | Add the 4 frame-border constants near the existing `_kHeaderLeftX`. Add the `case DotsPolaroidElement():` arm to `_buildElement`. Add the new private `_buildPolaroidElement(...)` function near the other `_build*` helpers. |
| `lib/src/render/dots_renderer.dart` | Modified | Add `case DotsPolaroidElement(): paths.add(element.assetPath);` to BOTH asset-preloader element switches (the `DotsElementsPage` arm at line ~38–49 AND the `DotsAlbumSpreadPage` arm at line ~55–67). Add `case DotsPolaroidElement(): return null;` to `_buildElement` at line ~369. |
| `lib/src/render/isolate_synthesis.dart` | Modified | Add `case DotsPolaroidElement(): return null;` to `_buildElement` at line ~288. (The isolate path does not have its own asset preloader — bytes are passed in via `preloadedBytes` populated by the main isolate's preloader.) |
| `lib/dots_pdf.dart` | Modified | Add the four new exports listed under D8. |
| `test/config/dots_polaroid_element_test.dart` | New | Model tests per D9. |
| `test/render/polaroid_collage_test.dart` | New | Factory tests per D9. |
| `test/api/build_polaroid_collage_page_test.dart` | New | Builder tests per D9. |

---

## Public API Delta

Net public additions:

- `DotsPolaroidElement` (rides on the existing `src/config/dots_template.dart` export)
- `PolaroidSlotPosition` (new export)
- `kDefaultPolaroidSlots` (new export)
- `AlbumCollageContent` (new export)
- `buildPolaroidCollagePageFor` (new export)
- `DotsAlbumSpreadPage.polaroidCollage(...)` (new named constructor on an
  already-exported class)

No removals. No renames. No breaking changes to slice 1 or slice 2 APIs.

---

## Open Questions for `/sdd-tasks` and `/sdd-apply`

1. **Bleed widget tree** — `_buildPolaroidElement` does NOT currently expand
   the rectangle by `bleedPt` like `_buildImage` does. If the apply phase
   discovers polar-2 visually clips at the page edge, the helper may need a
   bleed-expand pass mirroring the `_buildImage` math. Tracked as a
   follow-up; should be exercised by an integration render test during apply.
2. **`pw.LinearGradient` + `pw.MemoryImage` interaction** — the proposal's R6
   risk. The apply phase should land a 10-line spike first; if `pw.Stack` +
   `pw.LinearGradient` over a `pw.Image` produces a visually broken result,
   the fallback is `pw.CustomPaint` with a programmatic alpha gradient. The
   design assumes the simple path works.
3. **Polar-6 rotation** — shipped as 0° per D4. A follow-up task (NOT slice
   3) should measure the source InDesign file and update the constant. The
   spec calls out the LOW confidence.
4. **`additionalSlots` ordering** — when callers supply N extra slots, the
   factory simply appends them to the default 6 in the order given, and zips
   them against `photoPaths[6:]`. Callers are responsible for matching the
   list order; the factory does not reorder. This is the simplest contract;
   document it in the dartdoc.
5. **What happens when `photoPaths.length` does not match `6 + additionalSlots.length`?**
   Throw a `RangeError` with a clear message. The contract is "one photo per
   slot, in order". Asserted at factory entry. This needs an explicit test
   case.
6. **`size:exception` likelihood** — the changes touch ~9 files but most are
   small mechanical additions (4 lines per sealed-switch arm, plus one large
   new `_buildPolaroidElement` function). Net estimate: 350–450 changed
   lines. The review-workload guard may flag this; resolve at the tasks
   phase.

---

## Follow-ups (NOT slice 3)

- Measure and ship polar-6's true rotation from source InDesign file.
- Measure and ship polar-7 and polar-8 coordinates so the `additionalSlots`
  parameter is no longer load-bearing for a complete `otros` p.6.
- A render-byte integration test that diffs `useIsolate: true` vs
  `useIsolate: false` outputs (mirrors slice 2's R7 scenario 3) — may slot
  into apply or post-archive.
- Consider an `assert(content.photoPaths.length == 6 + content.additionalSlots.length)`
  or a softer `DotsLogger.warn` for length mismatch, depending on whether the
  apply phase finds callers stretch the contract.
