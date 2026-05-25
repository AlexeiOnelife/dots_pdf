# Design: album-type-photo-arc (slice 5 of 5)

## Technical Approach

Slice 5 adds the "Un año lleno de recuerdos" photo-arc spread by:

1. Introducing TWO new sealed `DotsElement` subtypes —
   `DotsPhotoCircleElement` (circular-cropped photo) and `DotsOvalQrElement`
   (oval-framed QR card with caption below).
2. Wiring both into the shared `buildAlbumSpreadPage` helper via two new
   `_buildElement` arms; defensive arms in the other four exhaustiveness
   sites (preloader x2 for `DotsElementsPage` and `DotsAlbumSpreadPage`,
   main-isolate renderer, isolate-side renderer).
3. Adding `DotsAlbumSpreadPage.photoArc(...)` on `dots_template.dart`
   (alongside `.dedication()`, `.closing()`, `.polaroidCollage()`,
   `.cover()`) that composes 10 photo-circle elements + 2 oval-QR elements
   + 2 text elements (title + date subtitle) and the standard header trio.
4. Adding `AlbumPhotoArcContent` value object and a top-level
   `buildPhotoArcPageFor(type, content, {pageNumber, contextLabelValue})`
   builder that resolves per-type QR caption defaults and rejects `boda`.
5. Storing the 10 spec coordinates as mm in `kPhotoArcLayout` (library-private,
   sibling of `polaroid_slots.dart` and `cover_circles.dart`).

The page renders as a SINGLE `pw.Page` whose `pageFormat.width` must equal
the 406-mm spread width (caller-enforced; see D10).

---

## Architecture Decisions

### D1: `DotsPhotoCircleElement` shape and units

| Field         | Type     | Unit    | Default  | Notes                                                         |
| ------------- | -------- | ------- | -------- | ------------------------------------------------------------- |
| `x`, `y`      | `double` | pt      | required | top-left of the bounding square (super-class fields)          |
| `assetPath`   | `String` | —       | required | photo asset path (same contract as `DotsImageElement`)        |
| `diameter`    | `double` | **pt**  | required | matches slice 3/4 unit convention                             |
| `bleed{Left,Right,Top,Bottom}` | `bool` | — | `false` | parity with `DotsImageElement` / `DotsPolaroidElement`        |

Rationale: all 10 photo-arc circles are inside the spread (no edge bleeds
in the spec) so the bleed flags default to `false`. They are present
anyway for future-proofing and consistency with the other photo-bearing
element types. Single `const` constructor; value equality and `hashCode`
over all 8 fields (incl. super.x, super.y), matching `DotsPolaroidElement`.

### D2: `DotsOvalQrElement` shape and units

| Field                | Type     | Unit    | Default       | Notes                                          |
| -------------------- | -------- | ------- | ------------- | ---------------------------------------------- |
| `x`, `y`             | `double` | pt      | required      | top-left of the oval's bounding box            |
| `ovalWidth`          | `double` | pt      | required      | bounding-box width of the ellipse              |
| `ovalHeight`         | `double` | pt      | required      | bounding-box height of the ellipse             |
| `qrPayload`          | `String` | —       | required      | typically a URL                                |
| `caption`            | `String` | —       | required      | resolved by the builder per-type               |

**Decision (resolves D2 question on caption styling):** caption font size,
font family, and color are HARDCODED in the renderer (`_buildOvalQrElement`),
NOT exposed as element fields. Rationale: the spec is fully prescriptive
(P22 Mackinac Book 8pt / 9.6pt LH, `#9E9E9D`). Exposing customisation
fields is over-engineering with no current caller. Value equality and
`hashCode` over the 6 fields (incl. super.x, super.y).

Renderer constants (file-private in `album_spread_page.dart`):
- `_kOvalQrCaptionFontSize = 8.0`
- `_kOvalQrCaptionLineHeight = 1.2`
- `_kOvalQrCaptionColor = PdfColor(0x9E/255, 0x9E/255, 0x9D/255)`
- `_kOvalQrCaptionGapMm = 3.0`  (gap between oval bottom and caption top)
- `_kOvalBorderWidthPt = 0.5`
- `_kOvalBorderColor = PdfColor(0x9E/255, 0x9E/255, 0x9D/255)`  (matches caption)
- `_kQrInsetMm = 4.0`  (padding from oval bbox to QR — see D4)

