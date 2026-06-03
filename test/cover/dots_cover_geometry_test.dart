import 'package:dots_pdf/src/config/dots_config_exception.dart';
import 'package:dots_pdf/src/cover/dots_cover_geometry.dart';
import 'package:dots_pdf/src/cover/dots_paper_substrate.dart';
import 'package:dots_pdf/src/cover/dots_supplier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Floating-point equality bound for millimetre-scale comparisons.
const double _mmEpsilon = 1e-9;

void main() {
  group('DotsCoverGeometry — spreadsheet rows', () {
    // ---- Table 1: 150 gsm uncoated (one representative page count
    //      from inside each tier; cross-checked against SPECS_cover.md).
    test('uncoated150 A — 20 pages → 6.76 mm spine, 472.76 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 20,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'A');
      expect(g.spineWidthMm, closeTo(6.76, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(472.76, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('uncoated150 B — 60 pages → 11.25 mm spine, 477.25 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 60,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'B');
      expect(g.spineWidthMm, closeTo(11.25, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(477.25, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('uncoated150 C — 100 pages → 15.75 mm spine, 481.75 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 100,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'C');
      expect(g.spineWidthMm, closeTo(15.75, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(481.75, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('uncoated150 D — 132 pages → 20.24 mm spine, 486.24 × 306', () {
      // Sanity-check row called out explicitly in SPECS_cover.md.
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 132,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'D');
      expect(g.spineWidthMm, closeTo(20.24, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(486.24, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('uncoated150 E — 180 pages → 24.74 mm spine, 490.74 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 180,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'E');
      expect(g.spineWidthMm, closeTo(24.74, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(490.74, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('uncoated150 F — 220 pages → 29.24 mm spine, 495.24 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 220,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'F');
      expect(g.spineWidthMm, closeTo(29.24, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(495.24, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    // ---- Table 2: Satin 170 / Gloss 200 (one representative page
    //      count from inside each tier; cross-checked against
    //      SPECS_cover.md).
    test('satin170 A — 32 pages → 6.76 mm spine, 472.76 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 32,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'A');
      expect(g.spineWidthMm, closeTo(6.76, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(472.76, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('satin170 B — 80 pages → 11.25 mm spine, 477.25 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 80,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'B');
      expect(g.spineWidthMm, closeTo(11.25, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(477.25, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('gloss200 C — 120 pages → 15.75 mm spine, 481.75 × 306', () {
      // Same table as satin170; exercise gloss200 path here.
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 120,
        paperSubstrate: DotsPaperSubstrate.gloss200,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'C');
      expect(g.spineWidthMm, closeTo(15.75, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(481.75, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('satin170 D — 180 pages → 20.24 mm spine, 486.24 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 180,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'D');
      expect(g.spineWidthMm, closeTo(20.24, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(486.24, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('satin170 E — 220 pages → 24.74 mm spine, 490.74 × 306', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 220,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'E');
      expect(g.spineWidthMm, closeTo(24.74, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(490.74, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });

    test('satin170 F — 280 pages → 29.24 mm spine, 495.24 × 306', () {
      // Letter F on Table 2 (252–300) is reachable for coated stock,
      // whose per-substrate cap is 300 (not 250).
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 280,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'F');
      expect(g.spineWidthMm, closeTo(29.24, _mmEpsilon));
      expect(g.totalCoverWidthInclBleedMm, closeTo(495.24, _mmEpsilon));
      expect(g.totalCoverHeightInclBleedMm, closeTo(306.0, _mmEpsilon));
    });
  });

  group('DotsCoverGeometry — tier boundary transitions', () {
    // NOTE: every input must be a multiple of 4 (SPECS rule). The
    // spreadsheet ranges include odd-multiple-of-2 endpoints (42, 50,
    // 202, 242, 250) but those are unreachable through the constructor;
    // we cover the nearest in-range %4-valid neighbours and assert
    // separately that the unreachable endpoints throw.

    test('uncoated150 A→B transition: 40 → A, 44 → B (42 rejected)', () {
      final DotsCoverGeometry low = DotsCoverGeometry(
        pageCount: 40,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      final DotsCoverGeometry high = DotsCoverGeometry(
        pageCount: 44,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(low.spineLetter, 'A');
      expect(low.spineWidthMm, closeTo(6.76, _mmEpsilon));
      expect(high.spineLetter, 'B');
      expect(high.spineWidthMm, closeTo(11.25, _mmEpsilon));

      expect(
        () => DotsCoverGeometry(
          pageCount: 42,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('satin170 A→B transition: 48 → A, 52 → B (50 rejected)', () {
      final DotsCoverGeometry low = DotsCoverGeometry(
        pageCount: 48,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      final DotsCoverGeometry high = DotsCoverGeometry(
        pageCount: 52,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(low.spineLetter, 'A');
      expect(high.spineLetter, 'B');

      expect(
        () => DotsCoverGeometry(
          pageCount: 50,
          paperSubstrate: DotsPaperSubstrate.satin170,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('uncoated150 E→F transition: 200 → E, 204 → F (202 rejected)', () {
      final DotsCoverGeometry low = DotsCoverGeometry(
        pageCount: 200,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      final DotsCoverGeometry high = DotsCoverGeometry(
        pageCount: 204,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(low.spineLetter, 'E');
      expect(high.spineLetter, 'F');
      expect(high.spineWidthMm, closeTo(29.24, _mmEpsilon));
    });

    test('uncoated150 caps near 242: 240 → F, 244 throws (above 242)', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 240,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.spineLetter, 'F');
      expect(g.spineWidthMm, closeTo(29.24, _mmEpsilon));

      // 244 > 242 (tier-table cap) so the tier check should reject it.
      expect(
        () => DotsCoverGeometry(
          pageCount: 244,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
      // 242 itself is not a multiple of 4, so it also throws (different
      // reason, but same outcome from the caller's POV).
      expect(
        () => DotsCoverGeometry(
          pageCount: 242,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('satin170 E→F transition: 248 → E, 252 → F (Table 2 to 300)', () {
      final DotsCoverGeometry e = DotsCoverGeometry(
        pageCount: 248,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(e.spineLetter, 'E');
      expect(e.spineWidthMm, closeTo(24.74, _mmEpsilon));

      // 252 is in tier F for coated stock (252–300) and below the 300 cap.
      final DotsCoverGeometry f = DotsCoverGeometry(
        pageCount: 252,
        paperSubstrate: DotsPaperSubstrate.satin170,
        supplier: DotsSupplier.europa,
      );
      expect(f.spineLetter, 'F');
      expect(f.spineWidthMm, closeTo(29.24, _mmEpsilon));

      // 300 is the satin/gloss ceiling and a valid multiple of 4.
      final DotsCoverGeometry top = DotsCoverGeometry(
        pageCount: 300,
        paperSubstrate: DotsPaperSubstrate.gloss200,
        supplier: DotsSupplier.europa,
      );
      expect(top.spineLetter, 'F');

      // 304 exceeds the 300 satin/gloss cap → throws at $.pageCount.
      expect(
        () => DotsCoverGeometry(
          pageCount: 304,
          paperSubstrate: DotsPaperSubstrate.satin170,
          supplier: DotsSupplier.europa,
        ),
        throwsA(
          isA<DotsConfigException>().having(
            (final DotsConfigException ex) => ex.pointer,
            'pointer',
            r'$.pageCount',
          ),
        ),
      );

      // 252 on uncoated150 still throws: its cap is 250 and tier ceiling 242.
      expect(
        () => DotsCoverGeometry(
          pageCount: 252,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });
  });

  group('DotsCoverGeometry — validation failures', () {
    test('pageCount = 0 → throws (below supplier minimum)', () {
      expect(
        () => DotsCoverGeometry(
          pageCount: 0,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('pageCount = 15 → throws (not multiple of 4 and below floor)', () {
      expect(
        () => DotsCoverGeometry(
          pageCount: 15,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(
          isA<DotsConfigException>().having(
            (final DotsConfigException e) => e.message,
            'message',
            contains('multiple of 4'),
          ),
        ),
      );
    });

    test(
      'pageCount = 22 → throws (not multiple of 4) regardless of supplier',
      () {
        // 22 fails the %4 rule first; the supplier minimum is moot.
        expect(
          () => DotsCoverGeometry(
            pageCount: 22,
            paperSubstrate: DotsPaperSubstrate.uncoated150,
            supplier: DotsSupplier.latam,
          ),
          throwsA(
            isA<DotsConfigException>().having(
              (final DotsConfigException e) => e.message,
              'message',
              contains('multiple of 4'),
            ),
          ),
        );
      },
    );

    test(
      'pageCount = 28 + latam → throws (below latam supplier minimum of 30)',
      () {
        // 28 is a valid multiple of 4 and ≥ europa min (20) but below
        // latam min (30). This is the supplier-only distinction the
        // spec asks us to enforce.
        expect(
          () => DotsCoverGeometry(
            pageCount: 28,
            paperSubstrate: DotsPaperSubstrate.uncoated150,
            supplier: DotsSupplier.latam,
          ),
          throwsA(
            isA<DotsConfigException>().having(
              (final DotsConfigException e) => e.message,
              'message',
              contains('latam'),
            ),
          ),
        );
        // Same value on europa succeeds.
        final DotsCoverGeometry europa = DotsCoverGeometry(
          pageCount: 28,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        );
        expect(europa.spineLetter, 'A');
      },
    );

    test('pageCount = 251 → throws (above library cap of 250)', () {
      expect(
        () => DotsCoverGeometry(
          pageCount: 251,
          paperSubstrate: DotsPaperSubstrate.satin170,
          supplier: DotsSupplier.europa,
        ),
        // 251 is not a multiple of 4, so this trips the %4 guard first;
        // either way, it must throw.
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('pageCount = 300 + uncoated150 → throws (above tier table)', () {
      expect(
        () => DotsCoverGeometry(
          pageCount: 300,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test(r'pointer is $.pageCount on every validation failure', () {
      try {
        DotsCoverGeometry(
          pageCount: 15,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        );
        fail('expected DotsConfigException');
      } on DotsConfigException catch (e) {
        expect(e.pointer, r'$.pageCount');
      }
    });
  });

  group('DotsCoverGeometry — invariants & value semantics', () {
    test('constants match SPECS_cover.md', () {
      expect(DotsCoverGeometry.bookBlockWidthMm, 203);
      expect(DotsCoverGeometry.bookBlockHeightMm, 254);
      expect(DotsCoverGeometry.bleedMm, 3);
      expect(DotsCoverGeometry.hinchMm, 11);
      expect(DotsCoverGeometry.wrapMm, 20);
      expect(DotsCoverGeometry.boardThicknessMm, 2.5);
    });

    test('derived widths chain correctly', () {
      final DotsCoverGeometry g = DotsCoverGeometry(
        pageCount: 132,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(g.frontBackWidthMm, closeTo(199, _mmEpsilon));
      expect(g.frontBackWidthInclHinchMm, closeTo(210, _mmEpsilon));
      expect(g.bookBlockWidthInclBleedMm, closeTo(209, _mmEpsilon));
      expect(g.bookBlockHeightInclBleedMm, closeTo(260, _mmEpsilon));
      expect(g.totalCoverWidthExclBleedMm, closeTo(480.24, _mmEpsilon));
      // h = d + 2·f = 260 + 40 = 300 (see SPECS_cover.md height block).
      expect(g.totalCoverHeightExclBleedMm, closeTo(300, _mmEpsilon));
    });

    test('maxPageCountForSubstrate: uncoated=250, satin/gloss=300', () {
      expect(DotsCoverGeometry.maxPageCount, 250);
      expect(DotsCoverGeometry.satinGlossMaxPageCount, 300);
      expect(
        DotsCoverGeometry.maxPageCountForSubstrate(
          DotsPaperSubstrate.uncoated150,
        ),
        250,
      );
      expect(
        DotsCoverGeometry.maxPageCountForSubstrate(
          DotsPaperSubstrate.satin170,
        ),
        300,
      );
      expect(
        DotsCoverGeometry.maxPageCountForSubstrate(
          DotsPaperSubstrate.gloss200,
        ),
        300,
      );
    });

    test('value-equal instances compare ==', () {
      final DotsCoverGeometry a = DotsCoverGeometry(
        pageCount: 100,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      final DotsCoverGeometry b = DotsCoverGeometry(
        pageCount: 100,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('spineLetter: C'));
    });

    test('different supplier produces different geometry value', () {
      final DotsCoverGeometry europa = DotsCoverGeometry(
        pageCount: 100,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.europa,
      );
      final DotsCoverGeometry latam = DotsCoverGeometry(
        pageCount: 100,
        paperSubstrate: DotsPaperSubstrate.uncoated150,
        supplier: DotsSupplier.latam,
      );
      // Geometry numbers are identical; supplier field is not.
      expect(europa == latam, isFalse);
      expect(
        europa.totalCoverWidthInclBleedMm,
        latam.totalCoverWidthInclBleedMm,
      );
    });
  });

  group('DotsSupplier — crop-mark policy', () {
    test('europa draws crop marks', () {
      expect(DotsSupplier.europa.drawsCropMarks, isTrue);
    });
    test('latam does not draw crop marks', () {
      expect(DotsSupplier.latam.drawsCropMarks, isFalse);
    });
    test('minPageCount: europa=20, latam=30', () {
      expect(DotsSupplier.europa.minPageCount, 20);
      expect(DotsSupplier.latam.minPageCount, 30);
    });
  });
}
