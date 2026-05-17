# Hard-cover geometry spec

Derived from the two Excel files in `pdf_cover/`:

- `cover.drawing.1 (1).xlsx` — the labeled-variable cover layout (sizes a–m).
- `FileSpecs.203x254.V1.xlsx` — per-part-number table mapping page ranges to
  spine widths and final PDF sizes.

All units are millimeters unless stated. All values are exactly as found in
the spreadsheets (resolved formulas, not approximations).

---

## Fixed inputs

| Cell | Variable                       | Value |
|------|--------------------------------|-------|
| B5   | Book block width (finished)    | **203** mm |
| B6   | Book block height (finished)   | **254** mm |
| B7   | Spine stroke width (variable — depends on page count, see table below) | **6.76** mm (default sample) |
| B8   | Bleed                          | **3**   mm |

Constants used by the geometry:

| Constant      | Value | Notes                                            |
|---------------|-------|--------------------------------------------------|
| Hinch         | 11 mm | Joint allowance between board edge and spine     |
| Wrap          | 20 mm | Image-wrap overhang on each cover edge           |
| Board thickness | 2.5 mm | Front/back board (and spine board)             |
| Bleed margin  | 3 mm  | Added on every outer edge of the printable area  |

---

## Labeled variables a–m (cover.drawing.1)

| Var | Description                                  | Formula                          | Value @ 6.76 mm spine |
|-----|----------------------------------------------|----------------------------------|------------------------|
| a   | Width spine stroke (input from B7)           | = B7                             | **6.76** mm            |
| b   | Height spine stroke                          | = m + 2·3 mm                     | **260** mm             |
| c   | Width front and back cover                   | = l − 4 mm                       | **199** mm             |
| d   | Height front and back cover                  | = m + 2·3 mm                     | **260** mm             |
| e   | Hinch                                        | 11 mm (fixed)                    | **11** mm              |
| f   | Wrap allowance                               | 20 mm (fixed)                    | **20** mm              |
| g   | Total cover width incl. wrap **excl.** bleed | = (c + f + e)·2 + a              | **466.76** mm          |
| h   | Total cover height incl. wrap **excl.** bleed| = d + 2·f                        | **300** mm             |
| i   | Total cover width incl. wrap **incl.** bleed | = g + 2·3 mm                     | **472.76** mm          |
| j   | Total cover height incl. wrap **incl.** bleed| = h + 2·3 mm                     | **306** mm             |
| k   | Width front-and-back incl. hinch             | = c + e                          | **210** mm             |
| l   | Width book block (finished, = B5)            | = B5                             | **203** mm             |
| m   | Height book block (finished, = B6)           | = B6                             | **254** mm             |
|     | Width book block incl. bleed                 | = l + 2·bleed                    | **209** mm             |
|     | Height book block incl. bleed                | = m + 2·bleed                    | **260** mm             |

**Layout, left to right across the wrap:**

```
| wrap 20 | bleed 3 | front c | hinch 11 | spine a | hinch 11 | back c | bleed 3 | wrap 20 |
 ^                                                                                          ^
 0 mm                                              total cover width (i) — 472.76 mm
```

Top-to-bottom:

```
| wrap 20 | bleed 3 |   height d = 260   | bleed 3 | wrap 20 |
                          (= m + 2·bleed)
total height (j) = 306 mm
```

---

## Per-part-number table (FileSpecs.203x254.V1)

Both rows are **Hardcover Imagewrap**, **PUR-bound**, finished trim
**203 × 254 mm**, bleed 3 mm, hinch 11 mm, wrap 20 mm, board 2.5 mm.

The difference between the two tables is the interior paper substrate; that
affects how many pages fit on each spine-letter tier.

### Table 1 — Block paper: 150 gsm uncoated (`Substrate block` = s44)

| Letter | Page range | Spine size (mm) | Cover w/o wrap (mm) | PDF incl. wrap (mm) | Flat PDF incl. 3 mm bleed (mm) |
|--------|------------|-----------------|---------------------|---------------------|--------------------------------|
| A      | 20 – 40    | **6.76**        | 426.76 × 260        | 466.76 × 300        | **472.76 × 306**               |
| B      | 42 – 80    | **11.25**       | 431.25 × 260        | 471.25 × 300        | **477.25 × 306**               |
| C      | 82 – 120   | **15.75**       | 435.75 × 260        | 475.75 × 300        | **481.75 × 306**               |
| D      | 122 – 160  | **20.24**       | 440.24 × 260        | 480.24 × 300        | **486.24 × 306**               |
| E      | 162 – 200  | **24.74**       | 444.74 × 260        | 484.74 × 300        | **490.74 × 306**               |
| F      | 202 – 242  | **29.24**       | 449.24 × 260        | 489.24 × 300        | **495.24 × 306**               |