### D3: Oval frame drawing strategy

**Choice:** D3a — `pw.Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(...)))` sized to `ovalWidth × ovalHeight`.

Verified against `pdf 3.12.0` (pinned `^3.11.1`):
- `BoxDecoration.shape: BoxShape.circle` calls
  `canvas.drawEllipse(cx, cy, box.width/2, box.height/2)` —
  the ellipse is inscribed in the bounding box, NOT a true circle. Source:
  `~/.pub-cache/hosted/pub.dev/pdf-3.12.0/lib/src/widgets/decoration.dart`
  lines 350–355 and 372–378.
- `Border.all(color, width)` with `BoxShape.circle` paints an elliptical
  stroke via `_paintUniformBorderWithCircle`. Source:
  `~/.pub-cache/hosted/pub.dev/pdf-3.12.0/lib/src/widgets/box_border.dart`
  lines 241–248.

| Option | Tradeoff                                                       | Verdict   |
| ------ | -------------------------------------------------------------- | --------- |
| D3a    | `BoxDecoration + BoxShape.circle + Border.all` — declarative   | **Chosen** |
| D3b    | `pw.CustomPaint` with `canvas.drawEllipse` + `strokePath`      | Rejected — three times the code for the same result; `BoxDecoration` already calls `drawEllipse` internally |
| D3c    | `pw.ClipOval` for the border                                   | Rejected — `ClipOval` clips children but doesn't stroke an outline |

`pw.Canvas.drawEllipse(double x, double y, double r1, double r2)` IS
available in the pinned `pdf 3.12.0` (`lib/src/pdf/graphics.dart:429`),
so D3b would work as a fallback if `BoxDecoration` ever proved
insufficient — but D3a is the canonical path.

### D4: QR rendering inside the oval

**Choice:** `pw.BarcodeWidget` (same call shape as the existing
`_buildQrSlot` in `dots_renderer.dart:647-668`).

Sizing strategy: the QR is rendered at the **inscribed square** of the
oval minus `_kQrInsetMm` padding. Concretely:
```
qrSidePt = min(ovalWidth, ovalHeight) - 2 * _kQrInsetMm * _kMmToPt
qrLeftPt = (ovalWidth  - qrSidePt) / 2
qrTopPt  = (ovalHeight - qrSidePt) / 2
```

This is a deliberate simplification: a true ellipse-inscribed square has
side `min(w,h) / sqrt(2)` ≈ 0.707 × min(w,h), but for ovals close to
circular (which the spec QR ovals are — aspect ratio ~1.1:1) the
inscribed-bbox-minus-padding is visually identical and avoids a
`sqrt(2)` division on a hot path.

Same `Barcode.qrCode(errorCorrectLevel: BarcodeQRCorrectionLevel.medium)`
as the existing `_buildQrSlot`. `drawText: false`. The QR is positioned
inside the same `pw.Stack` as the oval frame, via `pw.Positioned`.

### D5: Caption position relative to oval

**Choice:** the caption is part of the `DotsOvalQrElement` widget tree —
NOT a separate element. The caller's `(x, y)` positions the OVAL's
top-left; the caption flows BELOW the oval at:
```
captionTopPt = ovalHeight + _kOvalQrCaptionGapMm * _kMmToPt
captionLeftPt = 0  (full-width within the element's coordinate frame)
```

The caption is centered horizontally using `pw.SizedBox(width: ovalWidth)` +
`pw.Text(textAlign: pw.TextAlign.center)`. The text uses
`fontFamily: 'P22 Mackinac Book'` resolved via
`DotsFontBundle.roleFromFamily('P22 Mackinac Book')`.

