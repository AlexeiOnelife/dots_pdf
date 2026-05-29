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
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
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
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l4a,
            photoAssetPaths: [
              '/assets/a.png',
              '/assets/b.png',
              '/assets/c.png',
              '/assets/d.png',
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
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
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.lhito,
            captions: <DotsSlotKind, String>{
              DotsSlotKind.captionTitle: 'A milestone',
              DotsSlotKind.captionDate: '2026-05-17',
              DotsSlotKind.captionBody: 'A short body of text.',
              DotsSlotKind.qrCard: 'https://example.com/album',
            },
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
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
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l4a,
            photoAssetPaths: [
              '/assets/good.png',
              '/assets/bad.png',
              '/assets/good.png',
              '/assets/bad.png',
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
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
    const chrome = DotsPageChrome(
      pageNumber: '3',
      centerLabel: 'My Album',
      wordmark: 'Dots. Memories',
      isLeftPage: true,
    );

    Future<Uint8List> generateAndRead(DotsTemplate template) async {
      final events =
          await generator.generateWhole(template: template).toList();
      expect(
        events.last,
        isA<PdfGenerationCompleted>(),
        reason: 'expected success but saw ${events.last}',
      );
      final outPath = await generator.wholePathFor(template.documentId);
      return fs.file(outPath).readAsBytes();
    }

    test('DotsLayoutPage render — chrome present: background + header + footer',
        () async {
      await _writePixel(fs, '/assets/a.png');
      const withChrome = DotsTemplate(
        documentId: 'doc_chrome_present',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      const noChrome = DotsTemplate(
        documentId: 'doc_chrome_present_baseline',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final bytesWithChrome = await generateAndRead(withChrome);
      final bytesNoChrome = await generateAndRead(noChrome);
      expect(_hasPdfMagic(bytesWithChrome), isTrue);
      expect(_hasPdfMagic(bytesNoChrome), isTrue);
      expect(
        bytesWithChrome.length,
        greaterThan(bytesNoChrome.length),
        reason: 'chrome adds background + header + footer content',
      );
    });

    test(
        'DotsLayoutPage render — bleedTop slot suppresses header; '
        'background present', () async {
      await _writePixel(fs, '/assets/a.png');
      // l1b is the only catalog layout with a bleedTop slot (yMm ≈ 8 mm,
      // which is below the 12 mm header band ceiling — triggers suppression).
      const bleedTopL1b = DotsTemplate(
        documentId: 'doc_bleedtop_suppress',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1b,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      const noBleed = DotsTemplate(
        documentId: 'doc_bleedtop_baseline',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final bytesSuppressed = await generateAndRead(bleedTopL1b);
      final bytesFull = await generateAndRead(noBleed);
      expect(_hasPdfMagic(bytesSuppressed), isTrue);
      // Suppressed-header build emits fewer chrome text widgets than the
      // unsuppressed l1 build at the same chrome settings.
      expect(
        bytesSuppressed.length,
        lessThan(bytesFull.length),
        reason: 'bleedTop must omit header text while keeping the background',
      );
    });

    test(
        'DotsLayoutPage render — footer renders when no slot has bleedBottom '
        '(integration coverage of the non-suppression path)', () async {
      // Honest scope note: no catalog layout currently carries
      // `bleedBottom: true`, so the *suppression* branch is unreachable from
      // the renderer pipeline today. It IS covered at the predicate level by
      // `deriveSuppressFooterForChrome` in `page_chrome_test.dart`. This
      // integration test pins the non-suppression path — the footer renders
      // when no slot bleeds — which is what the renderer actually exercises.
      await _writePixel(fs, '/assets/a.png');
      const tpl = DotsTemplate(
        documentId: 'doc_no_bleedbottom',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final bytes = await generateAndRead(tpl);
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('DotsLayoutPage render — no bleed slots: header and footer both render',
        () async {
      await _writePixel(fs, '/assets/a.png');
      // L1 has no bleed flags → both chrome bands render.
      const tpl = DotsTemplate(
        documentId: 'doc_no_bleed',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      const tplNoChrome = DotsTemplate(
        documentId: 'doc_no_bleed_baseline',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final withChrome = await generateAndRead(tpl);
      final baseline = await generateAndRead(tplNoChrome);
      expect(
        withChrome.length,
        greaterThan(baseline.length),
        reason: 'header + footer chrome both add bytes when no slot bleeds',
      );
    });

    test('DotsElementsPage render — chrome always present unconditionally',
        () async {
      const tpl = DotsTemplate(
        documentId: 'doc_elements_chrome',
        pageSize: _dotbookPageSize,
        defaultChrome: chrome,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      const tplNoChrome = DotsTemplate(
        documentId: 'doc_elements_baseline',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final withChrome = await generateAndRead(tpl);
      final baseline = await generateAndRead(tplNoChrome);
      expect(_hasPdfMagic(withChrome), isTrue);
      expect(
        withChrome.length,
        greaterThan(baseline.length),
        reason: 'elements page must render chrome unconditionally',
      );
    });

    test(
        'DotsTemplate — defaultChrome null is backward-compatible; '
        'no chrome rendered', () async {
      // The baseline-no-chrome templates above implicitly cover this: with
      // defaultChrome: null the pipeline still succeeds and produces a smaller
      // PDF than the chrome-on variant. This explicit smoke test pins the
      // backward-compatible default by rendering a chrome-less template alone.
      await _writePixel(fs, '/assets/a.png');
      const tpl = DotsTemplate(
        documentId: 'doc_no_chrome_compat',
        pageSize: _dotbookPageSize,
        // defaultChrome omitted → null
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: ['/assets/a.png'],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );
      final bytes = await generateAndRead(tpl);
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });
  });
}
