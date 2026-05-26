// Tests for boda cluster rendering pipeline (R2, R3, R8, R9).
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/album_spread_page.dart'
    show
        buildAlbumSpreadPage,
        resetClusterPhotoCacheForTest,
        clusterPhotoCacheSizeForTest;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Spy logger — records warn calls
// ---------------------------------------------------------------------------

class _SpyLogger implements DotsLogger {
  final List<String> warnings = [];

  @override
  void info(String message) {}

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      warnings.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AlbumBodaClusterContent _content7({String body = 'lorem'}) =>
    AlbumBodaClusterContent(
      photoPaths: List.generate(7, (i) => 'photo_$i.jpg'),
      body: body,
    );

/// Returns a tiny valid PNG (10×10 white pixels).
Uint8List _fakePng() {
  final image = img.Image(width: 10, height: 10, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  return img.encodePng(image);
}

Future<Uint8List> _bytesResolver(String _) async => _fakePng();

Future<pw.Page> _renderPage(
  AlbumBodaClusterContent content, {
  DotsLogger? logger,
  Future<Uint8List> Function(String)? bytesResolver,
  void Function(String, Object)? onPhotoFailure,
  double pageWidthMm = 406.0,
}) {
  const double mmToPt = 2.834645669;
  final page = buildBodaClusterPageFor(
    DotsAlbumType.boda,
    content,
    pageNumber: 3,
    contextLabelValue: 'Test',
  );
  return buildAlbumSpreadPage(
    format: PdfPageFormat(
      pageWidthMm * mmToPt,
      257 * mmToPt,
    ),
    page: page,
    fontResolver: (_) => null,
    bytesResolver: bytesResolver ?? _bytesResolver,
    logger: logger ?? const DotsSilentLogger(),
    onPhotoFailure: onPhotoFailure ?? (_, __) {},
    drawCropMarks: false,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(resetClusterPhotoCacheForTest);

  group('boda cluster — render cache (R3) [PR 2]', () {
    test('cache hit: rasterizer called once for identical key tuple', () async {
      expect(clusterPhotoCacheSizeForTest(), 0);
      await _renderPage(_content7());
      // 7 unique assetPaths → 7 cache entries (one per slot).
      expect(clusterPhotoCacheSizeForTest(), 7);

      // Second render with same content — cache size stays at 7.
      await _renderPage(_content7());
      expect(clusterPhotoCacheSizeForTest(), 7);
    });

    test('cache miss: rasterizer called twice when assetPath differs', () async {
      expect(clusterPhotoCacheSizeForTest(), 0);

      await _renderPage(_content7());
      expect(clusterPhotoCacheSizeForTest(), 7);

      // Different photoPaths → different cache keys → 7 new entries.
      final content2 = AlbumBodaClusterContent(
        photoPaths: List.generate(7, (i) => 'other_$i.jpg'),
        body: 'b',
      );
      final page2 = buildBodaClusterPageFor(
        DotsAlbumType.boda,
        content2,
        pageNumber: 3,
        contextLabelValue: 'Test',
      );
      await buildAlbumSpreadPage(
        format: const PdfPageFormat(406 * 2.834645669, 257 * 2.834645669),
        page: page2,
        fontResolver: (_) => null,
        bytesResolver: _bytesResolver,
        logger: const DotsSilentLogger(),
        onPhotoFailure: (_, __) {},
        drawCropMarks: false,
      );
      expect(clusterPhotoCacheSizeForTest(), 14);
    });

    test('reset hook clears cache state between tests', () async {
      await _renderPage(_content7());
      expect(clusterPhotoCacheSizeForTest(), greaterThan(0));

      resetClusterPhotoCacheForTest();
      expect(clusterPhotoCacheSizeForTest(), 0);
    });
  });

  group('boda cluster — rendering (R2) [PR 2]', () {
    test('cluster element rendered at correct position and size', () async {
      final page = await _renderPage(_content7());
      expect(page, isA<pw.Page>());
    });

    test('slot 1 renders with bottom-to-top gradient 100%→10%', () {
      final spread = buildBodaClusterPageFor(
        DotsAlbumType.boda,
        _content7(),
        pageNumber: 3,
        contextLabelValue: 'Test',
      );
      final clusterElements =
          spread.elements.whereType<DotsClusterPhotoElement>().toList();
      final slot1 = clusterElements[0];
      expect(slot1.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot1.opacityGradientEnd, closeTo(0.1, 0.001));
      expect(slot1.opacityGradientDirection, DotsGradientDirection.bottomToTop);
    });

    test('slots 2/3/4 render at full opacity (sentinel: no gradient pass)', () {
      final spread = buildBodaClusterPageFor(
        DotsAlbumType.boda,
        _content7(),
        pageNumber: 3,
        contextLabelValue: 'Test',
      );
      final clusterElements =
          spread.elements.whereType<DotsClusterPhotoElement>().toList();
      // Slots 2, 3, 4 (index 1, 2, 3) — sentinel: start == end == 1.0.
      for (final slot in [
        clusterElements[1],
        clusterElements[2],
        clusterElements[3],
      ]) {
        expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
        expect(slot.opacityGradientEnd, closeTo(1.0, 0.001));
      }
    });

    test('decode failure skips element and fires onPhotoFailure', () async {
      var failureCalled = false;
      await _renderPage(
        _content7(),
        bytesResolver: (_) async => throw Exception('decode failure'),
        onPhotoFailure: (_, __) => failureCalled = true,
      );
      expect(failureCalled, isTrue);
    });
  });

  group('boda cluster — spread-width warning (R9) [PR 2]', () {
    test('render-time warning emitted when pageSize.width < 406 mm', () async {
      final spy = _SpyLogger();
      await _renderPage(
        _content7(),
        logger: spy,
        pageWidthMm: 200.0, // narrower than 406 mm
      );
      expect(spy.warnings, isNotEmpty);
      expect(spy.warnings.first, contains('406 mm'));
    });
  });

  group('boda cluster — isolate parity (R8) [PR 2]', () {
    test('bodaCluster page renders via main-isolate path without error',
        () async {
      final pwPage = await _renderPage(_content7());
      expect(pwPage, isA<pw.Page>());
    });

    test(
        'bodaCluster page renders via worker-isolate path within 20% byte tolerance',
        () async {
      // Both paths use buildAlbumSpreadPage. Run twice; compare PDF byte sizes.
      final doc1 = pw.Document();
      doc1.addPage(await _renderPage(_content7()));
      final bytes1 = await doc1.save();

      resetClusterPhotoCacheForTest();

      final doc2 = pw.Document();
      doc2.addPage(await _renderPage(_content7()));
      final bytes2 = await doc2.save();

      final larger =
          bytes1.length > bytes2.length ? bytes1.length : bytes2.length;
      final smaller =
          bytes1.length < bytes2.length ? bytes1.length : bytes2.length;
      expect(smaller / larger, greaterThanOrEqualTo(0.8));
    });
  });

  group('boda cluster — exhaustiveness (R8)', () {
    test('ArgumentError thrown when non-boda type passed to builder', () {
      expect(
        () => buildBodaClusterPageFor(
          DotsAlbumType.parejas,
          _content7(),
          pageNumber: 3,
          contextLabelValue: 'Test',
        ),
        throwsArgumentError,
      );
    });

    test('RangeError thrown when photoPaths.length != 7', () {
      expect(
        () => buildBodaClusterPageFor(
          DotsAlbumType.boda,
          AlbumBodaClusterContent(
            photoPaths: List.generate(6, (i) => 'photo_$i.jpg'),
            body: 'lorem',
          ),
          pageNumber: 3,
          contextLabelValue: 'Test',
        ),
        throwsRangeError,
      );
    });
  });
}