Composition (file-private widget builder):
```dart
pw.Widget _buildOvalQrElement(
  DotsOvalQrElement element,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final captionFont = fontResolver(DotsFontRole.mackinacBook);  // see D5b
  final qrSidePt = (element.ovalWidth < element.ovalHeight
          ? element.ovalWidth
          : element.ovalHeight) -
      2 * _kQrInsetMm * _kMmToPt;
  final qrLeftPt = (element.ovalWidth - qrSidePt) / 2;
  final qrTopPt = (element.ovalHeight - qrSidePt) / 2;
  final captionTopPt =
      element.ovalHeight + _kOvalQrCaptionGapMm * _kMmToPt;

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Stack(
      children: [
        // Oval frame
        pw.Container(
          width: element.ovalWidth,
          height: element.ovalHeight,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(
              color: _kOvalBorderColor,
              width: _kOvalBorderWidthPt,
            ),
          ),
        ),
        // QR (centered)
        pw.Positioned(
          left: qrLeftPt,
          top: qrTopPt,
          child: pw.SizedBox(
            width: qrSidePt,
            height: qrSidePt,
            child: pw.BarcodeWidget(
              data: element.qrPayload,
              barcode: pw.Barcode.qrCode(
                errorCorrectLevel:
                    pw.BarcodeQRCorrectionLevel.medium,
              ),
              drawText: false,
            ),
          ),
        ),
        // Caption (below oval)
        pw.Positioned(
          left: 0,
          top: captionTopPt,
          child: pw.SizedBox(
            width: element.ovalWidth,
            child: pw.Text(
              element.caption,
              style: pw.TextStyle(
                font: captionFont,
                fontSize: _kOvalQrCaptionFontSize,
                color: _kOvalQrCaptionColor,
                lineSpacing:
                    _kOvalQrCaptionFontSize *
                    (_kOvalQrCaptionLineHeight - 1),
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}
```

**D5b (font role):** Use `DotsFontRole.mackinacBook` if it exists; fall back
to whatever `DotsFontBundle.roleFromFamily('P22 Mackinac Book')` returns.
The closing-page factory already uses `'P22 Mackinac Book'` as a string,
so the role-resolution path is established.

### D6: `kPhotoArcLayout` shape and location

**Location:** `lib/src/render/photo_arc_layout.dart` (new file, sibling of
`polaroid_slots.dart` and `cover_circles.dart`). **Library-private**
(no export from `lib/dots_pdf.dart`) — same precedent as slice 4's
`kCoverCircleLayout`.

Shape: file-private class `_PhotoArcAnchor` so the type doesn't leak via
the public `kPhotoArcLayout`. Fields in **mm** (SPREAD coordinates,
authoring units; factory converts to pt):

```dart
@immutable
class _PhotoArcAnchor {
  const _PhotoArcAnchor({
    required this.xMm,
    required this.yMm,
    this.diameterMm = 44.45,
  });
  final double xMm, yMm, diameterMm;
}

const List<_PhotoArcAnchor> kPhotoArcLayout = [
  _PhotoArcAnchor(xMm:  29.59, yMm: 273.28),
  _PhotoArcAnchor(xMm: 376.17, yMm: 273.28),
  _PhotoArcAnchor(xMm:  45.09, yMm: 224.02),
  _PhotoArcAnchor(xMm: 360.66, yMm: 224.02),
  _PhotoArcAnchor(xMm:  77.97, yMm: 180.93),
  _PhotoArcAnchor(xMm: 327.79, yMm: 180.93),
  _PhotoArcAnchor(xMm: 120.96, yMm: 150.11),
  _PhotoArcAnchor(xMm: 284.79, yMm: 150.11),
  _PhotoArcAnchor(xMm: 171.04, yMm: 134.01),
  _PhotoArcAnchor(xMm: 234.72, yMm: 134.01),
];
```

All 10 entries use the default `diameterMm = 44.45` (slice 1 locked the
uniform diameter — see proposal "Open question #8"). No bleed flags
because all 10 circles are inside the 406×254 mm spread.

### D7: `AlbumPhotoArcContent` shape

**Location:** `lib/src/api/album_photo_arc_content.dart` (new file, mirrors
`album_cover_content.dart`).

```dart
@immutable
class AlbumPhotoArcContent {
  const AlbumPhotoArcContent({
    required this.photoPaths,
    required this.qrPayloadLeft,
    required this.qrPayloadRight,
    required this.title,
    required this.dateSubtitle,
    this.qrCaptionLeftOverride,
    this.qrCaptionRightOverride,
  });
  final List<String> photoPaths;
  final String qrPayloadLeft;
  final String qrPayloadRight;
  final String title;
  final String dateSubtitle;
  final String? qrCaptionLeftOverride;
  final String? qrCaptionRightOverride;
  // == and hashCode over all 7 fields (list equality via _listEquals helper)
}
```

