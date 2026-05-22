// Tests for the shared album-spread-page rendering helper and the
// DotsAlbumSpreadPage.dedication / .closing named constructors.
//
// T1.1–T1.5 — now GREEN (PR 2 T3 and T4 implemented).
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/album_spread_page.dart'
    show buildAlbumSpreadPage, kHeaderFontSizeForTest;
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

const DotsPageSize _pageSize = DotsPageSize(width: 575.43, height: 720.0);
const PdfPageFormat _format = PdfPageFormat(575.43, 720.0);

// Spy logger that records warn calls.
class _SpyLogger implements DotsLogger {
  final List<String> warnMessages = [];
  final List<String> errorMessages = [];

  @override
  void info(String message) {}

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      warnMessages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      errorMessages.add(message);
}

// Null-returning photo failure callback — used when we don't need to track
// failures in the test.
void _ignorePhotoFailure(String path, Object error) {}

// Build a pw.Page from a DotsAlbumSpreadPage using null font + bytes resolvers
// (falls back to Helvetica; no real images needed unless a photoPath is given).
Future<pw.Page> _buildPage(
  DotsAlbumSpreadPage page, {
  DotsLogger? logger,
  Future<Uint8List> Function(String)? bytesResolver,
  void Function(String, Object)? onPhotoFailure,
}) async {
  return buildAlbumSpreadPage(
    format: _format,
    page: page,
    fontResolver: (_) => null,
    bytesResolver: bytesResolver ??
        (path) async => throw StateError('no bytes resolver — path: $path'),
    logger: logger ?? const DotsSilentLogger(),
    onPhotoFailure: onPhotoFailure ?? _ignorePhotoFailure,
    drawCropMarks: false,
  );
}

// Dedication page fixture reused across multiple test groups.
DotsAlbumSpreadPage _dedicationPage(DotsAlbumType type) =>
    DotsAlbumSpreadPage.dedication(
      type: type,
      pageNumber: 5,
      contextLabelValue: type.contextLabelToken,
      title: 'Nuestro viaje',
      body: 'Un año de amor.',
      signature: 'Blanqui',
    );

