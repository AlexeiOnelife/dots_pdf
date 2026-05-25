// Tests for buildCoverPageFor, AlbumCoverContent, and the public API exports
// (R4, R6, R7, R9).
//
// T1.4 — All tests are RED until PR 2 implements:
//   - AlbumCoverContent value object (T4.1)
//   - DotsAlbumSpreadPage.cover factory (T4.2)
//   - buildCoverPageFor top-level builder (T4.3)
//   - Public exports in lib/dots_pdf.dart (T5.1)
//
// Placeholder bodies use fail('PR 2: ...') so the file compiles cleanly and
// shows as expected-RED in the test runner until those tasks land.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // AlbumCoverContent value object (R4)
  // ──────────────────────────────────────────────────────────────────────────

  group('AlbumCoverContent — construction and equality (R4)', () {
    test(
        'AlbumCoverContent — constructs with title and dateLine; eyebrowOverride defaults to null',
        () {
      fail(
        'PR 2: AlbumCoverContent not yet implemented',
      );
    });

    test('AlbumCoverContent — equality: identical instances are equal', () {
      fail('PR 2: AlbumCoverContent not yet implemented');
    });

    test('AlbumCoverContent — inequality when eyebrowOverride differs', () {
      fail('PR 2: AlbumCoverContent not yet implemented');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // buildCoverPageFor — builder contract (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildCoverPageFor — builder contract (R7)', () {
    test('buildCoverPageFor — returns DotsAlbumSpreadPage', () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test('buildCoverPageFor — parejas default eyebrow resolves to DOTBOOK',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test(
        'buildCoverPageFor — hijos default eyebrow resolves to DOTBOOK DE {NOMBREHIJO}',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test('buildCoverPageFor — eyebrowOverride wins for both types', () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test(
        'buildCoverPageFor — throws ArgumentError for DotsAlbumType.individuales',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.boda',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.otros',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });

    test(
        'buildCoverPageFor — geometry identical for parejas vs hijos given same content',
        () {
      fail('PR 2: buildCoverPageFor not yet implemented');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Public API exports (R9)
  // ──────────────────────────────────────────────────────────────────────────

  group('public API — exports from lib/dots_pdf.dart (R9)', () {
    test(
        'public API — DotsDecorativeCircleElement exported from lib/dots_pdf.dart',
        () {
      // DotsDecorativeCircleElement is exported via dots_template.dart which
      // is already in lib/dots_pdf.dart — this should be GREEN in PR 1.
      //
      // Verify: constructing the type via the public barrel compiles and
      // the instance has the correct runtime type.
      const element = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
      );
      expect(element, isA<DotsDecorativeCircleElement>());
      expect(element, isA<DotsElement>());
    });

    test('public API — AlbumCoverContent exported from lib/dots_pdf.dart', () {
      fail('PR 2: AlbumCoverContent not yet exported');
    });

    test(
        'public API — buildCoverPageFor exported from lib/dots_pdf.dart',
        () {
      fail('PR 2: buildCoverPageFor not yet exported');
    });
  });
}
