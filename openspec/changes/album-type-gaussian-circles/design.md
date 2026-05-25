# Design: album-type-gaussian-circles (slice 4 of 5)

## Technical Approach

Slice 4 adds the parejas/hijos cover (p.1) by:

1. Introducing ONE new sealed `DotsElement` subtype —
   `DotsDecorativeCircleElement` — that bundles position + diameter + colour +
   Gaussian fade radius + the four bleed flags.
2. Wiring it into the shared `buildAlbumSpreadPage` helper via a single new
   `_buildDecorativeCircleElement(...)` switch arm; defensive `null` arms in
   the other four exhaustiveness sites (preloader x2, main-isolate renderer,
   isolate-side renderer).
3. Pre-rasterizing one PNG per unique `(diameterPt, colorHex, gaussianFadeMm)`
   tuple via `package:image`'s `Image` + `fillCircle` + `gaussianBlur` +
   `encodePng`, cached process-wide.
4. Adding `DotsAlbumSpreadPage.cover(...)` on `dots_template.dart` (where the
   other named constructors live) that composes 14 decorative circles +
   3 text elements (eyebrow / title / date) with header/footer NULL.
5. Adding `AlbumCoverContent` value object and a top-level
   `buildCoverPageFor(type, content, {required pageNumber})` builder that
   resolves the per-type eyebrow default and rejects unsupported types.

---

## Architecture Decisions

### D1: `DotsDecorativeCircleElement` shape and units

| Field             | Type     | Unit        | Default  | Notes                                                       |
| ----------------- | -------- | ----------- | -------- | ----------------------------------------------------------- |
| `x`, `y`          | `double` | pt          | required | un-rotated outer-bbox top-left (super-class fields)         |
| `diameter`        | `double` | **pt**      | required | matches slice 3 (all DotsElement geometry is pt)            |
| `colorHex`        | `String` | `#RRGGBB`   | required | baked into the PNG; renderer does NOT tint at runtime       |
| `gaussianFadeMm`  | `double` | **mm**      | `1.764`  | spec authoring unit; only field where mm beats pt           |
| `bleed{Left,Right,Top,Bottom}` | `bool` | — | `false`  | matches `DotsImageElement` / `DotsPolaroidElement` flags    |

Rationale: `diameter` in pt keeps the sealed hierarchy unit-consistent (renderer
does mm→pt conversion in the factory once, like polaroids). `gaussianFadeMm`
keeps mm because the spec is authored in mm (`1.764 mm`) and every cover circle
shares the same fade. Default `1.764` mm is pinned in dartdoc with a reference
to `SPECS_album_types.md` p.4. Implements value equality and `hashCode` over
all 8 fields (same pattern as `DotsPolaroidElement`).

### D2: Rasterization cache location

**Choice**: D2a — process-wide static `Map` private to
`album_spread_page.dart`, alongside the rasterizer helper.

| Option | Tradeoff                                                    | Verdict   |
| ------ | ----------------------------------------------------------- | --------- |
| D2a    | File-private; cache lives next to its only consumer         | **Chosen** |
| D2b    | New `_DecorativeCircleCache` class; testable in isolation   | Rejected — over-engineering for one map + one rasterizer; no second consumer planned |
| D2c    | Injected dependency; callers provide cache                  | Rejected — no caller needs custom strategy; complicates `buildAlbumSpreadPage` signature |

Exposed for testing via `@visibleForTesting void resetDecorativeCircleCacheForTest()`
that clears the map. Tests run with a hermetic cache by calling
`setUp(() => resetDecorativeCircleCacheForTest())`.

### D3: Rasterization pipeline

Function signature (file-private to `album_spread_page.dart`):

```dart
Uint8List _rasterizeFadedCircle({
  required double diameterPt,
  required PdfColor color,
  required double gaussianFadeMm,
});
```

Pipeline:

1. **Target DPI**: 300 (print-quality default for the rest of the codebase;
   matches dots_cover_renderer conventions).
