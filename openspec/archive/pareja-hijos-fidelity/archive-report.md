# Archive report: pareja-hijos-fidelity

**Date:** 2026-05-29
**Series position:** Task 4 of 7 (`final-render-refinement`)
**Result:** shipped — 667 tests GREEN / 0 RED, analyzer clean

## Commits
- `d600d6e` chore: SDD planning artifacts (explore, proposal, spec, design, tasks)
- `8fd88b4` feat(render): pareja+hijos fidelity — eyebrow fix + coordinate corrections + filled stubs

## What shipped

### CRITICAL fix
- `cover(parejas|hijos)` eyebrow text corrected to `"DOTBOOK DE {PROTAGONISTA}"` for both types. Previously parejas emitted only `'DOTBOOK'` (every parejas cover was wrong).

### Coordinate corrections against PDF measurements
- `cover`: 120 mm text box at x=41.5; eyebrow y=110.249; title y=119; date y=130.7.
- `dedication`: text x=50.53 mm; body width 120 mm.
- `closing`: photo y=71.534; title/subtitle x=44 mm width 115 mm; 5 mm gaps.

### Filled stub factories
- `beforeYouStart(parejas|hijos)`: two-page spread, 10 photo slots, per-category title + body, Q1/Q2 cluster.
- `closingQrSpread(any)`: left-page body with title, body, QR block, caption, bottom variable text. Right page chrome-only.

### API additions
- `AlbumBeforeYouStartContent.photoPaths` REQUIRED List<String> length 10.
- `AlbumQrSpreadContent.bottomTextOverride` OPTIONAL String?.

## Deferred follow-ups
- Dedication left-page `#CDE7F2` background.
- Photo-slot rounded corners.
- `closingQrSpread` right-page decorative circles (PDF lacks diameters).
- `photoArc` source-PDF reconciliation.
- `DotsOvalQrElement` square-frame variant.

## Verification
- `flutter analyze`: clean.
- `flutter test`: 667 GREEN / 0 RED.
- All 29 tasks.md items checked off.
