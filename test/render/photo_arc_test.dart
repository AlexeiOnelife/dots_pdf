// Tests for DotsAlbumSpreadPage.photoArc factory and photo-arc rendering
// (R6, R9, R10, R11, T1.4).
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/album_spread_page.dart'
    show buildAlbumSpreadPage, buildPhotoCircleElementForTest;
import 'package:dots_pdf/src/render/photo_arc_layout.dart'
    show kPhotoArcLayoutForTest;
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

const double _mmToPt = 2.834645669;

/// 406 mm spread × 254 mm page height — the canonical photo-arc format.
const PdfPageFormat _spreadFormat = PdfPageFormat(
  406.0 * _mmToPt,
  254.0 * _mmToPt,
);

/// Narrow format (203 mm wide) — triggers the width warning.
const PdfPageFormat _narrowFormat = PdfPageFormat(
  203.0 * _mmToPt,
  254.0 * _mmToPt,
);

/// 1×1 transparent PNG (smallest valid PNG payload).
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

List<String> _tenPaths() =>
    List.generate(10, (i) => 'photo_${i + 1}.jpg');

AlbumPhotoArcContent _content({
  List<String>? photoPaths,
  String? qrCaptionLeftOverride,
  String? qrCaptionRightOverride,
}) =>
    AlbumPhotoArcContent(
      photoPaths: photoPaths ?? _tenPaths(),
      qrPayloadLeft: 'https://left.example.com',
      qrPayloadRight: 'https://right.example.com',
      dateSubtitle: '01/01/2024 | 31/12/2024',
      qrCaptionLeftOverride: qrCaptionLeftOverride,
      qrCaptionRightOverride: qrCaptionRightOverride,
    );

/// Spy logger that records warn calls.
class _SpyLogger implements DotsLogger {
  final List<String> warnMessages = [];

  @override
  void info(String message) {}

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      warnMessages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

// ---------------------------------------------------------------------------

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.photoArc factory — element emission (R6)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.photoArc — elements list (R6)', () {
    late DotsAlbumSpreadPage page;

