# Design: album-type-boda-cluster (Slice 6)

**Series:** Album-type body-page closeout — boda p.3 cluster
**Depends on:** slices 1–5 (all archived). This design picks up slice-1 deferred boda p.3 work.
**Aligned with:** proposal.md (this folder).

---

## Technical Approach

Add a new sealed `DotsElement` subtype (`DotsClusterPhotoElement`) carrying per-photo opacity-gradient parameters, mirroring slice 3's `DotsPolaroidElement` pattern (`assetPath` on the element) and reusing slice 4's pre-rasterisation cache pattern for the Gaussian-fade edges. The CLUSTER LAYOUT is library-locked via `kBodaClusterLayout` (7 anchors from `extracted_coordinates.md` §1, HIGH confidence). The PHOTO CONTENT is caller-supplied via `AlbumBodaClusterContent.photoPaths` (length-7 enforced).

Public API symmetry with slice 5: `buildBodaClusterPageFor(DotsAlbumType type, AlbumBodaClusterContent content, {required int pageNumber, required String contextLabelValue})`, throws `ArgumentError` for non-boda. Caller MUST supply a `pageSize.width >= 406 mm`; a runtime warning fires (slice-5 pattern) below threshold.

Title is composed as **two separate `DotsTextElement` instances** (line 1 medium, line 2 medium italic) — no new rich-text subtype. 23pt locked per inline spec callout.

---

## Architecture Decisions

### D1 — `DotsClusterPhotoElement` shape

**Choice:** Sealed subtype with explicit per-photo gradient fields + `gaussianFadeMm` (default `1.764`) + 4 bleed flags.

```dart
@immutable
class DotsClusterPhotoElement extends DotsElement {
  const DotsClusterPhotoElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.width,
    required this.height,
    this.opacityGradientStart = 1.0,
    this.opacityGradientEnd = 1.0,
    this.opacityGradientDirection = DotsGradientDirection.topToBottom,
    this.gaussianFadeMm = 1.764,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
  // assetPath/width/height/gradient fields + bleed flags; full == / hashCode.
}
```

**Alternatives rejected:**
- Overloading `DotsImageElement` with optional gradient fields — pollutes a general primitive; failed the sealed-switch hygiene check (existing arms in 5 sites would need to no-op these new fields).
- Bundled placeholder photos (proposal Q1) — already rejected as visually nonsensical for a wedding library.

**Rationale:** Matches the established pattern from slices 3, 4, and 5 (one sealed subtype per visual primitive). Sentinel `opacityGradientStart == opacityGradientEnd` means "no gradient" — slots 2/3/4 use `(1.0, 1.0)` defaults; slot 1 uses `(1.0, 0.1, bottomToTop)` (100% → 10%); slots 5/6 use `(1.0, 0.3, topToBottom)` (100% → 30%); slot 7 uses `(1.0, 0.0, topToBottom)` (100% → 0%). The renderer can short-circuit gradient passes when start == end.

### D2 — `DotsGradientDirection` enum (new, kept separate from slice 3's `gradientRtl`)

**Choice:** New public enum in `dots_template.dart` (alongside `DotsAlbumType`, `DotsSpreadHalf`, `DotsTextAlign`). 4 values: `topToBottom`, `bottomToTop`, `leftToRight`, `rightToLeft`.

**Alternatives rejected:**
- Replace slice 3's `DotsPolaroidElement.gradientRtl: bool` with this enum — breaking API change for a primitive that already shipped. The polaroid only ever needs one direction; a 2-value bool is the simpler API for that case.
- Restrict to a 2-value enum (`topToBottom`, `bottomToTop`) — boda cluster only needs those two today, but the enum is the public API surface and future-proofing the 4-direction set costs nothing.

**Rationale:** `DotsClusterPhotoElement` and `DotsPolaroidElement` are different primitives; their gradient knobs do not need to be unified. Keeping them separate avoids a breaking change to slice 3.

### D3 — Title font size: 23pt (inline callout wins over table)