**Length validation: at the FACTORY (not at construction).** Rationale:
slice 3's `AlbumCollageContent` does not validate `photoPaths.length` at
construction either; the `polaroidCollage` factory throws `RangeError`.
Consistency with slice 3. The value object stays a dumb container.

### D8: `DotsAlbumSpreadPage.photoArc(...)` factory

**Location:** `dots_template.dart`, alongside the other named factories.

```dart
factory DotsAlbumSpreadPage.photoArc({
  required DotsAlbumType type,
  required int pageNumber,
  required String contextLabelValue,
  required AlbumPhotoArcContent content,
});
```

Behaviour:

1. **Type guard:** throw `ArgumentError.value(type, 'type',
   'DotsAlbumSpreadPage.photoArc does not support DotsAlbumType.boda; '
   'boda's analogue (p.4 radial halo) is not implemented')`
   when `type == DotsAlbumType.boda`. Defense-in-depth — `buildPhotoArcPageFor`
   throws the same `ArgumentError` first (see D9).
2. **Photo-paths length check:**
   ```dart
   if (content.photoPaths.length != kPhotoArcLayout.length) {  // 10
     throw RangeError.value(
       content.photoPaths.length, 'photoPaths.length',
       'Expected ${kPhotoArcLayout.length} photo paths, '
       'got ${content.photoPaths.length}.',
     );
   }
   ```
3. **Resolve per-type QR captions:**
   ```dart
   const String _rightCaption = 'Todos tus hitos en un lugar';
   final String defaultLeftCaption = switch (type) {
     DotsAlbumType.parejas      => 'Vuestro álbum en digital',
     DotsAlbumType.hijos        ||
     DotsAlbumType.individuales ||
     DotsAlbumType.otros        => 'Tu album en digital',
     DotsAlbumType.boda         => '',  // unreachable; guarded above
   };
   final String leftCaption  = content.qrCaptionLeftOverride  ?? defaultLeftCaption;
   final String rightCaption = content.qrCaptionRightOverride ?? _rightCaption;
   ```
4. **Build 10 photo circles** from `kPhotoArcLayout`:
   ```dart
   final circles = <DotsElement>[
     for (var i = 0; i < kPhotoArcLayout.length; i++)
       DotsPhotoCircleElement(
         x: kPhotoArcLayout[i].xMm * _mmToPt,
         y: kPhotoArcLayout[i].yMm * _mmToPt,
         assetPath: content.photoPaths[i],
         diameter: kPhotoArcLayout[i].diameterMm * _mmToPt,
       ),
   ];
   ```
5. **Build 2 oval-QR elements** at the gutter bottom. Spec geometry
   (SPREAD coordinates; gutter centre at x = 203 mm):
   - QR LEFT centre at  x = 203 - 27 = 176 mm
   - QR RIGHT centre at x = 203 + 27 = 230 mm
   - QR caption top at y = (page height 254) − 20 = 234 mm
   - Oval is sized 50 × 45 mm (slice 1 spec; aspect ratio ~1.1:1).
     Caption sits below the oval, top edge at y = 234 mm. The OVAL
     element's top-left y is therefore at
     `234 − 3 mm (gap) − 45 mm (ovalHeight)` = 186 mm.
   - Oval LEFT top-left x = `176 − 25 mm` = 151 mm.
   - Oval RIGHT top-left x = `230 − 25 mm` = 205 mm.

   The factory hardcodes `_kPhotoArcOvalWidthMm = 50` and
   `_kPhotoArcOvalHeightMm = 45` as file-private constants on
   `dots_template.dart`.
6. **Build title** at (19 mm, 43 mm) — single-line `DotsTextElement` in
   P22 Mackinac Medium 23pt (`fontFamily: 'P22 Mackinac Medium'`).
