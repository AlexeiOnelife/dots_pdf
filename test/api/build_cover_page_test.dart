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
      const content = AlbumCoverContent(
        title: 'Mi álbum',
        dateLine: '01/01/2024 | 31/12/2024',
      );
      expect(content.title, equals('Mi álbum'));
      expect(content.dateLine, equals('01/01/2024 | 31/12/2024'));
      expect(content.eyebrowOverride, isNull);
    });

    test('AlbumCoverContent — equality: identical instances are equal', () {
      const a = AlbumCoverContent(title: 'Mi álbum', dateLine: '2024');
      const b = AlbumCoverContent(title: 'Mi álbum', dateLine: '2024');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('AlbumCoverContent — inequality when eyebrowOverride differs', () {
      const a = AlbumCoverContent(title: 'T', dateLine: 'D');
      const b = AlbumCoverContent(
        title: 'T',
        dateLine: 'D',
        eyebrowOverride: 'CUSTOM',
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // buildCoverPageFor — builder contract (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildCoverPageFor — builder contract (R7)', () {
    test('buildCoverPageFor — returns DotsAlbumSpreadPage', () {
      final result = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      expect(result, isA<DotsAlbumSpreadPage>());
    });

    test(
        'buildCoverPageFor — parejas default eyebrow is '
        '"DOTBOOK DE {PROTAGONISTA}" (Task 4 fix)', () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      final eyebrow = page.elements.whereType<DotsTextBlockElement>().first;
      expect(eyebrow.value, equals('DOTBOOK DE {PROTAGONISTA}'));
    });

    test(
        'buildCoverPageFor — hijos default eyebrow is '
        '"DOTBOOK DE {PROTAGONISTA}" (Task 4 fix)', () {
      final page = buildCoverPageFor(
        DotsAlbumType.hijos,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      final eyebrow = page.elements.whereType<DotsTextBlockElement>().first;
      expect(eyebrow.value, equals('DOTBOOK DE {PROTAGONISTA}'));
    });

    test('buildCoverPageFor — eyebrowOverride wins for both types', () {
      for (final type in [DotsAlbumType.parejas, DotsAlbumType.hijos]) {
        final page = buildCoverPageFor(
          type,
          const AlbumCoverContent(
            title: 'T',
            dateLine: 'D',
            eyebrowOverride: 'CUSTOM',
          ),
          pageNumber: 1,
        );
        final eyebrow = page.elements.whereType<DotsTextBlockElement>().first;
        expect(eyebrow.value, equals('CUSTOM'),
            reason: 'eyebrowOverride must win for type $type');
      }
    });

    test(
        'buildCoverPageFor — throws ArgumentError for DotsAlbumType.individuales',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.individuales,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.boda',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.boda,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.otros',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.otros,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test(
        'buildCoverPageFor — geometry identical for parejas vs hijos given same content',
        () {
      final pageP = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      final pageH = buildCoverPageFor(
        DotsAlbumType.hijos,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );

      // 14 circle elements must be identical in position and diameter.
      final circlesP =
          pageP.elements.whereType<DotsDecorativeCircleElement>().toList();
      final circlesH =
          pageH.elements.whereType<DotsDecorativeCircleElement>().toList();
      expect(circlesP.length, equals(14));
      expect(circlesH.length, equals(14));
      for (var i = 0; i < circlesP.length; i++) {
        expect(circlesP[i].x, equals(circlesH[i].x),
            reason: 'circle $i x must match');
        expect(circlesP[i].y, equals(circlesH[i].y),
            reason: 'circle $i y must match');
        expect(circlesP[i].diameter, equals(circlesH[i].diameter),
            reason: 'circle $i diameter must match');
      }

      // Text element positions must match; only the eyebrow value differs.
      final textsP =
          pageP.elements.whereType<DotsTextBlockElement>().toList();
      final textsH =
          pageH.elements.whereType<DotsTextBlockElement>().toList();
      expect(textsP.length, equals(3));
      expect(textsH.length, equals(3));
      // Title (index 1) and date (index 2) must have identical x, y, and value.
      for (var i = 1; i < textsP.length; i++) {
        expect(textsP[i].x, equals(textsH[i].x));
        expect(textsP[i].y, equals(textsH[i].y));
        expect(textsP[i].value, equals(textsH[i].value));
      }
      // Eyebrow (index 0): after the Task 4 fix, BOTH types resolve to the
      // same canonical template `"DOTBOOK DE {PROTAGONISTA}"` — the per-
      // type difference is in the caller's variables-map substitution, not
      // in the factory default.
      expect(textsP[0].value, equals(textsH[0].value));
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
      // Verify AlbumCoverContent is accessible via the public barrel.
      const content = AlbumCoverContent(title: 'T', dateLine: 'D');
      expect(content, isA<AlbumCoverContent>());
      expect(content.eyebrowOverride, isNull);
    });

    test(
        'public API — buildCoverPageFor exported from lib/dots_pdf.dart',
        () {
      // Verify buildCoverPageFor is callable via the public barrel.
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      expect(page, isA<DotsAlbumSpreadPage>());
    });
  });
}
