# Design: album-type-simple-pages (slice 2 of 5)

## Technical Approach

Slice 2 turns the two `UnimplementedError` throw-sites that slice 1 left behind into a working renderer for the two simplest album-type pages — **dedication** and **closing single page** — plus the header/footer trio that every album-spread page draws. It does so by:

1. Adding TWO new `DotsElement` subtypes (`DotsRotatedTextElement`, `DotsTextBlockElement`) that absorb the new typographic primitives — rotation and width-constrained multi-line text. The page model `DotsAlbumSpreadPage` stays unchanged (still a `header` + `footer` + `elements` triple).
2. Adding two named constructors `DotsAlbumSpreadPage.dedication(...)` and `DotsAlbumSpreadPage.closing(...)` that take typed per-page parameters and assemble the correct `elements` list internally — including the per-album-type font-size variant on closing TITLE.
3. Adding a top-level `buildSimplePagesFor(DotsAlbumType, AlbumSimpleContent, {int firstPageNumber, int contextLabelValue})` that emits the ordered dedication + closing pages for the requested type.
4. Extracting a single shared `buildAlbumSpreadPage(...)` rendering helper used by BOTH `DotsRenderer.buildPage` and `_IsolatePageRenderer.buildPage`, eliminating drift between the two rendering paths.

The dispatch in the renderer's `_buildElement` switch grows two new arms; the asset-preloader's `case DotsAlbumSpreadPage()` arm grows two no-op arms for the new element subtypes (neither carries an `assetPath`).

---

## Architecture Decisions

### Decision D1: `DotsRotatedTextElement` signature — degrees, center-anchored

| Option | Pro | Con |
|---|---|---|
| A. `angleDegrees` field; renderer converts to radians (**chosen**) | Author-readable (spec calls out "2°", "−2.5°"). One conversion site in the renderer. | Need to remember to convert. |
| B. `angleRadians` field | No conversion. | Authors must compute `2 * pi / 180` inline — ugly. |

Field set:

```dart
class DotsRotatedTextElement extends DotsElement {
  const DotsRotatedTextElement({
    required super.x,
    required super.y,
    required this.value,
    required this.fontSize,
    required this.angleDegrees,
    this.fontFamily,
    this.colorHex,
  });
  final String value;
  final double fontSize;
  final double angleDegrees;   // signed; positive = clockwise.
  final String? fontFamily;
  final String? colorHex;
}
```

**Rotation origin**: `pw.Transform.rotate(angle, alignment: pw.Alignment.center)` rotates around the child's geometric centre. We keep that default. The signature's bounding box is the un-rotated text's measured width × height; the rotated content extends slightly beyond it (≈0.4 mm vertical excursion at 12 pt × 2°). Authors who need to push the rotated text further right MUST account for the extra excursion in `x` — we do not auto-grow the bbox. We wrap the rotated `pw.Text` in a fixed-width `pw.Container` sized for the un-rotated text so the rotation has a deterministic centre.

**Bounding-box consequence**: documented in the dartdoc — the un-rotated `(x, y, fontSize × charCount)` rect is what we place; rotated glyphs may visually extend a few tenths of a millimetre past it. For the 2° signature this is negligible. For larger angles, the author is responsible for layout.

---

### Decision D2: `DotsTextBlockElement` signature — wrap-to-width, soft warn on overflow

| Option | Pro | Con |
|---|---|---|
| A. New element with `width`, optional `maxLines`/`maxChars` (**chosen**) | Renderer can `pw.SizedBox(width:)` + `pw.Text` to get word-wrap. Author specifies the constraint once. | Two text element subtypes to maintain. |
| B. Reuse `DotsTextElement` with an optional `width` | One less subtype. | `width: null` semantics differ from `width: non-null`; sealed switch must branch internally. Less explicit. |

Field set:

```dart
class DotsTextBlockElement extends DotsElement {
  const DotsTextBlockElement({
    required super.x,
    required super.y,
    required this.value,
    required this.fontSize,
    required this.width,            // in PDF points (caller converts mm→pt)
    this.fontFamily,
    this.colorHex,
    this.textAlign = DotsTextAlign.left,
    this.lineHeight = 1.2,           // 9pt body × 1.2 → 10.8pt leading
    this.maxChars,                   // warn if value.length > maxChars
    this.maxLines,                   // warn if newline-counted lines > maxLines
  });
  // ...
}

enum DotsTextAlign { left, center, right }
```

**Why a new enum, not `pw.TextAlign`**: the public API must not leak `package:pdf` types. The renderer maps `DotsTextAlign` → `pw.TextAlign` internally.

**Wrap behavior**: at render time the element becomes `pw.SizedBox(width:, child: pw.Text(value, style: TextStyle(fontSize, font, height: lineHeight), textAlign: …))`. The `pdf` package's `pw.Text` already word-wraps to the `SizedBox` width.

**Warn semantics**: when `maxChars != null && value.length > maxChars` OR `maxLines != null && value.split('\n').length > maxLines`, the renderer (which has access to a `DotsLogger`) calls `log.warn(...)` with the page number and offending counts. Render proceeds regardless. Word-break suppression and widow-control are explicitly out of scope (deferred — they need a custom line-breaker).

---

## Follow-ups (NOT slice 2)

1. **Inter Semibold role** — add a dedicated static-weight TTF to `DotsFontBundle`, a new `DotsFontRole.interSemibold`, and update header/footer to use it.
2. **Widow & word-break enforcement** for `DotsTextBlockElement` — needs custom line-breaker.
3. **Soft-wrap line count** for the warn threshold — needs hooked-in layout measurement.
4. **Instructions spread** (5+5 photo grid + QR card per album-type voice) — explicitly deferred per proposal Out-of-Scope.
5. **boda p.3 / p.4 / individuales p.6** — coordinate confidence MEDIUM/LOW, defer to slices 3-5.
