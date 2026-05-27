// Tests for DotsDecorativeCircleElement — model construction, equality,
// hashCode, and bleed-flag defaults (R1).
//
// These tests are GREEN as soon as T2.1 lands (which it has in this PR batch).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsDecorativeCircleElement — construction (R1)', () {
    test('constructs with all named fields', () {
      const element = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      expect(element.x, equals(22.68));
      expect(element.y, equals(121.89));
      expect(element.diameter, equals(133.23));
      expect(element.colorHex, equals('#CDE7F2'));
      expect(element.gaussianFadeMm, equals(1.764));
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });

    test('bleed flags default to false', () {
      const element = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 45.0,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });

    test('gaussianFadeMm defaults to 1.764', () {
      const element = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 45.0,
        colorHex: '#CDE7F2',
      );
      expect(element.gaussianFadeMm, equals(1.764));
    });
  });

  group('DotsDecorativeCircleElement — equality and hashCode (R1)', () {
    test('identical instances are equal', () {
      const a = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      const b = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when diameter differs', () {
      const a = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 79.37,
        colorHex: '#CDE7F2',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when colorHex differs', () {
      const a = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#FF0000',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when x differs', () {
      const a = DotsDecorativeCircleElement(
        x: 10.0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeCircleElement(
        x: 20.0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when bleedLeft differs', () {
      const a = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
        bleedLeft: true,
      );
      const b = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
        bleedLeft: false,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsDecorativeCircleElement — sealed hierarchy (R1)', () {
    test('is a DotsElement subtype', () {
      const element = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 50.0,
        colorHex: '#CDE7F2',
      );
      expect(element, isA<DotsElement>());
    });
  });
}
