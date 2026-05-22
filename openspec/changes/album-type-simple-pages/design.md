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

### Decision D3: `AlbumSimpleContent` shape — both pages optional

```dart
@immutable
class AlbumSimpleContent {
  const AlbumSimpleContent({this.dedication, this.closing});

  /// Dedication-page payload. When `null`, no dedication page is emitted.
  final DedicationContent? dedication;

  /// Closing-page payload. When `null`, no closing page is emitted.
  final ClosingContent? closing;
}

@immutable
class DedicationContent {
  const DedicationContent({
    required this.title,
    required this.body,
    required this.signature,
  });
  final String title;
  final String body;
  final String signature;
}

@immutable
class ClosingContent {
  const ClosingContent({
    required this.photoPath,
    required this.title,
    required this.subtitle,
  });
  final String photoPath;
  final String title;
  final String subtitle;
}
```

**Why both pages optional**:
- `boda` legitimately has no dedication (proposal Q4); making it optional avoids a sentinel.
- A caller iterating on copy may want "dedication only, no closing yet" during authoring.
- The page-number derivation in `buildSimplePagesFor` (D4) handles the gap correctly because page numbers are passed in by the caller.

**Page numbers are NOT in `AlbumSimpleContent`** — they come from the caller via `buildSimplePagesFor`'s `firstPageNumber` argument so the builder can be composed with body pages of arbitrary length.

---

### Decision D4: Named-constructor signatures

```dart
class DotsAlbumSpreadPage extends DotsPage {
  // …existing default ctor unchanged…

  /// Builds a dedication page for [type] at [pageNumber].
  ///
  /// The header is derived from [type]:
  ///   - leftPageNumber: '$pageNumber'
  ///   - centerLabel: pre-resolved [contextLabelValue] string (caller's
  ///     substitution result — we do not substitute here)
  ///   - rightPageNumber: null  (dedication is a single page, no facing)
  /// The footer is fixed: "Dots. Memories".
  factory DotsAlbumSpreadPage.dedication({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required String title,
    required String body,
    required String signature,
  });

  /// Builds a closing single page for [type] at [pageNumber].
  /// Closing TITLE font size depends on [type]:
  ///   - boda                                         → 12 pt
  ///   - parejas | hijos | individuales | otros       → 20 pt
  factory DotsAlbumSpreadPage.closing({
    required DotsAlbumType type,
    required int pageNumber,
    required String contextLabelValue,
    required String photoPath,
    required String title,
    required String subtitle,
  });
}
```

**Rationale**:
- `contextLabelValue` is **pre-resolved** (a literal string the caller produces from `type.contextLabelToken` + their variable map). The constructor takes a value, not a token, because slice 1 chose parse-time substitution as the seam. Building a `DotsAlbumSpreadPage` programmatically should not re-introduce token logic.
- Each constructor's `switch (type)` selecting font sizes is exhaustive — `dart analyze` enforces every album type is handled.
- The constructors assemble `elements` by emitting the correct sequence of `DotsTextElement` / `DotsTextBlockElement` / `DotsRotatedTextElement` / `DotsImageElement` instances at the spec coordinates. The exact coordinates live inside the constructor body (one source of truth).