2. **Canvas size**: `ceil(diameterPx + 2 * fadePx * 3)` per side, where
   `fadePx = gaussianFadeMm / 25.4 * 300` and the ×3 factor reserves room
   for the Gaussian's >99% energy radius (3σ). The circle is centered in the
   canvas. The renderer's `pw.Image` is drawn at the canvas's pt dimensions,
   so the fade halo extends correctly past `diameterPt`.
3. **Build base image**: `img.Image(width: canvasPx, height: canvasPx, numChannels: 4)`
   filled with transparent pixels.
4. **Fill circle**: `img.fillCircle(image, x: canvasPx ~/ 2, y: canvasPx ~/ 2, radius: diameterPx ~/ 2, color: ColorRgba8(r, g, b, 255), antialias: true)`.
5. **Blur**: `img.gaussianBlur(image, radius: fadePx.round())` — the `radius`
   parameter in `package:image` is pixels, not σ. We pass the fade in pixels;
   the spec's "1.764 mm Gaussian-blur edge feather" is interpreted as the
   blur radius in mm (the spec is not more precise than that).
6. **Encode**: `img.encodePng(image)` returns `Uint8List`.

The returned bytes are then wrapped in `pw.MemoryImage` per placement, but
each unique cache-key entry only encodes the PNG once. Renderer draws
`pw.Image(memImage, width: canvasPt, height: canvasPt)` at `Positioned(left: x - haloPt, top: y - haloPt)` so the circle's geometric centre sits at
`(x + diameter/2, y + diameter/2)` — same anchoring convention as the spec
table (top-left of the un-rotated bbox).

### D4: Cache key and Map type

```dart
typedef _CircleCacheKey = ({
  double diameterPt,
  String colorHex,
  double gaussianFadeMm,
});
final Map<_CircleCacheKey, Uint8List> _circleCache = {};
```

Rationale: Dart record-typedef is the modern equivalent of a multi-field key
and gives free `==`/`hashCode`. String concatenation (e.g. `'${d}_${c}_${f}'`)
works but loses type safety and complicates future cache-key extensions.
Diameter is rounded to 4 decimals at rasterization-time to absorb floating-
point noise from mm→pt conversion (`(diameterPt * 10000).round() / 10000.0`)
— this keeps `kCoverCircleLayout`'s 16/28/47 mm circles to ≤3 cache entries
total.

### D5: `kCoverCircleLayout` shape and location

**Location**: `lib/src/render/cover_circles.dart` (new file, sibling of
`polaroid_slots.dart`). **Library-private** (no export from
`lib/dots_pdf.dart`) — slice 3 caused W-3 partly because `PolaroidSlotPosition`
escaped as public surface and gained a field that the factory ignored.
`kCoverCircleLayout` consumed by exactly two callers (the factory and the
test fixture) stays internal.

Shape: file-private class `_CoverCircleAnchor` so the type doesn't leak via
the public `kCoverCircleLayout`. Fields in **mm** (authoring units; factory
converts):

```dart
@immutable
class _CoverCircleAnchor {
  const _CoverCircleAnchor({
    required this.diameterMm,
    required this.xMm,
    required this.yMm,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
  final double diameterMm, xMm, yMm;
  final bool bleedLeft, bleedRight, bleedTop, bleedBottom;
}

const List<_CoverCircleAnchor> kCoverCircleLayout = [
  _CoverCircleAnchor(diameterMm: 47, xMm:   8, yMm:  43),
  _CoverCircleAnchor(diameterMm: 47, xMm: 141, yMm:   4, bleedTop: true),
  _CoverCircleAnchor(diameterMm: 47, xMm: 210, yMm:  33, bleedRight: true),
  _CoverCircleAnchor(diameterMm: 47, xMm: -13, yMm: 169, bleedLeft: true),
  _CoverCircleAnchor(diameterMm: 47, xMm: 200, yMm: 240, bleedRight: true, bleedBottom: true),
  _CoverCircleAnchor(diameterMm: 28, xMm:  36, yMm: 109),
  _CoverCircleAnchor(diameterMm: 28, xMm: 176, yMm:  91),
  _CoverCircleAnchor(diameterMm: 28, xMm:  49, yMm: 193),
  _CoverCircleAnchor(diameterMm: 28, xMm: 138, yMm: 225),
  _CoverCircleAnchor(diameterMm: 16, xMm:  70, yMm:  48),
  _CoverCircleAnchor(diameterMm: 16, xMm: 124, yMm:  68),
  _CoverCircleAnchor(diameterMm: 16, xMm: 170, yMm: 140),
  _CoverCircleAnchor(diameterMm: 16, xMm: 109, yMm: 181),
  _CoverCircleAnchor(diameterMm: 16, xMm:  50, yMm: 273, bleedBottom: true),
];
```

