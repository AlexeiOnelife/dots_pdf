// Tests for buildBodaHaloPageFor builder and DotsAlbumSpreadPage.bodaHalo
// factory — boda final p2 photo halo (docs/specs/04-boda.md §final p2).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _photoPaths28() => List.generate(28, (i) => 'photo_$i.jpg');

AlbumBodaHaloContent _content28({List<String>? photoPaths}) =>
    AlbumBodaHaloContent(photoPaths: photoPaths ?? _photoPaths28());

DotsAlbumSpreadPage _buildPage({
  DotsAlbumType type = DotsAlbumType.boda,
  AlbumBodaHaloContent? content,
  int pageNumber = 4,
  String contextLabelValue = 'Ana & Luis',
}) =>
    buildBodaHaloPageFor(
      type,
      content ?? _content28(),
      pageNumber: pageNumber,
      contextLabelValue: contextLabelValue,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---------------------------------------------------------------------------
  // AlbumBodaHaloContent value object
  // ---------------------------------------------------------------------------

  group('AlbumBodaHaloContent — list equality on photoPaths', () {
    test('two instances with identical photoPaths are equal', () {
      final a = _content28();
      final b = _content28();
      expect(a, equals(b));
    });

    test('equal instances have same hashCode', () {
      final a = _content28();
      final b = _content28();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different photoPaths entry are not equal', () {
      final a = _content28();
      final b = _content28(
        photoPaths: ['different.jpg', ..._photoPaths28().skip(1)],
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // DotsAlbumSpreadPage.bodaHalo factory
  // ---------------------------------------------------------------------------

  group('DotsAlbumSpreadPage.bodaHalo — 28 photo-circle elements', () {
    test('produces exactly 28 elements', () {
      final page = _buildPage();
      expect(page.elements.length, 28);
    });

    test('every element is a DotsPhotoCircleElement', () {
      final page = _buildPage();
      expect(
        page.elements.whereType<DotsPhotoCircleElement>().length,
        28,
      );
    });

    test('no QR or text elements on the halo page', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsOvalQrElement>(), isEmpty);
      expect(page.elements.whereType<DotsTextElement>(), isEmpty);
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — assetPath propagation', () {
    test('each photo-circle element assetPath matches photoPaths[i]', () {
      final content = _content28();
      final page = _buildPage(content: content);
      final circles =
          page.elements.whereType<DotsPhotoCircleElement>().toList();
      for (var i = 0; i < 28; i++) {
        expect(circles[i].assetPath, content.photoPaths[i]);
      }
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — header trio', () {
    test('header.leftPageNumber equals pageNumber as string', () {
      final page = _buildPage(pageNumber: 4);
      expect(page.header.leftPageNumber, '4');
    });

    test('header.rightPageNumber equals pageNumber+1 as string', () {
      final page = _buildPage(pageNumber: 4);
      expect(page.header.rightPageNumber, '5');
    });

    test('header.centerLabel equals contextLabelValue', () {
      final page = _buildPage(contextLabelValue: 'Ana & Luis');
      expect(page.header.centerLabel, 'Ana & Luis');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — ArgumentError for non-boda type', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      expect(
        () => _buildPage(type: DotsAlbumType.parejas),
        throwsArgumentError,
      );
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — RangeError for wrong length', () {
    test('throws RangeError when photoPaths has 27 entries', () {
      expect(
        () => _buildPage(
          content: _content28(
            photoPaths: List.generate(27, (i) => 'photo_$i.jpg'),
          ),
        ),
        throwsRangeError,
      );
    });

    test('throws RangeError when photoPaths has 29 entries', () {
      expect(
        () => _buildPage(
          content: _content28(
            photoPaths: List.generate(29, (i) => 'photo_$i.jpg'),
          ),
        ),
        throwsRangeError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildBodaHaloPageFor builder
  // ---------------------------------------------------------------------------

  group('buildBodaHaloPageFor — returns DotsAlbumSpreadPage for boda', () {
    test('return type is DotsAlbumSpreadPage', () {
      final result = _buildPage();
      expect(result, isA<DotsAlbumSpreadPage>());
    });
  });

  group('buildBodaHaloPageFor — ArgumentError for non-boda types', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      expect(() => _buildPage(type: DotsAlbumType.parejas), throwsArgumentError);
    });

    test('throws ArgumentError for DotsAlbumType.hijos', () {
      expect(() => _buildPage(type: DotsAlbumType.hijos), throwsArgumentError);
    });

    test('throws ArgumentError for DotsAlbumType.individuales', () {
      expect(
        () => _buildPage(type: DotsAlbumType.individuales),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.otros', () {
      expect(() => _buildPage(type: DotsAlbumType.otros), throwsArgumentError);
    });
  });

  group('buildBodaHaloPageFor — RangeError for photoPaths length mismatch', () {
    test('throws RangeError when photoPaths has 27 entries', () {
      expect(
        () => buildBodaHaloPageFor(
          DotsAlbumType.boda,
          AlbumBodaHaloContent(
            photoPaths: List.generate(27, (i) => 'photo_$i.jpg'),
          ),
          pageNumber: 4,
          contextLabelValue: 'Test',
        ),
        throwsRangeError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Public exports
  // ---------------------------------------------------------------------------

  group('public exports — symbols importable from lib/dots_pdf.dart', () {
    test('AlbumBodaHaloContent is importable via dots_pdf.dart', () {
      final content = _content28();
      expect(content, isA<AlbumBodaHaloContent>());
    });

    test('buildBodaHaloPageFor is importable via dots_pdf.dart', () {
      final page = buildBodaHaloPageFor(
        DotsAlbumType.boda,
        _content28(),
        pageNumber: 4,
        contextLabelValue: 'Test',
      );
      expect(page, isA<DotsAlbumSpreadPage>());
    });
  });
}
