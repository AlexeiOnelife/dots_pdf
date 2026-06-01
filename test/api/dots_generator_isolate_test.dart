import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// 1×1 transparent PNG — smallest valid PNG, encoded inline so the test
/// has no on-disk fixture dependencies.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

/// Solid-colour PNG of arbitrary size — used for cover artwork which has
/// minimum dimension requirements.
Uint8List _solidPng({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 160, 200));
  return Uint8List.fromList(img.encodePng(image));
}

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

// Page size matched to DotsPageGeometry.dotbookDefault() — 203×254 mm trim.
const DotsPageSize _dotbookPageSize =
    DotsPageSize(width: 575.43, height: 720.0);

// ---------------------------------------------------------------------------
// Capturing logger
// ---------------------------------------------------------------------------

/// Test double that records every [info] call.
class _CapturingLogger implements DotsLogger {
  final List<String> infoMessages = [];
  final List<String> warnMessages = [];
  final List<String> errorMessages = [];

  @override
  void info(String message) => infoMessages.add(message);

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      warnMessages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      errorMessages.add(message);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const fs = LocalFileSystem();

  late io.Directory tempDir;

  setUp(() {
    tempDir = io.Directory.systemTemp.createTempSync('dots_pdf_isolate_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // Helper: build a LocalFileSystem-based generator.
  DotsGenerator buildGenerator({
    DotsLogger? logger,
    bool useIsolate = true,
  }) {
    return DotsGenerator(
      fileSystem: fs,
      documentsDir: fs.directory(tempDir.path),
      logger: logger ?? const DotsSilentLogger(),
      useIsolate: useIsolate,
    );
  }

  // -------------------------------------------------------------------------
  // 1. Whole mode — isolate produces a valid PDF
  // -------------------------------------------------------------------------
  group('useIsolate=true — whole mode', () {
    test('produces a valid PDF and emits Started → Progress → Completed',
        () async {
      final generator = buildGenerator();

      const template = DotsTemplate(
        documentId: 'iso_whole',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Isolate test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      final events =
          await generator.generateWhole(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.whereType<PdfGenerationProgress>(), isNotEmpty);
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(
        events.whereType<PdfGenerationFailed>(),
        isEmpty,
        reason: 'expected no failures but got: '
            '${events.whereType<PdfGenerationFailed>().map((PdfGenerationFailed e) => e.error)}',
      );

      final outPath = await generator.wholePathFor('iso_whole');
      final bytes = fs.file(outPath).readAsBytesSync();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test(
        'output is byte-compatible with useIsolate=false '
        '(both are valid PDFs of similar size)', () async {
      // The pdf package embeds a creation timestamp so byte-identical comparison
      // is fragile. We assert that both outputs are valid PDFs and have plausibly
      // similar sizes (within 20 % of each other), confirming the isolate path
      // renders real content.
      final withIsolate = buildGenerator(useIsolate: true);
      final noIsolate = buildGenerator(useIsolate: false);

      const isoTemplate = DotsTemplate(
        documentId: 'iso_whole_cmp',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Compare test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      const noIsoTemplate = DotsTemplate(
        documentId: 'iso_whole_cmp_no',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Compare test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      await withIsolate.generateWhole(template: isoTemplate).toList();
      await noIsolate.generateWhole(template: noIsoTemplate).toList();

      final isoBytes = fs
          .file(await withIsolate.wholePathFor('iso_whole_cmp'))
          .readAsBytesSync();
      final noIsoBytes = fs
          .file(await noIsolate.wholePathFor('iso_whole_cmp_no'))
          .readAsBytesSync();

      expect(_hasPdfMagic(isoBytes), isTrue,
          reason: 'isolate output must be a valid PDF');
      expect(_hasPdfMagic(noIsoBytes), isTrue,
          reason: 'non-isolate output must be a valid PDF');

      // Size similarity: isolate PDF must be within 20 % of non-isolate PDF.
      final ratio = isoBytes.length / noIsoBytes.length;
      expect(ratio, greaterThan(0.8),
          reason: 'isolate PDF is suspiciously small');
      expect(ratio, lessThan(1.2),
          reason: 'isolate PDF is suspiciously large');
    });
  });

  // -------------------------------------------------------------------------
  // 2. Pairs mode — isolate produces valid pair PDFs
  // -------------------------------------------------------------------------
  group('useIsolate=true — pairs mode', () {
    test('produces valid pair PDFs and emits correct progress', () async {
      final generator = buildGenerator();

      // Write a 1×1 pixel PNG to the local temp dir for the photo slot.
      final assetPath = '${tempDir.path}/a.png';
      io.File(assetPath).writeAsBytesSync(_onePixelPng());

      final template = DotsTemplate(
        documentId: 'iso_pairs',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: [assetPath],
          ),
          right: DotsLayoutPage(
            pageNumber: 2,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: [assetPath],
          ),
        ),
        const DotsLayoutPliego(
          pliegoNumber: 2,
          left: DotsElementsPage(
            pageNumber: 3,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Last page', fontSize: 10),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      final events =
          await generator.generatePairs(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(
        events.whereType<PdfGenerationFailed>(),
        isEmpty,
        reason: 'expected no failures but got: '
            '${events.whereType<PdfGenerationFailed>().map((PdfGenerationFailed e) => e.error)}',
      );

      final completed = events.last as PdfGenerationCompleted;
      // 3 pages → 2 pairs: [p1, p2] and [p3].
      expect(completed.artifactPaths, hasLength(2));

      for (final path in completed.artifactPaths) {
        final bytes = fs.file(path).readAsBytesSync();
        expect(_hasPdfMagic(bytes), isTrue,
            reason: 'pair PDF at $path must be a valid PDF');
        expect(bytes.length, greaterThan(0));
      }

      // Verify progress events mirror pair count.
      final progress = events.whereType<PdfGenerationProgress>().toList();
      expect(progress, hasLength(2));
      expect(progress.first.completedUnits, 1);
      expect(progress.first.totalUnits, 2);
      expect(progress.last.completedUnits, 2);
      expect(progress.last.totalUnits, 2);
    });
  });

  // -------------------------------------------------------------------------
  // 3. Cover mode — isolate produces a valid cover PDF
  // -------------------------------------------------------------------------
  group('useIsolate=true — cover mode', () {
    test(
        'produces a valid cover PDF and emits '
        'Started → Progress(1/1) → Completed', () async {
      final generator = buildGenerator();

      final artworkPath = '${tempDir.path}/front.png';
      io.File(artworkPath).writeAsBytesSync(_solidPng(
        width: DotsCoverDesign.square.minSourceWidthPx,
        height: DotsCoverDesign.square.minSourceHeightPx,
      ));

      final template = DotsCoverTemplate(
        documentId: 'iso_cover',
        geometry: DotsCoverGeometry(
          pageCount: 132,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        design: DotsCoverDesign.square,
        frontArtworkPath: artworkPath,
      );

      final events =
          await generator.generateCover(template: template).toList();

      expect(events.first, isA<PdfGenerationStarted>());
      final started = events.first as PdfGenerationStarted;
      expect(started.totalPages, 1);

      final progress = events.whereType<PdfGenerationProgress>().toList();
      expect(progress, hasLength(1));
      expect(progress.single.completedUnits, 1);
      expect(progress.single.totalUnits, 1);

      expect(events.last, isA<PdfGenerationCompleted>());
      expect(
        events.whereType<PdfGenerationFailed>(),
        isEmpty,
        reason: 'expected no failures but got: '
            '${events.whereType<PdfGenerationFailed>().map((PdfGenerationFailed e) => e.error)}',
      );

      final coverPath = await generator.coverPathFor('iso_cover');
      final bytes = fs.file(coverPath).readAsBytesSync();
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // 4. MemoryFileSystem incompatibility
  // -------------------------------------------------------------------------
  group('useIsolate=true — MemoryFileSystem incompatibility', () {
    test(
        'emits PdfGenerationFailed or writes an artifact invisible to '
        'MemoryFileSystem (documents current behavior — see TODO)', () async {
      // TODO: Once DotsGenerator gains a guard that asserts useIsolate==false
      // when a MemoryFileSystem is detected, update this test to expect a clear
      // StateError/AssertionError instead of documenting the silent failure.
      //
      // Current behavior: the isolate writes via dart:io File directly. Paths
      // like '/docs/dots_pdf/...' don't exist as real OS paths, so dart:io
      // throws a FileSystemException and the generator emits PdfGenerationFailed.
      // If the path somehow exists on the host, the written file is invisible
      // to MemoryFileSystem — confirming the incompatibility either way.

      final memFs = MemoryFileSystem.test();
      final memDocs = memFs.directory('/docs')..createSync(recursive: true);

      final generator = DotsGenerator(
        fileSystem: memFs,
        documentsDir: memDocs,
        useIsolate: true,
      );

      const template = DotsTemplate(
        documentId: 'iso_mem',
        pageSize: DotsPageSize(width: 200, height: 300),
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'mem test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      final events =
          await generator.generateWhole(template: template).toList();

      final failed = events.whereType<PdfGenerationFailed>().toList();
      if (failed.isNotEmpty) {
        // Expected path: dart:io throws because the real OS path does not exist.
        expect(failed.first.error, isNotNull);
        return;
      }

      // Alternative path: dart:io wrote to a real OS path that coincidentally
      // existed. The artifact must be invisible to MemoryFileSystem.
      final completed = events.whereType<PdfGenerationCompleted>().toList();
      expect(
        completed,
        isNotEmpty,
        reason: 'expected either PdfGenerationFailed or PdfGenerationCompleted',
      );
      expect(
        await memFs.file(completed.first.artifactPaths.first).exists(),
        isFalse,
        reason: 'MemoryFileSystem must not see the file written by dart:io '
            'in the isolate — this confirms the incompatibility',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 5. Perf log line is emitted
  // -------------------------------------------------------------------------
  group('useIsolate=true — perf log', () {
    test(
        'whole mode: emits exactly one perf log line '
        'with all required fields', () async {
      final logger = _CapturingLogger();
      final generator = buildGenerator(logger: logger);

      const template = DotsTemplate(
        documentId: 'iso_perf_whole',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Perf test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      await generator.generateWhole(template: template).toList();

      final perfLines = logger.infoMessages
          .where((String m) => m.contains('[dots_pdf] perf'))
          .toList();
      expect(perfLines, hasLength(1),
          reason: 'expected exactly one perf log line, got: $perfLines');

      final line = perfLines.single;
      expect(line, contains('documentId=iso_perf_whole'));
      expect(line, contains('isolate=on'));
      expect(line, matches(RegExp(r'synth=\d+ms')));
      expect(line, matches(RegExp(r'save=\d+ms')));
      expect(line, matches(RegExp(r'raster=\d+ms')));
      expect(line, matches(RegExp(r'total=\d+ms')));
      expect(line, matches(RegExp(r'pages=\d+')));
      expect(line, contains('mode=whole'));
    });

    test(
        'pairs mode: emits exactly one perf log line '
        'with all required fields', () async {
      final logger = _CapturingLogger();
      final generator = buildGenerator(logger: logger);

      final assetPath = '${tempDir.path}/b.png';
      io.File(assetPath).writeAsBytesSync(_onePixelPng());

      final template = DotsTemplate(
        documentId: 'iso_perf_pairs',
        pageSize: _dotbookPageSize,
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: [assetPath],
          ),
          right: DotsLayoutPage(
            pageNumber: 2,
            layoutCode: DotsLayoutCode.l1,
            photoAssetPaths: [assetPath],
          ),
        ),
      ],
      );

      await generator.generatePairs(template: template).toList();

      final perfLines = logger.infoMessages
          .where((String m) => m.contains('[dots_pdf] perf'))
          .toList();
      expect(perfLines, hasLength(1),
          reason: 'expected exactly one perf log line, got: $perfLines');

      final line = perfLines.single;
      expect(line, contains('documentId=iso_perf_pairs'));
      expect(line, contains('isolate=on'));
      expect(line, matches(RegExp(r'synth=\d+ms')));
      expect(line, matches(RegExp(r'save=\d+ms')));
      expect(line, matches(RegExp(r'raster=\d+ms')));
      expect(line, matches(RegExp(r'total=\d+ms')));
      expect(line, matches(RegExp(r'pages=\d+')));
      expect(line, contains('mode=pairs'));
    });

    test(
        'cover mode: emits exactly one perf log line '
        'with all required fields', () async {
      final logger = _CapturingLogger();
      final generator = buildGenerator(logger: logger);

      final artworkPath = '${tempDir.path}/cover_perf.png';
      io.File(artworkPath).writeAsBytesSync(_solidPng(
        width: DotsCoverDesign.square.minSourceWidthPx,
        height: DotsCoverDesign.square.minSourceHeightPx,
      ));

      final template = DotsCoverTemplate(
        documentId: 'iso_perf_cover',
        geometry: DotsCoverGeometry(
          pageCount: 132,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        design: DotsCoverDesign.square,
        frontArtworkPath: artworkPath,
      );

      await generator.generateCover(template: template).toList();

      final perfLines = logger.infoMessages
          .where((String m) => m.contains('[dots_pdf] perf'))
          .toList();
      expect(perfLines, hasLength(1),
          reason: 'expected exactly one perf log line, got: $perfLines');

      final line = perfLines.single;
      expect(line, contains('documentId=iso_perf_cover'));
      expect(line, contains('isolate=on'));
      expect(line, matches(RegExp(r'synth=\d+ms')));
      expect(line, matches(RegExp(r'save=\d+ms')));
      expect(line, matches(RegExp(r'raster=\d+ms')));
      expect(line, matches(RegExp(r'total=\d+ms')));
      expect(line, contains('pages=1'));
      expect(line, contains('mode=cover'));
    });

    test('useIsolate=false emits isolate=off in the perf log line', () async {
      final logger = _CapturingLogger();
      final memFs = MemoryFileSystem.test();
      final memDocs = memFs.directory('/docs')..createSync(recursive: true);

      final generator = DotsGenerator(
        fileSystem: memFs,
        documentsDir: memDocs,
        logger: logger,
        useIsolate: false,
      );

      const template = DotsTemplate(
        documentId: 'iso_off',
        pageSize: DotsPageSize(width: 200, height: 300),
        pliegos: [
        DotsLayoutPliego(
          pliegoNumber: 1,
          left: DotsElementsPage(
            pageNumber: 1,
            elements: [
              DotsTextElement(x: 10, y: 20, value: 'Off test', fontSize: 12),
            ],
          ),
          right: DotsElementsPage(pageNumber: 0, elements: []),
        ),
      ],
      );

      await generator.generateWhole(template: template).toList();

      final perfLines = logger.infoMessages
          .where((String m) => m.contains('[dots_pdf] perf'))
          .toList();
      expect(perfLines, hasLength(1));
      expect(perfLines.single, contains('isolate=off'));
    });
  });
}