**Choice:** Lock title at **23pt / 27.6pt leading** (P22 Mackinac medium for line 1, medium italic for line 2).

**Alternatives rejected:** 27pt/31pt — the spec table hypothesises this; the inline render callout reads 23pt.

**Rationale:** The inline render callout is closer to the source rasterisation; the table value appears to be a draft hypothesis. Proposal already records this choice. **Recorded conflict:** if visual QA later shows 23pt is too small, a follow-up change can shift to 27pt without touching the model — only `buildBodaClusterPageFor` chooses the size.

### D4 — Slot 1 top bleed (y = −7.8 mm above trim)

**Choice:** Set `bleedTop: true` on slot 1 only in `kBodaClusterLayout`. Renderer applies no positional offset — `pw.Stack` does not clip its children, so the slot's 7.8 mm top extension naturally paints into the 3 mm bleed band and 4.8 mm past the bleed edge.

**Alternatives rejected:**
- Clip at the bleed edge — `pw.Stack` doesn't clip, so this would require explicit clipping logic.
- Reject the negative y — would falsify the extracted coordinate.

**Rationale:** This matches the slice-4 decorative-circle approach (circle #2 at y=4 mm sets `bleedTop: true` and the Gaussian halo paints outside the trim naturally). Document the consequence in the renderer: **the cluster's slot 1 paints 4.8 mm past the page top edge into reader/viewer space** — acceptable because PDF viewers crop to MediaBox, not TrimBox.

### D5 — `kBodaClusterLayout` shape and location

**Choice:** Library-private const in a NEW file `lib/src/render/boda_cluster_layout.dart`. File-private `_BodaClusterAnchor` class with mm fields + per-slot gradient settings.

```dart
@immutable
class _BodaClusterAnchor {
  const _BodaClusterAnchor({
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.opacityGradientStart = 1.0,
    this.opacityGradientEnd = 1.0,
    this.opacityGradientDirection = DotsGradientDirection.topToBottom,
    this.bleedTop = false,
  });
  // ...
}

const List<_BodaClusterAnchor> kBodaClusterLayout = <_BodaClusterAnchor>[
  // Slot 1: 94.6, -7.8, 27.5×33.9, gradient bottomToTop 0→1, bleedTop true
  // Slot 2: 86.3, 59.6, 5.0×5.8   (no gradient)
  // Slot 3: 90.0, 31.4, 20.3×24.7 (no gradient)
  // Slot 4: 87.4, 71.3, 12.8×15.2 (no gradient)
  // Slot 5: 103.1, 88.9, 13.7×16.2, gradient topToBottom 1→0
  // Slot 6: 90.4, 103.3, 9.0×10.6, gradient topToBottom 1→0
  // Slot 7: 103.1, 116.6, 7.8×9.2, gradient topToBottom 1→0
];

@visibleForTesting
typedef BodaClusterAnchorForTest = ({double xMm, double yMm, double widthMm,
  double heightMm, double opacityGradientStart, double opacityGradientEnd,
  DotsGradientDirection opacityGradientDirection, bool bleedTop});

@visibleForTesting
List<BodaClusterAnchorForTest> kBodaClusterLayoutForTest = ...;
```

**Alternatives rejected:** put `kBodaClusterLayout` in `album_spread_page.dart` — that file is already 900 lines and growing per slice. A dedicated layout file keeps the render module focused on rendering.

**Rationale:** Mirrors `photo_arc_layout.dart` (slice 5) and `cover_circles.dart` (slice 4). Coordinates are spread-relative (origin = top-left of the 406 mm spread); the factory adds 203 mm to translate from right-page-relative source values in `extracted_coordinates.md` §1.

### D6 — Pre-rasterisation cache: SEPARATE `_clusterPhotoCache`

**Choice:** Add a NEW process-wide cache in `album_spread_page.dart`:

```dart
typedef _ClusterCacheKey = ({
  String assetPath,
  double widthPt,
  double heightPt,
  double opacityGradientStart,
  double opacityGradientEnd,
  DotsGradientDirection opacityGradientDirection,
  double gaussianFadeMm,
});

final Map<_ClusterCacheKey, Uint8List> _clusterPhotoCache = {};

@visibleForTesting
void resetClusterPhotoCacheForTest() => _clusterPhotoCache.clear();

@visibleForTesting
int clusterPhotoCacheSizeForTest() => _clusterPhotoCache.length;
```

**Alternatives rejected:** unify with slice 4's `_circleCache`. Slice 4's key is `(diameterPt, colorHex, gaussianFadeMm)` — geometry + colour only. Slice 6 needs `(assetPath, width, height, gradient*4, fade)` — entirely different shape. A shared cache would require an `Object`-typed key and a sum-type wrapper; no value over two focused caches.

**Rationale:** Different growth model — slice 4 caches at most ~3 entries (3 unique diameters × 1 colour × 1 fade) for 14 circles per page. Slice 6 caches per-photo, so cache size grows with `caller_count × unique_gradient_configurations`. Distinct cache keeps lookup keys type-safe and reset hooks orthogonal (slice 4 tests won't accidentally clear slice 6 state).

### D7 — `_buildClusterPhotoElement` rendering pipeline

**Choice:** Asynchronous helper in `album_spread_page.dart`:

```
1. Compose cache key from element fields.
2. If cache miss → call _rasterizeClusterPhoto(...):
   a. Load source bytes via bytesResolver(assetPath).
   b. Decode with package:image (already used by slice 4).
   c. Resize to target dimensions at 300 DPI.
   d. Apply per-pixel opacity gradient (start → end) along
      DotsGradientDirection.
   e. Apply Gaussian blur to a 1.764 mm edge band (300 DPI).
   f. Encode as PNG; cache bytes.
3. Wrap pw.MemoryImage in pw.Positioned(left: element.x, top: element.y)
   sized to element.width × element.height.
4. On decode failure: call onPhotoFailure(assetPath, error); return null.
```

**Alternatives rejected:** render the gradient at PDF level (`pw.LinearGradient` overlay) like slice 3 polaroid. That works for opacity-mask gradients but cannot also produce the soft Gaussian edge feather; doing both in one pass requires pre-rasterisation.

**Rationale:** Slice 4 already proved the pre-rasterisation pattern at this DPI. Per-pixel opacity gives pixel-accurate gradient control independent of PDF renderer quirks.

### D8 — `AlbumBodaClusterContent` and builder signature

**Choice:** Immutable value object + top-level builder:

```dart
@immutable
class AlbumBodaClusterContent {
  const AlbumBodaClusterContent({
    required this.photoPaths,       // List<String>, length-7 enforced
    this.title = 'Antes de empezar',
    this.titleItalicLine = 'el viaje',
    required this.body,
  });
  // value equality (list equality on photoPaths).
}

DotsAlbumSpreadPage buildBodaClusterPageFor(
  DotsAlbumType type,
  AlbumBodaClusterContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type != DotsAlbumType.boda) {
    throw ArgumentError.value(type, 'type',
      'buildBodaClusterPageFor only supports DotsAlbumType.boda');
  }
  return DotsAlbumSpreadPage.bodaCluster(...);
}
```

`DotsAlbumSpreadPage.bodaCluster(...)` validates `content.photoPaths.length == 7` (throws `RangeError`) before any element construction.

**Rationale:** Symmetric with slice 5's `buildPhotoArcPageFor`; throws `ArgumentError` only for unsupported types; throws `RangeError` only for length violations.

### D9 — Public API exports

**Choice:** Add to `lib/dots_pdf.dart`:
- `AlbumBodaClusterContent` (new file `lib/src/api/album_boda_cluster_content.dart`)
- `buildBodaClusterPageFor` (new file `lib/src/api/build_boda_cluster_page.dart`)
- `DotsGradientDirection` (already in `dots_template.dart`, exported via existing barrel line)
- `DotsClusterPhotoElement` (rides on existing `export 'src/config/dots_template.dart'`)

**Rationale:** Matches slice 3/4/5 export shape.

### D10 — Test file structure

| File | Purpose |
|---|---|
| `test/config/dots_cluster_photo_element_test.dart` | Model: constructor, all-field equality, inequality on each field, bleed defaults, gradient defaults. |
| `test/config/dots_gradient_direction_test.dart` | Enum: 4 values, exhaustiveness, name strings. |
| `test/render/boda_cluster_layout_test.dart` | Layout const (7 entries) via `kBodaClusterLayoutForTest`; mm values match `extracted_coordinates.md` §1 within ±0.001 mm. |
| `test/render/boda_cluster_render_test.dart` | Cache hit / miss behaviour, `ArgumentError`, `RangeError`, isolate-parity rendering (slice-2 pattern), bleed handling. |
| `test/api/build_boda_cluster_page_test.dart` | Builder: rejects non-boda types, default title/italic-line, custom content, `photoPaths` propagated to elements, header trio populated. |

**Rationale:** Same shape as slice 4 and slice 5 test directories.

---

## Data Flow

    AlbumBodaClusterContent (photoPaths × 7, title, italic, body)
            │
            ▼
    buildBodaClusterPageFor(type, content, pageNumber, contextLabel)
            │  validates type == boda
            ▼
    DotsAlbumSpreadPage.bodaCluster(...)
            │  validates photoPaths.length == 7
            │  zips photoPaths against kBodaClusterLayout
            ▼
    DotsAlbumSpreadPage(header trio + 7 DotsClusterPhotoElement + 2 DotsTextElement + 1 DotsTextBlockElement)
            │
            ▼
    buildAlbumSpreadPage(...) → _buildElement switch
            │
            ├─ DotsTextElement → _buildText
            ├─ DotsTextBlockElement → _buildTextBlock
            └─ DotsClusterPhotoElement → _buildClusterPhotoElement
                       │
                       ▼
              _clusterPhotoCache  ← (cache key includes gradient params)
                       │
                       │ miss
                       ▼
              _rasterizeClusterPhoto → bytesResolver + package:image
                       │
                       ▼
              pw.MemoryImage → pw.Positioned

---

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/config/dots_template.dart` | Modify | Add `DotsGradientDirection` enum + `DotsClusterPhotoElement` sealed arm with `==` / `hashCode`. Add `DotsAlbumSpreadPage.bodaCluster` named factory. |
| `lib/src/render/boda_cluster_layout.dart` | Create | Library-private `_BodaClusterAnchor` + `kBodaClusterLayout` (7 entries) + `@visibleForTesting` projection. |
| `lib/src/render/album_spread_page.dart` | Modify | Add `_buildClusterPhotoElement`, `_rasterizeClusterPhoto`, `_clusterPhotoCache`, reset/size test hooks. Add `_buildClusterPhotoElement` arm to `_buildElement` switch. |
| `lib/src/render/dots_renderer.dart` | Modify | 3 new exhaustiveness arms: `_buildElement` returns `null`; both `preloadAssetBytes` switches (`DotsElementsPage` + `DotsAlbumSpreadPage`) add `paths.add(element.assetPath)`. |
| `lib/src/render/isolate_synthesis.dart` | Modify | 1 new exhaustiveness arm in `_buildElement` returning `null`. |
| `lib/src/api/album_boda_cluster_content.dart` | Create | `AlbumBodaClusterContent` value object (4 fields, value equality, list equality on `photoPaths`). |
| `lib/src/api/build_boda_cluster_page.dart` | Create | `buildBodaClusterPageFor` top-level builder. |
| `lib/dots_pdf.dart` | Modify | Re-export `AlbumBodaClusterContent`, `buildBodaClusterPageFor` (and the new symbols already ride existing barrel exports). |
| `test/config/dots_cluster_photo_element_test.dart` | Create | Model tests. |
| `test/config/dots_gradient_direction_test.dart` | Create | Enum tests. |
| `test/render/boda_cluster_layout_test.dart` | Create | Layout-const tests. |
| `test/render/boda_cluster_render_test.dart` | Create | Render + cache + isolate-parity tests. |
| `test/api/build_boda_cluster_page_test.dart` | Create | Builder + factory validation tests. |

**Exhaustiveness arms (5 sites × 1 new element type = 5 arms):**
1. `album_spread_page.dart` `_buildElement` → `_buildClusterPhotoElement`
2. `dots_renderer.dart` `_buildElement` (ElementsPage path) → `return null`
3. `dots_renderer.dart` `preloadAssetBytes` (`DotsElementsPage`) → `paths.add(element.assetPath)`
4. `dots_renderer.dart` `preloadAssetBytes` (`DotsAlbumSpreadPage`) → `paths.add(element.assetPath)`
5. `isolate_synthesis.dart` `_buildElement` → `return null`

---

## Interfaces / Contracts

- `DotsClusterPhotoElement` — see D1.
- `DotsGradientDirection` — see D2.
- `AlbumBodaClusterContent` — see D8.
- `buildBodaClusterPageFor` — see D8.
- `DotsAlbumSpreadPage.bodaCluster(...)` — named factory; signature `({required DotsAlbumType type, required int pageNumber, required String contextLabelValue, required AlbumBodaClusterContent content})`.

---

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Model equality / hashCode / inequality across every field | `test/config/dots_cluster_photo_element_test.dart` |
| Unit | `DotsGradientDirection` enum value set + exhaustiveness | `test/config/dots_gradient_direction_test.dart` |
| Unit | `kBodaClusterLayout` matches `extracted_coordinates.md` §1 within ±0.001 mm | `test/render/boda_cluster_layout_test.dart` via `kBodaClusterLayoutForTest` |
| Unit | Cache hit/miss + reset hook | `test/render/boda_cluster_render_test.dart` |
| Integration | Factory validates `photoPaths.length == 7` (throws `RangeError`) | builder + factory tests |
| Integration | Builder rejects 4 non-boda types (`ArgumentError`) | builder tests |
| Integration | Main vs worker isolate produce byte buffers within 20% size tolerance | parity test (slice-2 pattern) |
| Integration | Rendered PDF contains "Antes de empezar", "el viaje", body text; 7 cluster elements positioned correctly | end-to-end render test |

---

## Migration / Rollout

No migration required. New public symbols are purely additive. Existing tests pass unchanged (verified by slices 1–5 backwards-compatibility test guard).

---

## Open Questions

- [ ] Visual QA: confirm 23pt title size against the design reference. Recorded in D3.
- [ ] Visual QA: confirm slot 1's 4.8 mm past-trim paint is acceptable when the PDF viewer crops to MediaBox (D4). If unacceptable, add an explicit clip in `_buildClusterPhotoElement`.
- [ ] Performance: `_rasterizeClusterPhoto` decodes + resizes + applies gradient + Gaussian-blurs 7 photos on first render. Slice 4 already established this is acceptable for 14 circles; 7 photos with larger pixel counts may be heavier. If render-time regresses, lower the rasterisation DPI from 300 to 200 (still print-acceptable).

---

## References

- Proposal: `openspec/changes/album-type-boda-cluster/proposal.md`
- Foundation spec: `openspec/specs/album-type-foundation.md`
- Polaroid (slice 3) spec: `openspec/specs/album-type-polaroid-collage.md`
- Gaussian-circle (slice 4) spec: `openspec/specs/album-type-gaussian-circles.md`
- Photo-arc (slice 5) spec: `openspec/specs/album-type-photo-arc.md`
- Slot coordinates: `docs/templates/extracted_coordinates.md` § 1
- Cache pattern reference: `lib/src/render/album_spread_page.dart` lines 334–360 (`_circleCache`), 395–431 (`_rasterizeFadedCircle`), 464–505 (`_buildDecorativeCircleElement`)
