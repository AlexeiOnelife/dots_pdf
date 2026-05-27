// Tests for DotsRotatedPhotoElement — model construction, equality, hashCode,
// inequality when angleDegrees differs, cornerRadiusMm default 6.0, and all
// 4 bleed flags defaulting to false.
// Scenarios S1–S5 from R1.
// GREEN immediately: all tested symbols exist after T2.1.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsRotatedPhotoElement — construction (S1)', () {
    test('constructs with all fields and all values are accessible', () {
      const element = DotsRotatedPhotoElement(
        x: 37.4,
        y: 266.5,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
        cornerRadiusMm: 6.0,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );

      expect(element.x, 37.4);
      expect(element.y, 266.5);
      expect(element.assetPath, 'a.jpg');
      expect(element.width, 95.0);
      expect(element.height, 131.4);
      expect(element.angleDegrees, 3.2);
      expect(element.cornerRadiusMm, 6.0);
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });
  });

  group('DotsRotatedPhotoElement — equality and hashCode (S2)', () {
    test('two instances with identical fields are equal', () {
      const a = DotsRotatedPhotoElement(
        x: 37.4,
        y: 266.5,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
        cornerRadiusMm: 6.0,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      const b = DotsRotatedPhotoElement(
        x: 37.4,
        y: 266.5,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
        cornerRadiusMm: 6.0,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('DotsRotatedPhotoElement — inequality when angleDegrees differs (S3)', () {
    test('two instances differing only in angleDegrees are not equal', () {
      const a = DotsRotatedPhotoElement(
        x: 37.4,
        y: 266.5,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
      );
      const b = DotsRotatedPhotoElement(
        x: 37.4,
        y: 266.5,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 20.7,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('DotsRotatedPhotoElement — cornerRadiusMm default (S4)', () {
    test('cornerRadiusMm defaults to 6.0', () {
      const element = DotsRotatedPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 20.7,
      );

      expect(element.cornerRadiusMm, 6.0);
    });
  });

  group('DotsRotatedPhotoElement — bleed flags default to false (S5)', () {
    test('all four bleed flags default to false', () {
      const element = DotsRotatedPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
      );

      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });
  });

  group('DotsRotatedPhotoElement — sealed hierarchy', () {
    test('is a DotsElement subtype', () {
      const DotsElement element = DotsRotatedPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
      );

      expect(element, isA<DotsRotatedPhotoElement>());
    });
  });
}
