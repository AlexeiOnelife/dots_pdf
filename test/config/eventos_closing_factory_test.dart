// Tests for DotsAlbumSpreadPage.eventosClosing — Task 7 of
// `final-render-refinement`. The factory targets the generalEventos
// final pliego 2 (photo + {TítuloDelAlbum} title; no signature subtitle
// per docs/specs/07-general-eventos.md §final p3).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;
const double _pageWidthPt = 575.43;

AlbumEventosClosingContent _content({
  String? photoPath = 'photo.jpg',
  String title = 'Boda de Ana y Luis',
}) => AlbumEventosClosingContent(photoPath: photoPath, title: title);

void main() {
  group('DotsAlbumSpreadPage.eventosClosing — guards', () {
    test('rejects non-generalEventos types', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
        DotsAlbumType.boda,
      ]) {
        expect(
          () => DotsAlbumSpreadPage.eventosClosing(type: type, pageNumber: 14, content: _content()),
          throwsArgumentError,
          reason: '$type should be rejected',
        );
      }
    });

    test('accepts generalEventos', () {
      expect(
        () => DotsAlbumSpreadPage.eventosClosing(
          type: DotsAlbumType.generalEventos,
          pageNumber: 14,
          content: _content(),
        ),
        returnsNormally,
      );
    });

    test('asserts title is non-empty', () {
      expect(
        () => DotsAlbumSpreadPage.eventosClosing(
          type: DotsAlbumType.generalEventos,
          pageNumber: 14,
          content: _content(title: ''),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DotsAlbumSpreadPage.eventosClosing — element shape', () {
    DotsAlbumSpreadPage page({String? photoPath = 'photo.jpg'}) =>
        DotsAlbumSpreadPage.eventosClosing(
          type: DotsAlbumType.generalEventos,
          pageNumber: 14,
          content: _content(photoPath: photoPath),
        );

    test('emits photo + title only when photoPath is non-null', () {
      final p = page();
      expect(p.elements, hasLength(2));
      expect(p.elements.whereType<DotsImageElement>(), hasLength(1));
      // Title is a centered 115 mm box per docs/specs/07-general-eventos.md
      // §final p3. The base-truth PDF p3 carries no signature subtitle.
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(1));
    });

    test('omits photo when photoPath is null', () {
      final p = page(photoPath: null);
      expect(p.elements, hasLength(1));
      expect(p.elements.whereType<DotsImageElement>(), isEmpty);
    });

    test('photo is 66×86 mm centered horizontally at y=71.534 mm', () {
      final img = page().elements.whereType<DotsImageElement>().single;
      expect(img.width, closeTo(66 * _mmToPt, 0.01));
      expect(img.height, closeTo(86 * _mmToPt, 0.01));
      expect(img.y, closeTo(71.534 * _mmToPt, 0.01));
      // Centered on a 203 mm-wide (575.43 pt) page.
      expect(img.x, closeTo((_pageWidthPt - 66 * _mmToPt) / 2, 0.01));
      expect(img.assetPath, equals('photo.jpg'));
    });

    test('title is content.title at 20pt P22 Mackinac Medium, centered in a '
        '115 mm box at x=44 mm', () {
      final title = page().elements.whereType<DotsTextBlockElement>().single;
      expect(title.value, equals('Boda de Ana y Luis'));
      expect(title.fontSize, equals(20.0));
      expect(title.fontFamily, equals('P22 Mackinac Medium'));
      expect(title.textAlign, equals(DotsTextAlign.center));
      expect(title.lineHeight, closeTo(24.0 / 20.0, 1e-9));
      expect(title.width, closeTo(115 * _mmToPt, 0.01));
      expect(title.x, closeTo(44 * _mmToPt, 0.01));
      // y = photo_y + photo_height + 5 mm.
      expect(title.y, closeTo((71.534 + 86 + 5) * _mmToPt, 0.01));
    });

    test('no signature subtitle is rendered (matches pdf13 p.3)', () {
      final blocks = page().elements.whereType<DotsTextBlockElement>();
      expect(
        blocks.where((b) => b.value.startsWith('Vivido con mucho amor')),
        isEmpty,
      );
    });
  });

  group('DotsAlbumSpreadPage.eventosClosing — chrome', () {
    test('single-page header: leftPageNumber=N, rightPageNumber=N', () {
      final p = DotsAlbumSpreadPage.eventosClosing(
        type: DotsAlbumType.generalEventos,
        pageNumber: 14,
        content: _content(),
      );
      expect(p.header.leftPageNumber, equals('14'));
      expect(p.header.rightPageNumber, equals('14'));
    });

    test('contextLabelValue populates centerLabel; empty leaves null', () {
      final empty = DotsAlbumSpreadPage.eventosClosing(
        type: DotsAlbumType.generalEventos,
        pageNumber: 14,
        content: _content(),
      );
      expect(empty.header.centerLabel, isNull);

      final labelled = DotsAlbumSpreadPage.eventosClosing(
        type: DotsAlbumType.generalEventos,
        pageNumber: 14,
        content: _content(),
        contextLabelValue: 'Ana y Luis',
      );
      expect(labelled.header.centerLabel, equals('Ana y Luis'));
    });

    test('footer wordmark is "Dots. Memories"', () {
      final p = DotsAlbumSpreadPage.eventosClosing(
        type: DotsAlbumType.generalEventos,
        pageNumber: 14,
        content: _content(),
      );
      expect(p.footer.wordmark, equals('Dots. Memories'));
    });
  });
}
