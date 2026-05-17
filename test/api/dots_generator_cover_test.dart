import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

bool _hasPdfMagic(final Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

DotsCoverTemplate _template({
  final String documentId = 'doc_alpha',
  final String? spineTitle,
}) =>
    DotsCoverTemplate(
      documentId: documentId,
      geometry: DotsCoverGeometry(
        pageCount: 132,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      ),
      frontArtworkPath: '/assets/front.png',
      backArtworkPath: '/assets/back.png',
      spineTitle: spineTitle,
    );

void main() {
  late MemoryFileSystem fs;

  setUp(() async {
    fs = MemoryFileSystem.test();
    await fs.directory('/docs').create(recursive: true);
    await fs.directory('/assets').create(recursive: true);
    await fs.file('/assets/front.png').writeAsBytes(_onePixelPng());
    await fs.file('/assets/back.png').writeAsBytes(_onePixelPng());
  });

  group('DotsGenerator.generateCover', () {
    test('end-to-end emits Started → Progress(1/1) → Completed', () async {
      final DotsGenerator generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
      );
      final DotsCoverTemplate template = _template();

      final events =
          await generator.generateCover(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      final started = events.first as PdfGenerationStarted;
      expect(started.documentId, 'doc_alpha');
      expect(started.totalPages, 1);

      final progress = events.whereType<PdfGenerationProgress>().toList();
      expect(progress, hasLength(1));
      expect(progress.single.completedUnits, 1);
      expect(progress.single.totalUnits, 1);

      expect(events.last, isA<PdfGenerationCompleted>());
      final completed = events.last as PdfGenerationCompleted;
      expect(completed.artifactPaths, hasLength(1));

      final String coverPath = await generator.coverPathFor('doc_alpha');
      expect(completed.artifactPaths.single, coverPath);

      final bytes = await fs.file(coverPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('second run hits the cache and skips re-rendering', () async {
      final DotsGenerator generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
      );
      final DotsCoverTemplate template = _template(documentId: 'doc_cache');

      final first =
          await generator.generateCover(template: template).toList();
      expect(first.last, isA<PdfGenerationCompleted>());

      final second =
          await generator.generateCover(template: template).toList();
      expect(second, hasLength(1));
      expect(second.single, isA<PdfGenerationCacheHit>());
      final hit = second.single as PdfGenerationCacheHit;
      expect(
        hit.artifactPaths.single,
        await generator.coverPathFor('doc_cache'),
      );
    });

    test('forceRegenerate re-runs the pipeline (no cache hit)', () async {
      final DotsGenerator generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
      );
      final DotsCoverTemplate template = _template(documentId: 'doc_force');

      await generator.generateCover(template: template).toList();
      final second = await generator
          .generateCover(template: template, forceRegenerate: true)
          .toList();

      expect(second.whereType<PdfGenerationCacheHit>(), isEmpty);
      expect(second.first, isA<PdfGenerationStarted>());
      expect(second.last, isA<PdfGenerationCompleted>());
    });

    test('changing spineTitle invalidates the cache', () async {
      final DotsGenerator generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
      );

      await generator
          .generateCover(template: _template(documentId: 'doc_hash'))
          .toList();

      final second = await generator
          .generateCover(
            template:
                _template(documentId: 'doc_hash', spineTitle: 'NEW TITLE'),
          )
          .toList();

      // Sidecar hash differs → second run renders again rather than
      // emitting a cache hit.
      expect(second.whereType<PdfGenerationCacheHit>(), isEmpty);
      expect(second.last, isA<PdfGenerationCompleted>());
    });
  });
}