Cover material: Satin 170 gsm. Laminate: Scuff-free matt. Print: 4/4 inside,
4/0 cover (cover printed one side only). PreProcess yes.

### Table 2 — Block paper: Satin 170 gsm **or** Gloss 200 gsm (`Substrate block` = s45)

Heavier (silk-coated) paper — fewer pages fit per spine tier.

| Letter | Page range | Spine size (mm) | Cover w/o wrap (mm) | PDF incl. wrap (mm) | Flat PDF incl. 3 mm bleed (mm) |
|--------|------------|-----------------|---------------------|---------------------|--------------------------------|
| A      | 20 – 50    | **6.76**        | 426.76 × 260        | 466.76 × 300        | **472.76 × 306**               |
| B      | 52 – 100   | **11.25**       | 431.25 × 260        | 471.25 × 300        | **477.25 × 306**               |
| C      | 105 – 150  | **15.75**       | 435.75 × 260        | 475.75 × 300        | **481.75 × 306**               |
| D      | 152 – 200  | **20.24**       | 440.24 × 260        | 480.24 × 300        | **486.24 × 306**               |
| E      | 202 – 250  | **24.74**       | 444.74 × 260        | 484.74 × 300        | **490.74 × 306**               |
| F      | 252 – 300  | **29.24**       | 449.24 × 260        | 489.24 × 300        | **495.24 × 306**               |

---

## Implementation summary

A `DotsCoverGeometry` model can be derived from just three inputs:

```
DotsCoverGeometry.fromSpec(
  blockWidthMm: 203,
  blockHeightMm: 254,
  pageCount: 132,           // → looks up tier, picks 20.24 mm spine
  paperSubstrate: PaperSubstrate.uncoated150,  // → Table 1
  bleedMm: 3,
  hinchMm: 11,
  wrapMm: 20,
);
```

Derived properties (all computed lazily, no caching needed — these are pure
arithmetic):

```
get totalCoverWidthExclBleedMm => (frontBackWidthMm + wrapMm + hinchMm) * 2 + spineWidthMm;
get totalCoverHeightExclBleedMm => bookBlockHeightMm + 2 * wrapMm;
get totalCoverWidthInclBleedMm => totalCoverWidthExclBleedMm + 2 * bleedMm;
get totalCoverHeightInclBleedMm => totalCoverHeightExclBleedMm + 2 * bleedMm;
get frontBackWidthMm => bookBlockWidthMm - 4;  // 4 mm fold-loss
get frontBackWidthInclHinchMm => frontBackWidthMm + hinchMm;
```

PageCount → spine-tier lookup tables (one per `PaperSubstrate`) are static
constants pulled directly from the FileSpecs table above.

Sanity-check: at 132 pages × 150 gsm uncoated → letter D → 20.24 mm spine →
total PDF size 486.24 × 306 mm. Matches the spreadsheet row exactly.

---

## Open questions

- **Page-count below 20 or above 242 (uncoated) / 300 (coated)**: the
  spreadsheet does not extrapolate. The issue body specifies a hard cap at
  250 pages (so we will never exceed Table 2 letter E) and a floor of 20
  (Europa) / 30 (Latam). What should the library do if a caller requests a
  page count outside the table? Most likely answer: throw a
  `DotsConfigException` — but the issue doesn't say.
- **Europa vs Latam difference**: the issue mentions Latam has no bleed
  marks while Europa does. The Excel files do not distinguish providers.
  This is presumably a render-time toggle (draw crop marks or not), not a
  geometry change. **Confirm with stakeholders.**
- **Front cover artwork rotation**: nothing in either spreadsheet says
  whether the cover artwork is laid out left-to-right with the spine in the
  middle, or if the back cover gets its own design. The
  `SPECS_album_types.md` per-type templates only show the front; we may
  need a `coverBack` artwork variant.
- **Spine text** (`Spine Letter` column in FileSpecs holds A–F but the
  hardcover-drawing sheet has no spine-text geometry): is the spine
  intended to carry a printed title? No artwork in `pdf_cover/` shows this.
- **Substrate selection logic**: the library JSON contract does not yet
  carry `paperSubstrate`. Once cover generation is implemented the template
  parser will need a new field — or the caller will need to pass it
  alongside the template.
