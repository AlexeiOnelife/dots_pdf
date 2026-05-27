// Tests for kBodaHaloLayout — 10 entries, unrotated x/y/angle within ±0.001 mm
// of the D1 worked table, uniform 33.5×46.4 mm dims, R5/L5 bleedBottom true,
// all other slots bleedBottom false. Scenarios S10–S14 from R3.
// GREEN immediately: kBodaHaloLayout and kBodaHaloLayoutForTest exist after T2.3.
import 'package:dots_pdf/src/render/boda_halo_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kBodaHaloLayout — entry count (S10)', () {
    test('has exactly 10 entries', () {
      expect(kBodaHaloLayoutForTest.length, 10);
    });
  });

  group('kBodaHaloLayout — uniform dimensions (S11)', () {
    test('all 10 slots have widthMm == 33.5', () {
      for (var i = 0; i < 10; i++) {
        expect(
          kBodaHaloLayoutForTest[i].widthMm,
          closeTo(33.5, 0.001),
          reason: 'slot $i widthMm',
        );
      }
    });

    test('all 10 slots have heightMm == 46.4', () {
      for (var i = 0; i < 10; i++) {
        expect(
          kBodaHaloLayoutForTest[i].heightMm,
          closeTo(46.4, 0.001),
          reason: 'slot $i heightMm',
        );
      }
    });
  });

  group('kBodaHaloLayout — right-page slot angles positive (S12)', () {
    test('R1 angleDegrees == +3.2', () {
      expect(kBodaHaloLayoutForTest[0].angleDegrees, closeTo(3.2, 0.001));
    });
    test('R2 angleDegrees == +20.7', () {
      expect(kBodaHaloLayoutForTest[1].angleDegrees, closeTo(20.7, 0.001));
    });
    test('R3 angleDegrees == +37.2', () {
      expect(kBodaHaloLayoutForTest[2].angleDegrees, closeTo(37.2, 0.001));
    });
    test('R4 angleDegrees == +55.2', () {
      expect(kBodaHaloLayoutForTest[3].angleDegrees, closeTo(55.2, 0.001));
    });
    test('R5 angleDegrees == +68.3', () {
      expect(kBodaHaloLayoutForTest[4].angleDegrees, closeTo(68.3, 0.001));
    });

    test('all R slots (0–4) have strictly positive angleDegrees', () {
      for (var i = 0; i < 5; i++) {
        expect(
          kBodaHaloLayoutForTest[i].angleDegrees,
          greaterThan(0),
          reason: 'R-slot $i should be positive',
        );
      }
    });
  });

  group('kBodaHaloLayout — left-page slot angles negative (S13)', () {
    test('L1 angleDegrees == -3.2', () {
      expect(kBodaHaloLayoutForTest[5].angleDegrees, closeTo(-3.2, 0.001));
    });
    test('L2 angleDegrees == -20.7', () {
      expect(kBodaHaloLayoutForTest[6].angleDegrees, closeTo(-20.7, 0.001));
    });
    test('L3 angleDegrees == -37.2', () {
      expect(kBodaHaloLayoutForTest[7].angleDegrees, closeTo(-37.2, 0.001));
    });
    test('L4 angleDegrees == -55.2', () {
      expect(kBodaHaloLayoutForTest[8].angleDegrees, closeTo(-55.2, 0.001));
    });
    test('L5 angleDegrees == -68.3', () {
      expect(kBodaHaloLayoutForTest[9].angleDegrees, closeTo(-68.3, 0.001));
    });
  });

  group('kBodaHaloLayout — unrotated top-left coords vs D1 table (S10–S14)', () {
    test('R1 xMm == 15.30', () {
      expect(kBodaHaloLayoutForTest[0].xMm, closeTo(15.30, 0.001));
    });
    test('R1 yMm == 94.95', () {
      expect(kBodaHaloLayoutForTest[0].yMm, closeTo(94.95, 0.001));
    });

    test('R2 xMm == 63.30', () {
      expect(kBodaHaloLayoutForTest[1].xMm, closeTo(63.30, 0.001));
    });
    test('R2 yMm == 111.30', () {
      expect(kBodaHaloLayoutForTest[1].yMm, closeTo(111.30, 0.001));
    });

    test('R3 xMm == 104.75', () {
      expect(kBodaHaloLayoutForTest[2].xMm, closeTo(104.75, 0.001));
    });
    test('R3 yMm == 141.00', () {
      expect(kBodaHaloLayoutForTest[2].yMm, closeTo(141.00, 0.001));
    });

    test('R4 xMm == 134.00', () {
      expect(kBodaHaloLayoutForTest[3].xMm, closeTo(134.00, 0.001));
    });
    test('R4 yMm == 181.90', () {
      expect(kBodaHaloLayoutForTest[3].yMm, closeTo(181.90, 0.001));
    });

    test('R5 xMm == 151.80', () {
      expect(kBodaHaloLayoutForTest[4].xMm, closeTo(151.80, 0.001));
    });
    test('R5 yMm == 228.75', () {
      expect(kBodaHaloLayoutForTest[4].yMm, closeTo(228.75, 0.001));
    });

    test('L1 xMm == 154.30', () {
      expect(kBodaHaloLayoutForTest[5].xMm, closeTo(154.30, 0.001));
    });
    test('L1 yMm == 94.20', () {
      expect(kBodaHaloLayoutForTest[5].yMm, closeTo(94.20, 0.001));
    });

    test('L2 xMm == 118.90', () {
      expect(kBodaHaloLayoutForTest[6].xMm, closeTo(118.90, 0.001));
    });
    test('L2 yMm == 108.80', () {
      expect(kBodaHaloLayoutForTest[6].yMm, closeTo(108.80, 0.001));
    });

    test('L3 xMm == 76.55', () {
      expect(kBodaHaloLayoutForTest[7].xMm, closeTo(76.55, 0.001));
    });
    test('L3 yMm == 138.50', () {
      expect(kBodaHaloLayoutForTest[7].yMm, closeTo(138.50, 0.001));
    });

    test('L4 xMm == 25.50', () {
      expect(kBodaHaloLayoutForTest[8].xMm, closeTo(25.50, 0.001));
    });
    test('L4 yMm == 179.10', () {
      expect(kBodaHaloLayoutForTest[8].yMm, closeTo(179.10, 0.001));
    });

    test('L5 xMm == 17.90', () {
      expect(kBodaHaloLayoutForTest[9].xMm, closeTo(17.90, 0.001));
    });
    test('L5 yMm == 230.30', () {
      expect(kBodaHaloLayoutForTest[9].yMm, closeTo(230.30, 0.001));
    });
  });

  group('kBodaHaloLayout — bleedBottom flags (S14)', () {
    test('R5 (index 4) bleedBottom is true', () {
      expect(kBodaHaloLayoutForTest[4].bleedBottom, isTrue);
    });

    test('L5 (index 9) bleedBottom is true', () {
      expect(kBodaHaloLayoutForTest[9].bleedBottom, isTrue);
    });

    test('all other 8 slots have bleedBottom == false', () {
      const bleedSlots = {4, 9};
      for (var i = 0; i < 10; i++) {
        if (bleedSlots.contains(i)) continue;
        expect(
          kBodaHaloLayoutForTest[i].bleedBottom,
          isFalse,
          reason: 'slot $i should not bleed bottom',
        );
      }
    });
  });
}
