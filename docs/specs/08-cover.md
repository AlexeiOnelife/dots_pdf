# 08 — Cover (hardcover image-wrap)

> Source: `docs/templates/pdf_cover/cover.drawing.1 (1).xlsx` (labeled wrap
> geometry) + `docs/templates/pdf_cover/FileSpecs.203x254.V1.xlsx` (per-substrate
> spine tier tables).

The cover is **separate from the interior** — it has its own template and
geometry and is generated via `generateCover(...)`. Cover geometry is a pure
function of **page count + paper substrate** (which set the spine width). All
dimensions are millimetres unless noted.

## 1. Fixed construction constants

| Constant | Value |
|---|---|
| Book block (trim) | 203 × 254 mm |
| Bleed | 3 mm all sides |
| Hinge (hinch) | 11 mm |
| Wrap (turn-in) | 20 mm |
| Board thickness | 2.5 mm |
| Print | 4/4 interior, 4/0 cover |
| Binding | PUR bound, hardcover imagewrap |

## 2. Wrap layout (left → right across the flat cover sheet)

```
| wrap 20 | bleed 3 | back 199 | hinge 11 | spine a | hinge 11 | front 199 | bleed 3 | wrap 20 |
```

| Label | Region | Width (mm) |
|---|---|---|
| a | spine | variable (tier — see §4) |
| b | spine height | 260 |
| c | front / back panel width | **199** (203 trim − 2× 2 mm board pull-in) |
| d | front / back panel height | 260 |
| e | hinge | 11 |
| f | wrap | 20 |
| g | total width **excl** bleed | 466.76 (at min spine 6.76) |
| h | total height **excl** bleed | 300 |
| i | total width **incl** bleed | 472.76 (at min spine) |
| j | total height **incl** bleed | 306 |
| k | front + hinge | 210 |
| l | book block width | 203 |
| m | book block height | 254 |

Book block incl bleed: **209 × 260 mm** (matches the interior single-page media).

## 3. Spine width depends on page count AND substrate

Two tier tables. Pick by the interior paper substrate, then by page count.

### Table 1 — 150 gsm uncoated block

| Tier | Page count | Spine (mm) | Flat PDF incl bleed (mm) |
|---|---|---|---|
| A | 20–40 | 6.76 | 472.76 × 306 |
| B | 42–80 | 11.25 | 477.25 × 306 |
| C | 82–120 | 15.75 | 481.75 × 306 |
| D | 122–160 | 20.24 | 486.24 × 306 |
| E | 162–200 | 24.74 | 490.74 × 306 |
| F | 202–242 | 29.24 | 495.24 × 306 |

### Table 2 — Satin 170 / Gloss 200 block

| Tier | Page count | Spine (mm) | Flat PDF incl bleed (mm) |
|---|---|---|---|
| A | 20–50 | 6.76 | 472.76 × 306 |
| B | 52–100 | 11.25 | 477.25 × 306 |
| C | 105–150 | 15.75 | 481.75 × 306 |
| D | 152–200 | 20.24 | 486.24 × 306 |
| E | 202–250 | 24.74 | 490.74 × 306 |
| F | 252–300 | 29.24 | 495.24 × 306 |

> Flat width incl bleed = `2×wrap (40) + 2×bleed (6) + 2×panel (398) + 2×hinge
> (22) + spine`. Height incl bleed is always **306 mm** (254 + 2×wrap 20 + ...);
> total height **excl** bleed is 300 mm.

## 4. Page-count rules

| Rule | Value |
|---|---|
| Divisibility | page count **% 4 == 0** |
| Maximum | **≤ 250** (≤ 300 for satin/gloss per Table 2) |
| Round to a multiple of 4 | inside the substrate tier range |

`DotsCoverGeometry` throws `DotsConfigException` at `$.pageCount` if the count is
not divisible by 4. See [AGENTS.md](../../AGENTS.md).

## 5. Provider bleed / crop-mark rules

The crop/bleed-mark treatment is the **only** geometric difference between
providers (panel/spine math is identical):

| Provider | Crop + bleed marks | Min pages |
|---|---|---|
| **europa** | **yes** (3 mm bleed + crop/bleed marks) | 20 |
| **latam** | **no** marks | 30 |

Substrate options (`DotsPaperSubstrate`): `uncoated150`, `satin170`, `gloss200`
— each selects its spine tier table above.

## 6. Dust-jacket (partial DJ) variant

For the partial dust-jacket sheet:

| Property | Value (mm) |
|---|---|
| Total width | 632.76 |
| Flap base (each, L + R) | 100 |
| Total height | 150 |

## 7. Comparison checklist

1. Confirm substrate → pick Table 1 or Table 2.
2. Confirm page count → resolve tier → spine width.
3. Verify flat sheet width incl bleed matches the tier's value (height always
   306 mm incl bleed).
4. Verify wrap (20) / hinge (11) / bleed (3) bands and panel width (199).
5. Verify crop/bleed marks present for europa, absent for latam.
