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

    test(
        'unreadable photo slot does NOT abort generation; '
        'pipeline emits PdfPhotoSlotSkipped and completes', () async {
      await _writePixel(fs, '/assets/good.png');
      await fs
          .file('/assets/bad.png')
          .writeAsBytes(Uint8List.fromList(<int>[0, 1, 2, 3])); // not an image
      const template = DotsTemplate(
        documentId: 'doc_bad_slot',
        pageSize: _dotbookPageSize,
        pages: [
          DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l4a,
            photoAssetPaths: [
              '/assets/good.png',
              '/assets/bad.png',
              '/assets/good.png',
              '/assets/bad.png',
            ],
          ),
        ],
      );

      final events =
          await generator.generateWhole(template: template).toList();

      expect(
        events.last,
        isA<PdfGenerationCompleted>(),
        reason: 'a bad photo slot must not abort the run',
      );
      final skipped =
          events.whereType<PdfPhotoSlotSkipped>().toList();
      expect(skipped, hasLength(2));
      expect(skipped.first.assetPath, '/assets/bad.png');
      expect(skipped.first.documentId, 'doc_bad_slot');

      final outPath = await generator.wholePathFor('doc_bad_slot');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // T1.2 — Chrome-presence integration tests (RED in PR 1, GREEN in PR 2)
  //
  // These tests are intentional RED placeholders. The renderer wiring that
  // reads DotsTemplate.defaultChrome and calls buildPageChrome is implemented
  // in PR 2 (tasks T6.1–T6.3). Each test body calls fail() so the suite
  // compiles cleanly but the tests fail with the expected PR-2 message.
  // ──────────────────────────────────────────────────────────────────────────

  group('Chrome-presence — renderer integration (PR 2 wiring)', () {
    test('DotsLayoutPage render — chrome present: background + header + footer',
        () {
      // R1, R2, R8: when defaultChrome is non-null the rendered page stack
      // must have a full-bleed #fdfefd background as its first child, header
      // text widgets, and a footer wordmark widget.
      // In PR 2: render a DotsLayoutPage with defaultChrome set and walk the
      // pw.Stack children to assert background color, header positions, and
      // footer presence.
      fail('PR 2: chrome wiring not yet implemented');
    });

    test(
        'DotsLayoutPage render — bleedTop slot suppresses header; '
        'background present', () {
      // R5: a slot with bleedTop:true and yMm < geometry.headerBandMm causes
      // the renderer to derive suppressHeader:true. The header text widgets
      // must be absent but the #fdfefd background must still be present.
      fail('PR 2: chrome wiring not yet implemented');
    });

    test(
        'DotsLayoutPage render — bleedBottom slot suppresses footer; '
        'background present', () {
      // R5: a slot with bleedBottom:true and yMm+heightMm > liveAreaBottomMm
      // causes suppressFooter:true. The footer wordmark must be absent but the
      // background must still be present.
      fail('PR 2: chrome wiring not yet implemented');
    });

    test('DotsLayoutPage render — no bleed slots: header and footer both render',
        () {
      // R5: when no slots carry bleed flags, both header and footer are present
      // in addition to the background widget.
      fail('PR 2: chrome wiring not yet implemented');
    });

    test('DotsElementsPage render — chrome always present unconditionally', () {
      // R5: DotsElementsPage always renders chrome (background + header +
      // footer) unconditionally regardless of element positions.
      // In PR 2: render with defaultChrome set; assert all three chrome layers.
      fail('PR 2: chrome wiring not yet implemented');
    });

    test(
        'DotsTemplate — defaultChrome null is backward-compatible; '
        'no chrome rendered', () {
      // R10: a template with defaultChrome:null must produce a page stack with
      // no #fdfefd background widget — identical output to pre-change behavior.
      // In PR 2: render with defaultChrome:null; assert no background in stack.
      fail('PR 2: chrome wiring not yet implemented');
    });
  });
}