7. **Build date subtitle** at (19 mm, `43 + (23 * 1.2 / 2.834645669) + 5` mm)
   ≈ (19 mm, 57.74 mm) — single-line `DotsTextElement` in P22 Mackinac Book
   9pt. The y offset is derived from "23pt title leading (23 × 1.2 LH =
   27.6 pt = 9.74 mm) + 5 mm spec gap".
8. **Header:** `DotsSpreadHeader(leftPageNumber: '$pageNumber',
   centerLabel: contextLabelValue.isEmpty ? null : contextLabelValue,
   rightPageNumber: '$pageNumber')`. Both page-number positions filled
   (single `pw.Page` of spread width — left/right edges of the SAME page
   each get a number, per the spec).
9. **Footer:** `DotsSpreadFooter(wordmark: 'Dots. Memories')`.

### D9: `buildPhotoArcPageFor` top-level

**Location:** `lib/src/api/build_photo_arc_page.dart` (new file, mirrors
`build_cover_page.dart`).

```dart
DotsAlbumSpreadPage buildPhotoArcPageFor(
  DotsAlbumType type,
  AlbumPhotoArcContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type == DotsAlbumType.boda) {
    throw ArgumentError.value(
      type, 'type',
      'buildPhotoArcPageFor does not support DotsAlbumType.boda; '
      'boda's analogue (p.4 radial halo) is not implemented.',
    );
  }
  return DotsAlbumSpreadPage.photoArc(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    content: content,
  );
}
```

Same defense-in-depth pattern as slice 4: builder throws first, factory
throws if anyone constructs it directly.

### D10: pageSize constraint enforcement

**Choice:** D10a — dartdoc-only + best-effort logger warning at render time.

The factory cannot enforce page width from inside `DotsAlbumSpreadPage`
(it doesn't know the caller's `DotsTemplate.pageSize`). Options weighed:

| Option | Cost                                                       | Verdict   |
| ------ | ---------------------------------------------------------- | --------- |
| D10a   | Dartdoc + render-time `logger.warn` when any photoArc element's `x + width` exceeds `format.width` | **Chosen** |
| D10b   | New `DotsSpreadPageSize` value object distinct from `DotsPageSize` | Rejected — overkill for a caller-discipline issue |
| D10c   | Pure documentation, no runtime check                       | Rejected — silent clip is the worst outcome |

The dartdoc on `DotsAlbumSpreadPage.photoArc` and `buildPhotoArcPageFor`
states: *"The caller MUST set `DotsTemplate.pageSize.width` to the
spread width (406 mm = 1150.87 pt). Elements with `x + diameter > pageWidth`
will be clipped silently by the PDF viewer."*

The runtime check lives in `buildAlbumSpreadPage` (shared helper) as a
generic post-pass:

```dart
// After all elements added, before pw.Page is built:
const double _kPhotoArcSpreadWidthMm = 406.0;
final double minSpreadWidthPt = _kPhotoArcSpreadWidthMm * _kMmToPt;
if (page.elements.any((e) => e is DotsPhotoCircleElement || e is DotsOvalQrElement)
    && format.width < minSpreadWidthPt - 1.0 /* 1pt tolerance */) {
  logger.warn(
    'DotsAlbumSpreadPage.photoArc rendered on a page narrower '
    'than 406 mm (got ${format.width / _kMmToPt} mm); '
    'right-half elements will be clipped.',
  );
}
```

This is additive; existing dedication/closing/polaroid/cover pages are
unaffected because the check is gated on the presence of photo-arc
elements.

### D11: Public API surface

| Symbol                            | Export?  | Module                                  |
| --------------------------------- | -------- | --------------------------------------- |
| `DotsPhotoCircleElement`          | **Yes**  | rides via `dots_template.dart`          |
| `DotsOvalQrElement`               | **Yes**  | rides via `dots_template.dart`          |
| `DotsAlbumSpreadPage.photoArc()`  | **Yes**  | rides via `dots_template.dart`          |
| `AlbumPhotoArcContent`            | **Yes**  | `src/api/album_photo_arc_content.dart`  |
| `buildPhotoArcPageFor`            | **Yes**  | `src/api/build_photo_arc_page.dart`     |
| `_PhotoArcAnchor`                 | No       | file-private                            |
| `kPhotoArcLayout`                 | No       | library-private                         |
| `_buildPhotoCircleElement`        | No       | file-private (album_spread_page.dart)   |
| `_buildOvalQrElement`             | No       | file-private (album_spread_page.dart)   |

