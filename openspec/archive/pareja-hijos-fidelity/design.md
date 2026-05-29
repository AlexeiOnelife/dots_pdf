# Design: pareja-hijos-fidelity

## Technical Approach

Approach A from the explore — in-place coordinate corrections on the four
existing factories (`cover`, `dedication`, `closing`, plus eyebrow copy)
PLUS full factory bodies for the two Task-2 stubs (`beforeYouStart`,
`closingQrSpread`). Two new layout-constant files
(`lib/src/render/before_you_start_layout.dart`,
`lib/src/render/closing_qr_spread_layout.dart`) mirror the
`kPhotoArcLayout` / `kBodaClusterLayout` pattern: library-private record
lists keyed by mm coordinates with a `@visibleForTesting` projection.
Both new factories emit ONE `DotsAlbumSpreadPage` in spread coordinates
(0–406 mm); element x values ≥ 203 mm land on the right page. Header is
`leftPageNumber=$pageNumber`, `rightPageNumber=${pageNumber+1}` — same as
`photoArc`. Two content-class deltas: `AlbumBeforeYouStartContent` gains
a `required List<String> photoPaths` (length 10), and `AlbumQrSpreadContent`
gains an optional `String? bottomTextOverride`. No new renderer paths,
no parser changes.

## Architecture Decisions

### Decision 1: QR element for the 27×27 mm closing block — reuse `DotsOvalQrElement` with a square bbox + frame-off knob

| Option | Pro | Con | Decision |
|---|---|---|---|
| (a) Reuse `DotsOvalQrElement` with `ovalWidth == ovalHeight` and a new `drawFrame: bool = true` named param (default keeps existing photoArc behaviour) | Single QR element; renderer already handles inscribed-square QR + caption + asset preload + isolate copy | One additive bool on a public element; renderer arms get a single `if (drawFrame)` around the border | **Chosen** |
| (b) New `DotsSquareQrElement` with frame-less geometry + caption | Pure separation of concerns | Duplicates ~50 LOC of QR logic across `album_spread_page.dart` and `isolate_synthesis.dart`; new asset-preload arm in both | Rejected |
| (c) `DotsImageElement` with caller-pre-rendered QR PNG | Zero new code in this lib | Pushes QR rasterisation onto every caller; defeats the whole point of an `qrPayload`-bearing element type | Rejected |

Rationale: `DotsOvalQrElement` already renders a **square** inscribed QR
(`album_spread_page.dart:733-738` — `qrSidePt = min(width,height) − 2*inset`
and `qrLeftPt/qrTopPt` centre it). The "oval" is purely the optional
elliptical frame stroke (`_kOvalBorderWidthPt = 0.5pt`). Adding
`drawFrame: bool = true` and gating the `BoxDecoration.shape:
BoxShape.circle` block on it lets the closing QR re-use 100% of the QR +
caption pipeline with the frame off and a square 35×35 mm bbox
(`27 mm QR + 2 × 4 mm inset = 35 mm`). The 4 mm inset is the existing
`_kQrInsetMm` constant; we deliberately keep it because the closing QR
caption sits beside the QR (not below), so the inset becomes irrelevant
for layout and we save a renderer-constant fork. Caption text for the
closing variant is the QR_CAPTION (`"Escanea el QR y vuelve…"`); we pass
`caption = ''` and emit a separate `DotsTextBlockElement` because the
explore mandates the caption sits to the RIGHT of the QR
(x=62 mm vs QR at x=30 mm), not below. The default
`drawFrame = true` preserves photoArc behaviour bit-for-bit.

### Decision 2: ONE `DotsAlbumSpreadPage` per spread, elements in spread coords

| Option | Pro | Con | Decision |
|---|---|---|---|
| Single spread page; right-page elements at x ≥ 203 mm | Matches `photoArc` / `bodaCluster` / `bodaHalo` pattern exactly; parser packs as a 2-page mandatory pliego with one call | None | **Chosen** |
| Two separate pages with a `whichPage` enum | Cleaner per-page locality | Diverges from established pattern; doubles header/footer wiring; would force parser to know about pairing | Rejected |

Rationale: pinned by Decision 4 of the proposal. The Task-2 stub's
`pageNumber.isOdd`-parity chrome was incorrect (it never rendered, so
the bug was latent). Fixing it to the spread shape brings the two
factories into uniformity with the rest of the album-type series.

