import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Records every `raster()` invocation and emits N deterministic
/// flat-colour pages so the preview pipeline has real PNG bytes to
/// decode and crop.
class _CountingFakeRasterizer implements DotsPdfRasterizer {
  _CountingFakeRasterizer({required this.pageCount});

  final int pageCount;
  int callCount = 0;

  @override
  Stream<DotsPdfRasterPage> raster(
    final Uint8List pdfBytes, {
    final double dpi = 150,
  }) async* {
    callCount += 1;
    for (var i = 0; i < pageCount; i++) {
      final img.Image page = img.Image(width: 200, height: 280);
      img.fill(page, color: img.ColorRgb8(40 * (i + 1), 80, 120));
      yield DotsPdfRasterPage(
        widthPx: page.width,
        heightPx: page.height,
        pngBytes: Uint8List.fromList(img.encodePng(page)),
      );
    }
  }
}

DotsTemplate _twoPageTemplate(final String id) => DotsTemplate(
      documentId: id,
      pageSize: const DotsPageSize(width: 200, height: 300),
      pages: const <DotsPage>[
        DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
        DotsElementsPage(pageNumber: 2, elements: <DotsElement>[]),
      ],
    );

void main() {
  late MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
  });

  group('DotsGenerator + preview generation', () {
    test(
        'emits Started → Progress → PdfPreviewProgress×2 → Completed and '
        'writes 2 PNGs', () async {
      final rasterizer = _CountingFakeRasterizer(pageCount: 2);
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );
      final template = _twoPageTemplate('doc_preview');

      final events =
          await generator.generateWhole(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.whereType<PdfGenerationProgress>(), hasLength(1));
      final previewEvents = events.whereType<PdfPreviewProgress>().toList();
      expect(previewEvents, hasLength(2));
      expect(previewEvents[0].completedPages, 1);
      expect(previewEvents[0].totalPages, 2);
      expect(previewEvents[1].completedPages, 2);
      expect(previewEvents[1].totalPages, 2);
      expect(events.last, isA<PdfGenerationCompleted>());

      final completed = events.last as PdfGenerationCompleted;
      expect(completed.previewPaths, hasLength(2));
      expect(
        completed.previewPaths.first,
        '/docs/dots_pdf/preview/doc_preview/page_001.png',
      );
      expect(
        completed.previewPaths.last,
        '/docs/dots_pdf/preview/doc_preview/page_002.png',
      );

      expect(
        await fs.file(completed.previewPaths.first).exists(),
        isTrue,
      );
      expect(
        await fs.file(completed.previewPaths.last).exists(),
        isTrue,
      );
    });

    test('cache hit reuses existing previews and does NOT call rasterizer',
        () async {
      final rasterizer = _CountingFakeRasterizer(pageCount: 2);
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );
      final template = _twoPageTemplate('doc_cache_preview');

      await generator.generateWhole(template: template).toList();
      expect(rasterizer.callCount, 1);

      final second =
          await generator.generateWhole(template: template).toList();
      expect(second, hasLength(1));
      expect(second.single, isA<PdfGenerationCacheHit>());
      final hit = second.single as PdfGenerationCacheHit;
      expect(hit.previewPaths, hasLength(2));
      // The fake should NOT have been re-invoked on the cache-hit run.
      expect(rasterizer.callCount, 1);
    });

    test('forceRegenerate wipes prior previews and emits a fresh set',
        () async {
      final rasterizer = _CountingFakeRasterizer(pageCount: 2);
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );
      final template = _twoPageTemplate('doc_force_preview');

      await generator.generateWhole(template: template).toList();
      final firstCount = rasterizer.callCount;
      expect(firstCount, 1);

      // Plant a stale rogue PNG to prove the directory is wiped.
      await fs
          .file('/docs/dots_pdf/preview/doc_force_preview/stale.png')
          .create(recursive: true);

      final second = await generator
          .generateWhole(template: template, forceRegenerate: true)
          .toList();

      expect(second.whereType<PdfGenerationCacheHit>(), isEmpty);
      expect(second.last, isA<PdfGenerationCompleted>());
      expect(rasterizer.callCount, firstCount + 1);

      // The rogue file is gone after the wipe.
      expect(
        await fs
            .file('/docs/dots_pdf/preview/doc_force_preview/stale.png')
            .exists(),
        isFalse,
      );
    });

    test('without a rasterizer, previewPaths is empty and behavior is '
        'preserved', () async {
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
      );
      final template = _twoPageTemplate('doc_no_preview');

      final events =
          await generator.generateWhole(template: template).toList();

      expect(events.last, isA<PdfGenerationCompleted>());
      final completed = events.last as PdfGenerationCompleted;
      expect(completed.previewPaths, isEmpty);
      expect(events.whereType<PdfPreviewProgress>(), isEmpty);

      // Second run still hits the cache (no preview requirement when no
      // rasterizer was wired in).
      final second =
          await generator.generateWhole(template: template).toList();
      expect(second.single, isA<PdfGenerationCacheHit>());
    });

    test('pairs mode produces a per-pair preview set with a prefix',
        () async {
      final rasterizer = _CountingFakeRasterizer(pageCount: 2);
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );
      // 3 pages → 2 pairs (one of 2 pages, one of 1).
      const template = DotsTemplate(
        documentId: 'doc_pairs_preview',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: <DotsPage>[
          DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
          DotsElementsPage(pageNumber: 2, elements: <DotsElement>[]),
          DotsElementsPage(pageNumber: 3, elements: <DotsElement>[]),
        ],
      );

      final events =
          await generator.generatePairs(template: template).toList();

      expect(events.last, isA<PdfGenerationCompleted>());
      final completed = events.last as PdfGenerationCompleted;
      // The fake emits 2 pages per pair, so we get 4 PNGs total.
      expect(completed.previewPaths, hasLength(4));
      expect(
        completed.previewPaths,
        containsAll(<String>[
          '/docs/dots_pdf/preview/doc_pairs_preview/'
              'pair_001_page_001.png',
          '/docs/dots_pdf/preview/doc_pairs_preview/'
              'pair_001_page_002.png',
          '/docs/dots_pdf/preview/doc_pairs_preview/'
              'pair_002_page_001.png',
          '/docs/dots_pdf/preview/doc_pairs_preview/'
              'pair_002_page_002.png',
        ]),
      );
    });
  });
}
