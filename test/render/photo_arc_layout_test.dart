// Tests for kPhotoArcLayout — entry count, uniform diameter, and coordinate
// values (D6, T1.3).
//
// These tests are GREEN immediately: kPhotoArcLayout is defined in
// photo_arc_layout.dart as part of slice 5 PR 1 (T2.3).
import 'package:dots_pdf/src/render/photo_arc_layout.dart'
    show kPhotoArcLayoutForTest;
import 'package:flutter_test/flutter_test.dart';

// Tolerance for floating-point mm coordinate comparisons.
const double _epsilon = 0.0001;

void main() {
  group('kPhotoArcLayout — structure (D6)', () {
    test('exactly 10 entries', () {
      expect(kPhotoArcLayoutForTest.length, equals(10));
    });

    test('all entries have diameterMm == 44.45', () {
      for (final anchor in kPhotoArcLayoutForTest) {
        expect(
          anchor.diameterMm,
          equals(44.45),
          reason:
              'Expected diameterMm=44.45 at '
              '(x=${anchor.xMm}, y=${anchor.yMm})',
        );
      }
    });
  });

  group('kPhotoArcLayout — coordinates match spec table (D6)', () {
    // Spec table (mm from top-left of 406 × 254 mm spread):
    // # | x (mm)  | y (mm)
    // 1 | 29.59   | 273.28
    // 2 | 376.17  | 273.28
    // 3 | 45.09   | 224.02
    // 4 | 360.66  | 224.02
    // 5 | 77.97   | 180.93
    // 6 | 327.79  | 180.93
    // 7 | 120.96  | 150.11
    // 8 | 284.79  | 150.11
    // 9 | 171.04  | 134.01
    //10 | 234.72  | 134.01

    const expected = <(double, double)>[
      (29.59, 273.28),
      (376.17, 273.28),
      (45.09, 224.02),
      (360.66, 224.02),
      (77.97, 180.93),
      (327.79, 180.93),
      (120.96, 150.11),
      (284.79, 150.11),
      (171.04, 134.01),
      (234.72, 134.01),
    ];

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
