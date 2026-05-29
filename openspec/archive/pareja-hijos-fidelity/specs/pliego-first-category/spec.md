# Delta for pliego-first-category

## MODIFIED Requirements

### Requirement: R7 — Stub factory signatures and content classes

`DotsAlbumSpreadPage.beforeYouStart(...)` and
`DotsAlbumSpreadPage.closingQrSpread(...)` MUST NO LONGER throw
`UnimplementedError` for the `parejas` and `hijos` types. For those two types
both factories MUST render the canonical layout defined in the
`category-render-fidelity-parejas-hijos` spec. Other supported types
(`individuales`, `otros`, `generalEventos`) on `beforeYouStart` MUST fall through
to the `parejas` copy branch with a `// TODO(task-5-7): per-category copy`
comment; the `boda` guard MUST throw `ArgumentError`. For `closingQrSpread`,
the factory is category-agnostic and MUST render for all types (no type guard).
All other factories from Task 2 (`photoOnlyCover`, `welcomeJourney`,
`openingQrSpread`, `bodaCover`, `eventosClosing`) retain their stub-throw
behaviour unchanged.

(Previously: all seven new named constructors threw `UnimplementedError` at
render time regardless of type.)

#### Scenario: stub factory throws UnimplementedError at call time (unchanged — non-parejas-hijos stubs)

- GIVEN a call to `DotsAlbumSpreadPage.photoOnlyCover(content: ...)`,
  `welcomeJourney`, `openingQrSpread`, `bodaCover`, or `eventosClosing`
- WHEN the returned page is asked to render
- THEN `UnimplementedError` is thrown with the task-number message

#### Scenario: beforeYouStart(parejas) renders without UnimplementedError

- GIVEN `DotsAlbumSpreadPage.beforeYouStart(DotsAlbumType.parejas, content: validContent)`
- WHEN the spread is rendered (or elements are accessed)
- THEN no `UnimplementedError` is thrown and the spread contains renderable elements

#### Scenario: beforeYouStart(hijos) renders without UnimplementedError

- GIVEN `DotsAlbumSpreadPage.beforeYouStart(DotsAlbumType.hijos, content: validContent)`
- WHEN the spread is rendered
- THEN no `UnimplementedError` is thrown

#### Scenario: closingQrSpread renders without UnimplementedError for any category

- GIVEN `DotsAlbumSpreadPage.closingQrSpread(content: validContent)`
  where content carries either a `parejas` or `hijos` placement context
- WHEN the spread is rendered
- THEN no `UnimplementedError` is thrown

#### Scenario: stub factory compiles and is callable (unchanged)

- GIVEN source code that calls any of the seven named constructors
  with the correct argument types
- WHEN the project is compiled
- THEN no compile-time error occurs

#### Scenario: content class equality works (unchanged)

- GIVEN two `AlbumPhotoOnlyCoverContent` instances with identical fields
- WHEN `==` is evaluated
- THEN the result is `true` and `hashCode` values match

#### Scenario: stub factories are exported (extended)

- GIVEN `lib/dots_pdf.dart`
- WHEN inspected for exports
- THEN `AlbumBeforeYouStartContent` (with `photoPaths`) and `AlbumQrSpreadContent`
  (with `bottomTextOverride`) are accessible to consumers, along with all
  existing Task 2 exports

---

## ADDED Requirements

### Requirement: R-delta-A — Caller contract for `AlbumBeforeYouStartContent.photoPaths`

`AlbumBeforeYouStartContent` MUST require `photoPaths` (a `List<String>` of
length 10) at construction. Callers who previously constructed this type
without `photoPaths` MUST add the field; `dart analyze` surfaces every
affected site. The invariant is enforced at both compile time (required named
parameter) and at factory entry (length assertion).

(See full spec in `category-render-fidelity-parejas-hijos R7`.)

#### Scenario: existing callers without photoPaths fail to compile

- GIVEN source that constructs `AlbumBeforeYouStartContent` without `photoPaths`
- WHEN `dart analyze` or `flutter analyze` is run
- THEN a compile-time error is reported for each affected site

---

### Requirement: R-delta-B — Caller contract for `AlbumQrSpreadContent.bottomTextOverride`

`AlbumQrSpreadContent` MUST expose an optional `bottomTextOverride: String?`
named parameter (default `null`). No existing call site is broken (additive).

(See full spec in `category-render-fidelity-parejas-hijos R8`.)

#### Scenario: existing AlbumQrSpreadContent callers still compile

- GIVEN all existing call sites that construct `AlbumQrSpreadContent` without
  `bottomTextOverride`
- WHEN compiled
- THEN no compile-time errors are introduced by the new optional parameter

---

## Out of Scope (unchanged from Task 2)

The following stub bodies remain unimplemented in Task 4 and MUST NOT be
filled by this change:

| Deferred factory | Owning task |
|---|---|
| `DotsAlbumSpreadPage.photoOnlyCover` render geometry | Task 5 |
| `DotsAlbumSpreadPage.welcomeJourney` render geometry | Task 5 |
| `DotsAlbumSpreadPage.openingQrSpread` render geometry | Task 5 |
| `DotsAlbumSpreadPage.bodaCover` render geometry | Task 6 |
| `DotsAlbumSpreadPage.eventosClosing` render geometry | Task 7 |
| `beforeYouStart` per-category copy for individuales / otros / generalEventos | Tasks 5–7 |
