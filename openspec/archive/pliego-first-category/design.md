# Design: pliego-first-category

## Technical Approach

Approach A from the explore — **parser-time mandatory-pliego injection**. The
parser becomes the single source of truth for "what a category template
contains end-to-end": it reads the user body pliegos, builds the per-category
mandatory initial and final pliegos from `categoryInputs`, concatenates
`[...initial, ...userBody, ...final]`, renumbers contiguously from
`pliegoNumber: 1`, and constructs `DotsTemplate`. The model stays flat (one
`pliegos` list), the sealed `DotsPliego` hierarchy is unchanged, and the
renderer is unchanged. The JSON contract becomes pliego-only — `pages` is
hard-removed; the legacy `albumType` key is hard-removed and replaced by
`category`. Stub factories return real `DotsAlbumSpreadPage` instances whose
single element is a new `DotsUnimplementedElement` variant; the renderer's
element switch throws `UnimplementedError` ONLY when that variant is reached —
so parsing always succeeds, the throw happens at render time as the brief and
spec R7 require.

## Architecture Decisions

### Decision: Injection function lives on `DotsTemplateParser`, NOT a free helper

| Option | Pro | Con | Decision |
|---|---|---|---|
| Private method `_injectCategoryMandatoryPliegos` on `DotsTemplateParser` | One owner; nested validation walks the same `categoryInputs` JSON; no new public surface; consistent with existing `_parsePliego`/`_parsePage` shape | Not reusable by typed-only callers | **Chosen** |
| Free function in `lib/src/config/category_injection.dart` | Reusable by typed-only callers | Requires a typed `CategoryInputs` model in public API (large new surface); duplicates JSON-pointer validation logic; no caller asks for it today | Rejected |

Rationale: the **only** consumer of category injection in Task 2 is the
parser. There is no typed-construction caller that needs it (programmatic
callers compose pliegos directly today via `buildSimplePagesFor` /
`buildPhotoArcPageFor` etc.). Introducing a public `CategoryInputs` value
object now would inflate the surface for zero use. If a future task needs
typed injection, the private method extracts cleanly to a free function —
nothing depends on its current location.

### Decision: Body-pliego `pliegoNumber` is silently overwritten, not rejected

| Option | Pro | Con | Decision |
|---|---|---|---|
| Silently overwrite any author `pliegoNumber` on body pliegos | Mechanical, parser code stays simple, JSON authors can ignore the field | "Surprise" if author writes `pliegoNumber: 1` expecting page 1 | **Chosen** (with diagnostic) |
| Reject with `DotsConfigException` if body `pliegoNumber` ≠ expected position | Loud failure | Forces author to compute injection-aware positions BEFORE running the parser — they don't yet know the category's initial count without reading library docs; bad UX |  Rejected |

