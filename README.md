# dots_pdf

JSON-templated PDF generation for Flutter, optimized for the **Dotbook**
photo-album workflow: hardcover book block + cover, multi-page interior
templates, milestone (hito) pages with QR codes, spread-spanning
images, and per-supplier (europa / latam) print rules.

Built on top of [`pdf`](https://pub.dev/packages/pdf). Output is a raw
print-ready PDF byte stream suitable for a physical or virtual printer.

---

## Status at a glance

- **Public API:** stable and tested (140+ tests).
- **Output modes:** whole-document PDF, 2-page-pair PDFs, cover PDF.
- **Embedded typography:** P22 Mackinac (medium/book/medium-italic),
  Inter (variable, regular + italic), Biro Script Plus (regular).
- **Crop marks:** europa supplier gets trim-corner ticks; latam does not.
- **PDF/X-4 + FOGRA39 ICC conformance:** **not yet**. The library
  emits PDF 1.7 with subsetted glyphs. The CGATS reference data for
  FOGRA39 ships in the package but a binary `.icc` profile must be
  generated separately before full conformance can land. See
  [`docs/templates/SPECS.md`](docs/templates/SPECS.md) §
  "Deferred work".

---

## Install

In your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  dots_pdf:
    git:
      url: https://github.com/<your-org>/dots_pdf.git
      ref: main
```

The library bundles its own fonts and the FOGRA39 CGATS data — no
extra `assets:` declarations are required in your app.

Then in your app code:

```dart
import 'package:dots_pdf/dots_pdf.dart';
```

---

## Quickstart

```dart
import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/local.dart';
import 'package:path_provider/path_provider.dart';

Future<String> generateMyAlbum() async {
  // 1. Load the bundled typography (P22 Mackinac, Inter, Biro Script Plus).
  final fontBundle = await DotsFontBundle.fromPackageAssets();

  // 2. Where to persist the generated PDFs.
  final fs = const LocalFileSystem();
  final docs = await getApplicationDocumentsDirectory();

  // 3. Configure the generator (one instance per app is fine — it owns
  //    no per-document state).
  final generator = DotsGenerator(
    fileSystem: fs,
    documentsDir: fs.directory(docs.path),
    fontBundle: fontBundle,
    drawCropMarks: DotsSupplier.europa.drawsCropMarks,
  );

  // 4. Describe the document.
  const template = DotsTemplate(
    documentId: 'album_alexei_2026',
    pageSize: DotsPageSize(width: 592.34, height: 736.81), // 209 x 260 mm
    pages: <DotsPage>[
      DotsLayoutPage(
        pageNumber: 1,
        layoutCode: DotsLayoutCode.l1,
        photoAssetPaths: <String>['https://example.com/cover.jpg'],
      ),
      DotsLayoutPage(
        pageNumber: 2,
        layoutCode: DotsLayoutCode.lhito,
        captions: <DotsSlotKind, String>{
          DotsSlotKind.captionTitle: 'A milestone',
          DotsSlotKind.captionDate: 'May 17, 2026',
          DotsSlotKind.captionBody: 'The body of the milestone story…',
          DotsSlotKind.qrCard: 'https://onelife.example/album/123',
        },
      ),
    ],
  );

  // 5. Generate. The stream emits Started → Progress(N/N) → Completed
  //    on a fresh run, or a single PdfGenerationCacheHit on reuse.
  await for (final event in generator.generateWhole(template: template)) {
    if (event is PdfGenerationFailed) throw event.error;
  }

  return generator.wholePathFor(template.documentId);
}
```

There's a full working example at
[`example/example.dart`](example/example.dart) covering URL images,
QR codes, spread-spanning images, the cover renderer, and the
progress-stream UI hook.

---

## Core concepts

### Output modes

A document can be rendered three ways. Each has its own cached
artifact path and its own re-generation cycle.

| Method | Output | Path |
|---|---|---|
| `generator.generateWhole(template:)` | one PDF for the whole document | `<docs>/dots_pdf/whole/<id>.pdf` |
| `generator.generatePairs(template:)` | one PDF per 2-page pair (`pair_001.pdf`, `pair_002.pdf`, …) | `<docs>/dots_pdf/pairs/<id>/` |
| `generator.generateCover(template:)` | the single-page hardcover wrap PDF (driven by `DotsCoverGeometry`, separate from the interior template) | `<docs>/dots_pdf/cover/<id>.pdf` |

All three return a `Stream<PdfGenerationEvent>` (`Started`,
`Progress`, `CacheHit`, `Completed`, `Failed`). Drain it to drive a
progress UI; you don't have to.

### Template structure

A `DotsTemplate` is a typed tree of pages. Each page is either an
**elements page** (explicit coordinates for each text/image element)
or a **layout page** (layout code + raw photo paths + caption strings;
the library positions everything via the layout solver).

```dart
const DotsTemplate(
  documentId: 'demo',
  pageSize: DotsPageSize(width: 592.34, height: 736.81),
  pages: <DotsPage>[
    // Explicit-coords: caller chooses every (x, y, w, h).
    DotsElementsPage(
      pageNumber: 1,
      elements: <DotsElement>[
        DotsTextElement(
          x: 72, y: 72, value: 'Hello', fontSize: 24,
          fontFamily: 'P22 Mackinac Medium',
        ),
        DotsImageElement(
          x: 72, y: 120, width: 200, height: 150,
          assetPath: 'https://example.com/photo.jpg',
          bleedRight: true,
        ),
      ],
    ),

    // Layout-driven: caller names the layout + supplies content.
    DotsLayoutPage(
      pageNumber: 2,
      layoutCode: DotsLayoutCode.l4a, // 2x2 grid, 86x110 mm each
      photoAssetPaths: <String>['…', '…', '…', '…'],
    ),
  ],
);
```

### Layout codes

The library ships with the full Dotbook layout repertoire from
`docs/templates/SPECS_interior.md`:

| Code | Photos | Notes |
|---|---|---|
| `l1`, `l1a`–`l1e` | 1 | Protagonist variants (default 142×189, plus alt sizes 113×152 / 175×238 / 175×196 / 107×107 / 107×152) |
| `l2a`, `l2b`, `l2c` | 2 | Side-by-side, stacked, or small framed pair |
| `l3a` | 3 | Row of three (60.27 × 82 mm, 3 mm gaps) |
| `l4a`, `l4b` | 4 | 2×2 grid or per-page slice of a spread grid |
| `l6a` | 6 | Three-up + one across a spread |
| `l7` | 4 + captions | 4-pane collage with text under each |
| `l8` | 4 + 2 | Quad top, double bottom |
| `lhito` | 0 | Milestone text page with title + date + body + QR card |

Slot kinds emitted by the solver — what shows up in
`DotsLayoutPage.captions`:

```dart
DotsSlotKind.captionTitle   // P22 Mackinac medium, 11 pt (20 pt for lhito)
DotsSlotKind.captionDate    // P22 Mackinac medium, 11 pt (Book 9 pt for lhito)
DotsSlotKind.captionBody    // Inter, 9 pt
DotsSlotKind.qrCard         // QR rendered from the payload string (typically a URL)
```

#### Required vs. optional captions per layout

Each `DotsLayoutCode` exposes its content contract via `.requirements`:

```dart
final r = DotsLayoutCode.lhito.requirements;
r.photoCount;             // 0
r.requiredCaptionKinds;   // [captionTitle, captionBody]
r.optionalCaptionKinds;   // [captionDate, qrCard]
```

| Layout | Photos | Required captions | Optional captions |
|---|---|---|---|
| `l1`, `l1a`–`l1e` | 1 | — | — |
| `l2a`–`l2c` | 2 | — | — |
| `l3a` | 3 | — | — |
| `l4a` | 4 | — | — |
| `l4b` | 2 (per page of a 2-page spread) | — | — |
| `l6a` | 3 (per page) | — | — |
| `l7` | 2 (per page) | — | `captionDate`, `captionBody` |
| `l8` | 3 (per page) | — | — |
| `lhito` | 0 | `captionTitle`, `captionBody` | `captionDate`, `qrCard` |

The parser raises `DotsConfigException` at parse time when a required
caption is missing or empty.

### Asset sources

`DotsImageElement.assetPath` (and the photo paths in a
`DotsLayoutPage`) accept two forms:

- **Local path** — read directly from the injected `FileSystem`.
- **URL** (`http://` or `https://`) — downloaded into the
  per-document `tmp/<id>/` directory, used, and swept away at the
  end of the run.

The default URL fetcher uses `dart:io HttpClient` with a 10-second
timeout and accepts only 2xx responses. Inject `urlFetcher:` on
`DotsGenerator` for tests or corporate proxies.

### Pliegos (2-page spreads, recommended)

`DotsTemplate` accepts content two equivalent ways: a flat `pages`
list, or a `pliegos` list of 2-page spreads. The pliego-level API is
recommended for new code — it's stricter about pagination (every
pliego is exactly two pages) and lets you declare a spread-spanning
image with a single asset path.

