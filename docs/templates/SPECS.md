# Dotbook — ground-truth spec for the `dots_pdf` library

This document consolidates the three detailed specs into a single reference
that maps the source material onto concrete implementation decisions for
the Flutter library. The detailed specs remain authoritative; this file is
the index and the bridge to code.

| Topic                           | Authoritative file              |
|---------------------------------|----------------------------------|
| Hard-cover geometry & spine math | [SPECS_cover.md](SPECS_cover.md) |
| Interior body-page layouts       | [SPECS_interior.md](SPECS_interior.md) |
| Per-album-type front/back matter | [SPECS_album_types.md](SPECS_album_types.md) |
| Original issue                   | onelife-social/onelife_app#10443 (Impresión del dotbook) |

---

## What a "Dotbook" is

A printable hardcover photo album generated from a user's digital album.
Inputs are photos, milestones (hitos), and user-authored text (title,
subtitle, dedication). Output is two-PDF set per dotbook: **(1) cover PDF**
(image wrap), **(2) interior PDF** (book block). Both go to a print
supplier ("Europa" or "Latam").

The library renders both PDFs from a typed JSON template that the caller
provides; layout selection (1-photo protagonist vs N-photo grid vs hito
text page) is driven by the template, not auto-generated.

---

## Five orthogonal axes that define a print job

Each call to the generator carries a value for each of these:

1. **Album type** — `boda | parejas | hijos | individuales | otros`. Drives
   the front-matter / back-matter spreads and the right-page context
   label. See [SPECS_album_types.md](SPECS_album_types.md).
2. **Supplier region** — `europa | latam`. Drives:
   - Minimum page count (20 vs 30).
   - Whether crop / bleed marks are drawn on the output PDF.
3. **Page count** — must be a multiple of 4, between supplier min and 250.
   Drives spine width via [SPECS_cover.md](SPECS_cover.md) lookup table.
4. **Paper substrate** — `uncoated150 | satin170 | gloss200`. Drives which
   page-range tier maps to which spine width.
5. **Output mode** — `whole | pairs`. Library-level choice from the
   existing `DotsOutputMode` enum; orthogonal to the four above.

---

## Trim geometry (universal)

- **Interior page trim**: 203 × 254 mm.
- **Bleed**: 3 mm on every outer edge.
- **Interior PDF flat size**: 209 × 260 mm per page (with bleed).
- **Cover PDF flat size**: depends on page count + paper, ranges from
  472.76 × 306 mm (smallest spine) to 495.24 × 306 mm (largest spine).
- All measurements in mm; convert to PDF points via × 2.834645 (1 mm = 2.834645 pt).
- Output spec: **PDF/X-4:2008**, CMYK Coated FOGRA39 (ISO 12647-2:2004).

---

## Per-page anatomy of an interior page

```
+--- 3 mm bleed -----------------------+
|                                      |  ← top header band (~12 mm)
| Nº página  |  context label  |  page |
|                                      |
|        live area for layout slots    |  ← 203 × ~228 mm usable
|                                      |
|              Dots. Memories          |  ← footer band (~12 mm)
+--- 3 mm bleed -----------------------+
```

The header / footer bands are constant across every body page; the live
area is what each layout (L1–L8, L_hito) carves into photo slots and text
blocks. Per-layout dimensions live in [SPECS_interior.md](SPECS_interior.md).

---

## Layout repertoire to support

From [SPECS_interior.md](SPECS_interior.md):

| Code     | Photos | Distinguishing element                            |
|----------|--------|---------------------------------------------------|
| L1       | 1      | Protagonist (142 × 189 default, several variants) |
| L2       | 2      | Side-by-side or stacked                           |
| L3       | 3      | Row of three (60.27 × 82)                         |
| L4       | 4      | 2 × 2 grid (86 × 110)                             |
| L5       | 5      | Hybrid — TBD, see open questions                  |
| L6       | 6      | 3 × 2 across a spread                             |
| L7       | 4 + text | Caption-per-photo collage (350 char per pane)   |
| L8       | 4 + 2  | Quad top, double bottom                            |
| L_hito   | 0      | Milestone text page (title + body + QR card)      |

