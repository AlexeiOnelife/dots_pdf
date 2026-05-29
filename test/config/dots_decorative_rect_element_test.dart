// Tests for DotsDecorativeRectElement — model construction, equality,
// hashCode, defaults, and sealed-hierarchy membership.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsDecorativeRectElement — construction', () {
    test('constructs with all named fields', () {
      const element = DotsDecorativeRectElement(
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
        borderRadius: 4.0,
      );
      expect(element.x, equals(10.0));
      expect(element.y, equals(20.0));
      expect(element.width, equals(100.0));
      expect(element.height, equals(200.0));
      expect(element.colorHex, equals('#CDE7F2'));
      expect(element.borderRadius, equals(4.0));
    });

    test('borderRadius defaults to 0', () {
      const element = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 50.0,
        height: 50.0,
        colorHex: '#CDE7F2',
      );
      expect(element.borderRadius, equals(0.0));
    });
  });

  group('DotsDecorativeRectElement — equality and hashCode', () {
    test('identical instances are equal', () {
      const a = DotsDecorativeRectElement(
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
        borderRadius: 4.0,
      );
      const b = DotsDecorativeRectElement(
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
        borderRadius: 4.0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when width differs', () {
      const a = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 150.0,
        height: 200.0,
        colorHex: '#CDE7F2',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when colorHex differs', () {
      const a = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 100.0,
        height: 200.0,
        colorHex: '#FF0000',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when borderRadius differs', () {
      const a = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
        borderRadius: 0,
      );
      const b = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 100.0,
        height: 200.0,
        colorHex: '#CDE7F2',
        borderRadius: 4,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsDecorativeRectElement — sealed hierarchy', () {
    test('is a DotsElement subtype', () {
      const element = DotsDecorativeRectElement(
        x: 0,
        y: 0,
        width: 50.0,
        height: 50.0,
        colorHex: '#CDE7F2',
      );
      expect(element, isA<DotsElement>());
    });
  });
}