```dart
const template = DotsTemplate(
  documentId: 'demo',
  pageSize: DotsPageSize(width: 592.34, height: 736.81),
  pliegos: <DotsPliego>[
    // Two independent pages glued together.
    DotsLayoutPliego(
      pliegoNumber: 1,
      left:  DotsLayoutPage(layoutCode: DotsLayoutCode.l1,
                            photoAssetPaths: <String>['…']),
      right: DotsLayoutPage(layoutCode: DotsLayoutCode.l4a,
                            photoAssetPaths: <String>['…', '…', '…', '…']),
    ),
    // One image, one URL, spans the whole spread. The library splits
    // it into left and right halves at render time — no duplicate
    // declaration needed.
    DotsSpreadImagePliego(
      pliegoNumber: 2,
      assetPath: 'https://example.com/panorama.jpg',
      spreadWidth: 1184, height: 689,
      bleedTop: true, bleedBottom: true, bleedOuter: true,
    ),
  ],
);
```

`pages` and `pliegos` are **mutually exclusive** — set one or the
other, not both. When `pliegos` is set, the library flattens the
list into output pages internally (pliego N becomes pages 2N-1 and
2N). The page numbers on the inner pages of a `DotsLayoutPliego`
are overwritten with the correct sequential values, so you can put
any placeholder there.

