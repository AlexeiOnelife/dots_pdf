# Archive report: pliego-first-category

**Date:** 2026-05-29
**Change:** pliego-first-category
**Series position:** Task 2 of 7 (final-render-refinement)
**Result:** shipped — 660 tests GREEN / 0 RED, `flutter analyze` clean

---

## What shipped

Single-PR delivery (no chained split this time per user direction): branch
`pliego-first-category` off the Task 1 tip, with 6 work-unit commits.

### Architectural shift

- **JSON contract is pliego-only.** The deprecated `pages` JSON key is now
  rejected at parse time with a `DotsConfigException` at `$.pages` pointing
  the caller at `pliegos`. The deprecated `albumType` JSON key is rejected
  at `$.albumType` pointing at `category`.
- **`DotsAlbumType.generalEventos`** added as the sixth enum value, with
  `contextLabelToken: '{Protagonistas}'`. Exhaustive arms added in
  `DotsAlbumSpreadPage.closing.titleFontSize` and
  `.photoArc.defaultLeftCaption`; `photoArc` type guard extended to throw
  for `generalEventos` (it has its own opening QR spread).
- **`DotsTemplate.albumType` → `DotsTemplate.category`.** Field is now
  non-nullable with default `DotsAlbumType.generalEventos`. JSON callers
  that omit `category` receive the same default.
- **`DotsTemplate.pages` field removed entirely.** `_emptyPages` constant
  and the XOR assert are gone; `effectivePages` simplifies to a pure pliego
  flatten; `contentHash` drops the `Object.hashAll(pages)` term.
- **`DotsUnimplementedElement`** added as a new sealed `DotsElement` arm,
  with the 5 switch-site updates the design predicted (`dots_renderer.dart`
  × 3 — two `preloadAssetBytes` paths + `_buildElement`;
  `album_spread_page.dart` `_buildElement`;
  `isolate_synthesis.dart` `_buildElement`). Stub factories construct
  cleanly and throw `UnimplementedError('Task <N>: <factory>')` at render
  time.

### New content classes (6)

All `@immutable` with `const` ctors, hand-written `==`/`hashCode`, full
dartdoc:

- `AlbumPhotoOnlyCoverContent` (Task 4 — individuales/otros cover)
- `AlbumBeforeYouStartContent` (Task 4 — "Busca/Más allá" spread)
- `AlbumWelcomeJourneyContent` (Task 5 — "Bienvenido/a" spread)
- `AlbumQrSpreadContent` + `AlbumQrSpreadPlacement` enum (Task 5 —
  opening + closing QR spread, placement-discriminated)
- `AlbumEventosClosingContent` (Task 7 — generalEventos closing)
- `AlbumBodaCoverContent` (Task 6 — deferred per album-type series memo)

### New factory stubs (7) on `DotsAlbumSpreadPage`

- `.photoOnlyCover(...)` — Task 4 body
- `.beforeYouStart(...)` — Task 4 body
- `.welcomeJourney(...)` — Task 5 body
- `.openingQrSpread(...)` — Task 5 body
- `.closingQrSpread(...)` — Task 5 body
- `.bodaCover(...)` — Task 6 body (deferred)
- `.eventosClosing(...)` — Task 7 body

Each stub builds a real `DotsAlbumSpreadPage` with chrome wired
(`pageNumber`, `centerLabel`, `wordmark`) and a single
`DotsUnimplementedElement` carrying the responsible task id.

### Parser changes (`DotsTemplateParser`)

- Deletes the `pages` JSON branch (lines 147–165 of the previous file).
- Deletes the `pages`/`pliegos` XOR check.
- Rejects the deprecated `albumType` JSON key with a migration-helpful
  `DotsConfigException`.
- Rejects the deprecated `pages` JSON key with a migration-helpful
  `DotsConfigException`.
- Parses `category` with default `DotsAlbumType.generalEventos`.
- Requires `pliegos` at the JSON root.

