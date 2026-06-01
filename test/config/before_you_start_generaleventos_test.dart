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

    test('emits exactly 10 photo slots + 6 cluster text blocks = 16 total',
        () {
      // 10 DotsImageElement (5 left + 5 right) + 6 DotsTextBlockElement
      // (marker + title + body per page, post-fidelity-fix all cluster
      // elements use DotsTextBlockElement for center alignment).
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements, hasLength(16));
    });

    test('Q1 cluster uses "(01)" marker + "Busca un lugar tranquilo" title '
        'at title-x=30.53 mm', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      // First 2 cluster blocks are LEFT-page marker + title.
      expect(blocks[0].value, equals('(01)'));
      expect(blocks[1].value, equals('Busca un lugar tranquilo'));
      // Title/marker at x=30.53 mm (title-box width 141 mm, center-aligned).
      expect(blocks[0].x, closeTo(30.53 * _mmToPt, 0.01));
      expect(blocks[1].x, closeTo(30.53 * _mmToPt, 0.01));
    });

    test('Q2 cluster uses "(02)" marker + "Más allá del papel" title '
        'at spread title-x=203+30.53 mm', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      // Blocks 3-4 are RIGHT-page marker + title (x = 203 + 30.53).
      expect(blocks[3].value, equals('(02)'));
      expect(blocks[4].value, equals('Más allá del papel'));
      expect(blocks[3].x, closeTo((203 + 30.53) * _mmToPt, 0.01));
      expect(blocks[4].x, closeTo((203 + 30.53) * _mmToPt, 0.01));
    });

    test('Q1 body uses generalEventos canonical tú-form copy at body-x=55.309',
        () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      // Body is the 3rd cluster block (marker, title, body).
      expect(blocks[2].value, contains('Encuentra un espacio'));
      expect(blocks[2].value, contains('Siéntate'));
      expect(blocks[2].value, contains('Respira despacio'));
      expect(blocks[2].x, closeTo(55.309 * _mmToPt, 0.01));
    });

    test('Q2 body references the QR / videos preview at body-x=203+55.309',
        () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      // Block 5 (0-indexed) is the right-page Q2 body.
      expect(blocks[5].value, contains('vídeos'));
      expect(blocks[5].value, contains('código QR'));
      expect(blocks[5].x, closeTo((203 + 55.309) * _mmToPt, 0.01));
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

    test('does NOT include the legacy "Antes de empezar el viaje" big '
        'title or the "Pasad la página" CTA (post-fidelity-fix)', () {
      final p = page();
      for (final b in p.elements.whereType<DotsTextBlockElement>()) {
        expect(b.value, isNot(equals('Antes de empezar')));
        expect(b.value, isNot(equals('el viaje')));
        expect(b.value, isNot(contains('Pasad la página')));
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

  group('beforeYouStart — parejas/hijos arms after fidelity fix', () {
    test('parejas emits canonical 16-element shape (post-fidelity-fix)', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        content: _content(),
      );
      // 10 photo slots + 6 cluster text blocks (marker+title+body per
      // page). Same shape as generalEventos/boda/individuales/otros
      // after the fidelity fix dropped the invented leftTitle/leftBody
      // and rightProtagonist/rightCTA elements.
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements, hasLength(16));
    });

    test('parejas Q1 marker is "(Q1)" with parens per pdf02 p.9', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        content: _content(),
      );
      final blocks =
          p.elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].value, equals('(Q1)'));
      expect(blocks[1].value, equals('Buscad vuestro momento'));
      // Q1 body — canonical vosotros copy from pdf02 p.9.
      expect(blocks[2].value, contains('Encontrad un espacio'));
      expect(blocks[2].value, contains('vuestro viaje al pasado'));
    });

    test('parejas Q2 body matches pdf02 p.9 canonical vosotros copy', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        content: _content(),
      );
      final blocks =
          p.elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[3].value, equals('(Q2)'));
      expect(blocks[4].value, equals('Escuchad vuestra historia'));
      // Q2 body — canonical "Hay recuerdos que no caben…" vosotros copy.
      expect(blocks[5].value, contains('habéis ido guardando'));
      expect(blocks[5].value, contains('podréis revivir'));
    });

    test('hijos emits canonical 16-element shape (post-fidelity-fix)', () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.hijos,
        pageNumber: 5,
        content: _content(),
      );
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements, hasLength(16));
    });

    test('hijos Q1/Q2 markers + canonical tú-form bodies from pdf08 p.9',
        () {
      final p = DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.hijos,
        pageNumber: 5,
        content: _content(),
      );
      final blocks =
          p.elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].value, equals('(Q1)'));
      expect(blocks[1].value, equals('Busca un lugar tranquilo'));
      expect(blocks[2].value, contains('Encuentra un espacio'));
      expect(blocks[2].value, contains('tu viaje al pasado'));
      expect(blocks[3].value, equals('(Q2)'));
      expect(blocks[4].value, equals('Escucha los momentos especiales'));
      // pdf08 p.9 Q2 body opens "Hay páginas con recuerdos…" — DISTINCT
      // from the parejas "Hay recuerdos que no caben…".
      expect(blocks[5].value, startsWith('Hay páginas con recuerdos'));
      expect(blocks[5].value, contains('marcaron tu camino'));
      expect(blocks[5].value, contains('mientras crecías'));
    });

    test('post-fidelity-fix: parejas/hijos NO LONGER carry the invented '
        '"Antes de empezar el viaje" leftTitle or "Pasad la página" CTA',
        () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
      ]) {
        final p = DotsAlbumSpreadPage.beforeYouStart(
          type: type,
          pageNumber: 5,
          content: _content(),
        );
        for (final b in p.elements.whereType<DotsTextBlockElement>()) {
          expect(b.value, isNot(equals('Antes de empezar')));
          expect(b.value, isNot(equals('el viaje')));
          expect(b.value, isNot(contains('Pasad la página')));
        }
      }
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
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements, hasLength(16));
    });

    test('Q1 marker "(01)" + title "Encontra tu momento" + tú-form body',
        () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].value, equals('(01)'));
      expect(blocks[1].value, equals('Encontra tu momento'));
      // tú-form body — singular imperatives.
      expect(blocks[2].value, contains('Encuentra un espacio'));
      expect(blocks[2].value, contains('Siéntate'));
      expect(blocks[2].value, contains('Respira despacio'));
      expect(blocks[2].value, contains('tus recuerdos'));
    });

    test('Q2 marker "(02)" + title "Escucha la historia" + tú-form body',
        () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[3].value, equals('(02)'));
      expect(blocks[4].value, equals('Escucha la historia'));
      // tú-form QR references.
      expect(blocks[5].value, contains('encontrarás'));
      expect(blocks[5].value, contains('escanéalo'));
      expect(blocks[5].value, contains('Escucharás'));
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
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements, hasLength(16));
    });

    test('Q1 marker "(01)" + title "Encontrad vuestro momento" + '
        'vosotros body', () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[0].value, equals('(01)'));
      expect(blocks[1].value, equals('Encontrad vuestro momento'));
      expect(blocks[2].value, contains('Encontrad un espacio'));
      expect(blocks[2].value, contains('Sentaos'));
      expect(blocks[2].value, contains('Respirad despacio'));
      expect(blocks[2].value, contains('vuestros recuerdos'));
    });

    test('Q2 marker "(02)" + title "Escuchad la historia" + vosotros body',
        () {
      final blocks =
          page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[3].value, equals('(02)'));
      expect(blocks[4].value, equals('Escuchad la historia'));
      expect(blocks[5].value, contains('encontraréis'));
      expect(blocks[5].value, contains('escaneadlo'));
      expect(blocks[5].value, contains('Escucharéis'));
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
      final indBlocks =
          ind.elements.whereType<DotsTextBlockElement>().toList();
      final otrBlocks =
          otr.elements.whereType<DotsTextBlockElement>().toList();
      // Q1 body (block 2) and Q2 body (block 5) both differ.
      expect(indBlocks[2].value, isNot(equals(otrBlocks[2].value)));
      expect(indBlocks[5].value, isNot(equals(otrBlocks[5].value)));
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
        '(10 slots + 6 cluster blocks)', () {
      final p = page();
      expect(p.elements.whereType<DotsImageElement>(), hasLength(10));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(6));
      expect(p.elements.whereType<DotsTextElement>(), isEmpty);
      expect(p.elements, hasLength(16));
    });

    test('Q1 cluster (marker + title + body) matches generalEventos exactly',
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
      // Q1 marker (block 0), title (block 1), body (block 2) all shared.
      expect(bodaBlocks[0].value, equals('(01)'));
      expect(bodaBlocks[1].value, equals('Busca un lugar tranquilo'));
      expect(bodaBlocks[0].value, equals(geBlocks[0].value));
      expect(bodaBlocks[1].value, equals(geBlocks[1].value));
      expect(bodaBlocks[2].value, equals(geBlocks[2].value));
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
      // Q2 body (block 5) distinct from generalEventos.
      expect(bodaBlocks[5].value, isNot(equals(geBlocks[5].value)));
      expect(bodaBlocks[5].value,
          contains('estuvieron a tu lado en este día tan importante'));
      expect(bodaBlocks[5].value, contains('código QR'));
    });

    test('Q2 marker "(02)" and title match generalEventos', () {
      final blocks = page().elements.whereType<DotsTextBlockElement>().toList();
      expect(blocks[3].value, equals('(02)'));
      expect(blocks[4].value, equals('Más allá del papel'));
    });

    test('does NOT include parejas/hijos invented furniture '
        '(post-fidelity-fix all categories share the same layout)', () {
      final p = page();
      for (final b in p.elements.whereType<DotsTextBlockElement>()) {
        expect(b.value, isNot(equals('Antes de empezar')));
        expect(b.value, isNot(equals('el viaje')));
        expect(b.value, isNot(contains('Pasad la página')));
      }
    });
  });
}
