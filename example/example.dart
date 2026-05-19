// Comprehensive usage example for the `dots_pdf` Flutter library.
//
// This file demonstrates the library's public API end-to-end. It does
// not run as a standalone script (the library depends on Flutter); copy
// the pieces you need into your Flutter app and adapt the
// `documentsDir` source from `path_provider`.
//
// What you'll find below, in order:
//   1. Building a typed `DotsTemplate` programmatically — explicit
//      elements, layout-driven pages, milestone (hito) with QR, spread
//      images split across a 2-page pair.
//   2. Generating the whole-document PDF and the 2-page-pair PDFs.
//   3. Generating the hardcover-wrap PDF that ships alongside the
//      interior block.
//   4. Plugging in URL-sourced images.
//   5. Subscribing to the progress stream.
//
// In real app code:
//   - replace `MemoryFileSystem()` with `LocalFileSystem()` from
//     `package:file/local.dart`;
//   - replace the hard-coded `'/docs'` directory with the result of
//     `path_provider.getApplicationDocumentsDirectory()`;
//   - keep the `DotsGenerator` instance and reuse it across documents.

import 'dart:io';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';

Future<void> main() async {
  // ----- 1. Choose the file system + a documents root -------------------
  //
  // `MemoryFileSystem` keeps everything in RAM (good for tests).
  // Production code uses `LocalFileSystem()` and the result of
  // `path_provider.getApplicationDocumentsDirectory()`.
  final FileSystem fs = MemoryFileSystem.test();
  final Directory documentsDir = fs.directory('/docs')..createSync();

  // ----- 2. Build a template programmatically ----------------------------
  //
  // The page-size is 209 × 260 mm including a 3 mm bleed on every edge
  // (Dotbook interior trim is 203 × 254 mm). Multiply mm by 2.834645 to
  // get PDF points.
  const double mm = 2.834645669;
  const DotsTemplate template = DotsTemplate(
    documentId: 'demo_2026',
    pageSize: DotsPageSize(width: 209 * mm, height: 260 * mm),
    pages: <DotsPage>[
      // Page 1 — explicit-element page with a text greeting and a
      // remote image. Note: when `assetPath` starts with http:// or
      // https://, the renderer downloads it into the per-document
      // tmp/ directory, reads the bytes, and lets the orchestration
      // layer wipe the file at the end of the run.
      DotsElementsPage(
        pageNumber: 1,
        elements: <DotsElement>[
          DotsTextElement(
            x: 72,
            y: 72,
            value: 'Hello, dots_pdf!',
            fontSize: 24,
          ),
          DotsImageElement(
            assetPath: 'https://example.com/photo.jpg',
            x: 72,
            y: 120,
            width: 200,
            height: 150,
            bleedRight: true,
          ),
        ],
      ),

      // Page 2 — layout-driven page using the L4.A grid (four 86×110 mm
      // photos in a 2×2 grid). The library positions the photo slots
      // by calling the layout solver; the caller only supplies the
      // photo asset paths in row-major order.
      DotsLayoutPage(
        pageNumber: 2,
        layoutCode: DotsLayoutCode.l4a,
        photoAssetPaths: <String>[
          'https://example.com/p1.jpg',
          'https://example.com/p2.jpg',
          '/local/p3.jpg', // local-path images still work
          '/local/p4.jpg',
        ],
      ),

      // Page 3 — milestone (hito) text page with a real QR code.
      //
      // The `qr` caption key is a URL string; the library renders an
      // actual QR matrix into the QR slot using the pdf package's
      // BarcodeWidget (medium error correction).
      DotsLayoutPage(
        pageNumber: 3,
        layoutCode: DotsLayoutCode.lhito,
        captions: <DotsSlotKind, String>{
          DotsSlotKind.captionTitle: 'A milestone worth remembering',
          DotsSlotKind.captionDate: 'May 17, 2026',
          DotsSlotKind.captionBody:
              'Body copy up to 800 chars per the spec.',
          DotsSlotKind.qrCard: 'https://onelife.example/album/123',
        },
      ),

      // Pages 4 + 5 — a 2-page pair carrying a single image that spans
      // the spread. Caller declares the SAME image twice with matching
      // `half: left | right`; the renderer clips and offsets so the
      // two halves stitch at the binding.
      DotsElementsPage(
        pageNumber: 4,
        elements: <DotsElement>[
          DotsSpreadImageElement(
            x: 0,
            y: 0,
            assetPath: 'https://example.com/panorama.jpg',
            spreadWidth: 1184,
            height: 689,
            half: DotsSpreadHalf.left,
            bleedTop: true,
            bleedBottom: true,
            bleedOuter: true,
          ),
        ],
      ),
      DotsElementsPage(
        pageNumber: 5,
        elements: <DotsElement>[
          DotsSpreadImageElement(
            x: 0,
            y: 0,
            assetPath: 'https://example.com/panorama.jpg',
            spreadWidth: 1184,
            height: 689,
            half: DotsSpreadHalf.right,
            bleedTop: true,
            bleedBottom: true,
            bleedOuter: true,
          ),
        ],
      ),
    ],
  );

  // ----- 3. Load the bundled fonts ---------------------------------------
  //
  // `DotsFontBundle.fromPackageAssets()` pulls every font (P22 Mackinac
  // medium / book / medium-italic, Inter, Inter Italic, Biro Script
  // Plus) out of the library's bundled assets via Flutter's
  // `rootBundle`. The renderer parses each font exactly once per
  // generator instance and reuses the parsed `pw.Font` across every
  // page. Pass `fontBundle: null` (the default) to fall back to the
  // pdf package's built-in Helvetica.
  //
  // NOTE: this call requires a Flutter app context (rootBundle).
  // For non-Flutter use (CLI scripts, tests), build the bundle
  // manually by reading the font bytes off disk.
  final DotsFontBundle fontBundle = await DotsFontBundle.fromPackageAssets();

  // ----- 4. Construct the generator --------------------------------------
  //
  // `drawCropMarks: true` adds L-shaped trim-corner ticks to every
  // interior page. Derive this from `DotsSupplier.drawsCropMarks`:
  // europa=true, latam=false.
  //
  // `urlFetcher` is optional. Production code defaults to a `dart:io
  // HttpClient` with a 10-second timeout and 2xx-only validation. Tests
  // and corporate environments can inject a fake (see below).
  final DotsGenerator generator = DotsGenerator(
    fileSystem: fs,
    documentsDir: documentsDir,
    drawCropMarks: DotsSupplier.europa.drawsCropMarks,
    urlFetcher: _fakeUrlFetcher, // remove in production code
    fontBundle: fontBundle,
  );

  // ----- 4. Generate the interior in whole-document mode -----------------
  await _drain(generator.generateWhole(template: template));
  stdout.writeln(
    'whole PDF → ${await generator.wholePathFor(template.documentId)}',
  );

  // ----- 5. Also generate the 2-page-pair PDFs ---------------------------
  //
  // Each pair is a separate PDF file (pair_001.pdf, pair_002.pdf, …)
  // under the pairs/<documentId>/ directory. Suppliers that accept
  // imposed pairs (one pliego per file) consume this output directly.
  await _drain(generator.generatePairs(template: template));
  stdout.writeln(
    'pairs dir → ${await generator.pairsDirPathFor(template.documentId)}',
  );

  // ----- 6. Generate the hardcover wrap PDF ------------------------------
  //
  // Cover geometry is a pure function of (page count, paper substrate,
  // supplier). The wrap dimensions, spine width, bleed, and hinch are
  // all derived from `DotsCoverGeometry`.
  final DotsCoverGeometry coverGeometry = DotsCoverGeometry(
    pageCount: template.pages.length.isEven ? template.pages.length : 4,
    paperSubstrate: DotsPaperSubstrate.uncoated150,
    supplier: DotsSupplier.europa,
  );
  final DotsCoverTemplate coverTemplate = DotsCoverTemplate(
    documentId: template.documentId,
    geometry: coverGeometry,
    design: DotsCoverDesign.square,
    frontArtworkPath: '/local/cover_front.jpg',
    spineTitle: 'Memories 2026',
  );
  await _drain(generator.generateCover(template: coverTemplate));
  stdout.writeln(
    'cover PDF → ${await generator.coverPathFor(coverTemplate.documentId)}',
  );

  // ----- 7. Cache + re-generation ----------------------------------------
  //
  // A second call to generateWhole with the same template emits a
  // single `PdfGenerationCacheHit` event and returns the cached path.
  // Pass `forceRegenerate: true` to delete prior artifacts and
  // re-render from scratch.
  //
  // Run this after editing the template — the contentHash changes
  // automatically and the cache is invalidated even without
  // forceRegenerate.
  await _drain(generator.generateWhole(template: template));
}

