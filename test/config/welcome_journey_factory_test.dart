// Tests for DotsAlbumSpreadPage.welcomeJourney — Task 5 of
// `final-render-refinement`. The factory targets the generalEventos
// initial pliego 2 ("Bienvenido/a a tu viaje al pasado").
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

void main() {
  group('DotsAlbumSpreadPage.welcomeJourney — guards', () {
    test('rejects non-generalEventos types', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
        DotsAlbumType.boda,
      ]) {
        expect(
          () => DotsAlbumSpreadPage.welcomeJourney(
            type: type,
            pageNumber: 3,
            content: const AlbumWelcomeJourneyContent(),
          ),
          throwsArgumentError,
          reason: '$type should be rejected',
        );
      }
    });

    test('accepts generalEventos', () {
      expect(
        () => DotsAlbumSpreadPage.welcomeJourney(
          type: DotsAlbumType.generalEventos,
          pageNumber: 3,
          content: const AlbumWelcomeJourneyContent(),
        ),
        returnsNormally,
      );
    });
  });

  group('DotsAlbumSpreadPage.welcomeJourney — element shape', () {
    DotsAlbumSpreadPage page({
      String? titleOverride,
      String? bodyOverride,
      String contextLabelValue = '',
    }) =>
        DotsAlbumSpreadPage.welcomeJourney(
          type: DotsAlbumType.generalEventos,
          pageNumber: 3,
          content: AlbumWelcomeJourneyContent(
            titleOverride: titleOverride,
            bodyOverride: bodyOverride,
          ),
          contextLabelValue: contextLabelValue,
        );

    test('emits one decorative rect + two text blocks', () {
      final p = page();
      expect(p.elements.whereType<DotsDecorativeRectElement>(), hasLength(1));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
      expect(p.elements, hasLength(3));
    });

    test('decorative rect is 48×60 mm light-blue rounded rectangle at '
        '(77.5, 67) mm', () {
      final rect =
          page().elements.whereType<DotsDecorativeRectElement>().first;
      expect(rect.x, closeTo(77.5 * _mmToPt, 0.01));
      expect(rect.y, closeTo(67 * _mmToPt, 0.01));
      expect(rect.width, closeTo(48 * _mmToPt, 0.01));
      expect(rect.height, closeTo(60 * _mmToPt, 0.01));
      expect(rect.colorHex, equals('#CDE7F2'));
      expect(rect.borderRadius, closeTo(4 * _mmToPt, 0.01));
    });

    test('title block uses canonical Spanish copy when no override', () {
      final blocks = page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks.first.value, contains('Bienvenido/a'));
      expect(blocks.first.value, contains('a tu viaje al pasado'));
      expect(blocks.first.fontSize, equals(18.0));
      expect(blocks.first.fontFamily, equals('P22 Mackinac Medium'));
      expect(blocks.first.textAlign, equals(DotsTextAlign.center));
      expect(blocks.first.width, closeTo(87 * _mmToPt, 0.01));
    });

    test('titleOverride replaces the default title', () {
      final blocks = page(titleOverride: 'Hola viajero')
          .elements
          .whereType<DotsTextBlockElement>()
          .toList();
      expect(blocks.first.value, equals('Hola viajero'));
    });

    test('body block uses canonical Spanish copy when no override', () {
      final blocks = page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks.last.value, contains('puerta que se abre'));
      expect(blocks.last.fontSize, equals(9.0));
      expect(blocks.last.fontFamily, equals('Inter'));
      expect(blocks.last.textAlign, equals(DotsTextAlign.center));
      expect(blocks.last.width, closeTo(87 * _mmToPt, 0.01));
    });

    test('bodyOverride replaces the default body', () {
      final blocks = page(bodyOverride: 'Custom body')
          .elements
          .whereType<DotsTextBlockElement>()
          .toList();
      expect(blocks.last.value, equals('Custom body'));
    });
  });

  group('DotsAlbumSpreadPage.welcomeJourney — chrome', () {
    test('odd pageNumber places page number on the LEFT, even on RIGHT', () {
      final odd = DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 3,
        content: const AlbumWelcomeJourneyContent(),
      );
      expect(odd.header.leftPageNumber, equals('3'));
      expect(odd.header.rightPageNumber, isNull);

      final even = DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 4,
        content: const AlbumWelcomeJourneyContent(),
      );
      expect(even.header.leftPageNumber, isNull);
      expect(even.header.rightPageNumber, equals('4'));
    });

    test('contextLabelValue populates the center label; empty leaves null',
        () {
      final empty = DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 3,
        content: const AlbumWelcomeJourneyContent(),
      );
      expect(empty.header.centerLabel, isNull);

      final labelled = DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 3,
        content: const AlbumWelcomeJourneyContent(),
        contextLabelValue: 'Ana y Luis',
      );
      expect(labelled.header.centerLabel, equals('Ana y Luis'));
    });

    test('footer wordmark is "Dots. Memories"', () {
      final p = DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 3,
        content: const AlbumWelcomeJourneyContent(),
      );
      expect(p.footer.wordmark, equals('Dots. Memories'));
    });
  });
}
