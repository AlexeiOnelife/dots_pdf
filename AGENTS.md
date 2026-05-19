# AGENTS.md — dots_pdf

Cliff notes for AI agents working in this repo. The user-facing
contract lives in [README.md](README.md); this file captures what an
agent needs to know *before touching code* — invariants, conventions,
and gotchas that are easy to miss.

If something here disagrees with the code, **the code wins** — open
the file, verify, and update this doc in the same change.

---

## What this project is

`dots_pdf` is a **Flutter package** (pure-Dart logic, no widgets) that
turns a typed or JSON template into a print-ready PDF byte stream.
It powers the **Dotbook** photo-album workflow: hardcover wrap, multi-
page interior layouts (L1–L8, `lhito`), milestone QR pages, spread-
spanning images, and per-supplier print rules.

Built on `package:pdf` (`pw` widgets, `PdfPageFormat`). Output is
PDF 1.7 — **not PDF/X-4 yet**; see [README §Known limitations](README.md#known-limitations-and-follow-ups).

---

## Quick path (first 60 seconds)

1. **Read [pubspec.yaml](pubspec.yaml)** — Dart `>=3.9.0 <4.0.0`,
   Flutter `>=3.35.0`. Deps: `pdf`, `barcode`, `file`, `path`,
   `image`, `printing`. Dev deps: `flutter_test`, `mocktail`.
2. **Read [lib/dots_pdf.dart](lib/dots_pdf.dart)** — the entire
   public surface. Anything not exported here is private to the
   library and must not be referenced from `example/` or app code.
3. **Run the suite**: `flutter test` (140+ tests, fast, no network,
   `MemoryFileSystem`). For one area: `flutter test test/render/`.
4. **Skim [docs/templates/SPECS.md](docs/templates/SPECS.md)** — the
   product spec. Layout math, cover geometry, supplier rules, and
   resolved clarifications all live there.

---

## Repo map (where things live)

| Path | What's there |
|---|---|
| [lib/dots_pdf.dart](lib/dots_pdf.dart) | Public exports — single source of truth for the API surface. |
| [lib/src/api/](lib/src/api/) | `DotsGenerator`, `DotsOutputMode`, `DotsAlbumType`. The entry point. |
| [lib/src/config/](lib/src/config/) | `DotsTemplate`, `DotsPliego`, `DotsTemplateParser`, `DotsConfigException`. Typed model + JSON parser. |
| [lib/src/cover/](lib/src/cover/) | `DotsCoverTemplate`, `DotsCoverGeometry`, `DotsCoverRenderer`, `DotsCoverDesign`, `DotsSupplier`, `DotsPaperSubstrate`. Cover is **separate** from interior. |
| [lib/src/render/](lib/src/render/) | `DotsRenderer`, whole/pair renderers, font bundle, asset loader, crop marks, layout solver. |
| [lib/src/render/layout/](lib/src/render/layout/) | `DotsLayoutSolver`, `DotsLayoutCode`, `DotsSlotKind`, `DotsLayoutRequirements`, `DotsPageGeometry`. |
| [lib/src/events/](lib/src/events/) | Sealed `PdfGenerationEvent` (Started, Progress, CacheHit, PreviewProgress, PhotoSlotSkipped, Completed, Failed). |
| [lib/src/cache/](lib/src/cache/) | `DotsCache`, `DotsCacheStatus`. Content-hash invalidation. |
| [lib/src/io/](lib/src/io/) | `DotsPathManager`. All disk path resolution. |
| [lib/src/preview/](lib/src/preview/) | `DotsPdfRasterizer`, `DotsPagePreviewGenerator`. PNG previews via `printing`. |
| [lib/src/logging/](lib/src/logging/) | `DotsLogger`, `DotsSilentLogger`. Default is silent. |
| [test/](test/) | Mirrors `lib/` layout. ~50 files. Uses `MemoryFileSystem` + `mocktail`. |
| [assets/](assets/) | Bundled fonts + FOGRA39 CGATS reference data. |
| [docs/templates/](docs/templates/) | `SPECS.md` (cross-cutting), `SPECS_interior.md`, `SPECS_cover.md`, `SPECS_album_types.md`. |
| [example/example.dart](example/example.dart) | End-to-end usage demo. Mirror real-world wiring here. |

---

## Architecture rules (non-negotiable)

| Rule | Why |
|---|---|
| Thin public API. Anything new ships via `lib/dots_pdf.dart` or stays private. | Consumers depend on the export list. Anything not exported is implementation. |
| `@immutable` + `const` on every model. `==` and `hashCode` by hand. | Content hashing drives the cache. Mutation breaks invalidation silently. |
| Sealed hierarchies (`DotsElement`, `DotsPage`, `DotsPliego`, `PdfGenerationEvent`). | Renderer switches on concrete type — extending these from outside breaks the pipeline. |
| Async-first; long pipelines emit `Stream<PdfGenerationEvent>`. | UI drives progress without polling. |
| Inject `FileSystem` and `DotsUrlFetcher` — never use `dart:io File` directly in `lib/`. | Tests run against `MemoryFileSystem` with no network. |
| One page (or pair) live at a time. Dispose image bytes inside `buildPage`. | Library is sized for low-end mobile devices. See [README §Memory budget](README.md#memory-budget). |
| Cover is **NOT** part of `DotsTemplate`. It has its own `DotsCoverTemplate` + `DotsCoverGeometry`. | Geometry is a pure function of page count + substrate. Mixing them confuses the cache. |
| Parser raises `DotsConfigException` with a JSON pointer (`$.field`) on every validation error. | Callers locate failures without parsing error strings. |
| `assets/FOGRA99.txt` is **CGATS reference data**, not a binary ICC. PDF/X-4 + FOGRA39 conformance is **deferred work**. | Don't claim conformance the library doesn't have. |
| Fonts are **TrueType only**. `.otf` (CFF) throws `DotsConfigException`. | `pdf` package's `TtfParser` silently maps every glyph to `.notdef` for CFF outlines. |

---

## Domain concepts (these will trip you up)

| Term | Meaning |
|---|---|
| **Pliego** | A 2-page spread. Preferred input shape for new code (`pliegos:` on `DotsTemplate`). `pages:` and `pliegos:` are **mutually exclusive**. |
| **Layout code** | `l1`, `l1a`–`l1e`, `l2a`–`l2c`, `l3a`, `l4a`, `l4b`, `l6a`, `l7`, `l8`, `lhito`. The layout solver positions photos + captions; the renderer just draws. |
| **Slot kind** | `captionTitle`, `captionDate`, `captionBody`, `qrCard`. What the solver emits — what consumers fill via `DotsLayoutPage.captions`. |
| **Spread image** | One image spans two pages. Prefer `DotsSpreadImagePliego`; the page-level fallback is `DotsSpreadImageElement` with `half: left/right` mirrored on the two pages. |
| **Supplier** | `europa` (crop marks, min 20 pages) vs `latam` (no crop marks, min 30 pages). `page count % 4 == 0` and `<= 250` always. |
| **Substrate** | `uncoated150` / `satin170` / `gloss200`. Each has its own page-count → spine-width tier table. See [docs/templates/SPECS_cover.md](docs/templates/SPECS_cover.md). |
| **Album type** | `boda`, `parejas`, `hijos`, `individuales`, `otros`. Selects front/back-matter spreads only; body rendering is type-agnostic. |
| **Cache key** | `(documentId, mode, contentHash)`. `contentHash` is `Object.hash` over the parsed template — any field change invalidates. Force a re-run with `forceRegenerate: true`. |
| **`hito`** | Spanish for "milestone". `lhito` is the milestone-text page (title + body required; date + QR optional). |

---

## Output modes

Three independent pipelines. Each has its own cache key and its own
on-disk artifact path.

| Method | Output | Path |
|---|---|---|
| `generator.generateWhole(template:)` | one PDF | `<docs>/dots_pdf/whole/<id>.pdf` |
| `generator.generatePairs(template:)` | one PDF per pair | `<docs>/dots_pdf/pairs/<id>/pair_NNN.pdf` |
| `generator.generateCover(template:)` | the hardcover wrap | `<docs>/dots_pdf/cover/<id>.pdf` |
| previews (any mode, opt-in) | per-page PNG | `<docs>/dots_pdf/preview/<id>/page_NNN.png` |

Drain the `Stream<PdfGenerationEvent>` to drive UI; you don't have to.

---

## Style and tooling

- **Analyzer:** [analysis_options.yaml](analysis_options.yaml) enables
  `strict-casts`, `strict-inference`, `strict-raw-types`, plus
  `public_member_api_docs` as a lint. **Every exported symbol needs a
  doc comment.** Treat missing docs as a build failure, not a nit.
- **Lints:** `prefer_const_*`, `prefer_single_quotes`,
  `require_trailing_commas`, `unawaited_futures`, `avoid_print`,
  `avoid_dynamic_calls`, `always_declare_return_types`. Don't fight
  the formatter.
- **Imports:** relative inside `lib/src/`. Consumers always use the
  package import (`package:dots_pdf/dots_pdf.dart`).
- **Errors:** validation throws `DotsConfigException` with `pointer`.
  Runtime failures land in `PdfGenerationFailed` on the stream — do
  not throw past the stream boundary.
- **No `print`.** Route logs through `DotsLogger`.

---

## Testing

```bash
flutter test                    # full suite
flutter test test/render/       # one area
flutter test test/render/layout_page_render_test.dart   # one file
```

Conventions:

- **Filesystem:** `MemoryFileSystem` from `package:file`. The real
  disk only shows up when you intentionally inject `LocalFileSystem`.
- **Network:** never. Inject a fake `DotsUrlFetcher`. The default
  fetcher (`dart:io HttpClient`, 10s timeout, 2xx only) is for
  production, not tests.
- **Fonts:** font tests load real `.ttf` files from `assets/fonts/`
  via `dart:io File` directly — they are the exception to the
  injected-FS rule.
- **Mocking:** `mocktail`. No `mockito`.
- **Rasterizer:** `Printing.raster` only runs on a real device. In
  tests, inject a fake `DotsPdfRasterizer`.
- **Preview tests** live in `test/preview/` and assert on `previewPaths`
  exposed by `PdfGenerationCompleted` / `PdfGenerationCacheHit`.

When you add a public symbol, add a test in the mirrored `test/`
path. When you add a config field, add a `DotsTemplateParser` test
proving the missing-field message points at the right `$.pointer`.

---

## Committing and pushing

- **Conventional Commits.** `feat(scope): …`, `fix(scope): …`,
  `refactor(scope): …`, `test(scope): …`, `docs(scope): …`,
  `chore(scope): …`.
- **Never** add `Co-Authored-By:` lines or any AI attribution to
  commits. This is a hard project rule.
- Don't push or open PRs without explicit user request. Local commits
  are fine when asked.
- Keep PRs under ~400 lines of diff when possible. Larger work splits
  into chained PRs.

---

## Common pitfalls

| Trap | What actually happens | Fix |
|---|---|---|
| Importing from `lib/src/...` in `example/` or in user code. | Works today, breaks at the next refactor. | Only import `package:dots_pdf/dots_pdf.dart`. Add the export if you need it public. |
| Mutating a `DotsTemplate` field after construction. | Cache hash silently stale. | Templates are `const`/immutable. Build a new one with the change. |
| Setting both `pages` and `pliegos` on a `DotsTemplate`. | Parser throws `DotsConfigException`. | Pick one — pliegos is preferred for new code. |
| Putting cover fields in `DotsTemplate`. | They don't exist there. | Use `DotsCoverTemplate` + `DotsCoverGeometry` and call `generateCover(...)`. |
| Loading a `.otf` font. | `DotsConfigException` at construction, or — if bypassed — every glyph collapses to `.notdef` (all letters render at x=0). | Convert with `otf2ttf`. See [README §Font format requirement](README.md#font-format-requirement--truetype-only). |
| Passing `pageCount` not divisible by 4 to `DotsCoverGeometry`. | `DotsConfigException` at `$.pageCount`. | Round to a multiple of 4 inside the supplier's tier range. |
| Re-running `generateWhole` and expecting fresh output. | Cache hit; stream emits a single `PdfGenerationCacheHit`. | Pass `forceRegenerate: true`. |
| Calling `pw.Document.save()` incrementally. | The `pdf` package returns the whole `Uint8List` at once. | This is the one buffer we can't eliminate. Don't chase it. |
| Re-querying CodeGraph immediately after editing a file in the same turn. | Index lags ~500ms behind writes. | Defer to the next turn. |

---

## Where to dig deeper

- **Full user contract:** [README.md](README.md).
- **Cross-cutting spec:** [docs/templates/SPECS.md](docs/templates/SPECS.md).
- **Interior layouts (L1–L8 + lhito):** [docs/templates/SPECS_interior.md](docs/templates/SPECS_interior.md).
- **Cover geometry math + tier table:** [docs/templates/SPECS_cover.md](docs/templates/SPECS_cover.md).
- **Per-album-type front/back matter:** [docs/templates/SPECS_album_types.md](docs/templates/SPECS_album_types.md).
- **End-to-end usage:** [example/example.dart](example/example.dart).
- **CodeGraph index:** `.codegraph/` — prefer `codegraph_*` MCP tools
  over grep for structural questions ("where is X defined", "what
  calls Y", "what would break if I change Z").
