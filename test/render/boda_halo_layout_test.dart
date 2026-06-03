// Tests for kBodaHaloLayout — entry count, uniform diameter, and coordinate
// values (docs/specs/04-boda.md §final p2 — the same 28-slot photo halo set as
// docs/specs/02-pareja.md §final p2).
import 'package:dots_pdf/src/render/boda_halo_layout.dart'
    show kBodaHaloLayoutForTest;
import 'package:flutter_test/flutter_test.dart';

// Tolerance for floating-point mm coordinate comparisons.
const double _epsilon = 0.0001;

void main() {
  group('kBodaHaloLayout — structure (boda final p2)', () {
    test('exactly 28 entries', () {
      expect(kBodaHaloLayoutForTest.length, equals(28));
    });

    test('all entries have diameterMm == 44.45', () {
      for (final anchor in kBodaHaloLayoutForTest) {
        expect(
          anchor.diameterMm,
          equals(44.45),
          reason: 'Expected diameterMm=44.45 at '
              '(x=${anchor.xMm}, y=${anchor.yMm})',
        );
      }
    });
  });

  group('kBodaHaloLayout — coordinates match spec table (boda final p2)', () {
    // docs/specs/04-boda.md §final p2 — same 28-slot coordinate set as
    // docs/specs/02-pareja.md §final p2 (mm, spread artboard).
    const expected = <(double, double)>[
      (390, 57),
      (362, 77),
      (338, 57),
      (307, 94),
      (266, 102),
      (236, 140),
      (202, 128),
      (205, 160),
      (137, 142),
      (149, 142),
      (163, 136),
      (165, 154),
      (182, 157),
      (177, 140),
      (185, 132),
      (241, 186),
      (389, 94),
      (348, 138),
      (310, 194),
      (271, 203),
      (291, 135),
      (266, 151),
      (307, 216),
      (348, 232),
      (395, 139),
      (369, 182),
      (391, 201),
      (389, 238),
    ];

    test('layout has same length as spec table (28)', () {
      expect(kBodaHaloLayoutForTest.length, equals(expected.length));
    });

    for (var i = 0; i < expected.length; i++) {
      final (xExpected, yExpected) = expected[i];
      test('entry #${i + 1}: xMm ≈ $xExpected, yMm ≈ $yExpected', () {
        final anchor = kBodaHaloLayoutForTest[i];
        expect(
          anchor.xMm,
          closeTo(xExpected, _epsilon),
          reason: 'xMm mismatch at entry #${i + 1}',
        );
        expect(
          anchor.yMm,
          closeTo(yExpected, _epsilon),
          reason: 'yMm mismatch at entry #${i + 1}',
        );
      });
    }
  });
}