### Decision 3: Layout constants exported as records, library-private with `@visibleForTesting` projection

| Option | Pro | Con | Decision |
|---|---|---|---|
| `const List<({double xMm, double yMm, double widthMm, double heightMm})>` slot records + `const ({double xMm, double yMm, double widthMm, double heightMm}) k…Layout = (…)` for singletons; library-private + `@visibleForTesting` typedef accessor for tests | Mirrors `kPhotoArcLayout` exactly; constants stay out of the public surface; tests assert without leaking private types | Verbose typedef projections in each file | **Chosen** |
| Public constants exported from `lib/dots_pdf.dart` | Tests need no projection | Inflates the public API for internal layout tables | Rejected |
| Custom `_BeforeYouStartSlot` class per file | Stronger typing | New nominal types for trivial bags of doubles | Rejected |

### Decision 4: `beforeYouStart` per-category copy via `switch (type)` with parejas fallback

| Option | Pro | Con | Decision |
|---|---|---|---|
| Exhaustive `switch (type)`: `parejas` + `hijos` real copy; `individuales`, `otros`, `generalEventos` fall through to parejas with `// TODO(task-5-7)`; `boda` throws `ArgumentError` (same guard as `photoArc`) | Sealed enum forces compile-time exhaustiveness; future tasks see the TODO; matches proposal Approach A | Three branches share one body for now | **Chosen** |
| Per-category map of copy constants | DRY-er | Premature for 2-of-5 real branches | Rejected |

### Decision 5: `closing` single-page chrome unchanged

| Option | Pro | Con | Decision |
|---|---|---|---|
| Keep `leftPageNumber=$pageNumber`, `rightPageNumber=$pageNumber` (Task-1 chrome predicate handles parity at draw time) | Zero chrome change; aligns with the rest of the codebase | Both numbers identical in the header struct feels redundant | **Chosen** |
| Set `rightPageNumber=null` to make the intent explicit | Slightly clearer struct | Breaks the existing test expectation; chrome predicate would need adjustment | Rejected |

### Decision 6: `bottomTextOverride` substitution convention

| Option | Pro | Con | Decision |
|---|---|---|---|
| `content.bottomTextOverride ?? '{Protagonistas}, disfruta de está última experiencia.'` (literal token left for caller debug; production caller pre-resolves and passes via `bottomTextOverride`) | Mirrors `contextLabelValue` convention; no new token resolver in this layer | Default contains an unresolved token | **Chosen** |
| Require non-null `bottomTextOverride` | Forces caller to pre-resolve | Hard break on existing `AlbumQrSpreadContent` users | Rejected |

### Decision 7: Parser injection NOT touched

Verified: `dots_template_parser.dart` does not synthesise `beforeYouStart`
or `closingQrSpread` pliegos. Callers build `DotsPliego` instances from
`DotsAlbumSpreadPage` factories directly. The Task-2 spec
(`openspec/specs/pliego-first-category.md`) treats `beforeYouStart` as
one entry between cover and dedication — and "one entry" maps to one
`DotsAlbumSpreadPage` that carries the whole 2-page spread. No
adjustment needed; verified in test.