Plus the per-album-type front- and back-matter spreads listed in
[SPECS_album_types.md](SPECS_album_types.md): cover, dedication, instructions,
"Antes de empezar el viaje", "Un año lleno de recuerdos", and closing page.

---

## Mapping spec → Dart types

The skeleton in `lib/src/config/dots_template.dart` already models
`DotsTemplate` / `DotsPage` / `DotsElement` (sealed: `text`, `image`).
Extending it to support the Dotbook spec requires:

| Spec concept                       | Dart addition                                     |
|------------------------------------|---------------------------------------------------|
| Album type                         | `enum DotsAlbumType { boda, parejas, hijos, individuales, otros }` |
| Supplier region                    | `enum DotsSupplier { europa, latam }`             |
| Paper substrate                    | `enum DotsPaperSubstrate { uncoated150, satin170, gloss200 }` |
| Cover geometry                     | `class DotsCoverGeometry` — pure function of (page count, paper) |
| Photo slot                         | `class DotsPhotoSlot extends DotsElement` — image + bleed flag + crop strategy |
| Layout selector                    | `enum DotsLayoutCode { l1, l1a, l1b, …, l_hito }` |
| Milestone                          | `class DotsHito` — title, date, body, qrPayload, mediaKind (audio/text/video) |
| Mark-rendering toggle              | `DotsRenderOptions { drawCropMarks: bool }` derived from supplier |
| Crop strategy                      | `enum DotsCropStrategy { centerFill }` (only one strategy in spec) |

The existing `DotsTemplate.contentHash` mechanism keeps working — the new
fields just contribute to the hash.

---

## Required fonts

| Family            | Weights used                | License                 |
|-------------------|-----------------------------|-------------------------|
| P22 Mackinac      | medium, book, medium-italic | Commercial — confirm licensing |
| Inter             | Book, Semibold, Light       | OFL                     |
| Biro Script Plus  | Regular (signature only)    | Commercial — confirm licensing |

Fonts must be loaded once per pipeline run via `TtfParser` / `PdfTtfFont`
and reused across pages. Do not reload per page (memory budget).

---

## Mandatory rules to enforce in code

Hard, enforced at parse time:

1. `pageCount % 4 == 0`, otherwise `DotsConfigException`.
2. `pageCount >= supplierMin && pageCount <= 250`.
3. Photo count `>= 16` (block) and `<= 490` (hard cap).
4. Hito title `<= 80 chars`.
5. Text-block caps per layout (see [SPECS_interior.md](SPECS_interior.md))
   — these are front-end limits but the library should defensively trim or
   throw on overflow.
6. Image min resolution: 150 dpi (image is rejected if lower); 300 dpi
   target (downsample if higher).

Soft, applied during rendering:

1. Bleed: photos marked `bleed: true` extend 3 mm beyond trim on marked edges.
2. Crop: center-fill, no deformation.
3. Widow lines: no break that leaves < 3 words on the trailing line.
4. Inter-word hyphenation: never.
5. Crop marks: drawn only when supplier == europa.

---

## What the library already supports (skeleton)

From the existing scaffold:

- JSON template parsing with strict validation (`DotsTemplateParser`).
- Path management (`DotsPathManager`) — `dots_pdf/whole/`, `dots_pdf/pairs/<id>/`, `dots_pdf/tmp/<id>/`.
- Cache with sidecar-hash invalidation (`DotsCache`).
- Progress-stream public API (`DotsGenerator.generateWhole` / `generatePairs`).
- Output mode `whole | pairs` (the 2-page-pair output is what the print
  supplier consumes when each pair is uploaded individually).

The rendering pipeline (`WholeDocumentRenderer.render`,
`PairDocumentRenderer.render`, `DotsRenderer.buildPage`) is stubbed —
implementing it is the next phase and is what this spec enables.

---

## What the library does NOT yet model