Bleed flags derived from the spec table (`x < 0` ⇒ `bleedLeft`,
`y < 0` ⇒ `bleedTop`, `x + diameter > 203` ⇒ `bleedRight`,
`y + diameter > 254` ⇒ `bleedBottom`). The 47/28/16 mm tiers produce
**3 cache entries total** across all 14 circles.

### D6: `DotsAlbumSpreadPage.cover(...)` factory

**Location**: `dots_template.dart`, alongside `.dedication()`, `.closing()`,
`.polaroidCollage()` — same file all the other factories already live in.

```dart
factory DotsAlbumSpreadPage.cover({
  required DotsAlbumType type,
  required int pageNumber,
  required String title,        // resolved {NombreDelAlbum}
  required String dateLine,     // resolved date string
  String? eyebrowOverride,      // null → use per-type default
});
```

Behaviour:

- Computes per-type default eyebrow when `eyebrowOverride` is `null`:
  - `parejas` → `"DOTBOOK"`
  - `hijos` → `"DOTBOOK DE {NOMBREHIJO}"` (literal token; caller substitutes)
  - any other type → throws `ArgumentError`
    (`'DotsAlbumSpreadPage.cover only supports DotsAlbumType.parejas and DotsAlbumType.hijos; got $type'`).
- Emits 14 `DotsDecorativeCircleElement` instances by mapping
  `kCoverCircleLayout` through:
  ```dart
  DotsDecorativeCircleElement(
    x: anchor.xMm * _mmToPt,
    y: anchor.yMm * _mmToPt,
    diameter: anchor.diameterMm * _mmToPt,
    colorHex: '#CDE7F2',
    gaussianFadeMm: 1.764,
    bleedLeft: anchor.bleedLeft,
    bleedRight: anchor.bleedRight,
    bleedTop: anchor.bleedTop,
    bleedBottom: anchor.bleedBottom,
  )
  ```
- Emits 3 text elements (eyebrow / title / dateLine) — see D8.
- Header: `DotsSpreadHeader()` with all three fields `null` (cover has no
  header trio per spec p.1).
- Footer: `DotsSpreadFooter(wordmark: '')` (empty string; renderer already
  short-circuits `wordmark.isEmpty`).

### D7: `buildCoverPageFor` top-level signature

**Location**: `lib/src/api/build_cover_page.dart` (new file, mirrors
`build_polaroid_collage_page.dart`).

```dart
DotsAlbumSpreadPage buildCoverPageFor(
  DotsAlbumType type,
  AlbumCoverContent content, {
  required int pageNumber,
}) {
  if (type != DotsAlbumType.parejas && type != DotsAlbumType.hijos) {
    throw ArgumentError.value(
      type, 'type',
      'buildCoverPageFor only supports DotsAlbumType.parejas and DotsAlbumType.hijos',
    );
  }
  return DotsAlbumSpreadPage.cover(
    type: type,
    pageNumber: pageNumber,
    title: content.title,
    dateLine: content.dateLine,
    eyebrowOverride: content.eyebrowOverride,
  );
}
```

The builder is a thin shim over the factory — same delegation pattern as
slice 3's `buildPolaroidCollagePageFor` over `polaroidCollage`. The
`ArgumentError` is thrown by BOTH the builder and the factory (defense in
depth — anyone constructing the factory directly still gets the same
contract).

