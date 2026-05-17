import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

void main() {
  late MemoryFileSystem fs;
  late DotsGenerator generator;
  late DotsTemplate template;

  setUp(() {
    fs = MemoryFileSystem.test();
    final docs = fs.directory('/docs')..createSync();
    generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

    template = const DotsTemplate(
      documentId: 'doc_alpha',
      pageSize: DotsPageSize(width: 200, height: 300),
      pages: [
        DotsElementsPage(
          pageNumber: 1,
          elements: [
            DotsTextElement(x: 10, y: 20, value: 'A', fontSize: 12),
          ],
        ),
      ],
    );
  });

  group('DotsGenerator', () {
    test('exposes deterministic path accessors', () async {
      expect(
        await generator.wholePathFor('doc_alpha'),
        '/docs/dots_pdf/whole/doc_alpha.pdf',
      );
      expect(
        await generator.pairsDirPathFor('doc_alpha'),
        '/docs/dots_pdf/pairs/doc_alpha',
      );
    });

    test('whole mode renders a valid PDF and emits Started → Progress → '
        'Completed', () async {
      final events =
          await generator.generateWhole(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.whereType<PdfGenerationProgress>(), isNotEmpty);
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(events.whereType<PdfGenerationFailed>(), isEmpty);

      final outPath = await generator.wholePathFor('doc_alpha');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('pairs mode renders pair files and emits matching progress', () async {
      const pairsTemplate = DotsTemplate(
        documentId: 'doc_pairs',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(pageNumber: 1, elements: []),
          DotsElementsPage(pageNumber: 2, elements: []),
          DotsElementsPage(pageNumber: 3, elements: []),
        ],
      );

      final events =
          await generator.generatePairs(template: pairsTemplate).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(events.whereType<PdfGenerationFailed>(), isEmpty);

      final completed = events.last as PdfGenerationCompleted;
      expect(completed.artifactPaths, hasLength(2));

      final dir = await generator.pairsDirPathFor('doc_pairs');
      expect(await fs.file('$dir/pair_001.pdf').exists(), isTrue);
      expect(await fs.file('$dir/pair_002.pdf').exists(), isTrue);
    });

    test('temp directory is cleaned up after a successful run', () async {
      await generator.generateWhole(template: template).toList();
      final tmpDir = fs.directory('/docs/dots_pdf/tmp/doc_alpha');
      expect(await tmpDir.exists(), isFalse);
    });

    test('cache hit short-circuits the pipeline on the second whole run',
        () async {
      await generator.generateWhole(template: template).toList();
      final second =
          await generator.generateWhole(template: template).toList();

      expect(second, hasLength(1));
      expect(second.single, isA<PdfGenerationCacheHit>());
      final hit = second.single as PdfGenerationCacheHit;
      expect(
        hit.artifactPaths.single,
        await generator.wholePathFor('doc_alpha'),
      );
    });

    test('forceRegenerate skips cache and re-renders', () async {
      await generator.generateWhole(template: template).toList();
      final second = await generator
          .generateWhole(template: template, forceRegenerate: true)
          .toList();

      expect(second.whereType<PdfGenerationCacheHit>(), isEmpty);
      expect(second.last, isA<PdfGenerationCompleted>());
    });
  });
}
