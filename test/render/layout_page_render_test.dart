import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 transparent PNG. Smallest valid PNG payload, captured as base64
/// so the test has no on-disk fixture dependencies.
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

// Page size matched (roughly) to DotsPageGeometry.dotbookDefault()
// 203 × 254 mm trim ≈ 575.43 × 720.0 pt.
const DotsPageSize _dotbookPageSize =
    DotsPageSize(width: 575.43, height: 720.0);

Future<void> _writePixel(MemoryFileSystem fs, String path) async {
  await fs.file(path).writeAsBytes(_onePixelPng());
}

void main() {
  late MemoryFileSystem fs;
  late DotsGenerator generator;

  setUp(() async {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
    await fs.directory('/assets').create(recursive: true);
    generator = DotsGenerator(
      fileSystem: fs,
      documentsDir: fs.directory('/docs'),
    );
  });

  group('Layout-driven page rendering', () {
    test('renders L1 (single photo) as a valid PDF', () async {
      await _writePixel(fs, '/assets/a.png');
      const template = DotsTemplate(
        documentId: 'doc_l1',
        pageSize: _dotbookPageSize,
        pages: [
          DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
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

      final outPath = await generator.wholePathFor('doc_l1');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });

    test('renders L4.A (2x2 grid) with four photos', () async {
      for (final name in <String>['a', 'b', 'c', 'd']) {
        await _writePixel(fs, '/assets/$name.png');
      }
      const template = DotsTemplate(
        documentId: 'doc_l4a',
        pageSize: _dotbookPageSize,
        pages: [
          DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l4a,
            photoAssetPaths: [
              '/assets/a.png',
              '/assets/b.png',
              '/assets/c.png',
              '/assets/d.png',
            ],
          ),
        ],
      );

      final events =
          await generator.generateWhole(template: template).toList();
      expect(events.last, isA<PdfGenerationCompleted>());

      final outPath = await generator.wholePathFor('doc_l4a');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });

    test('renders L_hito (no photos, all captions) as a valid PDF', () async {
      const template = DotsTemplate(
        documentId: 'doc_hito',
        pageSize: _dotbookPageSize,
        pages: [
          DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.lhito,
            captions: <DotsSlotKind, String>{
              DotsSlotKind.captionTitle: 'A milestone',
              DotsSlotKind.captionDate: '2026-05-17',
              DotsSlotKind.captionBody: 'A short body of text.',
              DotsSlotKind.qrCard: 'https://example.com/album',
            },
          ),
        ],
      );

      final events =
          await generator.generateWhole(template: template).toList();
      expect(events.last, isA<PdfGenerationCompleted>());

      final outPath = await generator.wholePathFor('doc_hito');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });
  });
}