`AlbumCoverContent` (new file `lib/src/api/album_cover_content.dart`):

```dart
@immutable
class AlbumCoverContent {
  const AlbumCoverContent({
    required this.title,
    required this.dateLine,
    this.eyebrowOverride,
  });
  final String title;
  final String dateLine;
  final String? eyebrowOverride;
  // == / hashCode over all 3 fields
}
```

### D8: Text element positions

**Layout interpretation** ("Layout-AUTO centered both axes"):

Page trim is 203 × 254 mm (575.43 × 719.74 pt). The 3-line block is
centered vertically. Text elements use `DotsTextBlockElement` (not
`DotsTextElement`) so the renderer's `pw.SizedBox` + `textAlign: center`
handles the horizontal centering across the full page width — `x = 0`,
`width = pageWidthPt`. This re-uses the same machinery slice 2's
dedication page uses for centered body text.

| Element  | font                  | size  | block width | x   | y (mm)             | notes                       |
| -------- | --------------------- | ----- | ----------- | --- | ------------------ | --------------------------- |
| eyebrow  | `Inter` (Book)        | 9 pt  | full page   | 0   | `(254/2) - 12`     | small caps not enforced; spec calls Inter Book 9pt only |
| title    | `P22 Mackinac Medium` | 23 pt | full page   | 0   | `(254/2) + 0`      | 23 pt / 27.6 pt LH; centered single line |
| dateLine | `Inter` (Book)        | 9 pt  | full page   | 0   | `(254/2) + 18`     | 5 mm gap below title; spec uses Inter Book 9pt / 10.8pt |

Vertical positions chosen so the 3-line block's geometric centre lands at
`pageHeight/2`. Exact y offsets in pt are computed from
`pageHeight / 2 ± offset_mm * _mmToPt`. Spec gives only "AUTO centered both
axes" — these offsets are derived to satisfy that and the documented inter-
line gaps (5 mm between title and date; eyebrow above title by one line).

Small-caps for the eyebrow is **deferred** — the Inter Book TTF in the
bundle does not expose an OpenType `smcp` feature toggle through the `pdf`
package. The spec authors `DOTBOOK` as a literal uppercase string so the
visual outcome is acceptable. Documented as a known gap.

### D9: Public API surface

| Symbol                                  | Export?  | Module                                  |
| --------------------------------------- | -------- | --------------------------------------- |
| `DotsDecorativeCircleElement`           | **Yes**  | rides via `dots_template.dart`          |
| `DotsAlbumSpreadPage.cover(...)`        | **Yes**  | rides via `dots_template.dart`          |
| `AlbumCoverContent`                     | **Yes**  | `src/api/album_cover_content.dart`      |
| `buildCoverPageFor`                     | **Yes**  | `src/api/build_cover_page.dart`         |
| `_CoverCircleAnchor`                    | No       | file-private                            |
| `kCoverCircleLayout`                    | No       | library-private                         |
| `_rasterizeFadedCircle`                 | No       | file-private                            |
| `_circleCache`                          | No       | file-private                            |
| `resetDecorativeCircleCacheForTest`     | No       | `@visibleForTesting` only               |

Four new exports added to `lib/dots_pdf.dart`: `AlbumCoverContent`,
`buildCoverPageFor`. (`DotsDecorativeCircleElement` and `.cover(...)`
already ride on the existing `dots_template.dart` export.)

---

## Exhaustiveness sites

Five sealed-switch sites accept the new element. The same five Slice 3
established:

