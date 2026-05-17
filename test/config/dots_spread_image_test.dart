import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DotsTemplateParser();

  String wrap(String elementJson) => '''
{
  "documentId": "doc_sp",
  "pageSize": { "width": 595, "height": 842 },
  "pages": [
    { "pageNumber": 1, "elements": [ $elementJson ] }
  ]
}
''';

  group('DotsTemplateParser — spreadImage', () {
    test('parses a fully-specified spreadImage element (left half)', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "https://example.com/wide.jpg",
          "x": 0, "y": 50,
          "spreadWidth": 1184.5,
          "height": 689.2,
          "half": "left",
          "bleedTop": true,
          "bleedBottom": false,
          "bleedOuter": true
        }
      ''');
      final template = parser.parse(source);

      final page = template.pages.single as DotsElementsPage;
      expect(page.elements, hasLength(1));
      final el = page.elements.single as DotsSpreadImageElement;
      expect(el.assetPath, 'https://example.com/wide.jpg');
      expect(el.x, 0);
      expect(el.y, 50);
      expect(el.spreadWidth, 1184.5);
      expect(el.height, 689.2);
      expect(el.half, DotsSpreadHalf.left);
      expect(el.bleedTop, isTrue);
      expect(el.bleedBottom, isFalse);
      expect(el.bleedOuter, isTrue);
    });

    test('parses half="right" with default bleed flags', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/local/wide.jpg",
          "x": 10, "y": 20,
          "spreadWidth": 800,
          "height": 400,
          "half": "right"
        }
      ''');
      final template = parser.parse(source);
      final page = template.pages.single as DotsElementsPage;
      final el = page.elements.single as DotsSpreadImageElement;
      expect(el.half, DotsSpreadHalf.right);
      expect(el.bleedTop, isFalse);
      expect(el.bleedBottom, isFalse);
      expect(el.bleedOuter, isFalse);
    });

    test('throws when "half" is missing', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 100
        }
      ''');
      expect(
        () => parser.parse(source),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.pointer,
            'pointer',
            contains('half'),
          ),
        ),
      );
    });

    test('throws when "half" is not "left" or "right"', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 100,
          "half": "middle"
        }
      ''');
      expect(
        () => parser.parse(source),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('left'),
          ),
        ),
      );
    });

    test('throws when spreadWidth is non-positive', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": -1, "height": 100,
          "half": "left"
        }
      ''');
      expect(
        () => parser.parse(source),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.pointer,
            'pointer',
            contains('spreadWidth'),
          ),
        ),
      );
    });

    test('throws when height is non-positive', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 0,
          "half": "right"
        }
      ''');
      expect(
        () => parser.parse(source),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.pointer,
            'pointer',
            contains('height'),
          ),
        ),
      );
    });

    test('throws when assetPath is missing', () {
      final source = wrap('''
        {
          "type": "spreadImage",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 100,
          "half": "left"
        }
      ''');
      expect(
        () => parser.parse(source),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.pointer,
            'pointer',
            contains('assetPath'),
          ),
        ),
      );
    });

    test('participates in equality and contentHash', () {
      final aSource = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 100,
          "half": "left"
        }
      ''');
      final bSource = wrap('''
        {
          "type": "spreadImage",
          "assetPath": "/x.jpg",
          "x": 0, "y": 0,
          "spreadWidth": 100, "height": 100,
          "half": "right"
        }
      ''');
      expect(
        parser.parse(aSource).contentHash,
        isNot(parser.parse(bSource).contentHash),
      );
    });
  });
}