### Spread-spanning images (page-level fallback)

If you're staying on the page-level API and need a spread image
without using a `DotsSpreadImagePliego`, declare a
`DotsSpreadImageElement` on each page with matching `half`:

```dart
const DotsElementsPage(
  pageNumber: 4,
  elements: <DotsElement>[
    DotsSpreadImageElement(
      x: 0, y: 0,
      assetPath: 'https://example.com/panorama.jpg',
      spreadWidth: 1184, // full image width across the spread, in pt
      height: 689,
      half: DotsSpreadHalf.left,
      bleedTop: true, bleedBottom: true, bleedOuter: true,
    ),
  ],
),
// Mirror with half: right on page 5.
```

The renderer clips and offsets the underlying image so the two
halves stitch at the binding. The same URL is fetched once per
renderer instance. For new code, prefer `DotsSpreadImagePliego` —
it expresses the same intent with a single asset path.

### Previewing the output

After each PDF is generated the library can also emit one PNG per page
under `<docs>/dots_pdf/preview/<documentId>/`, cropped to remove the
print-only bleed (and, for the cover, the 20 mm wrap). Opt in by
wiring a `DotsPdfRasterizer`:

```dart
final generator = DotsGenerator(
  fileSystem: fs,
  documentsDir: docs,
  rasterizer: DotsPdfRasterizer.printing(),
  previewDpi: 150, // optional, default
);
```

The stream then emits one `PdfPreviewProgress(documentId,
completedPages, totalPages)` per preview page;
`PdfGenerationCompleted.previewPaths` and
`PdfGenerationCacheHit.previewPaths` list the resulting PNGs in
document order. Without a rasterizer the field stays empty and prior
behaviour is preserved. Inject a fake `DotsPdfRasterizer` in tests —
`Printing.raster` only runs on a Flutter device.