| # | Site                                                               | Behaviour                                                                       |
| - | ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| 1 | `album_spread_page.dart` `_buildElement` switch                    | New arm calls `_buildDecorativeCircleElement(element)`                          |
| 2 | `dots_renderer.dart` `_buildElement` (DotsElementsPage path)       | `case DotsDecorativeCircleElement(): return null;` (decorative arms aren't valid here) |
| 3 | `dots_renderer.dart` `preloadAssetBytes` — `DotsElementsPage` arm  | `case DotsDecorativeCircleElement(): break;` — no asset path                    |
| 4 | `dots_renderer.dart` `preloadAssetBytes` — `DotsAlbumSpreadPage` arm | `case DotsDecorativeCircleElement(): break;` — no asset path                  |
| 5 | `isolate_synthesis.dart` `_buildElement` switch                    | `case DotsDecorativeCircleElement(): return null;` (rendered via shared helper) |

Sites 3 + 4: explicit `break` with `// no-op: decorative circles have no
asset path` comment. The preloader is the only place where the no-op is
not obvious; dartdoc-style inline comment kills the surprise.

---

## Data Flow

```
caller
  │
  │ AlbumCoverContent(title, dateLine, eyebrowOverride?)
  ▼
buildCoverPageFor(type, content, pageNumber:)
  │
  │ delegates to
  ▼
DotsAlbumSpreadPage.cover(...)
  │
  │ (factory composes 14 circle elements + 3 text elements)
  ▼
DotsAlbumSpreadPage(elements: [14 circles + 3 texts], header: null trio, footer: empty)
  │
  │ rendered via
  ▼
buildAlbumSpreadPage(...)
  │
  │ _buildElement -> case DotsDecorativeCircleElement
  ▼
_buildDecorativeCircleElement
  │
  │ key = (diameterPt, colorHex, gaussianFadeMm)
  ▼
_circleCache[key] ??= _rasterizeFadedCircle(...)
                              │
                              ▼
                       package:image Image + fillCircle + gaussianBlur + encodePng
```

---

## File Changes

| Path                                              | Action   | Summary                                                                       |
| ------------------------------------------------- | -------- | ----------------------------------------------------------------------------- |
| `lib/src/config/dots_template.dart`               | Modified | Add `DotsDecorativeCircleElement` class + `DotsAlbumSpreadPage.cover` factory |
| `lib/src/render/cover_circles.dart`               | New      | `_CoverCircleAnchor` (file-private) + `kCoverCircleLayout` (library-private)  |
| `lib/src/render/album_spread_page.dart`           | Modified | Add `_buildDecorativeCircleElement` + rasterizer + cache + reset hook         |
| `lib/src/render/dots_renderer.dart`               | Modified | 3 new sealed-switch arms (1 `_buildElement` + 2 preloader sites)              |
| `lib/src/render/isolate_synthesis.dart`           | Modified | 1 new sealed-switch arm in `_buildElement`                                    |
| `lib/src/api/album_cover_content.dart`            | New      | `AlbumCoverContent` value object                                              |
| `lib/src/api/build_cover_page.dart`               | New      | `buildCoverPageFor` top-level builder + ArgumentError guard                   |
| `lib/dots_pdf.dart`                               | Modified | 2 new exports (`AlbumCoverContent`, `buildCoverPageFor`)                      |
| `test/config/dots_decorative_circle_element_test.dart` | New      | Model equality / hashCode / defaults                                          |
| `test/render/cover_page_test.dart`                | New      | Factory: 17 elements; header null trio; footer empty; eyebrow per-type; ArgumentError on boda/individuales/otros; render via both isolate paths produces non-empty PDF |
| `test/render/cover_circles_test.dart`             | New      | `kCoverCircleLayout` matches spec table (14 entries; tiers 47/28/16; bleed flags correct) |
| `test/api/build_cover_page_test.dart`             | New      | Builder delegates correctly; ArgumentError on unsupported types               |

---

## Interfaces / Contracts

`DotsDecorativeCircleElement` (sealed subtype):

```dart
class DotsDecorativeCircleElement extends DotsElement {
  const DotsDecorativeCircleElement({
    required super.x,
    required super.y,
    required this.diameter,
    required this.colorHex,
    this.gaussianFadeMm = 1.764,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
  final double diameter;       // pt
  final String colorHex;       // '#RRGGBB'
  final double gaussianFadeMm; // mm; default 1.764 from spec p.4
  final bool bleedLeft, bleedRight, bleedTop, bleedBottom;
  // == and hashCode over all 9 fields (incl. super.x, super.y)
}
```

`AlbumCoverContent` (value object):

```dart
@immutable
class AlbumCoverContent {
  const AlbumCoverContent({
    required this.title,
    required this.dateLine,
    this.eyebrowOverride,
  });
  final String title;
  final String dateLine;
  final String? eyebrowOverride;
  // == and hashCode over all 3 fields
}
```

`buildCoverPageFor` (top-level):

```dart
DotsAlbumSpreadPage buildCoverPageFor(
  DotsAlbumType type,
  AlbumCoverContent content, {
  required int pageNumber,
});
```

Throws `ArgumentError` when `type` is not `parejas` or `hijos`.

---

## Testing Strategy

| Layer       | What                                                                          | Approach                                                                              |
| ----------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Unit        | `DotsDecorativeCircleElement` equality, hashCode, defaults                    | Construct two equal/two unequal instances; assert `==` and `hashCode`                  |
| Unit        | `AlbumCoverContent` equality                                                  | Same pattern                                                                          |
| Unit        | `kCoverCircleLayout` matches spec table                                       | 14 entries; tiers `{47, 28, 16}`; bleed flags derived from the documented coordinates |
| Unit        | `buildCoverPageFor(parejas, ...)` produces 17 elements                        | `result.elements.length == 17`; first 14 are `DotsDecorativeCircleElement`; last 3 are text |
| Unit        | Eyebrow default is `"DOTBOOK"` for parejas, `"DOTBOOK DE {NOMBREHIJO}"` for hijos | inspect text element value                                                            |
| Unit        | `eyebrowOverride` wins over default                                           | construct with override; assert element value                                          |
| Unit        | Unsupported types throw `ArgumentError`                                       | boda / individuales / otros each throw                                                |
| Unit        | Header is null trio; footer wordmark empty                                    | `result.header.leftPageNumber == null && centerLabel == null && rightPageNumber == null`; `result.footer.wordmark.isEmpty` |
| Unit        | Cover for parejas vs hijos differs only in eyebrow                            | clone elements skipping index 0; assert geometry-identical                            |
| Integration | Rasterizer cache hit                                                          | call `_rasterizeFadedCircle` twice with same key; assert identical bytes via reference equality; reset hook clears cache between tests |
| Integration | Render through main-isolate path produces non-empty valid PDF                 | mirrors slice 3's render test                                                          |
| Integration | Render through worker-isolate path produces non-empty valid PDF               | mirrors slice 3's render test                                                          |

The 3 rasterizer-internal tests above are gated by `setUp` calling
`resetDecorativeCircleCacheForTest()` so cache state doesn't leak between
tests.

---

## Migration / Rollout

No migration. Slice is additive: existing templates without
`DotsDecorativeCircleElement` parse and render identically. The
`pubspec.yaml` already has `image: ^4.8.0`. No fonts added.

---

## Open Questions

- [ ] Are the bleed flags derived in D5 actually intended for circles 2/3/5
  (those circles bleed off the spec-stated 203 × 254 mm trim by 1-3 mm)?
  The spec table calls out only 4 ("bleeds off left") and 14 ("bleeds off
  bottom"). Conservative interpretation: flag every circle whose bbox
  exceeds the trim. If wrong, only the bleed-extension paint in
  `dots_cover_renderer` is affected — geometric anchors are unchanged.
- [ ] Confirm "1.764 mm Gaussian-blur edge feather" maps to the `package:image`
  `radius` parameter (pixels at 300 dpi). If the spec is a sigma not a
  radius, multiply by ≈3 — the visual is softer but the centre of the
  circle is unchanged.
- [ ] Confirm `DotsFontRole.inter` is used (D8 references "Inter Book 9pt").
  Slice 2 noted Inter Semibold isn't a separate role yet; Book vs Semibold
  isn't separable through `DotsFontRole.inter` either. If "Book" matters
  visually, follow up after slice 4 with a `DotsFontRole.interBook` analogous
  to the planned `DotsFontRole.interSemibold`.