### Public exports (`lib/dots_pdf.dart`)

Added: `AlbumBeforeYouStartContent`, `AlbumBodaCoverContent`,
`AlbumEventosClosingContent`, `AlbumPhotoOnlyCoverContent`,
`AlbumQrSpreadContent` (+ `AlbumQrSpreadPlacement`),
`AlbumWelcomeJourneyContent`.

### Fixture migration

80+ test sites and `example/example.dart` migrated from
`pages: [DotsXPage(...)]` to `pliegos: [DotsLayoutPliego(...)]`. JSON
fixtures rewritten via a Python migrator that wraps each page in
`{"pliegoNumber":..., "type":"layout", "left":..., "right":...}`. Where
the migration added a blank right page for single-page fixtures,
`.effectivePages.single` / `hasLength(1)` assertions were rewritten to
`.effectivePages.first` / `hasLength(2)`.

---

## Commit graph (local)

```
final-render-refinement (tracker)
└── page-template-chrome-pr1
    └── page-template-chrome-pr2  (Task 1)
        └── pliego-first-category ← THIS CHANGE (Task 2)
```

Six commits on `pliego-first-category` ahead of the Task 1 tip:

| SHA | Title |
|---|---|
| `78ced1e` | chore(pliego-first-category): SDD planning artifacts |
| `47c3abe` | feat(api): add DotsAlbumType.generalEventos and exhaustive arm coverage |
| `b55f799` | refactor(config): rename DotsTemplate.albumType → category |
| `4184d92` | feat(config): make category non-nullable + remove pages field (T2.1) |
| `97f1f40` | feat(config): DotsUnimplementedElement + 6 content classes + 7 factory stubs + T3.1 parser |
| `6b9db8e` | test+example(pliego-first-category): migrate 80+ pages: fixtures to pliegos |

---

## Test delta

- Pre-change baseline: 657 tests GREEN (post-Task 1).
- Post-change: **660 tests GREEN / 0 RED**.
- Net change: +3 tests. (The migration added an `AlbumType.generalEventos`
  test trio while many pliego-rejection tests were rewritten in place.)

---

## Deferred work (Tasks 4–7 deliver these)

The architecture is in place; per-category factory bodies remain stubs
that throw `UnimplementedError` at render time:

- **Task 4** — Pareja + Hijos visual fidelity. Fills `photoOnlyCover`
  (individuales/otros wiring) and `beforeYouStart` factory bodies.
- **Task 5** — Individual + Otros visual fidelity. Fills `welcomeJourney`,
  `openingQrSpread`, `closingQrSpread` bodies.
- **Task 6** — Boda visual fidelity. Fills `bodaCover` body (coordinate
  extraction was previously deferred — see project-album-type-series
  memo).
- **Task 7** — General Eventos default. Fills `eventosClosing` body.

After Task 2 ships, no category renders end-to-end on its own — every
category requires at least one new factory body. Tests assert
construction succeeds and render throws cleanly.

---

## Risks and trust-but-verify notes

- **Breaking JSON contract**: `pages` removal + `albumType` rename are
  hard breaks. Mitigated by precise migration-pointing
  `DotsConfigException`s.
- **Stub render explosion**: any production caller of the parser today
  receives a `DotsTemplate` with mandatory pliegos auto-injected — those
  pliegos contain `DotsUnimplementedElement` and crash on render. This is
  intentional and documented in the spec.
- **`pliegoNumber` auto-renumber**: the parser overwrites caller-supplied
  `pliegoNumber` values during pliego flattening. Documented in the spec
  R5 risk note for downstream test authors.

---

## Verification

- `flutter analyze`: clean (0 warnings, 0 errors).
- `flutter test`: 660 GREEN / 0 RED.
- All 39 task items in `tasks.md` checked off.
- Spec requirements R1–R8 covered by implementation + tests; the 4 chrome
  bugs from Task 1 remain shipped.