## Data Flow

    Caller → AlbumBeforeYouStartContent(photoPaths: List<String>[10],
                                        titleOverride?, bodyOverride?)
        │
        ▼
    DotsAlbumSpreadPage.beforeYouStart(type, pageNumber, content, ctxLabel)
        │
        ├── switch(type) → per-category title L1+L2, body, Q1/Q2 copy
        ├── kBeforeYouStartLeftLayout → title/body/CTA records (mm)
        ├── kBeforeYouStartRightLayout → CTA/protagonist records
        ├── kBeforeYouStartPhotoSlots → 10 DotsSlotRect (page-local mm)
        ├── per-page Q1/Q2 cluster records
        ▼
    DotsAlbumSpreadPage{header: leftPN=$pn, rightPN=$pn+1, footer: 'Dots. Memories', elements: ~22}

    Caller → AlbumQrSpreadContent(qrPayload, placement=closing,
                                  captionOverride?, bottomTextOverride?)
        │
        ▼
    DotsAlbumSpreadPage.closingQrSpread(type, pageNumber, content, ctxLabel)
        │
        ├── kClosingQrSpreadLeftLayout → title/body1/qr/caption/bottom records
        ├── DotsOvalQrElement(width=height=35mm, drawFrame: false, caption: '')
        ├── DotsTextBlockElement (QR caption — separate, x=62 mm)
        ▼
    DotsAlbumSpreadPage{header: leftPN=$pn, rightPN=$pn+1, footer: 'Dots. Memories', elements: 5 left, 0 right}

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/api/album_before_you_start_content.dart` | Modify | Add `required List<String> photoPaths`; length-10 invariant via `assert(photoPaths.length == 10)` in const ctor body; extend `==`/`hashCode`/dartdoc. |
| `lib/src/api/album_qr_spread_content.dart` | Modify | Add optional `String? bottomTextOverride`; extend `==`/`hashCode`/dartdoc. |
| `lib/src/render/before_you_start_layout.dart` | New | `const List<_…Slot> kBeforeYouStartPhotoSlots` (10 entries, spread-coords mm) + per-element title/body/CTA/Q1/Q2 record singletons + `@visibleForTesting` accessor. |
| `lib/src/render/closing_qr_spread_layout.dart` | New | Title/body-1/QR/QR-caption/bottom-text record singletons (spread-coords mm, all on left page) + `@visibleForTesting` accessor. |
| `lib/src/config/dots_template.dart` | Modify (heavy) | (1) `DotsOvalQrElement`: add `final bool drawFrame; …drawFrame = true,` to const ctor + `==`/`hashCode`. (2) `cover(parejas\|hijos)`: rewrite eyebrow `switch` to `'DOTBOOK DE {PROTAGONISTA}'` for both; rewrite text positions per drift table (eyebrow y=110.249 mm, title y≈119 mm, date y≈130.7 mm; all at x=41.5 mm width=120 mm). Update dartdoc lines 1499–1502. (3) `dedication(...)`: text-block x=50.53 mm; body width=120 mm; title y=fixed top, body y=title_bottom+6.5 mm, signature y=body_bottom+8 mm. (4) `closing(...)`: photo y=71.534 mm; title/subtitle x=44 mm, subtitle width=115 mm; title y=photo_bottom+5 mm, subtitle y=title_bottom+5 mm. (5) `beforeYouStart(...)`: replace `DotsUnimplementedElement` with real elements per Data Flow. (6) `closingQrSpread(...)`: replace stub with title/body-1/QR/QR-caption/bottom-text on the left half; right half emits chrome only (no body elements). (7) `photoArc` source-comment cosmetic update (Decision Q1). |
| `lib/src/render/album_spread_page.dart` | Modify | `_buildOvalQrElement`: gate the `pw.Container … BoxDecoration(shape: BoxShape.circle, border: …)` block on `if (element.drawFrame)`. Keep the QR `BarcodeWidget` arm unchanged. |
| `lib/src/render/isolate_synthesis.dart` | Modify | Same `_buildOvalQrElement` gate (lock-step copy). Asset-preload `DotsOvalQrElement` arms unchanged (no asset). |
| `lib/dots_pdf.dart` | Modify | Export the updated content classes if not already; layout-constant files stay library-private. |
| `test/api/album_before_you_start_content_test.dart` | Modify | Add `photoPaths` required-param coverage; length-10 invariant test (constructing with length 9 or 11 throws `AssertionError` in debug). |
| `test/api/album_qr_spread_content_test.dart` | Modify | Add `bottomTextOverride` coverage; `==`/`hashCode` differentiates. |
| `test/config/dots_album_spread_page_test.dart` | Modify (heavy) | Update existing `cover`/`dedication`/`closing` fixtures to the new coordinates and eyebrow text. Add new test groups for `beforeYouStart(parejas)`, `beforeYouStart(hijos)`, `closingQrSpread(parejas)`, `closingQrSpread(hijos)`: assert element count, kinds, header trio (`$pn`/`$pn+1`), footer wordmark, key positions, per-category copy. Add `RangeError`/`AssertionError` test for `photoPaths.length != 10`. |
| `test/render/before_you_start_layout_test.dart` | New | Assert `kBeforeYouStartPhotoSlots` has length 10; per-slot xMm/yMm/widthMm/heightMm against explore table; title/body/CTA/Q1/Q2 record values. |
| `test/render/closing_qr_spread_layout_test.dart` | New | Assert title/body-1/QR/caption/bottom-text record values against explore table. |
| `test/render/album_spread_page_test.dart` | Modify | Add `DotsOvalQrElement(drawFrame: false)` rendering test: PDF contains no oval border but contains the QR barcode payload. |

## Interfaces / Contracts

```dart
// lib/src/api/album_before_you_start_content.dart
@immutable
class AlbumBeforeYouStartContent {
  const AlbumBeforeYouStartContent({
    required this.photoPaths,
    this.titleOverride,
    this.bodyOverride,
  }) : assert(photoPaths.length == 10,
            'photoPaths must contain exactly 10 entries');
  final List<String> photoPaths;
  final String? titleOverride;
  final String? bodyOverride;
  // ==, hashCode extended.
}

