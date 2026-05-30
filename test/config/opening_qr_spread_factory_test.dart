// Tests for DotsAlbumSpreadPage.openingQrSpread — Task 5 of
// `final-render-refinement`. The factory targets the generalEventos
// initial pliego 1 ("Porque algunos recuerdos merecen seguir vivos"
// opening variant). LEFT-page geometry mirrors closingQrSpread; the
// RIGHT-page decorative-circle scatter is deferred pending annotated
// coordinates.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

AlbumQrSpreadContent _content({String? caption}) => AlbumQrSpreadContent(
      qrPayload: 'https://dots.example/album/abc',
      placement: AlbumQrSpreadPlacement.opening,
      captionOverride: caption,
    );

void main() {
  group('DotsAlbumSpreadPage.openingQrSpread — guards', () {
    test('rejects non-generalEventos types', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
        DotsAlbumType.boda,
      ]) {
        expect(
          () => DotsAlbumSpreadPage.openingQrSpread(
            type: type,
            pageNumber: 1,
            content: _content(),
          ),
          throwsArgumentError,
          reason: '$type should be rejected',
        );
      }
    });

    test('accepts generalEventos', () {
      expect(
        () => DotsAlbumSpreadPage.openingQrSpread(
          type: DotsAlbumType.generalEventos,
          pageNumber: 1,
          content: _content(),
        ),
        returnsNormally,
      );
    });

    test('asserts placement is opening', () {
      expect(
        () => DotsAlbumSpreadPage.openingQrSpread(
          type: DotsAlbumType.generalEventos,
          pageNumber: 1,
          content: const AlbumQrSpreadContent(
            qrPayload: 'x',
            placement: AlbumQrSpreadPlacement.closing,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DotsAlbumSpreadPage.openingQrSpread — element shape', () {
    DotsAlbumSpreadPage page({String? caption, String contextLabel = ''}) =>
        DotsAlbumSpreadPage.openingQrSpread(
          type: DotsAlbumType.generalEventos,
          pageNumber: 1,
          content: _content(caption: caption),
          contextLabelValue: contextLabel,
        );

    test('emits title block, body block, QR, caption block — 4 elements', () {
      final p = page();
      expect(p.elements, hasLength(4));
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(3));
      expect(p.elements.whereType<DotsOvalQrElement>(), hasLength(1));
    });

    test('title is the shared "Porque algunos recuerdos…" wording at 23pt',
        () {
      final title = page().elements.whereType<DotsTextBlockElement>().first;
      expect(
        title.value,
        equals('Porque algunos recuerdos merecen seguir vivos'),
      );
      expect(title.fontSize, equals(23.0));
      expect(title.fontFamily, equals('P22 Mackinac Medium'));
      expect(title.x, closeTo(30 * _mmToPt, 0.01));
      expect(title.y, closeTo(50.892 * _mmToPt, 0.01));
      expect(title.width, closeTo(143 * _mmToPt, 0.01));
    });

    test('body block introduces the QR (welcoming, not farewell)', () {
      final body =
          page().elements.whereType<DotsTextBlockElement>().elementAt(1);
      // The opening body should reference the QR; closing's body is about
      // "memories outliving the moment" — distinct copy.
      expect(body.value.toLowerCase(), contains('qr'));
      expect(body.fontSize, equals(9.0));
      expect(body.fontFamily, equals('Inter'));
      expect(body.x, closeTo(30 * _mmToPt, 0.01));
      expect(body.y, closeTo(71.346 * _mmToPt, 0.01));
      expect(body.width, closeTo(92 * _mmToPt, 0.01));
    });

    test('QR block is 27×27 mm square at (30, 94.081) mm with caller payload',
        () {
      final qr = page().elements.whereType<DotsOvalQrElement>().single;
      expect(qr.x, closeTo(30 * _mmToPt, 0.01));
      expect(qr.y, closeTo(94.081 * _mmToPt, 0.01));
      expect(qr.ovalWidth, closeTo(27 * _mmToPt, 0.01));
      expect(qr.ovalHeight, closeTo(27 * _mmToPt, 0.01));
      expect(qr.qrPayload, equals('https://dots.example/album/abc'));
    });

    test('caption defaults to opening-specific copy', () {
      final caption =
          page().elements.whereType<DotsTextBlockElement>().last;
      expect(caption.value, contains('Escanea el QR'));
      expect(caption.x, closeTo(62 * _mmToPt, 0.01));
    });

    test('captionOverride replaces the default caption', () {
      final caption = page(caption: 'Tap me')
          .elements
          .whereType<DotsTextBlockElement>()
          .last;
      expect(caption.value, equals('Tap me'));
    });
  });

  group('DotsAlbumSpreadPage.openingQrSpread — chrome', () {
    test('header sets both leftPageNumber=N and rightPageNumber=N+1', () {
      final p = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _content(),
      );
      expect(p.header.leftPageNumber, equals('1'));
      expect(p.header.rightPageNumber, equals('2'));
    });

    test('contextLabelValue populates centerLabel; empty leaves null', () {
      final empty = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _content(),
      );
      expect(empty.header.centerLabel, isNull);

      final labelled = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _content(),
        contextLabelValue: 'Ana y Luis',
      );
      expect(labelled.header.centerLabel, equals('Ana y Luis'));
    });

    test('footer wordmark is "Dots. Memories"', () {
      final p = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _content(),
      );
      expect(p.footer.wordmark, equals('Dots. Memories'));
    });
  });
}