Compromise (matches spec R5 scenario "parser warns when body pliegoNumber is
below category minimum"): the parser **overwrites silently** AND emits a
`DotsConfigException` ONLY when a body pliego declares a `pliegoNumber` ≤ the
category's last-initial-pliego number (3 for most, 4 for generalEventos). That
catches the only realistic author confusion ("I set it to 1 and expected page
1") without forcing arithmetic on every body pliego.

The `pliegoNumber` field stays REQUIRED on body pliego JSON objects for shape
validity (consistent with the existing parser at `dots_template_parser.dart:193`),
but its value is replaced by the injection position. Documented in the field's
dartdoc on the new injection function.

### Decision: Stub factories return constructible `DotsAlbumSpreadPage`s whose render throws via a new element variant

| Option | Pro | Con | Decision |
|---|---|---|---|
| New sealed element variant `DotsUnimplementedElement(taskTag, factoryName)`; stub factories return `DotsAlbumSpreadPage(elements: [DotsUnimplementedElement(...)])`; renderer's element switch arm throws | Construction succeeds → parser succeeds → render throws at the exact moment the element is drawn, with task pointer | Adds one new arm to every `switch (element)` in the codebase (~5 sites) | **Chosen** |
| Factory body throws `UnimplementedError` at call time | Trivially simple | Parser calls the factory during injection → parser explodes → spec R7 "parser succeeds, render throws" violated | Rejected |
| Factory body returns a closure-deferred lazy page object | No new element variant | Requires DotsAlbumSpreadPage to model laziness; cross-cuts a lot | Rejected |
| Subclass `DotsUnimplementedSpreadPage extends DotsAlbumSpreadPage`; renderer instanceof-check | No element variant | Adds a runtime instance-of in the renderer; breaks the `DotsPage` sealed-switch exhaustiveness gain we already have | Rejected |

Adding the element variant is the cleanest compile-checked path: every
`switch (element)` in the codebase gets a missing-arm error from `dart
analyze --fatal-warnings` until we add the new arm, which is exactly what we
want for a deliberate render-time-deferred stub.

### Decision: `_emptyPages` sentinel is fully removed (not just unused)

Removing the `DotsTemplate.pages` field means the `_emptyPages` static const
list and the `identical(pages, _emptyPages)` XOR assert have no remaining
purpose. Both are deleted in the same commit. The `_emptyPliegos` sentinel
**also** loses its purpose (no XOR partner) but is **kept** as the default
value for `DotsTemplate.pliegos` so the `const` constructor compiles when
callers omit pliegos (e.g. minimal test fixtures). It is internally unused
beyond that.

### Decision: `category` is non-nullable on `DotsTemplate`; default = `generalEventos`

Spec R4 requires non-nullable with default `DotsAlbumType.generalEventos`. This
is a real behavior change: today `albumType` is nullable and defaults to
`null`. After this change, every `DotsTemplate` has a concrete category and
the parser injects mandatory pliegos accordingly. The same default applies to
the constructor's named parameter so programmatic construction stays terse.

### Decision: `categoryInputs` is parsed into a private typed record per-category and not exposed publicly

Each category gets a private struct (`_CategoryInputs.parejas`, `_CategoryInputs.boda`,
etc.) representing the validated nested inputs. These structs feed the
injection helpers directly. No public API surface for them — they exist only
inside `DotsTemplateParser`. Future typed-construction callers (if any
materialize) can promote them to public later.

### Decision: Mandatory pliego packing — full-spread factories pair with `_blankAlbumSpread`

Existing factories on `DotsAlbumSpreadPage`:

- Single-page output (one rendered page): `cover`, `dedication`, `closing`.
- Full-spread visual output (one rendered page but `leftPageNumber` and
  `rightPageNumber` both set; renders 406mm-wide content): `photoArc`,
  `polaroidCollage`, `bodaCluster`, `bodaHalo`.

A `DotsLayoutPliego` carries two `DotsPage`s. To fit the spec's mandatory
sequence — e.g. parejas pliego 3 contains "dedication + photoArc" — the
helper pairs `dedication` (single page) with `photoArc` (full-spread visual)
inside one `DotsLayoutPliego`. The renderer treats each as its own pw.Page;
the per-page chrome and labels resolve correctly because Task 1's chrome
helper derives `isLeftPage` per-page from `pageNumber % 2`. For mandatory
slots that have only one item per pliego (e.g. parejas pliego 1 carries
`cover` and nothing else; boda pliego 2 is "blank"), the helper pairs the
factory output with `_blankAlbumSpread(pageNumber)` — a stable helper that
returns an empty `DotsAlbumSpreadPage` whose chrome will be rendered uniformly
by Task 1's wiring.

This packing is internal to the injection helper. Tasks 4–7 may revisit the
packing once render geometry lands; the spec contract (R5: three initial
pliegos for most categories, four for generalEventos, two final) is the
stable boundary.

## Data Flow

    JSON                                ── DotsTemplateParser.parseMap
      ├─ documentId, pageSize
      ├─ category ──────────────────────► resolved to DotsAlbumType (default: generalEventos)
      ├─ categoryInputs ────────────────► _parseCategoryInputs(category) → _CategoryInputs.X
      │   (per-category validation, $.categoryInputs.X.Y pointers)
      └─ pliegos[] ─────────────────────► [body pliegos]
                                                 │
                                                 ▼
                              _injectCategoryMandatoryPliegos(
                                category, inputs, userBody)
                                                 │
                                                 ▼
                              [ initial(category, inputs)
                                ...userBody
                                final(category, inputs) ]
                                                 │
                                                 ▼
                              _renumberContiguously(concatenated)
                                                 │
                                                 ▼
                              DotsTemplate(documentId, pageSize,
                                category, defaultChrome, pliegos)

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/api/dots_album_type.dart` | Modify | Add enum value `generalEventos`; add `DotsAlbumType.generalEventos` arm to `contextLabelToken` switch (`'{Protagonistas}'`, grouped with `boda`/`hijos`). Update dartdoc table. |
| `lib/src/config/dots_template.dart` | Modify | Rename `albumType` → `category` (non-nullable, default `DotsAlbumType.generalEventos`); REMOVE `pages` field + `_emptyPages` const + XOR assert; simplify `effectivePages` (delete `if (pliegos.isEmpty) return pages` branch); update `contentHash` to swap `albumType` for `category` and drop `Object.hashAll(pages)`. Add `generalEventos` arms to `closing.titleFontSize` (`1299`) and `photoArc.defaultLeftCaption` (`1593`). Add 7 new factory stubs on `DotsAlbumSpreadPage` (see Interfaces). |
| `lib/src/config/dots_template_parser.dart` | Modify | DELETE the `pages` JSON branch (`147-165`) and the XOR check (`111-124`); replace `albumType` resolution (`91-109`) with `category` resolution that defaults to `generalEventos` and throws on legacy `albumType` key; add `_parseCategoryInputs` and per-category `_CategoryInputs.X` private records with `$.categoryInputs.X.Y` validation; add `_injectCategoryMandatoryPliegos`, `_renumberContiguously`, and `_blankAlbumSpread` helpers. |
| `lib/src/api/album_photo_only_cover_content.dart` | Create | `AlbumPhotoOnlyCoverContent` — immutable, `==`/`hashCode`, dartdoc. |
| `lib/src/api/album_before_you_start_content.dart` | Create | `AlbumBeforeYouStartContent` — immutable. |
| `lib/src/api/album_welcome_journey_content.dart` | Create | `AlbumWelcomeJourneyContent` — immutable. |
| `lib/src/api/album_qr_spread_content.dart` | Create | `AlbumQrSpreadContent` (reused for opening + closing via `placement` discriminator). |
| `lib/src/api/album_eventos_closing_content.dart` | Create | `AlbumEventosClosingContent` — immutable. |
| `lib/src/api/album_boda_cover_content.dart` | Create | `AlbumBodaCoverContent` — minimal placeholder (deferred per Task 6). |
| `lib/src/config/dots_element.dart` (or wherever sealed `DotsElement` lives) | Modify | Add sealed variant `DotsUnimplementedElement(String taskTag, String factoryName)`. Hand-written `==`/`hashCode`. |
| `lib/src/render/dots_renderer.dart`, `lib/src/render/album_spread_page.dart`, `lib/src/render/isolate_synthesis.dart` | Modify | Add the missing `case DotsUnimplementedElement()` arm in every `switch (element)` site (`dots_renderer.dart:39`, `:80`, `:443`, `album_spread_page.dart:224`, `isolate_synthesis.dart:289`). The render-time arm throws `UnimplementedError('${element.taskTag}: ${element.factoryName} body not yet implemented')`. The preload arms (`dots_renderer.dart:39/80`) are no-ops (nothing to preload). The isolate arm mirrors the render-time throw. |
| `lib/dots_pdf.dart` | Modify | Add exports for the six new content classes; the new `DotsAlbumType.generalEventos` is exported transitively via the existing `export 'src/api/dots_album_type.dart'`; the seven new factory stubs are reachable through the existing `export 'src/config/dots_template.dart'`. |
| `test/api/dots_album_type_test.dart` | Modify/extend | `generalEventos` present in `.values`; count = 6; `contextLabelToken` arm. |
| `test/config/dots_template_test.dart` | Modify | Drop `pages` fixtures; add `category` default; `contentHash` differs on `category` change; `effectivePages` always flattens pliegos. |
| `test/config/dots_template_parser_test.dart` | Modify + add | Drop `pages` JSON tests; add `category` parsing + default; legacy `albumType` key throws with migration hint; `categoryInputs` validation matrix (one missing-case per required field per category); injection count + order + renumbering per category; body `pliegoNumber` below minimum diagnostic. |
| `test/config/album_spread_stubs_test.dart` | Create | One test per stub: construction succeeds, render-time throw carries Task tag + factory name. RED-by-design in PR 1 (uses `fail('PR 2: stub render-time throw not wired')`), GREEN in PR 2. |
| `test/api/album_content_classes_test.dart` | Create | `==`/`hashCode` for the six new content classes. |

## Interfaces / Contracts

```dart
// lib/src/api/dots_album_type.dart — extended.
enum DotsAlbumType {
  boda, parejas, hijos, individuales, otros,
  /// General-events album. Four-pliego front matter (opening QR spread,
  /// photo-only cover, welcome spread, before-you-start spread) and a
  /// two-pliego back matter (closing QR + eventos closing variant). Body
  /// pliegos start at pliego 5.
  generalEventos,
}

extension DotsAlbumTypeContext on DotsAlbumType {
  String get contextLabelToken => switch (this) {
        DotsAlbumType.boda
            || DotsAlbumType.hijos
            || DotsAlbumType.generalEventos => '{Protagonistas}',
        DotsAlbumType.parejas => '{tiempojuntos}',
        DotsAlbumType.individuales || DotsAlbumType.otros => '{Año}',
      };
}

// lib/src/config/dots_template.dart — rename + removal.
@immutable
class DotsTemplate {
  const DotsTemplate({
    required this.documentId,
    required this.pageSize,
    this.category = DotsAlbumType.generalEventos,
    this.defaultChrome,
    this.pliegos = _emptyPliegos,
  });

  static const List<DotsPliego> _emptyPliegos = <DotsPliego>[];

  final String documentId;
  final DotsPageSize pageSize;
  final DotsAlbumType category;          // renamed from albumType, non-nullable
  final DotsPageChrome? defaultChrome;
  final List<DotsPliego> pliegos;

  List<DotsPage> get effectivePages {
    final result = <DotsPage>[];
    var nextPageNumber = 1;
    for (final pliego in pliegos) {
      final pliegoPages = pliego.toPages(nextPageNumber);
      result.addAll(pliegoPages);
      nextPageNumber += pliegoPages.length;
    }
    return List<DotsPage>.unmodifiable(result);
  }

  int get contentHash => Object.hash(
        documentId, pageSize, category, defaultChrome,
        Object.hashAll(pliegos),
      );
}

// lib/src/config/dots_template.dart — exhaustive switches updated.
final double titleFontSize = switch (type) {
  DotsAlbumType.boda => 12.0,
  DotsAlbumType.parejas
      || DotsAlbumType.hijos
      || DotsAlbumType.individuales
      || DotsAlbumType.otros
      || DotsAlbumType.generalEventos => 20.0,                  // closing:1299
};

final String defaultLeftCaption = switch (type) {
  DotsAlbumType.parejas => 'Vuestro álbum en digital',
  DotsAlbumType.hijos
      || DotsAlbumType.individuales
      || DotsAlbumType.otros
      || DotsAlbumType.generalEventos => 'Tu album en digital', // photoArc:1593
  DotsAlbumType.boda => '',
};
// cover.defaultEyebrow (1468) keeps its `_ =>` wildcard — generalEventos
// already falls into the rejection arm (cover stub takes its own path).

// lib/src/config/dots_element.dart — new sealed variant.
@immutable
final class DotsUnimplementedElement extends DotsElement {
  const DotsUnimplementedElement({
    required this.taskTag,    // e.g. 'Task 4'
    required this.factoryName, // e.g. 'photoOnlyCover'
  });
  final String taskTag;
  final String factoryName;
  @override bool operator ==(Object other) => other is DotsUnimplementedElement
      && other.taskTag == taskTag && other.factoryName == factoryName;
  @override int get hashCode => Object.hash(taskTag, factoryName);
}

// lib/src/config/dots_template.dart — seven stub factories. Pattern below
// is identical for all seven; only the parameter name + tag changes.
factory DotsAlbumSpreadPage.photoOnlyCover({
  required int pageNumber,
  required AlbumPhotoOnlyCoverContent content,
}) => DotsAlbumSpreadPage(
  pageNumber: pageNumber,
  header: const DotsSpreadHeader(leftPageNumber: null, centerLabel: null, rightPageNumber: null),
  footer: const DotsSpreadFooter(wordmark: ''),
  elements: const <DotsElement>[
    DotsUnimplementedElement(taskTag: 'Task 4', factoryName: 'photoOnlyCover'),
  ],
);

factory DotsAlbumSpreadPage.beforeYouStart({
  required int pageNumber,
  required String contextLabelValue,
  required AlbumBeforeYouStartContent content,
}) => /* taskTag: 'Task 4', factoryName: 'beforeYouStart' */;

factory DotsAlbumSpreadPage.welcomeJourney({
  required int pageNumber,
  required String contextLabelValue,
  required AlbumWelcomeJourneyContent content,
}) => /* taskTag: 'Task 5', factoryName: 'welcomeJourney' */;

factory DotsAlbumSpreadPage.openingQrSpread({
  required int pageNumber,
  required String contextLabelValue,
  required AlbumQrSpreadContent content,  // placement: opening
}) => /* taskTag: 'Task 5', factoryName: 'openingQrSpread' */;

factory DotsAlbumSpreadPage.closingQrSpread({
  required int pageNumber,
  required String contextLabelValue,
  required AlbumQrSpreadContent content,  // placement: closing
}) => /* taskTag: 'Task 5', factoryName: 'closingQrSpread' */;

factory DotsAlbumSpreadPage.bodaCover({
  required int pageNumber,
  required AlbumBodaCoverContent content,
}) => /* taskTag: 'Task 6', factoryName: 'bodaCover (deferred per album-type series)' */;

factory DotsAlbumSpreadPage.eventosClosing({
  required int pageNumber,
  required String contextLabelValue,
  required AlbumEventosClosingContent content,
}) => /* taskTag: 'Task 7', factoryName: 'eventosClosing' */;
```

### Content classes (one per stub factory; identical shape)

```dart
// lib/src/api/album_photo_only_cover_content.dart
@immutable
class AlbumPhotoOnlyCoverContent {
  const AlbumPhotoOnlyCoverContent({
    required this.photoPath,
    required this.title,        // resolved {NombreDelAlbum} or {TítuloDelAlbum}
    required this.dateLine,     // resolved {DiadeMesdeAñodeFechaDeInicio}
  });
  final String photoPath;
  final String title;
  final String dateLine;
  @override bool operator ==(Object o) => o is AlbumPhotoOnlyCoverContent
      && o.photoPath == photoPath && o.title == title && o.dateLine == dateLine;
  @override int get hashCode => Object.hash(photoPath, title, dateLine);
}

// lib/src/api/album_before_you_start_content.dart
@immutable
class AlbumBeforeYouStartContent {
  const AlbumBeforeYouStartContent({this.titleOverride, this.bodyOverride});
  /// Optional override of the fixed "Busca un lugar tranquilo" title.
  final String? titleOverride;
  /// Optional override of the fixed "Más allá del papel" body text.
  final String? bodyOverride;
  @override bool operator ==(Object o) => o is AlbumBeforeYouStartContent
      && o.titleOverride == titleOverride && o.bodyOverride == bodyOverride;
  @override int get hashCode => Object.hash(titleOverride, bodyOverride);
}

// lib/src/api/album_welcome_journey_content.dart
@immutable
class AlbumWelcomeJourneyContent {
  const AlbumWelcomeJourneyContent({this.titleOverride, this.bodyOverride});
  final String? titleOverride;
  final String? bodyOverride;
  // == / hashCode as above.
}

// lib/src/api/album_qr_spread_content.dart
enum AlbumQrSpreadPlacement { opening, closing }
@immutable
class AlbumQrSpreadContent {
  const AlbumQrSpreadContent({
    required this.qrPayload,
    required this.placement,
    this.captionOverride,
  });
  final String qrPayload;
  final AlbumQrSpreadPlacement placement;
  final String? captionOverride;
  @override bool operator ==(Object o) => o is AlbumQrSpreadContent
      && o.qrPayload == qrPayload
      && o.placement == placement
      && o.captionOverride == captionOverride;
  @override int get hashCode => Object.hash(qrPayload, placement, captionOverride);
}

// lib/src/api/album_eventos_closing_content.dart
@immutable
class AlbumEventosClosingContent {
  const AlbumEventosClosingContent({
    this.photoPath,
    required this.title,        // resolved {TítuloDelAlbum}
    required this.signature1,   // resolved {Firma 1}
    required this.signature2,   // resolved {Firma 2}
  });
  final String? photoPath;
  final String title;
  final String signature1;
  final String signature2;
  // == / hashCode over all four fields.
}

// lib/src/api/album_boda_cover_content.dart — minimal Task-6 placeholder
@immutable
class AlbumBodaCoverContent {
  /// Stub content class for the deferred boda cover (Task 6). Fields will
  /// be defined when the boda cover layout is unfrozen; today the class
  /// exists only so the factory signature is stable and downstream code
  /// can declare typed inputs.
  const AlbumBodaCoverContent({this.title, this.dateLine});
  final String? title;
  final String? dateLine;
  @override bool operator ==(Object o) => o is AlbumBodaCoverContent
      && o.title == title && o.dateLine == dateLine;
  @override int get hashCode => Object.hash(title, dateLine);
}
```

### Injection helper — signature + per-category bodies

```dart
// Private to DotsTemplateParser.
List<DotsPliego> _injectCategoryMandatoryPliegos({
  required DotsAlbumType category,
  required _CategoryInputs inputs,
  required List<DotsPliego> userBodyPliegos,
}) {
  final initial = _initialPliegosFor(category, inputs);
  final finalPliegos = _finalPliegosFor(category, inputs);
  final combined = <DotsPliego>[
    ...initial,
    ...userBodyPliegos,
    ...finalPliegos,
  ];
  return _renumberContiguously(combined);
}

List<DotsPliego> _renumberContiguously(List<DotsPliego> pliegos) {
  final out = <DotsPliego>[];
  for (var i = 0; i < pliegos.length; i++) {
    out.add(_pliegoWithNumber(pliegos[i], i + 1));
  }
  return List<DotsPliego>.unmodifiable(out);
}

/// Returns a 2-page pliego paired with a blank facing page. Used when a
/// single-page mandatory factory occupies one half of a pliego.
DotsLayoutPliego _pairWithBlank(DotsAlbumSpreadPage page, {
  required bool pageIsLeft,
  required String? facingContextLabel,
}) { /* … */ }

/// Returns an empty-elements DotsAlbumSpreadPage that still carries chrome.
DotsAlbumSpreadPage _blankAlbumSpread({
  required int pageNumber,
  required String? contextLabel,
}) { /* … */ }
```

#### Per-category mandatory pliego inventory

The injection helper returns the pliego sequences below. **`pageNumber`
inside each `DotsAlbumSpreadPage`** is filled in by `_renumberContiguously`
after concatenation (the `DotsLayoutPliego.toPages(firstPageNumber)` flatten
path assigns final page numbers from the pliego's position). Until then the
factories are constructed with placeholder `pageNumber: 0`. The "first body
pliego" column is for documentation only; the renumberer is what guarantees
it.

##### parejas (initial: 3 pliegos / final: 2 pliegos / body starts at pliego 4)

Initial:

1. `DotsLayoutPliego( cover(parejas) , beforeYouStart )` — pliego 1.
2. `DotsLayoutPliego( _blankAlbumSpread , dedication(parejas) )` — pliego 2.
3. `DotsLayoutPliego( _blankAlbumSpread , photoArc(parejas) )` — pliego 3.

Rationale for the blank facing pages: dedication and photoArc each return one
`DotsAlbumSpreadPage`. The blank fills the opposing half of the same pliego.
Tasks 4–7 may re-pair (e.g. dedication + photoArc on a single pliego) once
the visual flow is locked in; the spec contract is `3 initial pliegos`, the
internal packing is parser-private.

Final:

1. `DotsLayoutPliego( closingQrSpread , _blankAlbumSpread )` — last - 1.
2. `DotsLayoutPliego( _blankAlbumSpread , closing(parejas) )` — last.

##### hijos (same structure as parejas)

Same as parejas with `type: DotsAlbumType.hijos` substituted in every
factory call. `contextLabelValue` is supplied by the helper from the
caller's variables map (the parser already routes variables through the body
pliego parsing — same map is reused).

##### individuales (initial: 3 / final: 2 / body at 4)

Initial:

1. `DotsLayoutPliego( photoOnlyCover [STUB] , beforeYouStart [STUB] )`.
2. `DotsLayoutPliego( _blankAlbumSpread , dedication(individuales) )`.
3. `DotsLayoutPliego( _blankAlbumSpread , polaroidCollage(individuales) )`.

Final: same shape as parejas with `closing(individuales)` substituted.

##### otros (same as individuales)

Same as individuales with `type: otros`. `polaroidCollage` is called with
`applyOtrosGradient: true` (per the proposal's wording on the otros gradient
flag — preserves the existing convention at
`album_collage_content.dart:35`).

##### boda (initial: 3 / final: 2 / body at 4)

Initial:

1. `DotsLayoutPliego( bodaCover [STUB, DEFERRED] , _blankAlbumSpread )`.
2. `DotsLayoutPliego( _blankAlbumSpread , _blankAlbumSpread )` — the "pliego
   2 empty/blank" called out in spec R5.
3. `DotsLayoutPliego( bodaCluster(boda) , bodaHalo(boda) )` — both are
   full-spread visuals so they pair naturally into one pliego.

Boda has NO dedication (consistent with existing `_hasDedication` at
`build_simple_pages.dart:62`). Boda parses successfully; render explodes the
moment `DotsUnimplementedElement(taskTag: 'Task 6', factoryName: 'bodaCover (deferred per album-type series)')`
is reached.

Final:

1. `DotsLayoutPliego( closingQrSpread , _blankAlbumSpread )`.
2. `DotsLayoutPliego( _blankAlbumSpread , closing(boda) )`.

##### generalEventos (initial: 4 / final: 2 / body at 5)

Initial:

1. `DotsLayoutPliego( openingQrSpread [STUB] , photoOnlyCover [STUB] )`.
2. `DotsLayoutPliego( _blankAlbumSpread , welcomeJourney [STUB] )`.
3. `DotsLayoutPliego( beforeYouStart [STUB] , _blankAlbumSpread )`.
4. `DotsLayoutPliego( _blankAlbumSpread , _blankAlbumSpread )` — opens the
   first body pliego on a clean spread; matches pdf12 page count (8 pages =
   4 pliegos).

Final:

1. `DotsLayoutPliego( closingQrSpread [STUB] , _blankAlbumSpread )`.
2. `DotsLayoutPliego( _blankAlbumSpread , eventosClosing [STUB] )`.

### Parser delta — full new shape

```dart
// dots_template_parser.dart  parseMap(…) — replacement body.

final documentId = _requireString(json, 'documentId', r'$');
final pageSize = _parsePageSize(_requireMap(json, 'pageSize', r'$'), r'$.pageSize');

// (A) reject legacy keys with migration hints
if (json.containsKey('albumType')) {
  throw const DotsConfigException(
    'field "albumType" was removed — use "category" instead',
    pointer: r'$.albumType',
  );
}
if (json.containsKey('pages')) {
  throw const DotsConfigException(
    'field "pages" was removed — use "pliegos" instead',
    pointer: r'$.pages',
  );
}

// (B) resolve category with default = generalEventos
final categoryRaw = json['category'];
DotsAlbumType category = DotsAlbumType.generalEventos;
if (categoryRaw != null) {
  if (categoryRaw is! String) {
    throw const DotsConfigException(
      'field "category" must be a string',
      pointer: r'$.category',
    );
  }
  try {
    category = DotsAlbumType.values.byName(categoryRaw);
  } on ArgumentError {
    throw DotsConfigException(
      'unknown category "$categoryRaw" '
      '(expected one of: parejas, hijos, individuales, otros, boda, generalEventos)',
      pointer: r'$.category',
    );
  }
}

// (C) parse + validate categoryInputs (per-category nested validation)
final categoryInputs = _parseCategoryInputs(
  _requireMap(json, 'categoryInputs', r'$'),
  r'$.categoryInputs',
  category,
);

// (D) parse user body pliegos (pliego-only — no pages branch)
final pliegosRaw = _requireList(json, 'pliegos', r'$');
final bodyPliegos = <DotsPliego>[];
final firstBodyNumber = category == DotsAlbumType.generalEventos ? 5 : 4;
for (var i = 0; i < pliegosRaw.length; i++) {
  final entry = pliegosRaw[i];
  if (entry is! Map<String, dynamic>) {
    throw DotsConfigException(
      'pliego entry must be an object',
      pointer: r'$.pliegos[' '$i' ']',
    );
  }
  final p = _parsePliego(entry, r'$.pliegos[' '$i' ']', variables);
  if (p.pliegoNumber < firstBodyNumber) {
    throw DotsConfigException(
      'body pliego declares pliegoNumber ${p.pliegoNumber}, but '
      'category "${category.name}" reserves pliegoNumber 1..'
      '${firstBodyNumber - 1} for mandatory front matter. Body pliegos do '
      'not control their absolute number — the parser renumbers all pliegos '
      'after injecting front and back matter.',
      pointer: r'$.pliegos[' '$i' '].pliegoNumber',
    );
  }
  bodyPliegos.add(p);
}

// (E) inject + renumber
final pliegos = _injectCategoryMandatoryPliegos(
  category: category,
  inputs: categoryInputs,
  userBodyPliegos: bodyPliegos,
);

return DotsTemplate(
  documentId: documentId,
  pageSize: pageSize,
  category: category,
  pliegos: pliegos,
);
```

`_parseCategoryInputs` switches on `category` and parses one of six
`_CategoryInputs.parejas` / `.hijos` / `.individuales` / `.otros` / `.boda` /
`.generalEventos` private records. Each branch reads only the sub-objects
its category needs (`cover`, `dedication`, `photoArc`, etc.) and throws
`DotsConfigException` with the precise `$.categoryInputs.X.Y` pointer for
any missing/wrong-typed field — matching the spec R6 matrix.

## Testing Strategy

Strict-TDD applies (per project memory: PR 1 ships RED placeholders that fail
with `fail('PR 2: ...')` messages; PR 2 turns them GREEN). Tests live in the
existing per-area files where possible and one new file for the stub matrix.

| Layer | What | Approach | RED in PR 1 / GREEN in PR 2 |
|---|---|---|---|
| Unit | `DotsAlbumType` has 6 values, `generalEventos` present, `contextLabelToken` returns `'{Protagonistas}'` | direct enum/value checks | GREEN in PR 1 |
| Unit | `closing.titleFontSize` returns `20.0` for `generalEventos`; `photoArc.defaultLeftCaption` returns `'Tu album en digital'` for `generalEventos` | construct factories, inspect resolved text element | GREEN in PR 1 |
| Unit | `dart analyze --fatal-warnings` is clean after adding `generalEventos` | `flutter analyze` in CI | GREEN in PR 1 |
| Unit | `DotsTemplate.category` defaults to `generalEventos`; `pages` field no longer exists (compile-time); `contentHash` differs on `category` change; `effectivePages` always flattens pliegos | direct construction + reflection-free assertions | GREEN in PR 1 |
| Parser | `pliegos`-only contract: `pages` key throws `$.pages` with hint; `albumType` key throws `$.albumType` with hint; missing both throws `$` | one test per row of R1 table | GREEN in PR 1 |
| Parser | `category` resolution: omitted → `generalEventos`; valid value → enum; unknown → throws `$.category` listing all six | one test per scenario | GREEN in PR 1 |
| Parser | `categoryInputs` validation matrix (R6): one test per (category × required field) missing-case (~25 cases); one wrong-type case for an array field | parameterized test list | RED in PR 1 (validation paths fail with `fail('PR 2: categoryInputs validation not wired')`); GREEN in PR 2 |
| Parser | Injection counts: parejas 2 body → 7 total; generalEventos 1 body → 7 total; renumbered 1..N contiguously; body `pliegoNumber: 99` overwritten; body `pliegoNumber: 1` for parejas emits diagnostic with hint | one test per scenario | RED in PR 1; GREEN in PR 2 |
| Stub | One test per of the 7 stub factories: construction succeeds, `page.elements.single is DotsUnimplementedElement`, render-time throws `UnimplementedError` containing the task tag and factory name | construct + render with a stub renderer | RED in PR 1 (`fail('PR 2: stub render-time throw not wired')`); GREEN in PR 2 |
| Stub | Boda category-end-to-end: full boda `categoryInputs` parses without error; render fails at first pliego with `'Task 6'` + `'boda cover'` in the message | parse + render first pliego | RED in PR 1; GREEN in PR 2 |
| Content classes | `==` / `hashCode` for `AlbumPhotoOnlyCoverContent`, `AlbumBeforeYouStartContent`, `AlbumWelcomeJourneyContent`, `AlbumQrSpreadContent` (placement-sensitive), `AlbumEventosClosingContent`, `AlbumBodaCoverContent` | direct equality test pairs | GREEN in PR 1 |
| Export | `lib/dots_pdf.dart` re-exports all new content classes (no compile errors when consumers import the public library) | smoke import test | GREEN in PR 1 |

Strict-TDD note: the brief calls out that PR 1 ships RED placeholders for
factory-stub render-throws (intentional `fail('PR 2: ...')`), PR 2 implements
and turns GREEN. The split lines up with the `_injectCategoryMandatoryPliegos`
+ `DotsUnimplementedElement` arrival schedule: PR 1 lands the enum, model
rename, parser scaffolding (category parsing + legacy-key rejection), all
content classes, all factory-stub SIGNATURES (with bodies that still
`throw UnimplementedError('PR 2: …')` at call time so the suite stays RED but
compiles); PR 2 adds the `DotsUnimplementedElement` variant, the render-arm
throws, the renderer/album-spread/isolate switch arms, the full
`categoryInputs` validation matrix, and the injection helper — flipping every
PR-1 RED to GREEN.

## Migration / Rollout

Hard breaking change (pre-1.0). The parser emits precise migration-pointing
exceptions at `$.albumType` and `$.pages`. Internal test fixtures are
migrated to `pliegos: [DotsLayoutPliego(…)]` in PR 1 as part of the RED
phase. Cache invalidation is automatic via `contentHash` (swap `albumType`
for `category`). External consumers see CHANGELOG entries enumerating each
breaking axis. Rollback = `git revert` the slice commits; the enum-arm
additions revert mechanically and the model field rename reverts cleanly via
`git revert`.

## Open Questions

- [ ] None blocking. Two were called out by the brief and are resolved
      above: injection function lives privately on `DotsTemplateParser`
      (Decision 1); body `pliegoNumber` is silently overwritten with a
      below-minimum diagnostic (Decision 2).
- [ ] `boda` mandatory pliego 2 is intentionally a double-blank pliego per
      spec R5; if Task 6 unfreezes the boda cover layout and the spec
      contract changes, the helper's `boda` branch is the only site that
      needs updating.
