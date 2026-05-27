// Tests for DotsPhotoCircleElement — model construction, equality, hashCode,
// and bleed-flag defaults (R1, T1.1).
//
// These tests are GREEN immediately: DotsPhotoCircleElement is defined in
// dots_template.dart as part of slice 5 PR 1 (T2.1).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsPhotoCircleElement — construction (R1)', () {
    test('constructs with all named fields', () {
      const element = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'a.jpg',
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      expect(element.x, equals(83.82));
      expect(element.y, equals(774.42));
      expect(element.diameter, equals(125.98));
      expect(element.assetPath, equals('a.jpg'));
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });

    test('bleed flags default to false', () {
      const element = DotsPhotoCircleElement(
        x: 0,
        y: 0,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });
  });

  group('DotsPhotoCircleElement — equality and hashCode (R1)', () {
    test('identical instances are equal', () {
      const a = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      const b = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when diameter differs', () {
      const a = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      const b = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 99.0,
        assetPath: 'a.jpg',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when assetPath differs', () {
      const a = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      const b = DotsPhotoCircleElement(
        x: 83.82,
        y: 774.42,
        diameter: 125.98,
        assetPath: 'b.jpg',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsPhotoCircleElement — sealed hierarchy (R1)', () {
    test('is a DotsElement subtype', () {
      const element = DotsPhotoCircleElement(
        x: 0,
        y: 0,
        diameter: 125.98,
        assetPath: 'a.jpg',
      );
      expect(element, isA<DotsElement>());
    });
  });
}
