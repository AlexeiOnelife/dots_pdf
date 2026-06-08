// Tests for the shared final p1 QR keep-alive spread (closingQrSpread).
//
// Source of truth: docs/specs/02-pareja.md §final p1 (shared across
// otros/hijos/individual and boda/general-eventos). Title, body, and caption
// must be center-aligned; the body copy must match the spec verbatim.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

AlbumQrSpreadContent _closing() => const AlbumQrSpreadContent(
      qrPayload: 'https://dots.example/album',
      placement: AlbumQrSpreadPlacement.closing,
    );

List<DotsTextBlockElement> _textBlocks(DotsAlbumSpreadPage p) =>
    p.elements.whereType<DotsTextBlockElement>().toList();

void main() {
  group('closingQrSpread — final p1 QR keep-alive (docs/specs §final p1)', () {
    late DotsAlbumSpreadPage page;

    setUp(() {
      page = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.parejas,
        pageNumber: 11,
        contextLabelValue: 'Ana y Luis',
        content: _closing(),
      );
    });

    test('title text matches spec and is center-aligned', () {
      final title = _textBlocks(page).firstWhere(
        (e) => e.value == 'Porque algunos recuerdos merecen seguir vivos',
      );
      expect(title.textAlign, equals(DotsTextAlign.center));
    });

    test('body copy matches spec verbatim and is center-aligned', () {
      const expected =
          'Las fotografías capturan momentos. Los vídeos conservan la '
          'emoción…';
      final body = _textBlocks(page).firstWhere(
        (e) => e.value == expected,
        orElse: () => fail('body copy not found; spec body is: $expected'),
      );
      expect(body.textAlign, equals(DotsTextAlign.center));
    });

    test('caption (names line) is center-aligned', () {
      final caption = _textBlocks(page).firstWhere(
        (e) => e.value.contains('disfruta de está última experiencia'),
      );
      expect(caption.textAlign, equals(DotsTextAlign.center));
      expect(caption.value, contains('Ana y Luis'));
    });

    test('does NOT carry the old (non-spec) body sentence', () {
      for (final e in _textBlocks(page)) {
        expect(
          e.value.contains('Las palabras los hacen vivir'),
          isFalse,
          reason: 'old non-spec body copy must be removed',
        );
      }
    });
  });
}
