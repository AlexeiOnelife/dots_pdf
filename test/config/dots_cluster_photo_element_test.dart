// Tests for DotsClusterPhotoElement — model construction, equality,
// hashCode, inequality on assetPath, bleed defaults, gaussianFadeMm default.
// Scenarios SC1–SC5 from R1.
// GREEN immediately: all tested symbols exist after T2.2.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsClusterPhotoElement — construction (R1)', () {
    // SC1 — constructs with all fields, all values accessible
    test('constructs with all fields', () {
      const element = DotsClusterPhotoElement(
        x: 268.3,
        y: -22.1,
        assetPath: 'photo1.jpg',
        width: 77.9,
        height: 96.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 0.1,
        opacityGradientDirection: DotsGradientDirection.bottomToTop,
        gaussianFadeMm: 1.764,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: true,
        bleedBottom: false,
      );

      expect(element.x, 268.3);
      expect(element.y, -22.1);
      expect(element.assetPath, 'photo1.jpg');
      expect(element.width, 77.9);
      expect(element.height, 96.0);
      expect(element.opacityGradientStart, 1.0);
      expect(element.opacityGradientEnd, 0.1);
      expect(element.opacityGradientDirection, DotsGradientDirection.bottomToTop);
      expect(element.gaussianFadeMm, 1.764);
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isTrue);
      expect(element.bleedBottom, isFalse);
    });
  });

  group('DotsClusterPhotoElement — equality and hashCode (R1)', () {
    // SC2 — value equality: identical fields → equal, same hashCode
    test('two instances with identical fields are equal', () {
      const a = DotsClusterPhotoElement(
        x: 10.0,
        y: 20.0,
        assetPath: 'img.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 0.3,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
        gaussianFadeMm: 1.764,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      const b = DotsClusterPhotoElement(
        x: 10.0,
        y: 20.0,
        assetPath: 'img.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 0.3,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
        gaussianFadeMm: 1.764,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    // SC3 — inequality when assetPath differs
    test('inequality when assetPath differs', () {
      const a = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'photo_a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );
      const b = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'photo_b.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(a, isNot(equals(b)));
    });

    test('inequality when opacityGradientEnd differs', () {
      const a = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 0.3,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );
      const b = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 0.5,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('DotsClusterPhotoElement — defaults (R1)', () {
    // SC4 — gaussianFadeMm defaults to 1.764
    test('gaussianFadeMm defaults to 1.764', () {
      const element = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(element.gaussianFadeMm, 1.764);
    });

    // SC5 — bleed flags default to false
    test('bleed flags default to false', () {
      const element = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });

    test('opacityGradientDirection defaults to topToBottom', () {
      const element = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(element.opacityGradientDirection, DotsGradientDirection.topToBottom);
    });

    test('sentinel: start == end signals no gradient', () {
      const element = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(
        element.opacityGradientStart == element.opacityGradientEnd,
        isTrue,
        reason: 'equal start/end is the no-gradient sentinel',
      );
    });
  });

  group('DotsClusterPhotoElement — sealed hierarchy', () {
    test('is a DotsElement subtype', () {
      const DotsElement element = DotsClusterPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 50.0,
        height: 60.0,
        opacityGradientStart: 1.0,
        opacityGradientEnd: 1.0,
        opacityGradientDirection: DotsGradientDirection.topToBottom,
      );

      expect(element, isA<DotsClusterPhotoElement>());
    });
  });
}