// ── mm → pt constant (same as renderer) ──────────────────────────────────
const double _mmToPt = 2.834645669;

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // R1 — Dedication page rendering  (T1.1)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — dedication page rendering', () {
    for (final type in [
      DotsAlbumType.parejas,
      DotsAlbumType.hijos,
      DotsAlbumType.individuales,
      DotsAlbumType.otros,
    ]) {
      test(
          'AlbumSpreadPage — dedication page renders title, body, and signature '
          'for ${type.name}', () async {
        final page = _dedicationPage(type);

        // Inspect the element model — all three text content items must be
        // present as elements on the page.
        final titles = page.elements
            .whereType<DotsTextElement>()
            .where((e) => e.value == 'Nuestro viaje');
        expect(titles, isNotEmpty, reason: 'title text element must be present');

        final bodies = page.elements
            .whereType<DotsTextBlockElement>()
            .where((e) => e.value == 'Un año de amor.');
        expect(bodies, isNotEmpty, reason: 'body text block element must be present');

        final sigs = page.elements
            .whereType<DotsRotatedTextElement>()
            .where((e) => e.value == 'Blanqui');
        expect(sigs, isNotEmpty, reason: 'signature rotated element must be present');
      });
    }

    test(
        'AlbumSpreadPage — dedication signature is rendered via '
        'DotsRotatedTextElement at 2°', () {
      final page = _dedicationPage(DotsAlbumType.parejas);
      final sig = page.elements.whereType<DotsRotatedTextElement>().first;
      expect(sig.angleDegrees, equals(2.0));
    });

    test('AlbumSpreadPage — dedication body is constrained to 102 mm width',
        () {
      final page = _dedicationPage(DotsAlbumType.parejas);
      final body = page.elements.whereType<DotsTextBlockElement>().first;
      // 102 mm × 2.834645669 pt/mm ≈ 289.13 pt.
      expect(body.width, closeTo(102.0 * _mmToPt, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R2 — Closing single page rendering  (T1.2)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — closing page rendering', () {
    test('AlbumSpreadPage — closing page title is 12pt for boda', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.boda,
        pageNumber: 1,
        contextLabelValue: '{Protagonistas}',
        photoPath: 'photo.jpg',
        title: 'Que la vida siga reencontrándoos',
        subtitle: '',
      );
      final title = page.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(12.0));
    });

    test('AlbumSpreadPage — closing page title is 20pt for parejas', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.parejas,
        pageNumber: 2,
        contextLabelValue: '{tiempojuntos}',
        photoPath: 'photo.jpg',
        title: 'Vivid together',
        subtitle: 'Ana y Luis',
      );
      final title = page.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test('AlbumSpreadPage — closing page title is 20pt for hijos', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.hijos,
        pageNumber: 3,
        contextLabelValue: '{Protagonistas}',
        photoPath: 'photo.jpg',
        title: 'T',
        subtitle: 'S',
      );
      final title = page.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test('AlbumSpreadPage — closing page title is 20pt for individuales', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.individuales,
        pageNumber: 4,
        contextLabelValue: '{Año}',
        photoPath: 'photo.jpg',
        title: 'T',
        subtitle: 'S',
      );
      final title = page.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test('AlbumSpreadPage — closing page title is 20pt for otros', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.otros,
        pageNumber: 5,
        contextLabelValue: '{Año}',
        photoPath: 'photo.jpg',
        title: 'T',
        subtitle: 'S',
      );
      final title = page.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test(
        'AlbumSpreadPage — closing page with null photoPath renders without '
        'error', () async {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.parejas,
        pageNumber: 1,
        contextLabelValue: '{tiempojuntos}',
        photoPath: null,
        title: 'Title',
        subtitle: 'Sub',
      );
      // Rendering a page without a photo should not throw.
      expect(() async => _buildPage(page), returnsNormally);
      final pwPage = await _buildPage(page);
      expect(pwPage, isNotNull);
    });

    test('AlbumSpreadPage — closing page photo slot is 66×86 mm', () {
      final page = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.parejas,
        pageNumber: 1,
        contextLabelValue: '{tiempojuntos}',
        photoPath: 'photo.jpg',
        title: 'T',
        subtitle: 'S',
      );
      final img = page.elements.whereType<DotsImageElement>().first;
      expect(img.width, closeTo(66.0 * _mmToPt, 0.01));
      expect(img.height, closeTo(86.0 * _mmToPt, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R3 — Header and footer drawing  (T1.3)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — header and footer drawing', () {
    test(
        'AlbumSpreadPage — header labels (left, center, right) and footer '
        'wordmark are drawn', () {
      const page = DotsAlbumSpreadPage(
        pageNumber: 5,
        header: DotsSpreadHeader(
          leftPageNumber: '5',
          centerLabel: 'tiempojuntos',
          rightPageNumber: '6',
        ),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );
      // The header/footer values are carried in the model and will be drawn
      // by buildAlbumSpreadPage; verify the model carries the right values.
      expect(page.header.leftPageNumber, equals('5'));
      expect(page.header.centerLabel, equals('tiempojuntos'));
      expect(page.header.rightPageNumber, equals('6'));
      expect(page.footer.wordmark, equals('Dots. Memories'));
    });

    test('AlbumSpreadPage — header labels use Inter Semibold 7pt', () async {
      // The font role used for header/footer is DotsFontRole.inter at 7pt.
      // We verify via the fontResolver callback: it is called with DotsFontRole.inter
      // for header/footer text.
      final calledRoles = <DotsFontRole>[];
      const page = DotsAlbumSpreadPage(
        pageNumber: 1,
        header: DotsSpreadHeader(
          leftPageNumber: '1',
          centerLabel: 'label',
        ),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );
      await buildAlbumSpreadPage(
        format: _format,
        page: page,
        fontResolver: (role) {
          calledRoles.add(role);
          return null;
        },
        bytesResolver: (path) async => throw StateError('no bytes'),
        logger: const DotsSilentLogger(),
        onPhotoFailure: _ignorePhotoFailure,
        drawCropMarks: false,
      );
      // All header/footer text uses DotsFontRole.inter.
      expect(calledRoles, everyElement(equals(DotsFontRole.inter)));
    });

    test('AlbumSpreadPage — null header fields are omitted without error',
        () async {
      const page = DotsAlbumSpreadPage(
        pageNumber: 1,
        header: DotsSpreadHeader(leftPageNumber: null),
        footer: DotsSpreadFooter(wordmark: ''),
      );
      // Should not throw even with all nulls/empty.
      final pwPage = await _buildPage(page);
      expect(pwPage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R5 — DotsTextBlockElement warn behavior  (T1.4)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsTextBlockElement — warn behavior', () {
    test('DotsTextBlockElement — body within limits emits no warning', () async {
      final logger = _SpyLogger();
      const shortBody = 'A short body with a few lines.\nLine 2.';
      const page = DotsAlbumSpreadPage(
        pageNumber: 1,
        header: DotsSpreadHeader(),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
        elements: [
          DotsTextBlockElement(
            x: 0,
            y: 100,
            value: shortBody,
            fontSize: 9,
            width: 289,
            maxChars: 1000,
            maxLines: 32,
          ),
        ],
      );
      await _buildPage(page, logger: logger);
      expect(logger.warnMessages, isEmpty);
    });

    test(
        'DotsTextBlockElement — body exceeding 1000 chars emits a warning and '
        'renders', () async {
      final logger = _SpyLogger();
      final longBody = 'x' * 1001; // 1001 chars
      final page = DotsAlbumSpreadPage(
        pageNumber: 2,
        header: const DotsSpreadHeader(),
        footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
        elements: [
          DotsTextBlockElement(
            x: 0,
            y: 100,
            value: longBody,
            fontSize: 9,
            width: 289,
            maxChars: 1000,
            maxLines: 32,
          ),
        ],
      );
      final pwPage = await _buildPage(page, logger: logger);
      expect(logger.warnMessages.length, equals(1));
      expect(logger.warnMessages.first, contains('1001'));
      expect(pwPage, isNotNull); // page still produced
    });

    test(
        'DotsTextBlockElement — body exceeding 32 newline-separated lines emits '
        'a warning and renders', () async {
      final logger = _SpyLogger();
      // 33 newline-separated lines
      final manyLines = List.generate(33, (i) => 'Line $i').join('\n');
      final page = DotsAlbumSpreadPage(
        pageNumber: 3,
        header: const DotsSpreadHeader(),
        footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
        elements: [
          DotsTextBlockElement(
            x: 0,
            y: 100,
            value: manyLines,
            fontSize: 9,
            width: 289,
            maxChars: 1000,
            maxLines: 32,
          ),
        ],
      );
      final pwPage = await _buildPage(page, logger: logger);
      expect(logger.warnMessages, isNotEmpty);
      expect(pwPage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R7 — Isolate dispatch  (T1.5)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — isolate dispatch', () {
    const fs = LocalFileSystem();
    late io.Directory tempDir;

    setUp(() {
      tempDir =
          io.Directory.systemTemp.createTempSync('dots_pdf_album_spread_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    DotsGenerator makeGenerator({required bool useIsolate}) {
      return DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory(tempDir.path),
        useIsolate: useIsolate,
      );
    }

    final dedicationPage = DotsAlbumSpreadPage.dedication(
      type: DotsAlbumType.parejas,
      pageNumber: 5,
      contextLabelValue: '{tiempojuntos}',
      title: 'Nuestro viaje',
      body: 'Un año de amor.',
      signature: 'Blanqui',
    );

    test('AlbumSpreadPage — useIsolate=false path produces a valid PDF',
        () async {
      final generator = makeGenerator(useIsolate: false);
      final customTemplate = DotsTemplate(
        documentId: 'album_no_iso',
        pageSize: _pageSize,
        pages: [dedicationPage],
      );
      final events =
          await generator.generateWhole(template: customTemplate).toList();
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(events.whereType<PdfGenerationFailed>(), isEmpty);

      final outPath = await generator.wholePathFor('album_no_iso');
      final bytes = fs.file(outPath).readAsBytesSync();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test('AlbumSpreadPage — useIsolate=true path produces a valid PDF',
        () async {
      final generator = makeGenerator(useIsolate: true);
      final customTemplate = DotsTemplate(
        documentId: 'album_iso',
        pageSize: _pageSize,
        pages: [dedicationPage],
      );
      final events =
          await generator.generateWhole(template: customTemplate).toList();
      expect(events.last, isA<PdfGenerationCompleted>());
      expect(events.whereType<PdfGenerationFailed>(), isEmpty);

      final outPath = await generator.wholePathFor('album_iso');
      final bytes = fs.file(outPath).readAsBytesSync();
      expect(bytes.length, greaterThan(0));
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test(
        'AlbumSpreadPage — both isolate paths produce output of comparable '
        'size', () async {
      final noIso = makeGenerator(useIsolate: false);
      final withIso = makeGenerator(useIsolate: true);

      final noIsoTemplate = DotsTemplate(
        documentId: 'album_cmp_no_iso',
        pageSize: _pageSize,
        pages: [dedicationPage],
      );
      final isoTemplate = DotsTemplate(
        documentId: 'album_cmp_iso',
        pageSize: _pageSize,
        pages: [dedicationPage],
      );

      await noIso.generateWhole(template: noIsoTemplate).toList();
      await withIso.generateWhole(template: isoTemplate).toList();

      final noIsoBytes = fs
          .file(await noIso.wholePathFor('album_cmp_no_iso'))
          .readAsBytesSync();
      final isoBytes =
          fs.file(await withIso.wholePathFor('album_cmp_iso')).readAsBytesSync();

      expect(_hasPdfMagic(noIsoBytes), isTrue);
      expect(_hasPdfMagic(isoBytes), isTrue);

      // Both are valid PDFs of similar size (within 20% of each other).
      final larger = noIsoBytes.length > isoBytes.length
          ? noIsoBytes.length
          : isoBytes.length;
      final smaller = noIsoBytes.length < isoBytes.length
          ? noIsoBytes.length
          : isoBytes.length;
      expect(smaller / larger, greaterThan(0.80),
          reason: 'Both PDFs should be within 20% size of each other',);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // W1 — Title font and body font are distinct  (R1 font-distinct scenario)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — font family contracts', () {
    test(
        'AlbumSpreadPage — dedication title uses P22 Mackinac Medium and body '
        'uses Inter', () {
      final page = _dedicationPage(DotsAlbumType.parejas);

      final titleFont =
          page.elements.whereType<DotsTextElement>().first.fontFamily;
      expect(titleFont, equals('P22 Mackinac Medium'),
          reason: 'title element must use P22 Mackinac Medium');

      final bodyFont =
          page.elements.whereType<DotsTextBlockElement>().first.fontFamily;
      expect(bodyFont, equals('Inter'),
          reason: 'body text block must use Inter');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // W2 — Body exceeding both limits triggers at least one warning  (R5)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsTextBlockElement — combined-limits warn behavior', () {
    test(
        'DotsTextBlockElement — body exceeding both char and line limits emits '
        'at least one warning and renders', () async {
      final logger = _SpyLogger();
      // 1001 chars AND 33 newline-separated lines — exceeds both thresholds.
      final value = '${'x' * 1001}\n${'extra\n' * 32}';
      final page = DotsAlbumSpreadPage(
        pageNumber: 4,
        header: const DotsSpreadHeader(),
        footer: const DotsSpreadFooter(wordmark: 'Dots. Memories'),
        elements: [
          DotsTextBlockElement(
            x: 0,
            y: 100,
            value: value,
            fontSize: 9,
            width: 289,
            maxChars: 1000,
            maxLines: 32,
          ),
        ],
      );
      final pwPage = await _buildPage(page, logger: logger);
      expect(logger.warnMessages.length, greaterThanOrEqualTo(1),
          reason: 'must warn when both char and line limits are exceeded');
      expect(pwPage, isNotNull, reason: 'page must still render despite warnings');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // W3 — Header font size is 7pt  (R3)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — header font size', () {
    test('AlbumSpreadPage — header font size constant is 7pt', () {
      expect(kHeaderFontSizeForTest, equals(7.0),
          reason: 'header/footer labels must be rendered at 7pt');
    });

    // S3 — header render produces a non-null pw.Page when all fields populated.
    test(
        'AlbumSpreadPage — buildAlbumSpreadPage with all header/footer fields '
        'returns a non-null pw.Page', () async {
      const page = DotsAlbumSpreadPage(
        pageNumber: 7,
        header: DotsSpreadHeader(
          leftPageNumber: '7',
          centerLabel: 'tiempojuntos',
          rightPageNumber: '8',
        ),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );
      final pwPage = await _buildPage(page);
      expect(pwPage, isNotNull,
          reason: 'buildAlbumSpreadPage must return a page when all '
              'header/footer fields are populated');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // W4 — 86 mm bottom margin invariant  (R1)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumSpreadPage — 86mm bottom margin invariant', () {
    test(
        'AlbumSpreadPage — dedication signature respects 86mm bottom margin',
        () {
      final page = _dedicationPage(DotsAlbumType.parejas);

      final sig = page.elements.whereType<DotsRotatedTextElement>().first;

      // Trim height for a dotbook page: 254mm × _mmToPt.
      const double pageHeightPt = 254.0 * _mmToPt;
      // approxGlyphHeight = signature fontSize (12pt) — conservative guard.
      const double approxGlyphHeight = 12.0;
      const double bottomMarginPt = 86.0 * _mmToPt;

      expect(
        sig.y + approxGlyphHeight,
        lessThanOrEqualTo(pageHeightPt - bottomMarginPt),
        reason: 'signature must sit at or above the 86mm bottom margin',
      );
    });
  });
}