### Caching and re-generation

The cache key is implicitly `(documentId, mode, contentHash)`.
`contentHash` is a fast, non-cryptographic `Object.hash` over the
parsed template; any change to the template invalidates the cache
automatically. Force a re-run with `forceRegenerate: true`:

```dart
generator.generateWhole(template: template, forceRegenerate: true);
```

On a cache hit the stream emits a single `PdfGenerationCacheHit`
event with the existing artifact paths and skips the pipeline.

### Cover rendering

The hardcover wrap is generated from a `DotsCoverTemplate`, **not**
from the interior `DotsTemplate`. Geometry (spine width, wrap, bleed,
hinch) is a pure function of the page count + paper substrate:

```dart
final coverGeometry = DotsCoverGeometry(
  pageCount: 132,
  paperSubstrate: DotsPaperSubstrate.uncoated150,
  supplier: DotsSupplier.europa,
);

final coverTemplate = DotsCoverTemplate(
  documentId: 'album_alexei_2026',
  geometry: coverGeometry,
  frontArtworkPath: '/local/cover_front.jpg',
  backArtworkPath: '/local/cover_back.jpg',
  spineTitle: 'Memories 2026', // optional; null/empty → no spine text
  spineArtworkPath: null,       // optional spine background
);

await generator.generateCover(template: coverTemplate).drain();
```

Per-tier spine widths are hard-coded from the official FileSpecs
spreadsheet:

| Letter | Page range (uncoated 150 gsm) | Page range (satin 170 / gloss 200) | Spine |
|---|---|---|---|
| A | 20 – 40 | 20 – 50 | 6.76 mm |
| B | 42 – 80 | 52 – 100 | 11.25 mm |
| C | 82 – 120 | 105 – 150 | 15.75 mm |
| D | 122 – 160 | 152 – 200 | 20.24 mm |
| E | 162 – 200 | 202 – 250 | 24.74 mm |
| F | 202 – 242 | 252 – 300 | 29.24 mm |

Constructor validation:
- `pageCount` must be a multiple of 4.
- `pageCount` must be `>= supplier.minPageCount` (europa = 20, latam = 30).
- `pageCount` must be `<= 250` (hard library cap).
- `pageCount` must fall inside the substrate's tier table.

Out-of-range inputs throw `DotsConfigException` with the JSON pointer
`$.pageCount`.

---

## JSON template format

If you'd rather drive the generator from JSON (e.g. fetched from a
backend), parse with `DotsTemplateParser`:

```dart
const parser = DotsTemplateParser();
final template = parser.parse(jsonString);
await generator.generateWhole(template: template).drain();
```

```json
{
  "documentId": "album_2026",
  "pageSize": { "width": 592.34, "height": 736.81 },
  "pages": [
    {
      "pageNumber": 1,
      "elements": [
        { "type": "text",  "value": "Hello",
          "x": 72, "y": 72, "fontSize": 24,
          "fontFamily": "P22 Mackinac Medium" },
        { "type": "image", "assetPath": "https://example.com/photo.jpg",
          "x": 72, "y": 120, "width": 200, "height": 150,
          "bleedRight": true }
      ]
    },
    {
      "pageNumber": 2,
      "layout": "l4a",
      "photos": [
        "https://example.com/a.jpg",
        "https://example.com/b.jpg",
        "/local/c.jpg",
        "/local/d.jpg"
      ]
    },
    {
      "pageNumber": 3,
      "layout": "lhito",
      "captions": {
        "title": "A milestone",
        "date":  "May 17, 2026",
        "body":  "Story body…",
        "qr":    "https://onelife.example/album/123"
      }
    },
    {
      "pageNumber": 4,
      "elements": [
        { "type": "spreadImage", "assetPath": "https://example.com/panorama.jpg",
          "x": 0, "y": 0, "spreadWidth": 1184, "height": 689,
          "half": "left", "bleedOuter": true }
      ]
    },
    {
      "pageNumber": 5,
      "elements": [
        { "type": "spreadImage", "assetPath": "https://example.com/panorama.jpg",
          "x": 0, "y": 0, "spreadWidth": 1184, "height": 689,
          "half": "right", "bleedOuter": true }
      ]
    }
  ]
}
```

