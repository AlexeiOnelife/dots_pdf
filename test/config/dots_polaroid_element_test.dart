// Tests for DotsPolaroidElement — model equality, hashCode, construction.
//
// T1.1 — RED until T2.1 adds DotsPolaroidElement to dots_template.dart.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsPolaroidElement — construction and field access (R1)', () {
    test('DotsPolaroidElement — constructs with all fields and exposes them correctly',
        () {
      const element = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
        gradientRtl: false,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );

      expect(element.x, equals(59.5));
      expect(element.y, equals(51.0));
      expect(element.assetPath, equals('a.jpg'));
      expect(element.width, equals(306.14));
      expect(element.height, equals(379.84));
      expect(element.angleDegrees, equals(-2.5));
      expect(element.gradientRtl, isFalse);
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });

    test('DotsPolaroidElement — gradientRtl defaults to false', () {
      const element = DotsPolaroidElement(
        x: 0,
        y: 0,
        assetPath: 'b.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: 0.0,
      );
      expect(element.gradientRtl, isFalse);
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });
  });

  group('DotsPolaroidElement — equality and hashCode (R1)', () {
    test('DotsPolaroidElement — two instances with same fields are equal', () {
      const a = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
        gradientRtl: false,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      const b = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
        gradientRtl: false,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      expect(a, equals(b));
    });

    test('DotsPolaroidElement — two instances with same fields have equal hashCode',
        () {
      const a = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
      );
      const b = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DotsPolaroidElement — instances differing in angleDegrees are not equal',
        () {
      const a = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: -2.5,
      );
      const b = DotsPolaroidElement(
        x: 59.5,
        y: 51.0,
        assetPath: 'a.jpg',
        width: 306.14,
        height: 379.84,
        angleDegrees: 4.0,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
