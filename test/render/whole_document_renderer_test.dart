import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/whole_document_renderer.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 transparent PNG, the smallest valid PNG payload, captured as
/// base64 so the test has zero on-disk fixture dependencies.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

void main() {
  late MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
  });

  group('WholeDocumentRenderer', () {
    test('produces a valid PDF on disk with a text-only page', () async {
      final renderer = WholeDocumentRenderer(
        fileSystem: fs,
        logger: const DotsSilentLogger(),
      );

      const template = DotsTemplate(
        documentId: 'doc_text',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(
                x: 20,
                y: 40,
                value: 'Hello',
                fontSize: 12,
              ),
            ],
          ),
        ],
      );

      const outPath = '/docs/out.pdf';
      await renderer.render(
        template: template,
        pages: template.pages,
        outputPath: outPath,
      );

      final file = fs.file(outPath);
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue, reason: 'file should start with %PDF');
    });

    test('end-to-end via DotsGenerator.generateWhole emits expected events',
        () async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

      const template = DotsTemplate(
        documentId: 'doc_alpha',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(
                x: 20,
                y: 40,
                value: 'Hello',
                fontSize: 12,
              ),
            ],
          ),
        ],
      );

      final events =
          await generator.generateWhole(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.whereType<PdfGenerationProgress>().length, greaterThan(0));
      expect(events.last, isA<PdfGenerationCompleted>());

      final completed = events.last as PdfGenerationCompleted;
      expect(completed.documentId, 'doc_alpha');
      expect(completed.artifactPaths, hasLength(1));

      final outPath = await generator.wholePathFor('doc_alpha');
      expect(completed.artifactPaths.single, outPath);

      final file = fs.file(outPath);
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('renders an image element from a fake asset on the file system',
        () async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

      // Plant a 1×1 PNG fixture on the in-memory file system; the
      // renderer reads it via DotsRenderer.fs.
      await fs.directory('/assets').create(recursive: true);
      await fs.file('/assets/pixel.png').writeAsBytes(_onePixelPng());

      const template = DotsTemplate(
        documentId: 'doc_image',
        pageSize: DotsPageSize(width: 200, height: 300),
        pages: [
          DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsImageElement(
                x: 10,
                y: 10,
                assetPath: '/assets/pixel.png',
                width: 50,
                height: 50,
                bleedTop: true,
                bleedRight: true,
              ),
            ],
          ),
        ],
      );

      final events =
          await generator.generateWhole(template: template).toList();
      expect(
        events.last,
        isA<PdfGenerationCompleted>(),
        reason: 'expected success but saw ${events.last}',
      );

      final outPath = await generator.wholePathFor('doc_image');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('cache hit on second run without forceRegenerate', () async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

      const template = DotsTemplate(
        documentId: 'doc_cache',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: [DotsElementsPage(pageNumber: 1, elements: [])],
      );

      final first =
          await generator.generateWhole(template: template).toList();
      expect(first.last, isA<PdfGenerationCompleted>());

      final second =
          await generator.generateWhole(template: template).toList();
      expect(second, hasLength(1));
      expect(second.single, isA<PdfGenerationCacheHit>());
    });

    test('forceRegenerate re-runs the pipeline (no cache hit event)',
        () async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

      const template = DotsTemplate(
        documentId: 'doc_force',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: [DotsElementsPage(pageNumber: 1, elements: [])],
      );

      await generator.generateWhole(template: template).toList();
      final second = await generator
          .generateWhole(template: template, forceRegenerate: true)
          .toList();

      expect(second.whereType<PdfGenerationCacheHit>(), isEmpty);
      expect(second.first, isA<PdfGenerationStarted>());
      expect(second.last, isA<PdfGenerationCompleted>());
    });
  });
}