Validation is strict — any missing required field or shape mismatch
throws `DotsConfigException` with a `pointer` locating the field in
the source JSON.

#### Pliego JSON (recommended)

Replace `"pages"` with `"pliegos"` to use the 2-page-spread API:

```json
{
  "documentId": "album_2026",
  "pageSize": { "width": 592.34, "height": 736.81 },
  "pliegos": [
    {
      "pliegoNumber": 1,
      "type": "layout",
      "left":  { "layout": "l1", "photos": ["…"] },
      "right": { "layout": "l4a", "photos": ["…", "…", "…", "…"] }
    },
    {
      "pliegoNumber": 2,
      "type": "spreadImage",
      "assetPath": "https://example.com/panorama.jpg",
      "spreadWidth": 1184,
      "height": 689,
      "bleedTop": true,
      "bleedBottom": true,
      "bleedOuter": true
    }
  ]
}
```

`"pages"` and `"pliegos"` are mutually exclusive. Inner pages of a
`"layout"` pliego may omit `pageNumber` — the library assigns the
sequential value from the pliego's position.

---

## Memory budget

The library is sized for low-end mobile devices:

- One `pw.Page` worth of state is alive at a time.
- Image bytes are read inside `buildPage` and become unreachable as
  soon as `addPage` returns.
- Fonts parse once per generator instance and are reused across every
  page.
- URL downloads land in a per-document `tmp/` directory that's swept
  in a `finally` block after each run — success or failure.

The unavoidable buffering is `pw.Document.save()`, which returns the
full final PDF as a single `Uint8List`. The pdf package doesn't expose
an incremental save; until it does, the per-page contract is what we
can control.

---

## Per-supplier rules

The only printed-output difference between suppliers today is whether
crop marks are drawn:

| Supplier | `minPageCount` | `drawsCropMarks` |
|---|---|---|
| `DotsSupplier.europa` | 20 | `true` |
| `DotsSupplier.latam`  | 30 | `false` |

Pass `drawCropMarks: supplier.drawsCropMarks` when constructing the
generator; the cover renderer reads it off the geometry's supplier
field automatically.

---

## Custom fonts and the `fontFamily` field

`DotsTextElement.fontFamily` maps to a `DotsFontRole` via
`DotsFontBundle.roleFromFamily`. Recognised values (case-insensitive):

| Family string | Role |
|---|---|
| `P22 Mackinac`, `P22 Mackinac Medium` | `p22MackinacMedium` |
| `P22 Mackinac Book` | `p22MackinacBook` |
| `P22 Mackinac Medium Italic`, `P22 Mackinac Italic` | `p22MackinacMediumItalic` |
| `Inter`, `Inter Book`, `Inter Semibold`, `Inter Light` (variable upright) | `inter` |
| `Inter Italic` | `interItalic` |
| `Biro Script Plus`, `Biro` | `biroScriptPlus` |

Unrecognised strings fall back to the pdf package's default font
(Helvetica). Pass `fontBundle: null` (the default) to skip font
loading entirely if you don't need real typography.

### Font format requirement — TrueType only

`DotsFontBundle` accepts **TrueType** (`.ttf`) fonts only. The
underlying `pdf` package's `TtfParser` reads the SFNT tables but
does **not** embed CFF outlines, which are what CFF-flavored
OpenType (`.otf`, SFNT magic `OTTO`) uses. If you pass an `.otf`
font, the library will throw `DotsConfigException` at construction
time with a pointer to the affected role.

The visible bug if the check is bypassed: **every letter renders at
the same x position** (zero advance widths because the parser
silently maps every glyph to `.notdef`).

