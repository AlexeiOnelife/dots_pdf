// Tests for buildPhotoArcPageFor — builder contract, per-type QR caption
// defaults, overrides, and ArgumentError for boda (R7, R8, T1.5).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

List<String> _tenPaths() =>
    List.generate(10, (i) => 'photo_${i + 1}.jpg');

AlbumPhotoArcContent _content({
  String? qrCaptionLeftOverride,
  String? qrCaptionRightOverride,
}) =>
    AlbumPhotoArcContent(
      photoPaths: _tenPaths(),
      qrPayloadLeft: 'https://left.example.com',
      qrPayloadRight: 'https://right.example.com',
      dateSubtitle: '01/01/2024 | 31/12/2024',
      qrCaptionLeftOverride: qrCaptionLeftOverride,
      qrCaptionRightOverride: qrCaptionRightOverride,
    );

/// Returns the left [DotsOvalQrElement] from [page.elements].
DotsOvalQrElement _leftOval(DotsAlbumSpreadPage page) =>
    page.elements.whereType<DotsOvalQrElement>().first;

/// Returns the right [DotsOvalQrElement] from [page.elements].
DotsOvalQrElement _rightOval(DotsAlbumSpreadPage page) =>
    page.elements.whereType<DotsOvalQrElement>().last;

// ---------------------------------------------------------------------------

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // AlbumPhotoArcContent — model tests (R5)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumPhotoArcContent — model (R5)', () {
    test(
        'constructs with required fields; title defaults to '
        '"Un año lleno de recuerdos"', () {
      final c = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '01/01/2024 | 31/12/2024',
      );
      expect(c.title, equals('Un año lleno de recuerdos'));
      expect(c.qrCaptionLeftOverride, isNull);
      expect(c.qrCaptionRightOverride, isNull);
      expect(c.photoPaths.length, equals(10));
    });

    test('equality: identical instances are equal', () {
      final a = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '01/01/2024 | 31/12/2024',
      );
      final b = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '01/01/2024 | 31/12/2024',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when qrCaptionLeftOverride differs', () {
      final a = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '01/01/2024 | 31/12/2024',
      );
      final b = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '01/01/2024 | 31/12/2024',
        qrCaptionLeftOverride: 'CUSTOM',
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Public API exports (R12)
  // ──────────────────────────────────────────────────────────────────────────

  group('public API exports (R12)', () {
    test('DotsPhotoCircleElement exported from lib/dots_pdf.dart', () {
      // If DotsPhotoCircleElement is not exported the reference below will not
      // compile — the test failing to compile IS the test failure.
      const element = DotsPhotoCircleElement(
        x: 0,
        y: 0,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      expect(element, isA<DotsElement>());
    });

    test('DotsOvalQrElement exported from lib/dots_pdf.dart', () {
      const element = DotsOvalQrElement(
        x: 0,
        y: 0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'caption',
      );
      expect(element, isA<DotsElement>());
    });

    test('AlbumPhotoArcContent exported from lib/dots_pdf.dart', () {
      final content = AlbumPhotoArcContent(
        photoPaths: _tenPaths(),
        qrPayloadLeft: 'https://l.example.com',
        qrPayloadRight: 'https://r.example.com',
        dateSubtitle: '2024',
      );
      expect(content, isA<AlbumPhotoArcContent>());
    });

    test('buildPhotoArcPageFor exported from lib/dots_pdf.dart', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        AlbumPhotoArcContent(
          photoPaths: _tenPaths(),
          qrPayloadLeft: 'https://l.example.com',
          qrPayloadRight: 'https://r.example.com',
          dateSubtitle: '2024',
        ),
        pageNumber: 1,
        contextLabelValue: 'x',
      );
      expect(page, isA<DotsAlbumSpreadPage>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // buildPhotoArcPageFor — builder contract (R8)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — builder contract (R8)', () {
    test('returns DotsAlbumSpreadPage', () {
      final result = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 9,
        contextLabelValue: '5 años juntos',
      );
      expect(result, isA<DotsAlbumSpreadPage>());
    });

    test('throws ArgumentError for DotsAlbumType.boda', () {
      expect(
        () => buildPhotoArcPageFor(
          DotsAlbumType.boda,
          _content(),
          pageNumber: 9,
          contextLabelValue: 'x',
        ),
        throwsArgumentError,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Per-type QR caption defaults (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — per-type QR caption defaults (R7)', () {
    test('parejas left caption defaults to "Vuestro álbum en digital"', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 9,
        contextLabelValue: 'x',
      );
      expect(_leftOval(page).caption, equals('Vuestro álbum en digital'));
    });

    test('hijos left caption defaults to "Tu album en digital"', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.hijos,
        _content(),
        pageNumber: 9,
        contextLabelValue: 'x',
      );
      expect(_leftOval(page).caption, equals('Tu album en digital'));
    });

    test('individuales left caption defaults to "Tu album en digital"', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.individuales,
        _content(),
        pageNumber: 7,
        contextLabelValue: 'x',
      );
      expect(_leftOval(page).caption, equals('Tu album en digital'));
    });

    test('otros left caption defaults to "Tu album en digital"', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.otros,
        _content(),
        pageNumber: 7,
        contextLabelValue: 'x',
      );
      expect(_leftOval(page).caption, equals('Tu album en digital'));
    });

    test(
        'right caption defaults to "Todos tus hitos en un lugar" for all 4 types',
        () {
      for (final type in [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ]) {
        final page = buildPhotoArcPageFor(
          type,
          _content(),
          pageNumber: 9,
          contextLabelValue: 'x',
        );
        expect(
          _rightOval(page).caption,
          equals('Todos tus hitos en un lugar'),
          reason: 'right caption must match for type $type',
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Caption overrides (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — caption overrides (R7)', () {
    test('qrCaptionLeftOverride wins over per-type default', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        _content(qrCaptionLeftOverride: 'CUSTOM'),
        pageNumber: 9,
        contextLabelValue: 'x',
      );
      expect(_leftOval(page).caption, equals('CUSTOM'));
    });

    test('qrCaptionRightOverride wins over per-type default', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        _content(qrCaptionRightOverride: 'MI QR'),
        pageNumber: 9,
        contextLabelValue: 'x',
      );
      expect(_rightOval(page).caption, equals('MI QR'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Geometry parity across types (R8)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — geometry identical for all 4 supported types',
      () {
    final pages = {
      for (final type in [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ])
        type: buildPhotoArcPageFor(
          type,
          _content(),
          pageNumber: 9,
          contextLabelValue: 'x',
        ),
    };

    test('all 4 types produce identical DotsPhotoCircleElement coordinates',
        () {
      final referenceCircles = pages[DotsAlbumType.parejas]!
          .elements
          .whereType<DotsPhotoCircleElement>()
          .toList();

      for (final type in [
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ]) {
        final circles = pages[type]!
            .elements
            .whereType<DotsPhotoCircleElement>()
            .toList();
        expect(circles.length, equals(referenceCircles.length));
        for (var i = 0; i < circles.length; i++) {
          expect(circles[i].x, equals(referenceCircles[i].x),
              reason: 'type $type circle $i x must match parejas');
          expect(circles[i].y, equals(referenceCircles[i].y),
              reason: 'type $type circle $i y must match parejas');
          expect(circles[i].diameter, equals(referenceCircles[i].diameter),
              reason: 'type $type circle $i diameter must match parejas');
        }
      }
    });

    test('all 4 types produce identical DotsOvalQrElement geometry', () {
      final referenceOvals = pages[DotsAlbumType.parejas]!
          .elements
          .whereType<DotsOvalQrElement>()
          .toList();

      for (final type in [
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ]) {
        final ovals =
            pages[type]!.elements.whereType<DotsOvalQrElement>().toList();
        expect(ovals.length, equals(2));
        for (var i = 0; i < ovals.length; i++) {
          expect(ovals[i].x, equals(referenceOvals[i].x),
              reason: 'type $type oval $i x must match parejas');
          expect(ovals[i].y, equals(referenceOvals[i].y),
              reason: 'type $type oval $i y must match parejas');
          expect(ovals[i].ovalWidth, equals(referenceOvals[i].ovalWidth),
              reason: 'type $type oval $i ovalWidth must match parejas');
          expect(ovals[i].ovalHeight, equals(referenceOvals[i].ovalHeight),
              reason: 'type $type oval $i ovalHeight must match parejas');
        }
      }
    });
  });
}
