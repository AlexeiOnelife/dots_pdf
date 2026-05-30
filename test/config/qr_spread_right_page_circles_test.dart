// Tests for the right-page decorative-circle scatter added to the
// shared closingQrSpread and to the symmetric generalEventos
// openingQrSpread. Source: pdf13_general_eventos_final.pdf p.1
// (diameters) + p.2 (positions).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

AlbumQrSpreadContent _closing() => const AlbumQrSpreadContent(
      qrPayload: 'https://dots.example/album',
      placement: AlbumQrSpreadPlacement.closing,
    );

AlbumQrSpreadContent _opening() => const AlbumQrSpreadContent(
      qrPayload: 'https://dots.example/album',
      placement: AlbumQrSpreadPlacement.opening,
    );

void main() {
  group('closingQrSpread — right-page decorative-circle scatter', () {
    test('emits exactly 28 decorative circles', () {
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      expect(
        p.elements.whereType<DotsDecorativeCircleElement>(),
        hasLength(28),
      );
    });

    test('circles emit regardless of category (shared scatter)', () {
      for (final type in const [
        DotsAlbumType.parejas,
        DotsAlbumType.hijos,
        DotsAlbumType.individuales,
        DotsAlbumType.otros,
        DotsAlbumType.boda,
        DotsAlbumType.generalEventos,
      ]) {
        final p = DotsAlbumSpreadPage.closingQrSpread(
          type: type,
          pageNumber: 13,
          content: _closing(),
        );
        expect(
          p.elements.whereType<DotsDecorativeCircleElement>(),
          hasLength(28),
          reason: '$type should still emit 28 circles',
        );
      }
    });

    test('all circles use light-blue #CDE7F2', () {
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      final circles =
          p.elements.whereType<DotsDecorativeCircleElement>().toList();
      for (final c in circles) {
        expect(c.colorHex, equals('#CDE7F2'));
      }
    });

    test('diameter histogram matches pdf13 p.1 annotations exactly', () {
      // Per pdf13 p.1: 40×2, 13×6, 23×4, 16×1, 56×2, 32×1, 43×3, 8×3,
      // 5×2, 6×1, 9×1, 26×1, 37×1.
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      final diameters = p.elements
          .whereType<DotsDecorativeCircleElement>()
          .map((c) => (c.diameter / _mmToPt).round())
          .toList();
      final hist = <int, int>{};
      for (final d in diameters) {
        hist[d] = (hist[d] ?? 0) + 1;
      }
      expect(hist[5], equals(2));
      expect(hist[6], equals(1));
      expect(hist[8], equals(3));
      expect(hist[9], equals(1));
      expect(hist[13], equals(6));
      expect(hist[16], equals(1));
      expect(hist[23], equals(4));
      expect(hist[26], equals(1));
      expect(hist[32], equals(1));
      expect(hist[37], equals(1));
      expect(hist[40], equals(2));
      expect(hist[43], equals(3));
      expect(hist[56], equals(2));
      expect(diameters.length, equals(28));
    });

    test('all circle X positions land in 137..395 mm (right-page cluster)',
        () {
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      for (final c
          in p.elements.whereType<DotsDecorativeCircleElement>()) {
        final xMm = c.x / _mmToPt;
        // 0.01 mm tolerance absorbs float noise from the mm → pt → mm
        // round-trip through _mmToPt = 2.834645669.
        expect(xMm, greaterThanOrEqualTo(137 - 0.01));
        expect(xMm, lessThanOrEqualTo(395 + 0.01));
      }
    });

    test('all circle Y positions land in 57..238 mm', () {
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      for (final c
          in p.elements.whereType<DotsDecorativeCircleElement>()) {
        final yMm = c.y / _mmToPt;
        expect(yMm, greaterThanOrEqualTo(57 - 0.01));
        expect(yMm, lessThanOrEqualTo(238 + 0.01));
      }
    });

    test('existing left-page content (title/body/QR/caption/bottom) is '
        'unchanged: 5 left-page text+QR elements', () {
      final p = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      // 4 text blocks + 1 QR = 5 left-page elements; 28 circles on right.
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(4));
      expect(p.elements.whereType<DotsOvalQrElement>(), hasLength(1));
      expect(p.elements.whereType<DotsDecorativeCircleElement>(),
          hasLength(28));
      expect(p.elements, hasLength(4 + 1 + 28));
    });
  });

  group('openingQrSpread — shares the same right-page scatter', () {
    test('emits the same 28 circles as closingQrSpread', () {
      final closing = DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        content: _closing(),
      );
      final opening = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _opening(),
      );
      final closingCircles = closing.elements
          .whereType<DotsDecorativeCircleElement>()
          .toList();
      final openingCircles = opening.elements
          .whereType<DotsDecorativeCircleElement>()
          .toList();
      expect(openingCircles.length, equals(closingCircles.length));
      expect(openingCircles.length, equals(28));
      // Same x/y/diameter table — closingQrSpread and openingQrSpread
      // share _kRightPageCircles by reference.
      for (var i = 0; i < 28; i++) {
        expect(openingCircles[i].x, equals(closingCircles[i].x));
        expect(openingCircles[i].y, equals(closingCircles[i].y));
        expect(openingCircles[i].diameter,
            equals(closingCircles[i].diameter));
      }
    });

    test('opening element count is 4 (title/body/QR/caption) + 28 circles',
        () {
      final p = DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        content: _opening(),
      );
      // Opening has 3 text blocks + 1 QR = 4 left-page elements
      // (closing has 1 extra "bottom variable text" line).
      expect(p.elements.whereType<DotsTextBlockElement>(), hasLength(3));
      expect(p.elements.whereType<DotsOvalQrElement>(), hasLength(1));
      expect(p.elements.whereType<DotsDecorativeCircleElement>(),
          hasLength(28));
      expect(p.elements, hasLength(3 + 1 + 28));
    });
  });
}
