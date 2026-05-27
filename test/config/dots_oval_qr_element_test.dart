// Tests for DotsOvalQrElement — model construction, equality, and hashCode
// (R3, T1.2).
//
// These tests are GREEN immediately: DotsOvalQrElement is defined in
// dots_template.dart as part of slice 5 PR 1 (T2.2).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsOvalQrElement — construction (R3)', () {
    test('constructs with all named fields', () {
      const element = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'Vuestro álbum en digital',
      );
      expect(element.x, equals(10.0));
      expect(element.y, equals(20.0));
      expect(element.ovalWidth, equals(73.24));
      expect(element.ovalHeight, equals(122.27));
      expect(element.qrPayload, equals('https://example.com'));
      expect(element.caption, equals('Vuestro álbum en digital'));
    });
  });

  group('DotsOvalQrElement — equality and hashCode (R3)', () {
    test('identical instances are equal', () {
      const a = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'Vuestro álbum en digital',
      );
      const b = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'Vuestro álbum en digital',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when caption differs', () {
      const a = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'Vuestro álbum en digital',
      );
      const b = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'Tu album en digital',
      );
      expect(a, isNot(equals(b)));
    });

    test('inequality when qrPayload differs', () {
      const a = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'caption',
      );
      const b = DotsOvalQrElement(
        x: 10.0,
        y: 20.0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://other.com',
        caption: 'caption',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsOvalQrElement — sealed hierarchy (R3)', () {
    test('is a DotsElement subtype', () {
      const element = DotsOvalQrElement(
        x: 0,
        y: 0,
        ovalWidth: 73.24,
        ovalHeight: 122.27,
        qrPayload: 'https://example.com',
        caption: 'caption',
      );
      expect(element, isA<DotsElement>());
    });
  });
}