These are explicit non-goals of the current skeleton, queued for
follow-up tasks:

- **Cover PDF generation** — the skeleton handles the book block only.
  A separate `DotsCoverRenderer` is needed, driven by `DotsCoverGeometry`.
- **Per-album-type front/back matter** — the parser only knows generic
  `text` and `image` elements. Adding the album-type templates means
  introducing high-level element kinds (`coverFront`, `instructionsSpread`,
  `dedication`, `closingPage`, etc.) that the renderer expands into
  primitive draw calls.
- **Layout auto-selection** — issue AC1–AC3 (consolidation, ordering,
  template selection). Out of scope of `dots_pdf`; the caller is expected
  to choose layouts and produce a template. We can ship a separate
  `dots_pdf_layout` helper later if needed.
- **Hito rendering** — needs QR generation (`qr` package, already a
  transitive dependency of `pdf`).
- **Color profile attachment** — confirm `pdf` package supports embedding
  FOGRA39 ICC; if not, an external post-process step is required.

---

## Resolved clarifications (decisions of record)

All 10 open questions answered. These are the implementation rules.

1. **Europa vs Latam**: only difference is crop / bleed marks. Geometry,
   pagination minimums, and PDF output dimensions are otherwise identical
   to what's already in the per-supplier sections of this spec.
2. **Page count outside spreadsheet ranges**: **throw**
   `DotsConfigException`. No extrapolation.
3. **5-photo layout**: not a primitive layout. Implement as **L4 + L1**
   hybrid (one L4 page paired with one L1 page across a spread, or one L4
   page with one L1 slot reused — caller decides).
