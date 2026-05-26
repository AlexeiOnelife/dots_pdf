// Tests for buildBodaClusterPageFor builder (R4, R5, R7).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AlbumBodaClusterContent _content7({
  String body = 'lorem',
  String title = 'Antes de empezar',
  String titleItalicLine = 'el viaje',
}) =>
    AlbumBodaClusterContent(
      photoPaths: List.generate(7, (i) => 'photo_$i.jpg'),
      title: title,
      titleItalicLine: titleItalicLine,
      body: body,
    );

DotsAlbumSpreadPage _buildPage({
  DotsAlbumType type = DotsAlbumType.boda,
  AlbumBodaClusterContent? content,
  int pageNumber = 3,
  String contextLabelValue = 'Ana & Luis',
}) =>
    buildBodaClusterPageFor(
      type,
      content ?? _content7(),
      pageNumber: pageNumber,
      contextLabelValue: contextLabelValue,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('buildBodaClusterPageFor — return type (R7) [PR 2]', () {
    test('returns DotsAlbumSpreadPage for DotsAlbumType.boda', () {
      final result = _buildPage();
      expect(result, isA<DotsAlbumSpreadPage>());
    });
  });

  group('buildBodaClusterPageFor — ArgumentError for non-boda types (R7) [PR 2]', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      expect(
        () => _buildPage(type: DotsAlbumType.parejas),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.hijos', () {
      expect(
        () => _buildPage(type: DotsAlbumType.hijos),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.individuales', () {
      expect(
        () => _buildPage(type: DotsAlbumType.individuales),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.otros', () {
      expect(
        () => _buildPage(type: DotsAlbumType.otros),
        throwsArgumentError,
      );
    });
  });

  group('buildBodaClusterPageFor — RangeError for wrong photoPaths count (R7) [PR 2]', () {
    test('throws RangeError when photoPaths has 6 entries', () {
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

    test('throws RangeError when photoPaths has 8 entries', () {
      expect(
        () => buildBodaClusterPageFor(
          DotsAlbumType.boda,
          AlbumBodaClusterContent(
            photoPaths: List.generate(8, (i) => 'photo_$i.jpg'),
            body: 'lorem',
          ),
          pageNumber: 3,
          contextLabelValue: 'Test',
        ),
        throwsRangeError,
      );
    });
  });

  group('DotsAlbumSpreadPage.bodaCluster — element count (R5) [PR 2]', () {
    test('produces exactly 10 elements', () {
      final page = _buildPage();
      expect(page.elements.length, 10);
    });

    test('contains exactly 7 DotsClusterPhotoElement instances', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsClusterPhotoElement>().length, 7);
    });

    test('contains exactly 2 DotsTextElement instances', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsTextElement>().length, 2);
    });

    test('contains exactly 1 DotsTextBlockElement', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsTextBlockElement>().length, 1);
    });
  });

  group('DotsAlbumSpreadPage.bodaCluster — content propagation (R5) [PR 2]', () {
    test('default title is "Antes de empezar"', () {
      final page = _buildPage();
      final textElements = page.elements.whereType<DotsTextElement>().toList();
      expect(textElements.any((e) => e.value == 'Antes de empezar'), isTrue);
    });

    test('default titleItalicLine is "el viaje"', () {
      final page = _buildPage();
      final textElements = page.elements.whereType<DotsTextElement>().toList();
      expect(textElements.any((e) => e.value == 'el viaje'), isTrue);
    });

    test('each cluster element assetPath matches photoPaths[i]', () {
      final content = _content7();
      final page = _buildPage(content: content);
      final clusterElements =
          page.elements.whereType<DotsClusterPhotoElement>().toList();
      for (var i = 0; i < 7; i++) {
        expect(clusterElements[i].assetPath, content.photoPaths[i]);
      }
    });
  });

  group('DotsAlbumSpreadPage.bodaCluster — header trio (R5) [PR 2]', () {
    test('header.leftPageNumber equals pageNumber as string', () {
      final page = _buildPage(pageNumber: 5);
      expect(page.header.leftPageNumber, '5');
    });

    test('header.rightPageNumber equals pageNumber+1 as string', () {
      final page = _buildPage(pageNumber: 5);
      expect(page.header.rightPageNumber, '6');
    });

    test('header.centerLabel equals contextLabelValue', () {
      final page = _buildPage(contextLabelValue: 'Ana & Luis');
      expect(page.header.centerLabel, 'Ana & Luis');
    });
  });
}