// lib/src/api/album_qr_spread_content.dart
@immutable
class AlbumQrSpreadContent {
  const AlbumQrSpreadContent({
    required this.qrPayload,
    required this.placement,
    this.captionOverride,
    this.bottomTextOverride,
  });
  final String? bottomTextOverride;
  // existing fields + extended ==/hashCode.
}

// lib/src/config/dots_template.dart
class DotsOvalQrElement extends DotsElement {
  const DotsOvalQrElement({
    required super.x,
    required super.y,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.qrPayload,
    required this.caption,
    this.drawFrame = true,         // NEW — default preserves photoArc
  });
  final bool drawFrame;
  // ==, hashCode extended to include drawFrame.
}
```

```dart
// lib/src/render/before_you_start_layout.dart  (excerpt)
typedef _SlotRectMm = ({double xMm, double yMm, double widthMm, double heightMm});
typedef _TextRectMm = ({double xMm, double yMm, double widthMm});

// 10 photo slots in SPREAD coords (0..406 mm). Slots 0..4 on left page
// (x ∈ [8, 43, 78, 113, 148]); slots 5..9 on right page (x += 203 mm).
const List<_SlotRectMm> kBeforeYouStartPhotoSlots = <_SlotRectMm>[
  (xMm:   8, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm:  43, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm:  78, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 113, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 148, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 211, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 246, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 281, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 316, yMm: 36, widthMm: 35, heightMm: 46),
  (xMm: 351, yMm: 36, widthMm: 35, heightMm: 46),
];

const _TextRectMm kBeforeYouStartTitleL1 =
    (xMm: 54.083, yMm:  96.200, widthMm: 95);
const _TextRectMm kBeforeYouStartTitleL2 =
    (xMm: 54.083, yMm: 105.7,   widthMm: 95);   // L1 + 27pt leading
const _TextRectMm kBeforeYouStartLeftBody =
    (xMm: 54.083, yMm: 120.300, widthMm: 95);
const _TextRectMm kBeforeYouStartProtagonistLabel =
    (xMm: 272.168, yMm: 210.800, widthMm: 65);  // 69.168 + 203
const _TextRectMm kBeforeYouStartCta =
    (xMm: 272.168, yMm: 219.000, widthMm: 65);

