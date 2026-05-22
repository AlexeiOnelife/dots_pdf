// Tests for the new DotsElement subtypes and DotsAlbumSpreadPage named
// constructors introduced in slice 2 (album-type-simple-pages).
//
// T1.7 status:
//   - DotsRotatedTextElement and DotsTextBlockElement equality tests → GREEN
//     immediately (types are added in T2 of this PR).
//   - DotsAlbumSpreadPage.dedication / .closing smoke tests → RED until
//     T4.1 / T4.2 are completed in PR 2. They call fail() as a placeholder
//     so this file compiles and the pre-existing 237 tests are unaffected.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DotsRotatedTextElement — equality + hashCode (R4 / T1.7)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsRotatedTextElement — equality and hashCode', () {
    const a = DotsRotatedTextElement(
      x: 10,
      y: 20,
      value: 'Blanqui',
      fontSize: 12,
      angleDegrees: 2.0,
    );
    const b = DotsRotatedTextElement(
      x: 10,
      y: 20,
      value: 'Blanqui',
      fontSize: 12,
      angleDegrees: 2.0,
    );
    const c = DotsRotatedTextElement(
      x: 10,
      y: 20,
      value: 'Blanqui',
      fontSize: 12,
      angleDegrees: 5.0,
    );

    test('equal when all fields match', () {
      expect(a, equals(b));
    });

    test('hashCode is consistent with equality', () {
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when angleDegrees differs', () {
      expect(a, isNot(equals(c)));
    });

    test('optional fields default to null', () {
      expect(a.fontFamily, isNull);
      expect(a.colorHex, isNull);
    });

    test('optional fontFamily participates in equality', () {
      const withFont = DotsRotatedTextElement(
        x: 10,
        y: 20,
        value: 'Blanqui',
        fontSize: 12,
        angleDegrees: 2.0,
        fontFamily: 'Biro',
      );
      expect(a, isNot(equals(withFont)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsTextBlockElement — equality + hashCode (R5 / T1.7)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsTextBlockElement — equality and hashCode', () {
    const a = DotsTextBlockElement(
      x: 5,
      y: 15,
      value: 'Un año de amor.',
      fontSize: 9,
      width: 289.13, // ~102 mm in pts
    );
    const b = DotsTextBlockElement(
      x: 5,
      y: 15,
      value: 'Un año de amor.',
      fontSize: 9,
      width: 289.13,
    );
    const c = DotsTextBlockElement(
      x: 5,
      y: 15,
      value: 'Un año de amor.',
      fontSize: 9,
      width: 300.0,
    );

    test('equal when all fields match', () {
      expect(a, equals(b));
    });

    test('hashCode is consistent with equality', () {
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when width differs', () {
      expect(a, isNot(equals(c)));
    });

    test('textAlign defaults to DotsTextAlign.left', () {
      expect(a.textAlign, equals(DotsTextAlign.left));
    });

    test('lineHeight defaults to 1.2', () {
      expect(a.lineHeight, equals(1.2));
    });

    test('maxChars and maxLines default to null', () {
      expect(a.maxChars, isNull);
      expect(a.maxLines, isNull);
    });

    test('textAlign participates in equality', () {
      const centred = DotsTextBlockElement(
        x: 5,
        y: 15,
        value: 'Un año de amor.',
        fontSize: 9,
        width: 289.13,
        textAlign: DotsTextAlign.center,
      );
      expect(a, isNot(equals(centred)));
    });

    test('maxChars participates in equality', () {
      const withMax = DotsTextBlockElement(
        x: 5,
        y: 15,
        value: 'Un año de amor.',
        fontSize: 9,
        width: 289.13,
        maxChars: 1000,
      );
      expect(a, isNot(equals(withMax)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage — backwards compatibility with empty elements (R8)
  // GREEN immediately — this tests slice-1 compat which already works.
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage — empty elements list constructs without error '
      '(slice 1 compat)', () {
    test('empty elements list constructs without error (slice 1 compat)', () {
      const page = DotsAlbumSpreadPage(
        pageNumber: 1,
        header: DotsSpreadHeader(
          leftPageNumber: '1',
          centerLabel: '{Protagonistas}',
        ),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );
      expect(page.elements, isEmpty);
      expect(page.pageNumber, equals(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.dedication — smoke tests (R1 / D4 / T1.7)
  // RED until T4.1 is implemented in PR 2. Named constructors don't exist
  // yet; tests call fail() so the file compiles but tests fail at runtime.
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.dedication — smoke (R1 / D4 / T4.1)', () {
    final page = DotsAlbumSpreadPage.dedication(
      type: DotsAlbumType.parejas,
      pageNumber: 5,
      contextLabelValue: '{tiempojuntos}',
      title: 'Nuestro viaje',
      body: 'Un año de amor.',
      signature: 'Blanqui',
    );

    test('constructs for parejas and elements list is non-empty', () {
      expect(page.elements, isNotEmpty);
    });

    test('has title DotsTextElement as first element', () {
      expect(page.elements.first, isA<DotsTextElement>());
      final title = page.elements.first as DotsTextElement;
      expect(title.value, equals('Nuestro viaje'));
    });

    test('has DotsTextBlockElement for body', () {
      expect(
        page.elements.whereType<DotsTextBlockElement>(),
        isNotEmpty,
      );
      final body = page.elements.whereType<DotsTextBlockElement>().first;
      expect(body.value, equals('Un año de amor.'));
    });

    test('has DotsRotatedTextElement for non-empty signature', () {
      expect(
        page.elements.whereType<DotsRotatedTextElement>(),
        isNotEmpty,
      );
    });

    test('signature element has angleDegrees = 2.0', () {
      final sig = page.elements.whereType<DotsRotatedTextElement>().first;
      expect(sig.angleDegrees, equals(2.0));
    });

    test('empty signature skips rotated element', () {
      final noSig = DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        contextLabelValue: '{tiempojuntos}',
        title: 'T',
        body: 'B',
        signature: '',
      );
      expect(noSig.elements.whereType<DotsRotatedTextElement>(), isEmpty);
    });

    test('header.leftPageNumber matches pageNumber string', () {
      expect(page.header.leftPageNumber, equals('5'));
    });

    test('header.centerLabel matches contextLabelValue', () {
      expect(page.header.centerLabel, equals('{tiempojuntos}'));
    });

    test('footer wordmark is "Dots. Memories"', () {
      expect(page.footer.wordmark, equals('Dots. Memories'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.closing — smoke tests (R2 / D4 / T1.7)
  // RED until T4.2 is implemented in PR 2.
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.closing — smoke (R2 / D4 / T4.2)', () {
    final parejas = DotsAlbumSpreadPage.closing(
      type: DotsAlbumType.parejas,
      pageNumber: 6,
      contextLabelValue: '{tiempojuntos}',
      photoPath: 'photo.jpg',
      title: 'Vivid together',
      subtitle: 'Ana y Luis',
    );

    test('constructs for parejas and elements list is non-empty', () {
      expect(parejas.elements, isNotEmpty);
    });

    test('boda closing title fontSize is 12', () {
      final boda = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.boda,
        pageNumber: 1,
        contextLabelValue: '{Protagonistas}',
        photoPath: 'photo.jpg',
        title: 'Que la vida siga',
        subtitle: '',
      );
      final title = boda.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(12.0));
    });

    test('parejas closing title fontSize is 20', () {
      final title = parejas.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test('hijos closing title fontSize is 20', () {
      final hijos = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.hijos,
        pageNumber: 2,
        contextLabelValue: '{Protagonistas}',
        photoPath: 'photo.jpg',
        title: 'T',
        subtitle: '',
      );
      final title = hijos.elements.whereType<DotsTextElement>().first;
      expect(title.fontSize, equals(20.0));
    });

    test('null photoPath produces page without DotsImageElement', () {
      final noPhoto = DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.parejas,
        pageNumber: 6,
        contextLabelValue: '{tiempojuntos}',
        photoPath: null,
        title: 'Title',
        subtitle: 'Sub',
      );
      expect(noPhoto.elements.whereType<DotsImageElement>(), isEmpty);
    });

    test('header.centerLabel matches contextLabelValue', () {
      expect(parejas.header.centerLabel, equals('{tiempojuntos}'));
    });
  });
}
