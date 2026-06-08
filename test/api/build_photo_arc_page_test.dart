// Tests for buildPhotoArcPageFor — builder contract and ArgumentError for boda.
//
// Per docs/specs/02-pareja.md §final p2 the photo arc/halo is the halo ALONE
// (28 photo slots); the QR keep-alive lives on final p1 (closingQrSpread).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

List<String> _paths() =>
    List.generate(28, (i) => 'photo_${i + 1}.jpg');

AlbumPhotoArcContent _content() =>
    AlbumPhotoArcContent(photoPaths: _paths());

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // AlbumPhotoArcContent — model tests
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumPhotoArcContent — model', () {
    test('constructs with 28 photo paths', () {
      final c = AlbumPhotoArcContent(photoPaths: _paths());
      expect(c.photoPaths.length, equals(28));
    });

    test('equality: identical instances are equal', () {
      final a = AlbumPhotoArcContent(photoPaths: _paths());
      final b = AlbumPhotoArcContent(photoPaths: _paths());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when photoPaths differ', () {
      final a = AlbumPhotoArcContent(photoPaths: _paths());
      final b = AlbumPhotoArcContent(
        photoPaths: List.generate(28, (i) => 'other_$i.jpg'),
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Public API exports
  // ──────────────────────────────────────────────────────────────────────────

  group('public API exports', () {
    test('DotsPhotoCircleElement exported from lib/dots_pdf.dart', () {
      const element = DotsPhotoCircleElement(
        x: 0,
        y: 0,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      expect(element, isA<DotsElement>());
    });

    test('AlbumPhotoArcContent exported from lib/dots_pdf.dart', () {
      final content = AlbumPhotoArcContent(photoPaths: _paths());
      expect(content, isA<AlbumPhotoArcContent>());
    });

    test('buildPhotoArcPageFor exported from lib/dots_pdf.dart', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        AlbumPhotoArcContent(photoPaths: _paths()),
        pageNumber: 1,
        contextLabelValue: 'x',
      );
      expect(page, isA<DotsAlbumSpreadPage>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // buildPhotoArcPageFor — builder contract
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — builder contract', () {
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

    test('page is the halo ALONE: 28 circles, no ovals, no text', () {
      final page = buildPhotoArcPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 9,
        contextLabelValue: 'x',
      );
      expect(
        page.elements.whereType<DotsPhotoCircleElement>().length,
        equals(28),
      );
      expect(page.elements.whereType<DotsOvalQrElement>(), isEmpty);
      expect(page.elements.whereType<DotsTextElement>(), isEmpty);
      expect(page.elements.length, equals(28));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Geometry parity across types
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

      expect(referenceCircles.length, equals(28));

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
  });
}
