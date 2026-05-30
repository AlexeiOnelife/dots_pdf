// Tests for DotsAlbumSpreadPage.beforeJourney — the "Antes de empezar
// el viaje" decorative-circles 2-page instruction spread.
//
// Sources:
//   - parejas       — pdf02 p.10 (vosotros form)
//   - hijos         — pdf08 p.10 (tú form)
//   - individuales  — pdf10 p.8  (tú form, shared body with otros)
//   - otros         — pdf04 p.8  (tú form, identical body to individuales)
//   - boda          — pdf06 p.3  (tú/vosotros mix; "nosotros" closing)
//   - generalEventos— pdf12 p.3  (tú form; "para siempre" closing)
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

DotsAlbumSpreadPage _page(DotsAlbumType type, {String? bodyOverride}) =>
    DotsAlbumSpreadPage.beforeJourney(
      type: type,
      pageNumber: 11,
      content: AlbumBeforeJourneyContent(bodyOverride: bodyOverride),
    );

void main() {
  group('DotsAlbumSpreadPage.beforeJourney — element shape', () {
    test('emits exactly 3 elements: title L1, title L2, body', () {
      for (final type in DotsAlbumType.values) {
        final p = _page(type);
        expect(p.elements, hasLength(3),
            reason: '$type should emit 3 elements');
        expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(3),
            reason: '$type elements should all be DotsTextBlockElement');
      }
    });

    test('all 6 categories construct without throwing', () {
      for (final type in DotsAlbumType.values) {
        expect(() => _page(type), returnsNormally, reason: '$type');
      }
    });
  });

  group('DotsAlbumSpreadPage.beforeJourney — title (shared across all 6)',
      () {
    test('Title L1 is "Antes de empezar" in P22 Mackinac Medium 27pt', () {
      for (final type in DotsAlbumType.values) {
        final blocks =
            _page(type).elements.whereType<DotsTextBlockElement>().toList();
        expect(blocks[0].value, equals('Antes de empezar'));
        expect(blocks[0].fontSize, equals(27.0));
        expect(blocks[0].fontFamily, equals('P22 Mackinac Medium'));
        expect(blocks[0].textAlign, equals(DotsTextAlign.center));
      }
    });

    test('Title L2 is "el viaje" in P22 Mackinac Medium Italic 27pt', () {
      for (final type in DotsAlbumType.values) {
        final blocks =
            _page(type).elements.whereType<DotsTextBlockElement>().toList();
        expect(blocks[1].value, equals('el viaje'));
        expect(blocks[1].fontSize, equals(27.0));
        expect(blocks[1].fontFamily, equals('P22 Mackinac Medium Italic'));
        expect(blocks[1].textAlign, equals(DotsTextAlign.center));
      }
    });

    test('Title is on the RIGHT page (spread x = 203 + 54.083 mm)', () {
      final blocks =
          _page(DotsAlbumType.parejas).elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].x, closeTo((203 + 54.083) * _mmToPt, 0.01));
      expect(blocks[1].x, closeTo((203 + 54.083) * _mmToPt, 0.01));
      expect(blocks[0].width, closeTo(95 * _mmToPt, 0.01));
    });

    test('Title L2 sits ~10.94 mm below L1 (27pt × ~1.148 leading)', () {
      final blocks =
          _page(DotsAlbumType.parejas).elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].y, closeTo(96.2 * _mmToPt, 0.01));
      expect(blocks[1].y, closeTo((96.2 + 10.94) * _mmToPt, 0.01));
    });
  });

  group('DotsAlbumSpreadPage.beforeJourney — per-category body copy', () {
    test('parejas (pdf02 p.10) — vosotros form', () {
      final body =
          _page(DotsAlbumType.parejas).elements.whereType<DotsTextBlockElement>().toList()[2];
      // Distinctive vosotros markers.
      expect(body.value, startsWith('Pensad que esto'));
      expect(body.value, contains('Cerrad los ojos'));
      expect(body.value, contains('Respirad despacio'));
      expect(body.value, contains('Volviendo a veros y escucharos'));
    });

    test('hijos (pdf08 p.10) — tú form', () {
      final body =
          _page(DotsAlbumType.hijos).elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(body.value, startsWith('Piensa que esto'));
      expect(body.value, contains('Cierra los ojos'));
      expect(body.value, contains('Respira despacio'));
      expect(body.value, contains('Y vuelve allí'));
      expect(body.value, contains('tus seres queridos'));
    });

    test('individuales and otros share the SAME body (pdf10 p.8 = pdf04 p.8)',
        () {
      final ind =
          _page(DotsAlbumType.individuales).elements.whereType<DotsTextBlockElement>().toList()[2];
      final otr =
          _page(DotsAlbumType.otros).elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(ind.value, equals(otr.value));
      expect(ind.value, startsWith('Piensa que esto'));
      expect(ind.value, contains('Fragmentos de una historia'));
      expect(ind.value, contains('podrás volver a ver'));
      expect(ind.value, contains('Y vuelve allí'));
    });

    test('boda (pdf06 p.3) — ends with the "nosotros" wedding line', () {
      final body =
          _page(DotsAlbumType.boda).elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(body.value, startsWith('Cierra los ojos un instante'));
      expect(body.value, contains('"yo estuve contigo"'));
      expect(body.value,
          contains('dejasteis de ser dos y empezasteis a ser un nosotros'));
    });

    test('generalEventos (pdf12 p.3) — closes "para siempre"', () {
      final body =
          _page(DotsAlbumType.generalEventos).elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(body.value, startsWith('Cierra los ojos un instante'));
      expect(body.value, contains('momentos compartidos que siguen vivos'));
      expect(body.value, contains('merecía quedarse para siempre'));
      // generalEventos should NOT contain the boda-specific wedding line.
      expect(body.value, isNot(contains('nosotros')));
    });

    test('bodyOverride replaces the per-category default', () {
      final p = _page(DotsAlbumType.parejas, bodyOverride: 'Custom body');
      final body =
          p.elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(body.value, equals('Custom body'));
    });
  });

  group('DotsAlbumSpreadPage.beforeJourney — body typography', () {
    test('Body is Inter Book 9pt, 95 mm wide, center-aligned', () {
      final body =
          _page(DotsAlbumType.parejas).elements.whereType<DotsTextBlockElement>().toList()[2];
      expect(body.fontSize, equals(9.0));
      expect(body.fontFamily, equals('Inter'));
      expect(body.textAlign, equals(DotsTextAlign.center));
      expect(body.width, closeTo(95 * _mmToPt, 0.01));
      // Body sits ~5 mm below the title block bottom.
      expect(body.y, closeTo((96.2 + 19.1 + 5) * _mmToPt, 0.01));
      // Right-page spread coords.
      expect(body.x, closeTo((203 + 54.083) * _mmToPt, 0.01));
    });
  });

  group('DotsAlbumSpreadPage.beforeJourney — chrome', () {
    test('Two-page spread header (leftPageNumber=N, rightPageNumber=N+1)', () {
      final p = DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.parejas,
        pageNumber: 11,
        content: const AlbumBeforeJourneyContent(),
      );
      expect(p.header.leftPageNumber, equals('11'));
      expect(p.header.rightPageNumber, equals('12'));
    });

    test('contextLabelValue populates centerLabel; empty leaves null', () {
      final empty = DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.boda,
        pageNumber: 11,
        content: const AlbumBeforeJourneyContent(),
      );
      expect(empty.header.centerLabel, isNull);
      final labelled = DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.boda,
        pageNumber: 11,
        content: const AlbumBeforeJourneyContent(),
        contextLabelValue: 'Ana y Luis',
      );
      expect(labelled.header.centerLabel, equals('Ana y Luis'));
    });

    test('Footer wordmark is "Dots. Memories"', () {
      expect(_page(DotsAlbumType.parejas).footer.wordmark,
          equals('Dots. Memories'));
    });
  });

  group('AlbumBeforeJourneyContent — value semantics', () {
    test('default constructor sets bodyOverride to null', () {
      const c = AlbumBeforeJourneyContent();
      expect(c.bodyOverride, isNull);
    });

    test('equality + hashCode honor bodyOverride', () {
      const a = AlbumBeforeJourneyContent(bodyOverride: 'X');
      const b = AlbumBeforeJourneyContent(bodyOverride: 'X');
      const c = AlbumBeforeJourneyContent(bodyOverride: 'Y');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