// A toy URL fetcher for the example. Production code should not pass
// `urlFetcher` at all — the default uses `dart:io HttpClient` with
// timeouts and HTTP-status validation. This stub returns the smallest
// valid 1×1 PNG for any URL so the example doesn't hit the network.
final List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

Future<List<int>> _fakeUrlFetcher(Uri url) async => _onePixelPng;

// Drains an event stream, logging the meaningful transitions. Real
// apps wire these into a progress UI.
Future<void> _drain(Stream<PdfGenerationEvent> events) async {
  await for (final event in events) {
    switch (event) {
      case PdfGenerationStarted(:final documentId, :final totalPages):
        stdout.writeln('[$documentId] started ($totalPages pages)');
      case PdfGenerationProgress(:final completedUnits, :final totalUnits):
        stdout.writeln(
          '  progress: $completedUnits / $totalUnits',
        );
      case PdfPreviewProgress(:final completedPages, :final totalPages):
        stdout.writeln(
          '  preview: $completedPages / $totalPages',
        );
      case PdfGenerationCacheHit(:final documentId, :final artifactPaths):
        stdout.writeln(
          '[$documentId] cache hit → ${artifactPaths.length} artifact(s)',
        );
      case PdfGenerationCompleted(:final documentId, :final artifactPaths):
        stdout.writeln(
          '[$documentId] completed → ${artifactPaths.length} artifact(s)',
        );
      case PdfGenerationFailed(:final documentId, :final error):
        stdout.writeln('[$documentId] FAILED: $error');
      case PdfPhotoSlotSkipped(
          :final documentId,
          :final assetPath,
          :final error,
        ):
        stdout.writeln(
          '[$documentId] photo slot skipped ($assetPath): $error',
        );
    }
  }
}