**Header positions are page-internal coordinates** (top-left page #, top-center label, top-right page # is null on these single pages). The renderer reads `header.leftPageNumber/centerLabel/rightPageNumber` and places each at its canonical position; the constructor only fills `header` and the `elements` body.

---

### Decision D5: Shared render helper — new file `lib/src/render/album_spread_page.dart`

| Option | Pro | Con |
|---|---|---|
| A. New file with top-level `buildAlbumSpreadPage(...)` (**chosen**) | Pure function, no inheritance, no statefulness. Both call-sites depend on it via a single import. Easy to unit-test in isolation. | One more file. |
| B. Static method on `DotsRenderer` | Same call ergonomics on the main isolate. | Isolate path would import `DotsRenderer` just for one static — awkward, and `DotsRenderer` pulls `FileSystem` etc. into the isolate. |
| C. Mixin on both renderers | Code reuse via mixin keyword. | Mixins add the function as instance methods on both, but the two renderers don't share a base class — would need a new shared mixin file anyway. |

Signature:

```dart
// lib/src/render/album_spread_page.dart
Future<pw.Page> buildAlbumSpreadPage({
  required PdfPageFormat format,
  required DotsAlbumSpreadPage page,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required bool drawCropMarks,
});
```

**Why callbacks for font + bytes**: the main-isolate renderer resolves fonts from `_fontCache` and bytes from the `DotsAssetLoader`; the isolate renderer resolves fonts from its own `_fontCache` and bytes from a `Map<String, Uint8List>`. Both call sites adapt their state to these callback signatures with one-liner closures. The helper itself stays state-free and testable without either renderer.

**Logger + onPhotoFailure** are also passed in — the main isolate has a real `DotsLogger` and a callback; the isolate renderer wires a no-op logger and accumulates failures into a list. The helper does not need to know the difference.

---

### Decision D6: Font roles — Inter Semibold fallback

The spec calls for these roles:

| Spec role                          | `DotsFontRole`                                | Exists in bundle? |
|------------------------------------|------------------------------------------------|-------------------|
| P22 Mackinac Medium 23/27.6        | `p22MackinacMedium`                            | yes               |
| Inter Book 9/10.8                  | `inter` (variable font, weight controlled)     | yes               |
| Biro Script Plus Regular 12/14.4   | `biroScriptPlus`                               | yes               |
| P22 Mackinac Medium 20/24 (or 12)  | `p22MackinacMedium`                            | yes               |
| P22 Mackinac Book 9/10.8           | `p22MackinacBook`                              | yes               |
| Inter Semibold 7/8.4 (header/foot) | `inter` (variable font, weight not exposed)    | partial           |

**Inter Semibold gap**: the `DotsFontBundle` exposes ONE `inter` role tied to the variable Inter TTF. The `pdf` package does NOT expose a way to dial the variable axis from `pw.TextStyle`, so all Inter text renders at the default (regular) weight regardless of the spec asking for "Semibold". Slice 2 uses `DotsFontRole.inter` for the header/footer trio and accepts visual drift from the spec at this size. Adding a dedicated `interSemibold` role with a separate static-weight TTF is a **follow-up** outside this slice (font bundle work, asset additions, parser updates).

**Color**: spec calls for `colorHex: "#1e1e1e"` (near-black) for ALL these text roles. The constructors hard-code that for header/footer and dedication body/signature/closing subtitle; title elements default to `null` (uses `PdfColor` default — black).

---

### Decision D7: Public API surface — five new exports

```dart
// lib/dots_pdf.dart additions:
export 'src/api/album_simple_content.dart' show
    AlbumSimpleContent, DedicationContent, ClosingContent;
export 'src/api/build_simple_pages.dart' show buildSimplePagesFor;
// DotsRotatedTextElement, DotsTextBlockElement, DotsTextAlign,
// and the two new named constructors ride along on
// 'src/config/dots_template.dart' which is already exported.
```

`DotsAlbumSpreadPage` is already exported (slice 1). Its new `.dedication(...)` / `.closing(...)` factories are reachable transitively. The two new `DotsElement` subtypes live in the same `dots_template.dart` file and ride along too. `DotsTextAlign` lives in `dots_template.dart` for the same reason.

---

## Data Flow

```
Caller                                               Library
  │
  │  AlbumSimpleContent(dedication: ..., closing: ...)
  │  + DotsAlbumType + firstPageNumber + contextLabelValue
  ▼
buildSimplePagesFor(type, content, firstPageNumber:, contextLabelValue:)
  │
  ├──[dedication != null]──► DotsAlbumSpreadPage.dedication(...)
  │                          │ assembles `elements`:
  │                          │   DotsTextElement(TITLE, P22 23pt)
  │                          │   DotsTextBlockElement(BODY, Inter 9pt, width=102mm)
  │                          │   DotsRotatedTextElement(SIGNATURE, Biro 12pt, 2°)
  │                          │ assembles header (leftPageNumber, centerLabel)
  │                          │ assembles footer (wordmark="Dots. Memories")
  ▼
[dedication, closing] : List<DotsPage>
  │
  ▼  Caller hands the list to DotsRenderer or synthesizePdfInIsolate
  ▼
DotsRenderer.buildPage(template, page)                _IsolatePageRenderer.buildPage(page)
  │  switch (page) → DotsAlbumSpreadPage              │  switch (page) → DotsAlbumSpreadPage
  │  → buildAlbumSpreadPage(format, page,             │  → buildAlbumSpreadPage(format, page,
  │       fontResolver: fontFor,                      │       fontResolver: _fontFor,
  │       bytesResolver: (p) async => loader.load(p), │       bytesResolver: (p) async => _bytesFor(p),
  │       logger: log,                                │       logger: _NoOpLogger(),
  │       onPhotoFailure: onPhotoSlotFailure)         │       onPhotoFailure: (p, e) => photoFailures.add(...))
  │
  ▼
buildAlbumSpreadPage(...)
  │  draws header trio at canonical positions
  │  draws footer wordmark at bottom-center
  │  draws crop marks (if drawCropMarks)
  │  iterates page.elements:
  │    DotsTextElement       → positioned Text
  │    DotsImageElement      → positioned Image
  │    DotsRotatedTextElement → positioned Transform.rotate(Text)
  │    DotsTextBlockElement  → positioned SizedBox(Text textAlign, lineHeight)
  │                            + warn-on-overflow side effect
  │
  ▼
pw.Page
```

---

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/config/dots_template.dart` | Modify | (a) Add `DotsRotatedTextElement` and `DotsTextBlockElement` as new sealed siblings of `DotsElement`, with `==` / `hashCode`. (b) Add `enum DotsTextAlign { left, center, right }`. (c) Add `DotsAlbumSpreadPage.dedication(...)` and `DotsAlbumSpreadPage.closing(...)` factory constructors that assemble the correct `header`, `footer`, and `elements` per spec. |
| `lib/src/api/album_simple_content.dart` | New | `AlbumSimpleContent`, `DedicationContent`, `ClosingContent` immutable value objects with `==` / `hashCode` mirroring existing style. |
| `lib/src/api/build_simple_pages.dart` | New | Top-level `List<DotsPage> buildSimplePagesFor(DotsAlbumType type, AlbumSimpleContent content, {required int firstPageNumber, required String contextLabelValue})`. Returns 0, 1, or 2 pages in dedication → closing order, skipping any whose payload is `null`. |
| `lib/src/render/album_spread_page.dart` | New | Pure `buildAlbumSpreadPage(...)` helper. Renders header trio (Inter 7pt at canonical mm coords), footer wordmark, and iterates `elements` over the now-4-arm `DotsElement` switch. |
| `lib/src/render/dots_renderer.dart` | Modify | (a) Replace `UnimplementedError` at `:274` with `return buildAlbumSpreadPage(...)` delegation. (b) Extend `_buildElement` switch with `case DotsRotatedTextElement():` and `case DotsTextBlockElement():`. (c) Extend the two `case DotsAlbumSpreadPage()` arms inside `preloadAssetBytes` to add no-op arms for the two new element subtypes (neither has an asset path). |
| `lib/src/render/isolate_synthesis.dart` | Modify | Same shape as `dots_renderer.dart`: replace `UnimplementedError` at `:206` with helper delegation; extend `_buildElement` switch with two new arms. |
| `lib/dots_pdf.dart` | Modify | Add exports for `album_simple_content.dart` and `build_simple_pages.dart`. |
| `test/render/album_spread_page_test.dart` | New | Widget-tree assertions: dedication emits 4 children (header L, header C, body title, body block, signature, footer) at the right positions; closing emits photo + title + subtitle + header/footer. Per-album-type closing-title font-size assertion. |
| `test/api/build_simple_pages_test.dart` | New | `buildSimplePagesFor(parejas, full content) → 2 pages`; `(boda, full content) → 1 page (closing only — boda has no dedication slot in spec)`; `(parejas, dedication-only) → 1 page (dedication)`. |
| `test/config/dots_template_test.dart` | Modify | New cases for `DotsRotatedTextElement` / `DotsTextBlockElement` equality + `DotsAlbumSpreadPage.dedication` / `.closing` smoke tests. |

---

## Interfaces / Contracts

```dart
// lib/src/config/dots_template.dart additions:

class DotsRotatedTextElement extends DotsElement {
  const DotsRotatedTextElement({
    required super.x, required super.y,
    required this.value,
    required this.fontSize,
    required this.angleDegrees,
    this.fontFamily, this.colorHex,
  });
  final String value;
  final double fontSize;
  final double angleDegrees;
  final String? fontFamily;
  final String? colorHex;
  // == + hashCode
}

class DotsTextBlockElement extends DotsElement {
  const DotsTextBlockElement({
    required super.x, required super.y,
    required this.value,
    required this.fontSize,
    required this.width,
    this.fontFamily, this.colorHex,
    this.textAlign = DotsTextAlign.left,
    this.lineHeight = 1.2,
    this.maxChars, this.maxLines,
  });
  final String value;
  final double fontSize;
  final double width;             // PDF points
  final String? fontFamily;
  final String? colorHex;
  final DotsTextAlign textAlign;
  final double lineHeight;
  final int? maxChars;
  final int? maxLines;
  // == + hashCode
}

enum DotsTextAlign { left, center, right }

// lib/src/api/album_simple_content.dart:
@immutable class AlbumSimpleContent { /* dedication?, closing? */ }
@immutable class DedicationContent  { /* title, body, signature */ }
@immutable class ClosingContent     { /* photoPath, title, subtitle */ }

// lib/src/api/build_simple_pages.dart:
List<DotsPage> buildSimplePagesFor(
  DotsAlbumType type,
  AlbumSimpleContent content, {
  required int firstPageNumber,
  required String contextLabelValue,
});

// lib/src/render/album_spread_page.dart:
Future<pw.Page> buildAlbumSpreadPage({
  required PdfPageFormat format,
  required DotsAlbumSpreadPage page,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required bool drawCropMarks,
});
```

---

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit (model) | New element equality + hashCode; named-constructor output for both pages and all 5 album types | Construct `DotsAlbumSpreadPage.dedication(...)` / `.closing(...)`, inspect `elements`. |
| Unit (builder) | `buildSimplePagesFor` page count per album type; dedication-only / closing-only / both | Parameterised tests over `DotsAlbumType.values`. |
| Unit (renderer helper) | `buildAlbumSpreadPage` emits expected `pw.Widget` shape (count, types) | Use a fake font resolver and a `Map<String, Uint8List>` bytes resolver; assert on the `pw.Stack` children. |
| Unit (warn behavior) | Dedication body exceeding 1000 chars or 32 lines triggers `logger.warn` once | Spy logger; assert `warn` was called with the offending count. |
| Integration | Drift between main-isolate and worker-isolate paths | A single golden-shape test on the shared helper covers both. Add one regression test that asserts both `DotsRenderer.buildPage` and the isolate `buildPage` produce the same `pw.Page` children count for the same page input. |
| Existing | Slice 1 tests | MUST still pass without modification. |

---

## Edge Cases

- **Closing photo path invalid**: the existing `_buildPhotoSlot` swallows decode failures, logs via `log.error`, and calls `onPhotoSlotFailure`. The helper reuses the same pattern via the injected `onPhotoFailure` callback. The closing page renders title + subtitle + header/footer with the photo slot empty.
- **`contextLabelValue` empty string**: header centre is drawn as empty text → effectively invisible. No special-case; matches the existing `header.centerLabel` semantics (slice 1: nullable string, absent = not drawn). We pass `null` when the value is empty.
- **`signature` empty**: dedication still renders title + body without rotated text element. The constructor checks `if (signature.isEmpty)` and skips adding the rotated element.
- **Rotation around centre with very short signatures**: tested at 2°. Larger angles are not used in slice 2.
- **Both `dedication` and `closing` `null` in `AlbumSimpleContent`**: `buildSimplePagesFor` returns an empty list. Caller is responsible for handling that.

---

## Migration / Rollout

All additions are additive. Slice 1's foundation API is unchanged. The two `UnimplementedError` throws are replaced by working renderer paths; any caller that previously hit those throws will now succeed.

Rollback: revert the commits; restore `UnimplementedError` throws; drop new files. Slice 1 remains intact.

---

## Open Questions for tasks/apply

- [ ] **Exact mm→pt header coordinates**: the spec defines header positions in millimetres (top-left, top-centre, top-right) at specific margins. Capture those constants once inside `album_spread_page.dart` as `_kHeaderLeftXMm`, `_kHeaderCentreYMm`, etc. The tasks phase will read the spec doc and pin numeric values; design only commits to "place the four canonical positions". The Inter weight rendering at 7pt remains as-is until a dedicated Semibold role is added (D6 follow-up).
- [ ] **Footer wordmark Y position**: 8 mm above page bottom? The spec mentions "bottom-center wordmark" without a precise offset for these two pages. Tasks phase confirms the exact value; design defers the literal.
- [ ] **`pw.SizedBox` height for rotated-text container**: the un-rotated text height at 12 pt is ~12 pt + leading. The renderer wraps the rotated text in a `Container(width: textWidth, height: textHeight)` sized roughly to the un-rotated text; tasks phase decides whether to measure-via-`pw.LayoutGraph` (overkill) or hard-code a 14 pt height (good enough at 12 pt × 2°).
- [ ] **Line-count heuristic for `DotsTextBlockElement` warn**: `value.split('\n').length` only catches author-inserted hard breaks. Soft-wrap line count requires the layout engine; defer to a follow-up. Spec accepts approximation per proposal Q3.

---

## Follow-ups (NOT slice 2)

1. **Inter Semibold role** — add a dedicated static-weight TTF to `DotsFontBundle`, a new `DotsFontRole.interSemibold`, and update header/footer to use it.
2. **Widow & word-break enforcement** for `DotsTextBlockElement` — needs custom line-breaker.
3. **Soft-wrap line count** for the warn threshold — needs hooked-in layout measurement.
4. **Instructions spread** (5+5 photo grid + QR card per album-type voice) — explicitly deferred per proposal Out-of-Scope.
5. **boda p.3 / p.4 / individuales p.6** — coordinate confidence MEDIUM/LOW, defer to slices 3-5.