If your foundry only ships `.otf`, convert once with
[`fontTools`](https://github.com/fonttools/fonttools):

```sh
pip3 install --user fonttools cu2qu otf2ttf
cd assets/fonts/p22_mackinac/        # or wherever your .otf files live
otf2ttf *.otf                        # produces .ttf alongside each .otf
```

Then:
1. Update `pubspec.yaml` so the `assets:` list points at the new
   `.ttf` filenames.
2. If you use `DotsFontBundle.fromPackageAssets()`, the helper
   currently expects the `.otf` filenames the library shipped with
   — point the `load(...)` calls at the new `.ttf` files (or copy
   the helper into your own code and adapt the paths).

The conversion is lossy at the outline level (cubic-Bezier
PostScript outlines are re-traced as quadratic-Bezier TrueType
outlines), but at print resolution the result is visually
indistinguishable.

---

## Project layout

```
lib/
  dots_pdf.dart                  public exports
  src/
    api/                          DotsGenerator + DotsOutputMode + DotsAlbumType
    cache/                        DotsCache, DotsCacheStatus
    config/                       DotsTemplate, DotsTemplateParser, DotsConfigException
    cover/                        DotsCoverGeometry, DotsCoverTemplate, DotsCoverRenderer,
                                  DotsSupplier, DotsPaperSubstrate
    events/                       PdfGenerationEvent (sealed: Started/Progress/CacheHit/
                                                       Completed/Failed)
    io/                           DotsPathManager
    logging/                      DotsLogger, DotsSilentLogger
    render/
      dots_renderer.dart          base renderer (handles every page type)
      whole_document_renderer.dart
      pair_document_renderer.dart
      dots_font_bundle.dart       DotsFontBundle, DotsFontRole
      asset_loader.dart           URL → tmp/ download
      crop_marks.dart             trim-corner ticks
      layout/                     DotsLayoutSolver, DotsLayoutCode, DotsSlotKind,
                                  DotsPageGeometry
assets/
  FOGRA99.txt                     FOGRA39 CGATS reference data (NOT a binary ICC; see SPECS)
  fonts/                          P22 Mackinac (24 OTF), Inter (2 variable TTF),
                                  Biro Script Plus (1 TTF)
docs/templates/
  SPECS.md                        cross-cutting spec + resolved decisions + deferred work
  SPECS_cover.md                  hardcover geometry math + per-tier table
  SPECS_interior.md               interior page layouts (L1–L8 + lhito) + text rules
  SPECS_album_types.md            per-album-type front/back-matter spread spec
example/
  example.dart                    end-to-end usage demo
test/                             140+ tests mirroring the lib/ layout
```

---

## Running tests

```bash
flutter test
```

To run only the renderer tests:

```bash
flutter test test/render/
```

The full suite runs against an in-memory `FileSystem` and uses fake
HTTP fetchers, so it never hits the network. Font tests load the
real OTF/TTF files from `assets/fonts/` via `dart:io File`.

---

## Known limitations and follow-ups

Tracked in [`docs/templates/SPECS.md`](docs/templates/SPECS.md) §
"Deferred work":

- **PDF/X-4 conformance.** The pdf package doesn't expose an
  `OutputIntents` helper; emitting the catalog dictionary + the
  ICC stream needs a `PdfObject` subclass.
- **Binary FOGRA39 ICC profile.** `assets/FOGRA99.txt` is the CGATS
  reference data, not a binary ICC. Generate the `.icc` from it with
  Argyll CMS (`colprof`) or basICColor and drop it under
  `assets/icc/`.
- **Full glyph embedding.** The pdf package subsets fonts on embed
  by default; PDF/X-4 requires the full glyph set. Patching the
  pdf package or pre-flighting fonts is the unblocker.
- **L5 (5-photo) layout.** Per stakeholder decision, 5-photo pages
  are composed as `L4 + L1` hybrids rather than a dedicated layout
  code.

---

## License

TBD. Bundled fonts (P22 Mackinac, Biro Script Plus) are licensed
commercial type — license documentation will land alongside the
license decision for the library itself.
