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
    test('parejas/hijos/individuales/otros emit 13 elements: '
        '1 LEFT-page background rect + 7 LEFT-page circles + title L1 + L2 + body + '
        'protagonist names + CTA', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ]) {
        final p = _page(type);
        expect(p.elements, hasLength(13),
            reason: '$type should emit 13 elements');
        expect(p.elements.whereType<DotsDecorativeRectElement>(), hasLength(1),
            reason: '$type should include 1 LEFT-page background rect');
        expect(p.elements.whereType<DotsDecorativeCircleElement>(),
            hasLength(7),
            reason: '$type should include 7 LEFT-page decorative circles');
        expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(5),
            reason: '$type should include 5 text blocks (title L1 + L2 '
                '+ body + protagonist names + CTA)');
      }
    });

    test('boda and generalEventos emit 11 elements: '
        '1 LEFT-page background rect + 7 LEFT-page circles + title L1 + L2 + body '
        '(no right-page chrome)',
        () {
      for (final type in const [
        DotsAlbumType.boda,
        DotsAlbumType.generalEventos,
      ]) {
        final p = _page(type);
        expect(p.elements, hasLength(11),
            reason: '$type should emit 11 elements (rect + 7 circles + 3 text, no chrome)');
        expect(p.elements.whereType<DotsDecorativeRectElement>(), hasLength(1));
        expect(p.elements.whereType<DotsDecorativeCircleElement>(),
            hasLength(7));
        expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(3));
      }
    });

    test('all 6 categories construct without throwing', () {
      for (final type in DotsAlbumType.values) {
        expect(() => _page(type), returnsNormally, reason: '$type');
      }
    });

    test('LEFT-page background rect covers the LEFT page edge-to-edge '
        '(x=0, y=0, w=203 mm, h=254 mm) and uses light-blue #CDE7F2', () {
      final rect = _page(DotsAlbumType.parejas)
          .elements
          .whereType<DotsDecorativeRectElement>()
          .single;
      expect(rect.x, equals(0));
      expect(rect.y, equals(0));
      expect(rect.width, closeTo(203 * _mmToPt, 0.01));
      expect(rect.height, closeTo(254 * _mmToPt, 0.01));
      expect(rect.colorHex, equals('#CDE7F2'));
    });

    test('LEFT-page circles all use light-blue #CDE7F2 and land on the '
        'LEFT page (x < 203 mm)', () {
      final circles = _page(DotsAlbumType.parejas)
          .elements
          .whereType<DotsDecorativeCircleElement>()
          .toList();
      for (final c in circles) {
        expect(c.colorHex, equals('#CDE7F2'));
        // x < 203 mm — circles must be on the LEFT page of the spread.
        expect(c.x / _mmToPt, lessThan(203));
        // opacityAlpha must be in (0, 1] — cluster uses [0.30, 1.00].
        expect(c.opacityAlpha, greaterThan(0));
        expect(c.opacityAlpha, lessThanOrEqualTo(1.0));
      }
    });

    test('LEFT-page cluster is monotonically decreasing in opacity from '
        'top circle (alpha=1.0) to bottom circle (alpha=0.30)', () {
      final circles = _page(DotsAlbumType.generalEventos)
          .elements
          .whereType<DotsDecorativeCircleElement>()
          .toList();
      // Cluster ordering: top-most circle first.
      expect(circles.first.opacityAlpha, equals(1.0));
      expect(circles.last.opacityAlpha, equals(0.30));
    });

    test('background rect is emitted BEFORE circles in the element list '
        '(z-order: rect → circles → text)', () {
      final elements = _page(DotsAlbumType.parejas).elements;
      final rectIdx = elements.indexWhere((e) => e is DotsDecorativeRectElement);
      final firstCircleIdx =
          elements.indexWhere((e) => e is DotsDecorativeCircleElement);
      final firstTextIdx =
          elements.indexWhere((e) => e is DotsTextBlockElement);
      expect(rectIdx, lessThan(firstCircleIdx),
          reason: 'rect must come before circles');
      expect(firstCircleIdx, lessThan(firstTextIdx),
          reason: 'circles must come before text');
    });
  });

  group('DotsAlbumSpreadPage.beforeJourney — right-page chrome', () {
    test('parejas / hijos CTA reads "Pasad la página para empezar '
        'esta experiencia" (pdf02 p.10 / pdf08 p.10)', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
      ]) {
        final cta =
            _page(type).elements.whereType<DotsTextBlockElement>().toList()[4];
        expect(cta.value,
            equals('Pasad la página para empezar esta experiencia'));
        expect(cta.fontSize, equals(15.0));
        expect(cta.fontFamily, equals('P22 Mackinac Medium'));
        expect(cta.width, closeTo(65 * _mmToPt, 0.01));
        // x = 203 + (203 - 65) / 2 = 272 mm.
        expect(cta.x, closeTo((203 + (203 - 65) / 2) * _mmToPt, 0.01));
      }
    });

    test('individuales / otros CTA reads "Pasad la página para vivir '
        'la experiencia" (pdf10 p.8 / pdf04 p.8)', () {
      for (final type in const [
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
      ]) {
        final cta =
            _page(type).elements.whereType<DotsTextBlockElement>().toList()[4];
        expect(cta.value,
            equals('Pasad la página para vivir la experiencia'));
      }
    });

    test('protagonist-names line uses contextLabelValue when provided', () {
      final p = DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.parejas,
        pageNumber: 11,
        content: const AlbumBeforeJourneyContent(),
        contextLabelValue: 'Ana y Luis',
      );
      final names =
          p.elements.whereType<DotsTextBlockElement>().toList()[3];
      expect(names.value, equals('Ana y Luis'));
      expect(names.fontSize, equals(9.0));
      expect(names.fontFamily, equals('Inter'));
      expect(names.width, closeTo(100 * _mmToPt, 0.01));
    });

    test('protagonist-names line falls back to "{Protagonistas}" when '
        'contextLabelValue is empty', () {
      final names =
          _page(DotsAlbumType.hijos).elements.whereType<DotsTextBlockElement>().toList()[3];
      expect(names.value, equals('{Protagonistas}'));
    });

    test('boda and generalEventos do NOT include the CTA or '
        'protagonist-names line', () {
      for (final type in const [
        DotsAlbumType.boda,
        DotsAlbumType.generalEventos,
      ]) {
        final p = _page(type);
        for (final b in p.elements.whereType<DotsTextBlockElement>()) {
          expect(b.value, isNot(contains('Pasad la página')),
              reason: '$type should not include CTA');
          expect(b.value, isNot(contains('{Protagonistas}')),
              reason: '$type should not include protagonist-names line');
        }
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