4. **Per-slot (x, y) anchors**:
   - **Boda p.3 cluster**: the existing callout numbers along the
     right-page right edge (80.842, 82.566, 84.511, 85.986, 92.278,
     92.626, 102.901, 103.772, 111.675 mm) are the x-positions of each
     photo, measured **from the right edge of the page**. Convert to
     page-origin x by `pageWidth - calloutMm - slotWidth`. The y values
     are derived from the gap callouts (3.492, 3.038, 2.884, 11.534,
     16.844, 5.292 mm) walked top-to-bottom from the top inset.
   - **Boda p.4 radial halo**: anchor is the **distance from the bottom**
     of the page. Compute each slot's y as `pageHeight - bottomOffset -
     slotHeight`. The arc-radius is implied by the visible spread render
     — the layout solver will need to fit each photo on the arc at a
     uniform angular step around the binding-side center.
   - **Individuales/otros p.6 polaroid collage**: one slot has full
     callouts (21 mm left, 18 mm top, etc.); apply the **same offset
     pattern** to the symmetric slots on the right page, and reuse the
     measured ±2.5° / +4° / +8° / −3.5° rotation set per the spec table.
5. **Spine text**: yes, the cover may carry a printed spine title.
   Implement as an optional `spineTitle: String?` on the cover template;
   when null or empty, render nothing on the spine.
6. **Back cover artwork**: separate from front cover artwork. Model as
   two distinct artwork inputs.
7. **Fonts P22 Mackinac + Biro Script Plus**: licenses are held. Use them
   directly. Licenses to be attached later once PDF output is verified.
8. **`{NOMBREHIJO}` token in individuales/otros**: authoring leftover.
   Treat **all** template variables as caller-supplied strings via the
   JSON config — the library does not hard-code any per-type variable
   semantics. The token name is irrelevant; the caller passes the value.
9. **150 dpi vs 300 dpi**: 150 dpi = **accept threshold** for input
   images (anything lower is rejected). 300 dpi = **PDF output target**
   (downsample if input is higher).
10. **`{tiempojuntos}` fallback**: the caller passes the string. If it
    expresses years-together ("2 años juntos"), use that; if it's empty
    or absent, the caller substitutes the current year. The library
    treats this as a plain string — no logic in the library.

---

## Deferred work — PDF/X-4 + FOGRA39 conformance

PDF/X-4 conformance is more involved than a single isolated module:

- It requires embedding a real ~1 MB FOGRA39 **binary ICC** profile
  stream and declaring `/OutputIntents` in the document catalog.
- It also requires XMP metadata declaring `pdfxid:GTS_PDFXVersion="PDF/X-4"`,
  `/Trapped /False` in the info dictionary, embedded (not subsetted)
  glyphs for every font, and a transparency model that supports the
  PDF/X-4 specification.
- The `pdf` package (3.12.0) does not expose a first-class
  `OutputIntent` helper. A research-phase agent confirmed this by
  probing the package's internal `format/dict.dart`, `format/name.dart`,
  and `format/base.dart` and concluded a raw-write workaround would be
  required.

**Status update:** `assets/FOGRA99.txt` ships in the package, but it
contains the **CGATS reference characterization data** for FOGRA39
(ISO 28178 ASCII format, 1485 data sets), **not a binary `.icc`
profile**. The CGATS file is the input you feed to a profile-building
tool (Argyll CMS, basICColor) to generate the binary ICC. Until the
binary is generated and dropped into `assets/icc/`, full PDF/X-4
conformance remains out of reach.

The library currently does **not** declare PDF/X-4 conformance — it
emits standard PDF 1.7 (the pdf package default). What ships:

- **Crop marks** for europa supplier (`DotsGenerator(drawCropMarks:
  true)` or `DotsSupplier.europa.drawsCropMarks`).
- **Embedded fonts** via `DotsFontBundle.fromPackageAssets()` — P22
  Mackinac, Inter, Biro Script Plus. The pdf package subsets glyphs
  on embed, so the resulting PDF is NOT PDF/X-4 compliant on the
  "all glyphs embedded" rule. A follow-up will need to disable
  subsetting or expand the embedded set to the printable ASCII range.

A follow-up task should:
1. Generate the ECI `CoatedFOGRA39.icc` from the bundled CGATS data
   (via Argyll's `colprof` or equivalent) and drop it under
   `assets/icc/`.
2. Extend the pdf package via a `PdfObject` subclass that emits the
   catalog's `/OutputIntents` array and references the ICC stream.
3. Generate XMP metadata via the pdf package's `PdfMetadata` (if
   available) or a raw-stream wrapper.
4. Force full-glyph embedding (or expand the embedded set) for every
   font in `DotsFontBundle`.
5. Verify against an external PDF/X-4 conformance checker (e.g.
   pdfx-checker, callas pdfToolbox) before declaring the milestone done.

Crop-marks + font embedding unblock the visual portion of the supplier
requirement; PDF/X-4 conformance unblocks the print-shop acceptance
portion and stays deferred.

## Suggested order of implementation

A reasonable next sequence, building on the existing skeleton:

1. **Cover geometry pure-math layer**: `DotsCoverGeometry` + the page-tier
   lookup. Pure functions, easy to test with `package:test`. (Hooks the
   `SPECS_cover.md` math directly.)
2. **Body-page renderer minimal viable**: implement
   `WholeDocumentRenderer.render` for L1 (single image with caption) only,
   end-to-end against `MemoryFileSystem`. Validates the `pw.Document` +
   `IOSink` + per-page disposal pattern from the agent prompt.
3. **Layout grid solver**: takes a `DotsLayoutCode` + page size and emits
   slot rectangles. Pure math, isolated tests.
4. **L2–L6 renderers**: implement one at a time, each with a test that
   renders a single page to PDF and checks the resulting byte stream
   parses back.
5. **L_hito renderer**: text-dominant page + QR card.
6. **Per-album-type spreads**: cover, dedication, instructions, etc.
7. **Cover PDF renderer**: `DotsCoverRenderer` using `DotsCoverGeometry`.
8. **Color profile / PDF/X-4 conformance**: validate against an external
   PDF/X-4 checker before declaring the supplier-ready milestone done.

Steps 1–4 fit naturally inside the existing skeleton; steps 5–8 require
the new types listed under "Mapping spec → Dart types" above.
