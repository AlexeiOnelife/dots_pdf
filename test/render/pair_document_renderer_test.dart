import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/pair_document_renderer.dart';
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

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
  });

  group('PairDocumentRenderer', () {
    test('renders a single-page slice', () async {
      final renderer = PairDocumentRenderer(
        fileSystem: fs,
        logger: const DotsSilentLogger(),
      );

      const template = DotsTemplate(
        documentId: 'doc_pair',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 10, value: 'p1', fontSize: 10),
            ],
          ),
        ],
      );

      const outPath = '/docs/single.pdf';
      await renderer.render(
        template: template,
        pages: template.pages,
        outputPath: outPath,
      );

      final bytes = await fs.file(outPath).readAsBytes();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('renders a 2-page slice', () async {
      final renderer = PairDocumentRenderer(
        fileSystem: fs,
        logger: const DotsSilentLogger(),
      );

      const template = DotsTemplate(
        documentId: 'doc_pair2',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 10, value: 'p1', fontSize: 10),
            ],
          ),
          DotsElementsPage(
            pageNumber: 2,
            elements: [
              DotsTextElement(x: 10, y: 10, value: 'p2', fontSize: 10),
            ],
          ),
        ],
      );

      const outPath = '/docs/pair.pdf';
      await renderer.render(
        template: template,
        pages: template.pages,
        outputPath: outPath,
      );

      final bytes = await fs.file(outPath).readAsBytes();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test(
      'end-to-end pairs generation writes pair_001.pdf and pair_002.pdf for '
      '3-page template (last pair is single-page)',
      () async {
        final docs = fs.directory('/docs');
        final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

        const template = DotsTemplate(
          documentId: 'doc_three',
          pageSize: DotsPageSize(width: 200, height: 300),
          pages: [
            DotsElementsPage(
              pageNumber: 1,
              elements: [
                DotsTextElement(x: 10, y: 10, value: 'p1', fontSize: 10),
              ],
            ),
            DotsElementsPage(
              pageNumber: 2,
              elements: [
                DotsTextElement(x: 10, y: 10, value: 'p2', fontSize: 10),
              ],
            ),
            DotsElementsPage(
              pageNumber: 3,
              elements: [
                DotsTextElement(x: 10, y: 10, value: 'p3', fontSize: 10),
              ],
            ),
          ],
        );

        final events =
            await generator.generatePairs(template: template).toList();

        expect(events.first, isA<PdfGenerationStarted>());
        final progressEvents =
            events.whereType<PdfGenerationProgress>().toList();
        expect(progressEvents, hasLength(2));
        expect(progressEvents.last.completedUnits, 2);
        expect(progressEvents.last.totalUnits, 2);
        expect(events.last, isA<PdfGenerationCompleted>());

        final completed = events.last as PdfGenerationCompleted;
        expect(completed.artifactPaths, hasLength(2));

        final dir = await generator.pairsDirPathFor('doc_three');
        final pair1 = fs.file('$dir/pair_001.pdf');
        final pair2 = fs.file('$dir/pair_002.pdf');
        expect(await pair1.exists(), isTrue);
        expect(await pair2.exists(), isTrue);

        final b1 = await pair1.readAsBytes();
        final b2 = await pair2.readAsBytes();
        expect(_hasPdfMagic(b1), isTrue);
        expect(_hasPdfMagic(b2), isTrue);
        expect(b1.length, greaterThan(0));
        expect(b2.length, greaterThan(0));
      },
    );

    test('cache hit on second pairs run without forceRegenerate', () async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

      const template = DotsTemplate(
        documentId: 'doc_pairs_cache',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: [
          DotsElementsPage(pageNumber: 1, elements: []),
          DotsElementsPage(pageNumber: 2, elements: []),
        ],
      );

      final first =
          await generator.generatePairs(template: template).toList();
      expect(first.last, isA<PdfGenerationCompleted>());

      final second =
          await generator.generatePairs(template: template).toList();
      expect(second, hasLength(1));
      expect(second.single, isA<PdfGenerationCacheHit>());
    });
  });
}
