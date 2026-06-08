// Tests for kPhotoArcLayout — entry count, uniform diameter, and coordinate
// values (docs/specs/02-pareja.md §final p2, 28-slot photo arc/halo).
import 'package:dots_pdf/src/render/photo_arc_layout.dart'
    show kPhotoArcLayoutForTest;
import 'package:flutter_test/flutter_test.dart';

// Tolerance for floating-point mm coordinate comparisons.
const double _epsilon = 0.0001;

void main() {
  group('kPhotoArcLayout — structure (final p2)', () {
    test('exactly 28 entries', () {
      expect(kPhotoArcLayoutForTest.length, equals(28));
    });

    test('all entries have diameterMm == 44.45', () {
      for (final anchor in kPhotoArcLayoutForTest) {
        expect(
          anchor.diameterMm,
          equals(44.45),
          reason: 'Expected diameterMm=44.45 at '
              '(x=${anchor.xMm}, y=${anchor.yMm})',
        );
      }
    });
  });

  group('kPhotoArcLayout — coordinates match spec table (final p2)', () {
    // docs/specs/02-pareja.md §final p2 — 28 slot coordinates (mm, spread
    // artboard).
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
      expect(kPhotoArcLayoutForTest.length, equals(expected.length));
    });

    for (var i = 0; i < expected.length; i++) {
      final (xExpected, yExpected) = expected[i];
      test('entry #${i + 1}: xMm ≈ $xExpected, yMm ≈ $yExpected', () {
        final anchor = kPhotoArcLayoutForTest[i];
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