Two new top-level exports added to `lib/dots_pdf.dart`:
`AlbumPhotoArcContent`, `buildPhotoArcPageFor`. The two new element
types and the `.photoArc(...)` factory ride on the existing
`dots_template.dart` export.

### D12: Test file structure

| File                                                      | Tests                                                                        |
| --------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `test/config/dots_photo_circle_element_test.dart`         | Model: construction, equality, hashCode, bleed defaults, value-equality with same/different field values |
| `test/config/dots_oval_qr_element_test.dart`              | Model: construction, equality, hashCode, value-equality on all 6 fields      |
| `test/render/photo_arc_layout_test.dart`                  | `kPhotoArcLayout` matches spec table (10 entries, all diameter 44.45 mm, x/y match the documented coordinates) |
| `test/render/photo_arc_test.dart`                         | Factory: 10 circles + 2 ovals + 2 texts + header trio (left+center+right); RangeError for wrong photoPaths length; ArgumentError for boda; render via both isolate paths produces non-empty PDF; logger warns on narrow page |
| `test/api/build_photo_arc_page_test.dart`                 | Builder delegates correctly; per-type QR caption defaults (parejas vs others); overrides win; ArgumentError on boda |

Five test files (one more than slice 4's four). The extra file is
`photo_arc_layout_test.dart` because we introduce a NEW layout constant
this slice — slice 4 had a layout constant too (`cover_circles_test.dart`),
so the count is actually equivalent.

---

## Exhaustiveness sites

Five sealed-switch sites need TWO new arms each (one per new element
type), for **10 new arms total**:

| # | Site                                                                   | PhotoCircle arm                                | OvalQr arm                                     |
| - | ---------------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| 1 | `album_spread_page.dart` `_buildElement` switch                        | `_buildPhotoCircleElement(element, bytesResolver, onPhotoFailure)` | `_buildOvalQrElement(element, fontResolver)`   |
| 2 | `dots_renderer.dart` `_buildElement` (DotsElementsPage path)           | `return null;` (delegation comment)            | `return null;`                                 |
| 3 | `dots_renderer.dart` `preloadAssetBytes` inner switch (`DotsElementsPage`) | `paths.add(element.assetPath);` (defensive — same as polaroid) | `break;` (no asset path; no-op comment)        |
| 4 | `dots_renderer.dart` `preloadAssetBytes` inner switch (`DotsAlbumSpreadPage`) | `paths.add(element.assetPath);` (real path)    | `break;` (no asset path; no-op comment)        |
| 5 | `isolate_synthesis.dart` `_buildElement` switch                        | `return null;` (delegation comment)            | `return null;`                                 |

The PhotoCircle preloader arms collect the photo asset path so the
isolate has the bytes. The OvalQr arms are no-ops because QR payloads
are strings (not assets) — the `BarcodeWidget` synthesises pixels at
render time.

---

## Data Flow

```
caller
  │ AlbumPhotoArcContent(photoPaths[10], qrPayloadLeft, qrPayloadRight,
  │                      title, dateSubtitle, qrCaptionLeftOverride?,
  │                      qrCaptionRightOverride?)
  ▼
buildPhotoArcPageFor(type, content, pageNumber:, contextLabelValue:)
  │ ArgumentError if type == boda
  │ delegates to
  ▼
DotsAlbumSpreadPage.photoArc(...)
  │ ArgumentError if boda (defense-in-depth)
  │ RangeError if photoPaths.length != 10
  │ resolves per-type caption defaults
  │ composes 10 DotsPhotoCircleElement + 2 DotsOvalQrElement + 2 text + header trio
  ▼
DotsAlbumSpreadPage(elements: 14, header: full trio, footer: 'Dots. Memories')
  │ rendered via
  ▼
buildAlbumSpreadPage(format, page, ...)
  │ optional width warning if photoArc on narrow page
  │ _buildElement → switch by type
  ▼
  ├─ DotsPhotoCircleElement → _buildPhotoCircleElement
  │                              │ load bytes via bytesResolver
  │                              │ wrap in pw.ClipOval over pw.Image
  │                              ▼
  │                          pw.Positioned(left, top, child: ClipOval(Image))
  │
  └─ DotsOvalQrElement     → _buildOvalQrElement
                                 │ Stack containing:
                                 │   – pw.Container(BoxDecoration.circle + Border.all) — oval frame
                                 │   – pw.Positioned(inscribed-square QR via BarcodeWidget)
                                 │   – pw.Positioned(SizedBox + Text caption, below oval)
                                 ▼
                             pw.Positioned(left, top, child: Stack)
```

---

## File Changes

| Path                                                  | Action   | Summary                                                                          |
| ----------------------------------------------------- | -------- | -------------------------------------------------------------------------------- |
| `lib/src/config/dots_template.dart`                   | Modified | Add `DotsPhotoCircleElement` + `DotsOvalQrElement` classes; add `.photoArc()` factory |
| `lib/src/render/photo_arc_layout.dart`                | New      | `_PhotoArcAnchor` (file-private) + `kPhotoArcLayout` (library-private)           |
| `lib/src/render/album_spread_page.dart`               | Modified | Add `_buildPhotoCircleElement` + `_buildOvalQrElement` + 6 file-private constants + 2 new sealed-switch arms + optional width warning |
| `lib/src/render/dots_renderer.dart`                   | Modified | 5 new sealed-switch arms (1 `_buildElement` × 2 + 2 preloader sites × 2 = 6 arms total, but the `_buildElement` switch is one site with 2 arms) |
| `lib/src/render/isolate_synthesis.dart`               | Modified | 2 new sealed-switch arms in `_buildElement`                                       |
| `lib/src/api/album_photo_arc_content.dart`            | New      | `AlbumPhotoArcContent` value object                                              |
| `lib/src/api/build_photo_arc_page.dart`               | New      | `buildPhotoArcPageFor` top-level builder + boda `ArgumentError`                  |
| `lib/dots_pdf.dart`                                   | Modified | 2 new exports (`AlbumPhotoArcContent`, `buildPhotoArcPageFor`)                   |
| `test/config/dots_photo_circle_element_test.dart`     | New      | Model equality / hashCode / defaults                                             |
| `test/config/dots_oval_qr_element_test.dart`          | New      | Model equality / hashCode                                                        |
| `test/render/photo_arc_layout_test.dart`              | New      | `kPhotoArcLayout` shape (10 entries, uniform diameter)                           |
| `test/render/photo_arc_test.dart`                     | New      | Factory composition + render (both isolate paths) + ArgumentError + RangeError + width-warning |
| `test/api/build_photo_arc_page_test.dart`             | New      | Builder + per-type caption defaults + overrides + ArgumentError                  |

---

## Interfaces / Contracts

`DotsPhotoCircleElement`:

```dart
class DotsPhotoCircleElement extends DotsElement {
  const DotsPhotoCircleElement({
    required super.x,
    required super.y,
    required this.assetPath,
    required this.diameter,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });
  final String assetPath;
  final double diameter;       // pt
  final bool bleedLeft, bleedRight, bleedTop, bleedBottom;
  // == / hashCode over all 8 fields (incl. super.x, super.y)
}
```

`DotsOvalQrElement`:

```dart
class DotsOvalQrElement extends DotsElement {
  const DotsOvalQrElement({
    required super.x,
    required super.y,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.qrPayload,
    required this.caption,
  });
  final double ovalWidth, ovalHeight;  // pt
  final String qrPayload, caption;
  // == / hashCode over all 6 fields
}
```

`AlbumPhotoArcContent`:

```dart
@immutable
class AlbumPhotoArcContent {
  const AlbumPhotoArcContent({
    required this.photoPaths,
    required this.qrPayloadLeft,
    required this.qrPayloadRight,
    required this.title,
    required this.dateSubtitle,
    this.qrCaptionLeftOverride,
    this.qrCaptionRightOverride,
  });
  final List<String> photoPaths;
  final String qrPayloadLeft, qrPayloadRight, title, dateSubtitle;
  final String? qrCaptionLeftOverride, qrCaptionRightOverride;
  // == / hashCode over all 7 fields
}
```

`buildPhotoArcPageFor`:

```dart
DotsAlbumSpreadPage buildPhotoArcPageFor(
  DotsAlbumType type,
  AlbumPhotoArcContent content, {
  required int pageNumber,
  required String contextLabelValue,
});
```

Throws `ArgumentError` when `type == DotsAlbumType.boda`.

---

## Testing Strategy

| Layer       | What                                                                          | Approach                                                                              |
| ----------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Unit        | `DotsPhotoCircleElement` equality, hashCode, bleed defaults                   | Two equal / two unequal instances                                                     |
| Unit        | `DotsOvalQrElement` equality                                                  | Same pattern                                                                          |
| Unit        | `AlbumPhotoArcContent` equality                                               | Same pattern; verify list-equality on `photoPaths`                                    |
| Unit        | `kPhotoArcLayout` matches spec table                                          | 10 entries, all `diameterMm == 44.45`, x/y match                                      |
| Unit        | Factory: 14 elements (10 circles + 2 ovals + 2 texts)                         | `result.elements.length == 14`; `whereType<DotsPhotoCircleElement>().length == 10`; `whereType<DotsOvalQrElement>().length == 2`; `whereType<DotsTextElement>().length == 2` |
| Unit        | Factory: header trio (left + center + right page numbers, center label)       | `result.header.leftPageNumber == '$pageNumber' && rightPageNumber == '$pageNumber' && centerLabel == contextLabelValue` |
| Unit        | Factory: footer wordmark = 'Dots. Memories'                                   | `result.footer.wordmark == 'Dots. Memories'`                                          |
| Unit        | Per-type QR caption defaults                                                  | parejas → 'Vuestro álbum en digital'; hijos / individuales / otros → 'Tu album en digital'; all four → right caption 'Todos tus hitos en un lugar' |
| Unit        | Caption overrides win                                                         | construct content with `qrCaptionLeftOverride: 'X'`; assert oval element's caption    |
| Unit        | `buildPhotoArcPageFor(boda, ...)` throws `ArgumentError`                      | wrap in `expect(() => ..., throwsArgumentError)`                                      |
| Unit        | `DotsAlbumSpreadPage.photoArc(type: boda, ...)` throws `ArgumentError`        | defense-in-depth                                                                      |
| Unit        | `photoPaths.length != 10` throws `RangeError`                                 | wrap in `expect(() => ..., throwsRangeError)`                                          |
| Integration | Render through main-isolate path produces non-empty valid PDF                 | Mirrors slice 3/4 render tests; uses 1150.87 pt × 719.74 pt page format               |
| Integration | Render through worker-isolate path produces non-empty valid PDF               | Mirrors slice 3/4 render tests                                                        |
| Integration | Logger warning when page width < 406 mm                                       | construct test logger that captures warnings; render with 575 pt (203 mm) format; assert one warning containing "narrower than 406 mm" |

---

## Migration / Rollout

No migration. Slice is additive: existing templates without
`DotsPhotoCircleElement` or `DotsOvalQrElement` parse and render
identically. No new pubspec dependencies (`pdf ^3.11.1` already provides
`BarcodeWidget`, `ClipOval`, `BoxDecoration`).

---

## Open Questions

- [ ] Caption font family verification: `'P22 Mackinac Book'` works in
  `closing(...)` (slice 2) — the bundle exposes it via
  `DotsFontBundle.roleFromFamily`. Spec phase should confirm the role
  enum exists (likely `DotsFontRole.mackinacBook` per slice 2's role list).
- [ ] Oval aspect ratio: spec says "oval QR card" but does not give exact
  dimensions. Design picks 50 × 45 mm as a visually reasonable oval close
  to the canonical render. Spec phase / verify phase should confirm
  against the source PDF.
- [ ] QR inset (4 mm) is design-side; the spec doesn't give an explicit
  QR-to-oval padding. Visual QA may reveal we want a tighter or looser
  inset.
- [ ] Width warning threshold (`format.width < 406 mm`) uses a 1 pt
  tolerance. If callers use floating-point page widths that round
  inexactly to mm, the threshold may need widening to e.g. 0.5 mm. Slice
  ships with 1 pt; revisit if false positives appear.