// Per-page Q1/Q2 cluster (page-local then spread-mirrored).
// NÚMERO + TITULO + TEXTO at x = 55.309 mm, width = 93 mm, starting
// y = photo_slot_bottom (= 36 + 46 = 82 mm) + small gap …
```

```dart
// lib/src/render/closing_qr_spread_layout.dart  (excerpt)
const _TextRectMm kClosingQrTitle    = (xMm: 30, yMm:  50.892, widthMm: 143);
const _TextRectMm kClosingQrBody1    = (xMm: 30, yMm:  71.346, widthMm:  92);
// QR bounding-box: 35 mm = 27 mm QR + 2 × 4 mm inset (renderer constant);
// caller geometry stays anchored on the 27 mm physical QR.
const _SlotRectMm kClosingQrBlock    = (xMm: 30, yMm:  94.081, widthMm: 35, heightMm: 35);
const _TextRectMm kClosingQrCaption  = (xMm: 62, yMm:  94.081, widthMm: 36.178);
const _TextRectMm kClosingQrBottom   = (xMm: 30, yMm: 229.420, widthMm: 143);
```

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit (content) | `AlbumBeforeYouStartContent` requires `photoPaths`; length-10 assertion fires; `==`/`hashCode` distinguish | Constructor calls + `expect(…, throwsA(isA<AssertionError>()))` |
| Unit (content) | `AlbumQrSpreadContent.bottomTextOverride` optional; `==`/`hashCode` distinguish | Constructor calls |
| Unit (layout consts) | `kBeforeYouStartPhotoSlots.length == 10`; per-slot fields ±0.001 mm against the explore table; title/body/CTA/Q1/Q2 records match | Direct `expect` with `closeTo` tolerance |
| Unit (layout consts) | `kClosingQr*` records match explore table ±0.001 mm | Direct `expect` |
| Unit (cover) | `parejas`: eyebrow = `'DOTBOOK DE {PROTAGONISTA}'`; `hijos`: eyebrow = `'DOTBOOK DE {PROTAGONISTA}'`; `eyebrowOverride` wins; text-block x=41.5 mm width=120 mm; eyebrow/title/date y values | Build page + scan `elements` for `DotsTextBlockElement` instances |
| Unit (dedication) | `parejas` + `hijos`: text x=50.53 mm; body width=120 mm; relative y math (body y = title y + title_height + 6.5 mm, signature y = body_y + body_height + 8 mm) | Compute expected y from constants; assert against actual element y |
| Unit (closing) | `parejas` + `hijos`: photo y=71.534 mm; title/subtitle x=44 mm; subtitle width=115 mm; title y=photo_bottom+5 mm; subtitle y=title_bottom+5 mm; chrome unchanged | Element scan |
| Unit (beforeYouStart) | `parejas` + `hijos`: 0 `DotsUnimplementedElement`; element count ≈ 22 (10 photos + ~12 text); header `leftPageNumber == $pn` and `rightPageNumber == ${pn+1}`; footer `'Dots. Memories'`; per-category title L2 / body / Q1+Q2 strings; `RangeError`/`AssertionError` for `photoPaths.length != 10` | `expect` + element kind/payload assertions |
| Unit (closingQrSpread) | `parejas` + `hijos`: 5 left-page elements (title, body-1, QR, QR-caption, bottom); 0 right-page elements; header `$pn` / `${pn+1}`; `DotsOvalQrElement.drawFrame == false`; bottom text = `content.bottomTextOverride ?? default` | Element scan |
| Unit (renderer) | `DotsOvalQrElement(drawFrame: false)` renders the BarcodeWidget but NOT the `BoxShape.circle` border | Golden-style or PDF byte inspection if available; otherwise widget-tree assertion via a small `@visibleForTesting` hook |
| Unit (parser) | Parser does NOT inject `beforeYouStart`/`closingQrSpread` pliegos — verified by absence; existing tests stay green | Inspect parser output for an album JSON that omits both spreads |

## Migration / Rollout

Single PR per the user's standing direction (proposal Size Estimate
~520 LOC; 400-line budget exception accepted). No data migration. The
`AlbumBeforeYouStartContent.photoPaths` addition is a hard analyzer
break — the existing usage sites are confined to test files
(verified: Task 2 left the type stubbed and no production caller wires
it yet), so the blast radius is bounded. The `DotsOvalQrElement.drawFrame`
addition is backward-compatible (`= true` default preserves photoArc).
Rollback = `git revert` the slice commits in reverse order:
content-class deltas first, then layout-constant files, then factory
bodies. No caches; elements computed fresh per render.

## Open Questions

- [x] QR element for the 27 mm square card → resolved: reuse
      `DotsOvalQrElement` with `drawFrame: false` + square bbox (Decision 1).
- [x] `_blankAlbumSpread` / parser injection interaction → resolved:
      parser does NOT inject these pliegos; callers build them directly
      via the factories (Decision 7).
- [x] `closing` single-page chrome parity → resolved: unchanged
      (Decision 5).
- [ ] Cover eyebrow `{PROTAGONISTA}` token vs `{tiempojuntos}` /
      `{Protagonistas}` token registry → spec phase pinned the literal
      `'DOTBOOK DE {PROTAGONISTA}'`; the runtime variables map MUST
      register `{PROTAGONISTA}`. Out of scope for this design; flagged
      as a caller-contract assumption.
- [ ] Per-page Q1/Q2 vertical stack exact y values: explore gives
      gaps (7.5 mm above TITULO, 5 mm above TEXTO) but not the absolute
      first-NÚMERO y. Tasks phase pins the value from the PDF; design
      sets `numero_y = photo_bottom_y + 7.5 mm = 89.5 mm` as the
      working default.