    setUp(() {
      page = DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: '5 años juntos',
        content: _content(),
      );
    });

    test('elements list has exactly 14 entries', () {
      expect(page.elements.length, equals(14));
    });

    test('exactly 10 elements are DotsPhotoCircleElement', () {
      final circles =
          page.elements.whereType<DotsPhotoCircleElement>().toList();
      expect(circles.length, equals(10));
    });

    test('exactly 2 elements are DotsOvalQrElement', () {
      final ovals = page.elements.whereType<DotsOvalQrElement>().toList();
      expect(ovals.length, equals(2));
    });

    test('exactly 2 elements are DotsTextElement', () {
      final texts = page.elements.whereType<DotsTextElement>().toList();
      expect(texts.length, equals(2));
    });

    test('circle elements match kPhotoArcLayout coordinates', () {
      final circles =
          page.elements.whereType<DotsPhotoCircleElement>().toList();
      final layout = kPhotoArcLayoutForTest;

      expect(circles.length, equals(layout.length));
      for (var i = 0; i < layout.length; i++) {
        expect(
          circles[i].x,
          closeTo(layout[i].xMm * _mmToPt, 0.001),
          reason: 'circle $i x mismatch',
        );
        expect(
          circles[i].y,
          closeTo(layout[i].yMm * _mmToPt, 0.001),
          reason: 'circle $i y mismatch',
        );
        expect(
          circles[i].diameter,
          closeTo(layout[i].diameterMm * _mmToPt, 0.001),
          reason: 'circle $i diameter mismatch',
        );
      }
    });

    test('header.centerLabel equals contextLabelValue', () {
      expect(page.header.centerLabel, equals('5 años juntos'));
    });

    test('footer.wordmark equals "Dots. Memories"', () {
      expect(page.footer.wordmark, equals('Dots. Memories'));
    });

    test(
        'header sets leftPageNumber=N and rightPageNumber=N+1 (spread convention)',
        () {
      // Spread convention: photoArc occupies TWO physical pages (left=N,
      // right=N+1). The `pageNumber` field represents the LEFT page.
      expect(page.header.leftPageNumber, equals('9'));
      expect(page.header.rightPageNumber, equals('10'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.photoArc — error contracts (R6, R10)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.photoArc — error contracts', () {
    test('throws ArgumentError for DotsAlbumType.boda', () {
      expect(
        () => DotsAlbumSpreadPage.photoArc(
          type: DotsAlbumType.boda,
          pageNumber: 1,
          contextLabelValue: 'x',
          content: _content(),
        ),
        throwsArgumentError,
      );
    });

    test('throws RangeError when photoPaths.length == 9', () {
      expect(
        () => DotsAlbumSpreadPage.photoArc(
          type: DotsAlbumType.parejas,
          pageNumber: 1,
          contextLabelValue: 'x',
          content: _content(
            photoPaths: List.generate(9, (i) => 'photo_${i + 1}.jpg'),
          ),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError when photoPaths.length == 11', () {
      expect(
        () => DotsAlbumSpreadPage.photoArc(
          type: DotsAlbumType.parejas,
          pageNumber: 1,
          contextLabelValue: 'x',
          content: _content(
            photoPaths: List.generate(11, (i) => 'photo_${i + 1}.jpg'),
          ),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('no error when photoPaths.length == 10', () {
      expect(
        () => DotsAlbumSpreadPage.photoArc(
          type: DotsAlbumType.parejas,
          pageNumber: 1,
          contextLabelValue: 'x',
          content: _content(),
        ),
        returnsNormally,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Photo-arc rendering (R9, R11)
  // ──────────────────────────────────────────────────────────────────────────

  group('photo-arc rendering (R9)', () {
    test('render via main-isolate produces non-empty PDF byte buffer', () async {
      final fs = MemoryFileSystem.test();
      for (var i = 1; i <= 10; i++) {
        await fs.file('/photo_$i.jpg').writeAsBytes(_onePixelPng());
      }

      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs')..createSync(recursive: true),
        useIsolate: false,
      );

      final page = DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: '5 años juntos',
        content: AlbumPhotoArcContent(
          photoPaths: [
            for (var i = 1; i <= 10; i++) '/photo_$i.jpg',
          ],
          qrPayloadLeft: 'https://left.example.com',
          qrPayloadRight: 'https://right.example.com',
          dateSubtitle: '2024',
        ),
      );

      final template = DotsTemplate(
        documentId: 'photo_arc_no_iso',
        pageSize: const DotsPageSize(
          width: 406.0 * _mmToPt,
          height: 254.0 * _mmToPt,
        ),
        pliegos: [DotsLayoutPliego(pliegoNumber: 1, left: page, right: const DotsElementsPage(pageNumber: 2, elements: []))],
      );

      final events =
          await generator.generateWhole(template: template).toList();
      expect(
        events.whereType<PdfGenerationFailed>(),
        isEmpty,
        reason: 'photo-arc no-isolate render must not fail: '
            '${events.whereType<PdfGenerationFailed>().map((e) => e.error)}',
      );
      expect(events.last, isA<PdfGenerationCompleted>());

      final outPath = await generator.wholePathFor('photo_arc_no_iso');
      final bytes = fs.file(outPath).readAsBytesSync();
      expect(bytes.length, greaterThan(0),
          reason: 'output PDF must be non-empty');
      expect(_hasPdfMagic(bytes), isTrue,
          reason: 'output must start with PDF magic bytes');
    });

    test('render via worker-isolate produces non-empty PDF byte buffer',
        () async {
      const fs = LocalFileSystem();
      final tempDir =
          io.Directory.systemTemp.createTempSync('dots_pdf_photo_arc_iso_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      for (var i = 1; i <= 10; i++) {
        io.File('${tempDir.path}/photo_$i.jpg')
            .writeAsBytesSync(_onePixelPng());
      }

      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory(tempDir.path),
        useIsolate: true,
      );

      final page = DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: '5 años juntos',
        content: AlbumPhotoArcContent(
          photoPaths: [
            for (var i = 1; i <= 10; i++) '${tempDir.path}/photo_$i.jpg',
          ],
          qrPayloadLeft: 'https://left.example.com',
          qrPayloadRight: 'https://right.example.com',
          dateSubtitle: '2024',
        ),
      );

      final template = DotsTemplate(
        documentId: 'photo_arc_iso',
        pageSize: const DotsPageSize(
          width: 406.0 * _mmToPt,
          height: 254.0 * _mmToPt,
        ),
        pliegos: [DotsLayoutPliego(pliegoNumber: 1, left: page, right: const DotsElementsPage(pageNumber: 2, elements: []))],
      );

      final events =
          await generator.generateWhole(template: template).toList();
      expect(
        events.whereType<PdfGenerationFailed>(),
        isEmpty,
        reason: 'photo-arc isolate render must not fail: '
            '${events.whereType<PdfGenerationFailed>().map((e) => e.error)}',
      );
      expect(events.last, isA<PdfGenerationCompleted>());

      final outPath = await generator.wholePathFor('photo_arc_iso');
      final bytes = fs.file(outPath).readAsBytesSync();
      expect(bytes.length, greaterThan(0),
          reason: 'isolate output PDF must be non-empty');
      expect(_hasPdfMagic(bytes), isTrue,
          reason: 'isolate output must start with PDF magic bytes');
    });

    test('photo circle element wraps decoded image in pw.ClipOval', () async {
      // Build the photo-circle widget directly via the @visibleForTesting
      // helper — this is the same code path the page renderer uses.
      const element = DotsPhotoCircleElement(
        x: 10.0,
        y: 20.0,
        diameter: 125.98,
        assetPath: 'photo_1.jpg',
      );

      final widget = await buildPhotoCircleElementForTest(
        element: element,
        bytesResolver: (_) async => _onePixelPng(),
        onPhotoFailure: (_, __) => fail('onPhotoFailure must not be called'),
      );

      expect(widget, isA<pw.Positioned>());
      final positioned = widget! as pw.Positioned;
      // The immediate child of Positioned must be ClipOval.
      expect(positioned.child, isA<pw.ClipOval>(),
          reason: 'photo circle element must wrap image in pw.ClipOval');
    });

    test('photo decode failure skips element and fires onPhotoFailure',
        () async {
      final failedPaths = <String>[];

      final page = DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: 'x',
        content: _content(),
      );

      // Build the pw.Page directly via buildAlbumSpreadPage — bytesResolver
      // always throws so all 10 photo-circle elements trigger onPhotoFailure.
      final builtPage = await buildAlbumSpreadPage(
        format: _spreadFormat,
        page: page,
        fontResolver: (_) => null,
        bytesResolver: (path) async => throw StateError('no asset: $path'),
        logger: const DotsSilentLogger(),
        onPhotoFailure: (path, _) => failedPaths.add(path),
        drawCropMarks: false,
      );

      // Page still builds (no exception thrown).
      expect(builtPage, isA<pw.Page>());
      // All 10 photo paths triggered onPhotoFailure.
      expect(failedPaths.length, equals(10));
    });

    test('logger warns when page width < 406 mm (R11)', () async {
      final spyLogger = _SpyLogger();

      final page = DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: 'x',
        content: _content(),
      );

      // Render with a narrow format (203 mm) — should trigger the warning.
      await buildAlbumSpreadPage(
        format: _narrowFormat,
        page: page,
        fontResolver: (_) => null,
        bytesResolver: (path) async => throw StateError('no asset: $path'),
        logger: spyLogger,
        onPhotoFailure: (_, __) {},
        drawCropMarks: false,
      );

      expect(spyLogger.warnMessages.length, greaterThanOrEqualTo(1),
          reason: 'at least one width warning must be emitted');
      expect(
        spyLogger.warnMessages.first,
        contains('406 mm'),
        reason: 'warning must mention the 406 mm threshold',
      );
    });
  });
}
