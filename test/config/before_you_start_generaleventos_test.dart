// Tests for the generalEventos arm of DotsAlbumSpreadPage.beforeYouStart
// added in Task 7 of `final-render-refinement`. The generalEventos
// variant uses the "(01)/(02)" chapter cluster layout: 10 photo slots
// plus per-page Q-clusters, with NO left-page main title and NO
// right-page protagonist+CTA (those are parejas/hijos-only furniture).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

AlbumBeforeYouStartContent _content() => AlbumBeforeYouStartContent(
      photoPaths: List<String>.generate(10, (i) => 'photo_$i.jpg'),
    );

void main() {
  group('beforeYouStart(generalEventos) — element shape', () {
    DotsAlbumSpreadPage page() => DotsAlbumSpreadPage.beforeYouStart(
          type: DotsAlbumType.generalEventos,
          pageNumber: 5,
          content: _content(),
        );

    test('emits exactly 10 photo slots + 6 cluster text elements = 16 total',
        () {
      // 10 DotsImageElement (5 left + 5 right) + 2 DotsTextElement per
      // cluster (number + title) × 2 clusters + 1 DotsTextBlockElement per
      // cluster body × 2 clusters = 10 + 4 + 2 = 16.
      // generalEventos has NO leftTitle L1+L2, NO leftBody,
      // NO rightProtagonist, NO rightCta — those are parejas/hijos only.
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextElement>(), hasLength(4));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
      expect(p.elements, hasLength(16));
    });

    test('Q1 cluster uses "(01)" marker + "Busca un lugar tranquilo" title',
        () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      // First 2 DotsTextElement entries are LEFT-page cluster (number + title).
      expect(texts[0].value, equals('(01)'));
      expect(texts[1].value, equals('Busca un lugar tranquilo'));
      // x coords are 55.309 mm on the LEFT page (cluster origin).
      expect(texts[0].x, closeTo(55.309 * _mmToPt, 0.01));
      expect(texts[1].x, closeTo(55.309 * _mmToPt, 0.01));
    });

    test('Q2 cluster uses "(02)" marker + "Más allá del papel" title', () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      // Next 2 entries are RIGHT-page cluster (number + title at x=203+55.309).
      expect(texts[2].value, equals('(02)'));
      expect(texts[3].value, equals('Más allá del papel'));
      expect(texts[2].x, closeTo((203 + 55.309) * _mmToPt, 0.01));
      expect(texts[3].x, closeTo((203 + 55.309) * _mmToPt, 0.01));
    });

    test('Q1 body uses generalEventos canonical Spanish copy (tú-form)', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      // Body opens with the tú-form invitation to be still.
      expect(blocks[0].value, contains('Encuentra un espacio'));
      expect(blocks[0].value, contains('Siéntate'));
      expect(blocks[0].value, contains('Respira despacio'));
    });

    test('Q2 body references the QR / videos preview', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[1].value, contains('vídeos'));
      expect(blocks[1].value, contains('código QR'));
    });

    test('photo slots are 35×46 mm at y=36 mm with 5-position grid', () {
      final imgs = page().elements.whereType<DotsImageElement>().toList();
      const List<double> leftX = [8, 43, 78, 113, 148];
      for (int i = 0; i < 5; i++) {
        expect(imgs[i].width, closeTo(35 * _mmToPt, 0.01));
        expect(imgs[i].height, closeTo(46 * _mmToPt, 0.01));
        expect(imgs[i].x, closeTo(leftX[i] * _mmToPt, 0.01));
        expect(imgs[i].y, closeTo(36 * _mmToPt, 0.01));
        // Right page slots: x = 203 + left_x.
        expect(imgs[5 + i].x, closeTo((203 + leftX[i]) * _mmToPt, 0.01));
        expect(imgs[5 + i].assetPath, equals('photo_${5 + i}.jpg'));
      }
    });

    test('does NOT include parejas/hijos left-page big title text', () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      for (final t in texts) {
        expect(t.value, isNot(equals('Antes de empezar')));
        expect(t.value, isNot(equals('el viaje')));
      }
    });

    test('does NOT include parejas/hijos right-page CTA', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      for (final b in blocks) {
        expect(
          b.value,
          isNot(contains('Pasad la página')),
        );
      }
    });
  });

  group('beforeYouStart(generalEventos) — chrome', () {
    test('two-page spread header with leftPageNumber=N, rightPageNumber=N+1',
        () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.generalEventos,
        pageNumber: 5,
        content: _content(),
      );
      expect(p.header.leftPageNumber, equals('5'));
      expect(p.header.rightPageNumber, equals('6'));
    });

    test('contextLabelValue populates centerLabel', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.generalEventos,
        pageNumber: 5,
        content: _content(),
        contextLabelValue: 'Ana',
      );
      expect(p.header.centerLabel, equals('Ana'));
    });
  });

  group('beforeYouStart — parejas/hijos arms remain intact (regression)', () {
    test('parejas still emits the full element list', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        content: _content(),
      );
      // parejas: 10 photo slots + (leftTitleL1, leftTitleL2,
      // rightProtagonist, q1Number, q1Title, q2Number, q2Title) = 7 text
      // + (leftBody, rightCta, q1Body, q2Body) = 4 text blocks. Total 21.
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextElement>(), hasLength(7));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(4));
      expect(p.elements, hasLength(21));
      // Q1 marker still 'Q1'.
      final texts = p.elements.whereType<DotsTextElement>().toList();
      expect(texts.any((t) => t.value == 'Q1'), isTrue);
      expect(texts.any((t) => t.value == 'Q2'), isTrue);
    });

    test('hijos still emits the full element list', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.hijos,
        pageNumber: 5,
        content: _content(),
      );
      expect(p.elements, hasLength(21));
    });

    test('all 6 categories construct without throwing', () {
      for (final type in DotsAlbumType.values) {
        expect(
          () => DotsAlbumSpreadPage.beforeYouStart(
            type: type,
            pageNumber: 5,
            content: _content(),
          ),
          returnsNormally,
          reason: '$type should construct',
        );
      }
    });
  });

  group('beforeYouStart(individuales) — pdf10 p.7, tú form', () {
    DotsAlbumSpreadPage page() => DotsAlbumSpreadPage.beforeYouStart(
          type: DotsAlbumType.individuales,
          pageNumber: 5,
          content: _content(),
        );

    test('emits the same 16-element shape as generalEventos', () {
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextElement>(), hasLength(4));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
      expect(p.elements, hasLength(16));
    });

    test('Q1 marker "(01)" + title "Encontra tu momento" + tú-form body',
        () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      expect(texts[0].value, equals('(01)'));
      expect(texts[1].value, equals('Encontra tu momento'));
      final body =
          page().elements.whereType<DotsTextBlockElement>().toList()[0];
      // tú-form body — singular imperatives ("Encuentra", "Siéntate", "Respira").
      expect(body.value, contains('Encuentra un espacio'));
      expect(body.value, contains('Siéntate'));
      expect(body.value, contains('Respira despacio'));
      expect(body.value, contains('tus recuerdos'));
    });

    test('Q2 marker "(02)" + title "Escucha la historia" + tú-form body',
        () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      expect(texts[2].value, equals('(02)'));
      expect(texts[3].value, equals('Escucha la historia'));
      final body =
          page().elements.whereType<DotsTextBlockElement>().toList()[1];
      // tú-form QR references — "encontrarás", "llegues", "escanéalo".
      expect(body.value, contains('encontrarás'));
      expect(body.value, contains('escanéalo'));
      expect(body.value, contains('Escucharás'));
    });
  });

  group('beforeYouStart(otros) — pdf04 p.7, vosotros form', () {
    DotsAlbumSpreadPage page() => DotsAlbumSpreadPage.beforeYouStart(
          type: DotsAlbumType.otros,
          pageNumber: 5,
          content: _content(),
        );

    test('emits the same 16-element shape as generalEventos', () {
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextElement>(), hasLength(4));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
      expect(p.elements, hasLength(16));
    });

    test('Q1 marker "(01)" + title "Encontrad vuestro momento" + '
        'vosotros body', () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      expect(texts[0].value, equals('(01)'));
      expect(texts[1].value, equals('Encontrad vuestro momento'));
      final body =
          page().elements.whereType<DotsTextBlockElement>().toList()[0];
      // vosotros imperatives — "Encontrad", "Sentaos", "Respirad", "Dejad".
      expect(body.value, contains('Encontrad un espacio'));
      expect(body.value, contains('Sentaos'));
      expect(body.value, contains('Respirad despacio'));
      expect(body.value, contains('vuestros recuerdos'));
    });

    test('Q2 marker "(02)" + title "Escuchad la historia" + vosotros body',
        () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      expect(texts[2].value, equals('(02)'));
      expect(texts[3].value, equals('Escuchad la historia'));
      final body =
          page().elements.whereType<DotsTextBlockElement>().toList()[1];
      // vosotros QR references — "encontraréis", "lleguéis", "escaneadlo".
      expect(body.value, contains('encontraréis'));
      expect(body.value, contains('escaneadlo'));
      expect(body.value, contains('Escucharéis'));
    });

    test('individuales (tú) and otros (vosotros) differ in body copy', () {
      final ind = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.individuales,
        pageNumber: 5,
        content: _content(),
      );
      final otr = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.otros,
        pageNumber: 5,
        content: _content(),
      );
      final indBodies =
          ind.elements.whereType<DotsTextBlockElement>().toList();
      final otrBodies =
          otr.elements.whereType<DotsTextBlockElement>().toList();
      // Q1 and Q2 bodies BOTH differ (tú vs vosotros throughout).
      expect(indBodies[0].value, isNot(equals(otrBodies[0].value)));
      expect(indBodies[1].value, isNot(equals(otrBodies[1].value)));
    });
  });

  group('beforeYouStart(boda) — shares generalEventos chapter-cluster layout',
      () {
    DotsAlbumSpreadPage page() => DotsAlbumSpreadPage.beforeYouStart(
          type: DotsAlbumType.boda,
          pageNumber: 5,
          content: _content(),
        );

    test('emits the same 16-element shape as generalEventos '
        '(10 slots + 6 cluster texts)', () {
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextElement>(), hasLength(4));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(2));
      expect(p.elements, hasLength(16));
    });

    test('Q1 cluster matches generalEventos exactly (shared "calm" copy)',
        () {
      final boda = page();
      final ge = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.generalEventos,
        pageNumber: 5,
        content: _content(),
      );
      final bodaBlocks =
          boda.elements.whereType<DotsTextBlockElement>().toList();
      final geBlocks =
          ge.elements.whereType<DotsTextBlockElement>().toList();
      // Q1 body (first text block) is shared canonical copy.
      expect(bodaBlocks[0].value, equals(geBlocks[0].value));
      // Q1 marker + title also shared.
      final bodaTexts =
          boda.elements.whereType<DotsTextElement>().toList();
      final geTexts = ge.elements.whereType<DotsTextElement>().toList();
      expect(bodaTexts[0].value, equals('(01)'));
      expect(bodaTexts[1].value, equals('Busca un lugar tranquilo'));
      expect(bodaTexts[0].value, equals(geTexts[0].value));
      expect(bodaTexts[1].value, equals(geTexts[1].value));
    });

    test('Q2 body is boda-specific (wedding-photo + QR copy)', () {
      final boda = page();
      final ge = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.generalEventos,
        pageNumber: 5,
        content: _content(),
      );
      final bodaBlocks =
          boda.elements.whereType<DotsTextBlockElement>().toList();
      final geBlocks =
          ge.elements.whereType<DotsTextBlockElement>().toList();
      // Q2 body distinct from generalEventos.
      expect(bodaBlocks[1].value, isNot(equals(geBlocks[1].value)));
      // boda Q2 body references the wedding-specific phrasing.
      expect(bodaBlocks[1].value,
          contains('estuvieron a tu lado en este día tan importante'));
      expect(bodaBlocks[1].value, contains('código QR'));
    });

    test('Q2 marker and title match generalEventos', () {
      final texts = page().elements.whereType<DotsTextElement>().toList();
      expect(texts[2].value, equals('(02)'));
      expect(texts[3].value, equals('Más allá del papel'));
    });

    test('does NOT include parejas/hijos left-page big title or right CTA',
        () {
      final p = page();
      final texts = p.elements.whereType<DotsTextElement>().toList();
      for (final t in texts) {
        expect(t.value, isNot(equals('Antes de empezar')));
        expect(t.value, isNot(equals('el viaje')));
      }
      final blocks = p.elements.whereType<DotsTextBlockElement>().toList();
      for (final b in blocks) {
        expect(b.value, isNot(contains('Pasad la página')));
      }
    });
  });
}
