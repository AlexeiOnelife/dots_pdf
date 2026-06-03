// Tests for buildSimplePagesFor and AlbumSimpleContent.
//
// T1.6 — becomes GREEN when T4.3 / T4.4 are implemented (PR 2).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

const _dedicationContent = DedicationContent(
  title: 'Nuestro viaje',
  body: 'Un año de amor.',
  signature: 'Blanqui',
);

const _closingContent = ClosingContent(
  photoPath: 'photo.jpg',
  title: 'Vivid together',
  subtitle: 'Ana y Luis',
);

const _fullContent = AlbumSimpleContent(
  dedication: _dedicationContent,
  closing: _closingContent,
);

// Helper: run buildSimplePagesFor and return pages.
List<DotsAlbumSpreadPage> _build(
  DotsAlbumType type,
  AlbumSimpleContent content, {
  int firstPageNumber = 5,
}) =>
    buildSimplePagesFor(
      type,
      content,
      firstPageNumber: firstPageNumber,
      contextLabelValue: type.contextLabelToken,
    );

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // R6 — page count per album type  (T1.6)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildSimplePagesFor — page count', () {
    test('buildSimplePagesFor — parejas returns [dedication, closing] in order',
        () {
      final pages = _build(DotsAlbumType.parejas, _fullContent);
      expect(pages.length, equals(2));
      // First page has a DotsTextElement (title) — dedication
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isNotEmpty);
      // Second page has a DotsImageElement — closing
      expect(pages[1].elements.whereType<DotsImageElement>(), isNotEmpty);
    });

    test('buildSimplePagesFor — hijos returns [dedication, closing] in order',
        () {
      final pages = _build(DotsAlbumType.hijos, _fullContent);
      expect(pages.length, equals(2));
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isNotEmpty);
      expect(pages[1].elements.whereType<DotsImageElement>(), isNotEmpty);
    });

    test(
        'buildSimplePagesFor — individuales returns [dedication, closing] in '
        'order', () {
      final pages = _build(DotsAlbumType.individuales, _fullContent);
      expect(pages.length, equals(2));
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isNotEmpty);
      expect(pages[1].elements.whereType<DotsImageElement>(), isNotEmpty);
    });

    test('buildSimplePagesFor — otros returns [dedication, closing] in order',
        () {
      final pages = _build(DotsAlbumType.otros, _fullContent);
      expect(pages.length, equals(2));
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isNotEmpty);
      expect(pages[1].elements.whereType<DotsImageElement>(), isNotEmpty);
    });

    test(
        'buildSimplePagesFor — boda returns [closing] only (no dedication)', () {
      final pages = _build(
        DotsAlbumType.boda,
        const AlbumSimpleContent(closing: _closingContent),
      );
      expect(pages.length, equals(1));
      // The single page has an image element (closing), not a rotated signature
      expect(pages[0].elements.whereType<DotsImageElement>(), isNotEmpty);
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R6 — header.centerLabel per album type  (T1.6)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildSimplePagesFor — header.centerLabel', () {
    test(
        'buildSimplePagesFor — hijos header.centerLabel equals '
        '{Protagonistas}', () {
      final pages = _build(DotsAlbumType.hijos, _fullContent);
      for (final p in pages) {
        expect(p.header.centerLabel, equals('{Protagonistas}'));
      }
    });

    test(
        'buildSimplePagesFor — individuales header.centerLabel equals {Año}',
        () {
      final pages = _build(DotsAlbumType.individuales, _fullContent);
      for (final p in pages) {
        expect(p.header.centerLabel, equals('{Año}'));
      }
    });

    test('buildSimplePagesFor — otros header.centerLabel equals {Año} | {Año}',
        () {
      final pages = _build(DotsAlbumType.otros, _fullContent);
      for (final p in pages) {
        expect(p.header.centerLabel, equals('{Año} | {Año}'));
      }
    });

    test(
        'buildSimplePagesFor — parejas header.centerLabel equals '
        '{tiempojuntos}', () {
      final pages = _build(DotsAlbumType.parejas, _fullContent);
      for (final p in pages) {
        expect(p.header.centerLabel, equals('{tiempojuntos}'));
      }
    });

    test(
        'buildSimplePagesFor — boda header.centerLabel equals {Protagonistas}',
        () {
      final pages = _build(
        DotsAlbumType.boda,
        const AlbumSimpleContent(closing: _closingContent),
      );
      for (final p in pages) {
        expect(p.header.centerLabel, equals('{Protagonistas}'));
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // R6 — partial content  (T1.6)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildSimplePagesFor — partial content', () {
    test(
        'buildSimplePagesFor — missing closing content omits closing page', () {
      final pages = _build(
        DotsAlbumType.parejas,
        const AlbumSimpleContent(dedication: _dedicationContent),
      );
      expect(pages.length, equals(1));
      // Only dedication → has rotated signature
      expect(pages[0].elements.whereType<DotsRotatedTextElement>(), isNotEmpty);
    });

    test(
        'buildSimplePagesFor — missing dedication content omits dedication '
        'page', () {
      final pages = _build(
        DotsAlbumType.parejas,
        const AlbumSimpleContent(closing: _closingContent),
      );
      expect(pages.length, equals(1));
      // Only closing → has image element
      expect(pages[0].elements.whereType<DotsImageElement>(), isNotEmpty);
    });

    test(
        'buildSimplePagesFor — both dedication and closing null returns empty '
        'list', () {
      final pages = _build(
        DotsAlbumType.parejas,
        const AlbumSimpleContent(),
      );
      expect(pages, isEmpty);
    });
  });
}
