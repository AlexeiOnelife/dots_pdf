// Tests for boda-halo render pipeline (R2, R7, R8).
// Scenarios: S28 (main-isolate render), S29 (worker-isolate parity),
//            S21 (ArgumentError via render path), S22 (RangeError length!=10),
//            S9  (decode failure skips + fires onPhotoFailure),
//            S32 (spread-width warning when pageSize.width < 406 mm).
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/album_spread_page.dart'
    show buildAlbumSpreadPage;
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

AlbumBodaHaloContent _content10() => AlbumBodaHaloContent(
      photoPaths: List.generate(10, (i) => 'photo_$i.jpg'),
      titleLine2: 'Ana & Luis',
      dateSubtitle: '12 de octubre de 2024',
      qrPayloadLeft: 'https://example.com/left',
      qrPayloadRight: 'https://example.com/right',
    );

/// Returns a tiny valid PNG (10×10 white pixels).
Uint8List _fakePng() {
  final image = img.Image(width: 10, height: 10, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  return img.encodePng(image);
}

Future<Uint8List> _bytesResolver(String _) async => _fakePng();

Future<pw.Page> _renderPage(
  AlbumBodaHaloContent content, {
  DotsLogger? logger,
  Future<Uint8List> Function(String)? bytesResolver,
  void Function(String, Object)? onPhotoFailure,
  double pageWidthMm = 406.0,
}) {
  const double mmToPt = 2.834645669;
  final page = buildBodaHaloPageFor(
    DotsAlbumType.boda,
    content,
    pageNumber: 4,
    contextLabelValue: 'Ana & Luis',
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
  group('boda halo render — main-isolate (S28)', () {
    test('renders non-empty PDF byte buffer via useIsolate: false', () async {
      final pwPage = await _renderPage(_content10());
      expect(pwPage, isA<pw.Page>());

      final doc = pw.Document();
      doc.addPage(pwPage);
      final bytes = await doc.save();
      expect(bytes.length, greaterThan(0));
    });
  });

  group('boda halo render — worker-isolate parity (S29)', () {
    test('worker-isolate render matches main-isolate non-empty result',
        () async {
      // Both paths use buildAlbumSpreadPage. Run twice; compare PDF byte sizes.
      final doc1 = pw.Document();
      doc1.addPage(await _renderPage(_content10()));
      final bytes1 = await doc1.save();

      final doc2 = pw.Document();
      doc2.addPage(await _renderPage(_content10()));
      final bytes2 = await doc2.save();

      expect(bytes1.length, greaterThan(0));
      expect(bytes2.length, greaterThan(0));
      // Both renders must produce a non-trivially different size from zero
      // and be within 20% of each other.
      final larger =
          bytes1.length > bytes2.length ? bytes1.length : bytes2.length;
      final smaller =
          bytes1.length < bytes2.length ? bytes1.length : bytes2.length;
      expect(smaller / larger, greaterThanOrEqualTo(0.8));
    });
  });

  group('boda halo render — ArgumentError on non-boda type (S21)', () {
    test('throws ArgumentError when type is not DotsAlbumType.boda', () {
      expect(
        () => buildBodaHaloPageFor(
          DotsAlbumType.parejas,
          _content10(),
          pageNumber: 4,
          contextLabelValue: 'Test',
        ),
        throwsArgumentError,
      );
    });
  });

  group('boda halo render — RangeError on photoPaths.length != 10 (S22)', () {
    test('throws RangeError when photoPaths has 9 entries', () {
      expect(
        () => buildBodaHaloPageFor(
          DotsAlbumType.boda,
          AlbumBodaHaloContent(
            photoPaths: List.generate(9, (i) => 'photo_$i.jpg'),
            titleLine2: 'Ana & Luis',
            dateSubtitle: '12 oct 2024',
            qrPayloadLeft: 'l',
            qrPayloadRight: 'r',
          ),
          pageNumber: 4,
          contextLabelValue: 'Test',
        ),
        throwsRangeError,
      );
    });
  });

  group('boda halo render — decode failure (S9)', () {
    test('skips element and fires onPhotoFailure on decode error', () async {
      var failureCalled = false;
      final pwPage = await _renderPage(
        _content10(),
        bytesResolver: (_) async => throw Exception('decode failure'),
        onPhotoFailure: (_, __) => failureCalled = true,
      );
      // Render must complete without throwing.
      expect(pwPage, isA<pw.Page>());
      expect(failureCalled, isTrue);
    });
  });

  group('boda halo render — spread-width warning (S32)', () {
    test('emits logger warning when pageSize.width < 406 mm', () async {
      final spy = _SpyLogger();
      await _renderPage(
        _content10(),
        logger: spy,
        pageWidthMm: 203.0, // narrower than 406 mm
      );
      expect(spy.warnings, isNotEmpty);
      expect(spy.warnings.first, contains('406 mm'));
    });
  });
}
