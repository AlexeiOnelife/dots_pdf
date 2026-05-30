// Tests for DotsAlbumSpreadPage.photoOnlyCover — fills the Task-2 stub
// against pdf10_individual_inicial.pdf p.1. Supports individuales,
// otros, and generalEventos (parejas/hijos use cover(); boda uses
// bodaCover which remains deferred).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

AlbumPhotoOnlyCoverContent _content({
  String photoPath = 'cover.jpg',
  String title = 'Mi Álbum',
  String dateLine = '1 de mayo de 2024 | 31 de diciembre de 2024',
}) =>
    AlbumPhotoOnlyCoverContent(
      photoPath: photoPath,
      title: title,
      dateLine: dateLine,
    );

void main() {
  group('DotsAlbumSpreadPage.photoOnlyCover — guards', () {
    test('accepts individuales, otros, generalEventos', () {
      for (final type in const [
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
        DotsAlbumType.generalEventos,
      ]) {
        expect(
          () => DotsAlbumSpreadPage.photoOnlyCover(
            type: type,
            pageNumber: 2,
            content: _content(),
          ),
          returnsNormally,
          reason: '$type should be accepted',
        );
      }
    });

    test('rejects parejas, hijos, boda', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.boda,
      ]) {
        expect(
          () => DotsAlbumSpreadPage.photoOnlyCover(
            type: type,
            pageNumber: 2,
            content: _content(),
          ),
          throwsArgumentError,
          reason: '$type should be rejected',
        );
      }
    });

    test('asserts photoPath is non-empty', () {
      expect(
        () => DotsAlbumSpreadPage.photoOnlyCover(
          type: DotsAlbumType.individuales,
          pageNumber: 2,
          content: _content(photoPath: ''),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DotsAlbumSpreadPage.photoOnlyCover — element shape', () {
    DotsAlbumSpreadPage page({DotsAlbumType type = DotsAlbumType.individuales}) =>
        DotsAlbumSpreadPage.photoOnlyCover(
          type: type,
          pageNumber: 2,
          content: _content(),
        );

    test('emits exactly 1 photo + 2 text blocks (title + date)', () {
      final p = page();
      expect(p.elements, hasLength(3));
      expect(p.elements.whereType<DotsImageElement>(), hasLength(1));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
    });

    test('photo is 59×73 mm centered at (72, 80.756) mm', () {
      final img = page().elements.whereType<DotsImageElement>().single;
      expect(img.width, closeTo(59 * _mmToPt, 0.01));
      expect(img.height, closeTo(73 * _mmToPt, 0.01));
      expect(img.x, closeTo(72 * _mmToPt, 0.01));
      expect(img.y, closeTo(80.756 * _mmToPt, 0.01));
      expect(img.assetPath, equals('cover.jpg'));
    });

    test('title is content.title at 23pt P22 Mackinac Medium, 120 mm wide', () {
      final title =
          page().elements.whereType<DotsTextBlockElement>().elementAt(0);
      expect(title.value, equals('Mi Álbum'));
      expect(title.fontSize, equals(23.0));
      expect(title.fontFamily, equals('P22 Mackinac Medium'));
      expect(title.textAlign, equals(DotsTextAlign.center));
      expect(title.x, closeTo(41.5 * _mmToPt, 0.01));
      expect(title.width, closeTo(120 * _mmToPt, 0.01));
      // y = photo_y + photo_height + 5 mm = 80.756 + 73 + 5 = 158.756.
      expect(title.y, closeTo(158.756 * _mmToPt, 0.01));
      // line-height ratio = 27.6 / 23 = 1.2.
      expect(title.lineHeight, closeTo(1.2, 0.001));
    });

    test('date is content.dateLine at 9pt Inter Book, 120 mm wide', () {
      final date =
          page().elements.whereType<DotsTextBlockElement>().elementAt(1);
      expect(
        date.value,
        equals('1 de mayo de 2024 | 31 de diciembre de 2024'),
      );
      expect(date.fontSize, equals(9.0));
      expect(date.fontFamily, equals('Inter'));
      expect(date.textAlign, equals(DotsTextAlign.center));
      expect(date.x, closeTo(41.5 * _mmToPt, 0.01));
      expect(date.width, closeTo(120 * _mmToPt, 0.01));
      // y = title_y + 6.635 (title height) + 5 mm = 170.391.
      expect(date.y, closeTo(170.391 * _mmToPt, 0.01));
    });

    test('layout coords are identical for individuales/otros/generalEventos',
        () {
      final pInd = page(type: DotsAlbumType.individuales);
      final pOtr = page(type: DotsAlbumType.otros);
      final pGen = page(type: DotsAlbumType.generalEventos);
      // Photo x/y/width/height match across categories.
      final imgs = [
        pInd.elements.whereType<DotsImageElement>().single,
        pOtr.elements.whereType<DotsImageElement>().single,
        pGen.elements.whereType<DotsImageElement>().single,
      ];
      for (var i = 1; i < imgs.length; i++) {
        expect(imgs[i].x, equals(imgs[0].x));
        expect(imgs[i].y, equals(imgs[0].y));
        expect(imgs[i].width, equals(imgs[0].width));
        expect(imgs[i].height, equals(imgs[0].height));
      }
    });
  });

  group('DotsAlbumSpreadPage.photoOnlyCover — chrome', () {
    test('odd pageNumber places page number on LEFT, even on RIGHT', () {
      final odd = DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 1,
        content: _content(),
      );
      expect(odd.header.leftPageNumber, equals('1'));
      expect(odd.header.rightPageNumber, isNull);

      final even = DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 2,
        content: _content(),
      );
      expect(even.header.leftPageNumber, isNull);
      expect(even.header.rightPageNumber, equals('2'));
    });

    test('contextLabelValue populates centerLabel; empty leaves null', () {
      final empty = DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 2,
        content: _content(),
      );
      expect(empty.header.centerLabel, isNull);

      final labelled = DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 2,
        content: _content(),
        contextLabelValue: '2024',
      );
      expect(labelled.header.centerLabel, equals('2024'));
    });

    test('footer wordmark is "Dots. Memories"', () {
      final p = DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 2,
        content: _content(),
      );
      expect(p.footer.wordmark, equals('Dots. Memories'));
    });
  });
}
