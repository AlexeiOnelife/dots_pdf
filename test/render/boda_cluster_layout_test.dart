// Tests for kBodaClusterLayout — 7 entries, mm values within ±0.001,
// gradient params, bleedTop only on slot 1 (R6 scenarios).
// GREEN immediately: kBodaClusterLayout and kBodaClusterLayoutForTest
// exist after T2.3.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/boda_cluster_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kBodaClusterLayout — entry count (R6)', () {
    test('has exactly 7 entries', () {
      expect(kBodaClusterLayoutForTest.length, 7);
    });
  });

  group('kBodaClusterLayout — slot geometry (R6)', () {
    test('slot 1 x=94.6 mm', () {
      expect(kBodaClusterLayoutForTest[0].xMm, closeTo(94.6, 0.001));
    });
    test('slot 1 y=−7.8 mm', () {
      expect(kBodaClusterLayoutForTest[0].yMm, closeTo(-7.8, 0.001));
    });
    test('slot 1 width=27.5 mm', () {
      expect(kBodaClusterLayoutForTest[0].widthMm, closeTo(27.5, 0.001));
    });
    test('slot 1 height=33.9 mm', () {
      expect(kBodaClusterLayoutForTest[0].heightMm, closeTo(33.9, 0.001));
    });

    test('slot 2 x=86.3 mm', () {
      expect(kBodaClusterLayoutForTest[1].xMm, closeTo(86.3, 0.001));
    });
    test('slot 2 y=59.6 mm', () {
      expect(kBodaClusterLayoutForTest[1].yMm, closeTo(59.6, 0.001));
    });
    test('slot 2 width=5.0 mm', () {
      expect(kBodaClusterLayoutForTest[1].widthMm, closeTo(5.0, 0.001));
    });
    test('slot 2 height=5.8 mm', () {
      expect(kBodaClusterLayoutForTest[1].heightMm, closeTo(5.8, 0.001));
    });

    test('slot 3 x=90.0 mm', () {
      expect(kBodaClusterLayoutForTest[2].xMm, closeTo(90.0, 0.001));
    });
    test('slot 3 y=31.4 mm', () {
      expect(kBodaClusterLayoutForTest[2].yMm, closeTo(31.4, 0.001));
    });
    test('slot 3 width=20.3 mm', () {
      expect(kBodaClusterLayoutForTest[2].widthMm, closeTo(20.3, 0.001));
    });
    test('slot 3 height=24.7 mm', () {
      expect(kBodaClusterLayoutForTest[2].heightMm, closeTo(24.7, 0.001));
    });

    test('slot 4 x=87.4 mm', () {
      expect(kBodaClusterLayoutForTest[3].xMm, closeTo(87.4, 0.001));
    });
    test('slot 4 y=71.3 mm', () {
      expect(kBodaClusterLayoutForTest[3].yMm, closeTo(71.3, 0.001));
    });
    test('slot 4 width=12.8 mm', () {
      expect(kBodaClusterLayoutForTest[3].widthMm, closeTo(12.8, 0.001));
    });
    test('slot 4 height=15.2 mm', () {
      expect(kBodaClusterLayoutForTest[3].heightMm, closeTo(15.2, 0.001));
    });

    test('slot 5 x=103.1 mm', () {
      expect(kBodaClusterLayoutForTest[4].xMm, closeTo(103.1, 0.001));
    });
    test('slot 5 y=88.9 mm', () {
      expect(kBodaClusterLayoutForTest[4].yMm, closeTo(88.9, 0.001));
    });
    test('slot 5 width=13.7 mm', () {
      expect(kBodaClusterLayoutForTest[4].widthMm, closeTo(13.7, 0.001));
    });
    test('slot 5 height=16.2 mm', () {
      expect(kBodaClusterLayoutForTest[4].heightMm, closeTo(16.2, 0.001));
    });

    test('slot 6 x=90.4 mm', () {
      expect(kBodaClusterLayoutForTest[5].xMm, closeTo(90.4, 0.001));
    });
    test('slot 6 y=103.3 mm', () {
      expect(kBodaClusterLayoutForTest[5].yMm, closeTo(103.3, 0.001));
    });
    test('slot 6 width=9.0 mm', () {
      expect(kBodaClusterLayoutForTest[5].widthMm, closeTo(9.0, 0.001));
    });
    test('slot 6 height=10.6 mm', () {
      expect(kBodaClusterLayoutForTest[5].heightMm, closeTo(10.6, 0.001));
    });

    test('slot 7 x=103.1 mm', () {
      expect(kBodaClusterLayoutForTest[6].xMm, closeTo(103.1, 0.001));
    });
    test('slot 7 y=116.6 mm', () {
      expect(kBodaClusterLayoutForTest[6].yMm, closeTo(116.6, 0.001));
    });
    test('slot 7 width=7.8 mm', () {
      expect(kBodaClusterLayoutForTest[6].widthMm, closeTo(7.8, 0.001));
    });
    test('slot 7 height=9.2 mm', () {
      expect(kBodaClusterLayoutForTest[6].heightMm, closeTo(9.2, 0.001));
    });
  });

  group('kBodaClusterLayout — gradient params (R6)', () {
    test('slot 1 gradient: bottomToTop 1.0→0.1', () {
      final slot = kBodaClusterLayoutForTest[0];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(0.1, 0.001));
      expect(slot.opacityGradientDirection, DotsGradientDirection.bottomToTop);
    });

    test('slot 2 no gradient (full opacity both ends)', () {
      final slot = kBodaClusterLayoutForTest[1];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(1.0, 0.001));
    });

    test('slot 3 no gradient (full opacity both ends)', () {
      final slot = kBodaClusterLayoutForTest[2];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(1.0, 0.001));
    });

    test('slot 4 no gradient (full opacity both ends)', () {
      final slot = kBodaClusterLayoutForTest[3];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(1.0, 0.001));
    });

    test('slot 5 gradient: topToBottom 1.0→0.3', () {
      final slot = kBodaClusterLayoutForTest[4];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(0.3, 0.001));
      expect(slot.opacityGradientDirection, DotsGradientDirection.topToBottom);
    });

    test('slot 6 gradient: topToBottom 1.0→0.3', () {
      final slot = kBodaClusterLayoutForTest[5];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(0.3, 0.001));
      expect(slot.opacityGradientDirection, DotsGradientDirection.topToBottom);
    });

    test('slot 7 gradient: topToBottom 1.0→0.0', () {
      final slot = kBodaClusterLayoutForTest[6];
      expect(slot.opacityGradientStart, closeTo(1.0, 0.001));
      expect(slot.opacityGradientEnd, closeTo(0.0, 0.001));
      expect(slot.opacityGradientDirection, DotsGradientDirection.topToBottom);
    });
  });

  group('kBodaClusterLayout — bleedTop (R6)', () {
    test('slot 1 bleedTop is true', () {
      expect(kBodaClusterLayoutForTest[0].bleedTop, isTrue);
    });

    test('slots 2–7 bleedTop are false', () {
      for (var i = 1; i < 7; i++) {
        expect(
          kBodaClusterLayoutForTest[i].bleedTop,
          isFalse,
          reason: 'slot ${i + 1} should not bleed top',
        );
      }
    });
  });

  group('kBodaClusterLayout — gaussianFadeMm (R6)', () {
    test('all 7 slots have gaussianFadeMm of 1.764', () {
      for (var i = 0; i < 7; i++) {
        expect(
          kBodaClusterLayoutForTest[i].gaussianFadeMm,
          closeTo(1.764, 0.001),
          reason: 'slot ${i + 1} gaussianFadeMm should be 1.764',
        );
      }
    });
  });
}
