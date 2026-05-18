import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsPliego — Dart-construction flattening', () {
    test('DotsLayoutPliego assigns sequential page numbers', () {
      const pliego = DotsLayoutPliego(
        pliegoNumber: 1,
        left: DotsElementsPage(pageNumber: 99, elements: <DotsElement>[]),
        right: DotsLayoutPage(
          pageNumber: 99,
          layoutCode: DotsLayoutCode.l1,
          photoAssetPaths: <String>['/p.jpg'],
        ),
      );
      final pages = pliego.toPages(5);
      expect(pages, hasLength(2));
      expect(pages[0].pageNumber, 5);
      expect(pages[1].pageNumber, 6);
      expect(pages[0], isA<DotsElementsPage>());
      expect(pages[1], isA<DotsLayoutPage>());
    });

    test('DotsSpreadImagePliego produces left+right halves', () {
      const pliego = DotsSpreadImagePliego(
        pliegoNumber: 1,
        assetPath: 'https://example.com/panorama.jpg',
        spreadWidth: 1000,
        height: 500,
        bleedOuter: true,
      );
      final pages = pliego.toPages(3);
      expect(pages, hasLength(2));
      expect(pages[0].pageNumber, 3);
      expect(pages[1].pageNumber, 4);
      final leftElem =
          (pages[0] as DotsElementsPage).elements.single as DotsSpreadImageElement;
      final rightElem =
          (pages[1] as DotsElementsPage).elements.single as DotsSpreadImageElement;
      expect(leftElem.half, DotsSpreadHalf.left);
      expect(rightElem.half, DotsSpreadHalf.right);
      expect(leftElem.assetPath, rightElem.assetPath);
      expect(leftElem.spreadWidth, 1000);
      expect(leftElem.bleedOuter, isTrue);
    });

    test('DotsTemplate.effectivePages flattens a mix of pliegos', () {
      const template = DotsTemplate(
        documentId: 'mix',
        pageSize: DotsPageSize(width: 100, height: 100),
        pliegos: <DotsPliego>[
          DotsLayoutPliego(
            pliegoNumber: 1,
            left: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
            right: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
          ),
          DotsSpreadImagePliego(
            pliegoNumber: 2,
            assetPath: '/local/spread.jpg',
            spreadWidth: 600,
            height: 400,
          ),
        ],
      );
      final pages = template.effectivePages;
      expect(pages, hasLength(4));
      expect(pages[0].pageNumber, 1);
      expect(pages[3].pageNumber, 4);
    });

    test('DotsTemplate.effectivePages returns pages as-is when no pliegos',
        () {
      const template = DotsTemplate(
        documentId: 'flat',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: <DotsPage>[
          DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
        ],
      );
      expect(template.effectivePages, hasLength(1));
    });

    test('contentHash differs between pages-form and pliegos-form even '
        'when the rendered output would be the same', () {
      // This is intentional — the hash is over the SOURCE, not the
      // flattened pages. Editing the template from one form to the
      // other invalidates the cache and re-renders, which is the
      // safe default.
      const flat = DotsTemplate(
        documentId: 'x',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: <DotsPage>[
          DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
          DotsElementsPage(pageNumber: 2, elements: <DotsElement>[]),
        ],
      );
      const pliego = DotsTemplate(
        documentId: 'x',
        pageSize: DotsPageSize(width: 100, height: 100),
        pliegos: <DotsPliego>[
          DotsLayoutPliego(
            pliegoNumber: 1,
            left: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
            right: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
          ),
        ],
      );
      expect(flat.contentHash, isNot(pliego.contentHash));
    });
  });

  group('DotsTemplateParser — pliegos JSON', () {
    const parser = DotsTemplateParser();

    test('parses a mixed pliego template', () {
      const json = '''
      {
        "documentId": "demo",
        "pageSize": { "width": 100, "height": 100 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left":  { "elements": [] },
            "right": { "layout": "l1", "photos": ["/local/a.jpg"] }
          },
          {
            "pliegoNumber": 2,
            "type": "spreadImage",
            "assetPath": "https://example.com/panorama.jpg",
            "spreadWidth": 1184,
            "height": 689,
            "bleedTop": true,
            "bleedOuter": true
          }
        ]
      }
      ''';
      final template = parser.parse(json);
      expect(template.pliegos, hasLength(2));
      expect(template.pages, isEmpty);
      final flattened = template.effectivePages;
      expect(flattened, hasLength(4));
      expect(flattened[0].pageNumber, 1);
      expect(flattened[3].pageNumber, 4);
    });

    test('rejects a template that declares both pages and pliegos', () {
      const json = '''
      {
        "documentId": "bad",
        "pageSize": { "width": 100, "height": 100 },
        "pages": [],
        "pliegos": []
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('pages'),
          ),
        ),
      );
    });

    test('rejects a template that declares neither pages nor pliegos', () {
      const json = '''
      {
        "documentId": "empty",
        "pageSize": { "width": 100, "height": 100 }
      }
      ''';
      expect(() => parser.parse(json), throwsA(isA<DotsConfigException>()));
    });

    test('rejects an unknown pliego type', () {
      const json = '''
      {
        "documentId": "bad",
        "pageSize": { "width": 100, "height": 100 },
        "pliegos": [
          { "pliegoNumber": 1, "type": "weird" }
        ]
      }
      ''';
      expect(() => parser.parse(json), throwsA(isA<DotsConfigException>()));
    });

    test('rejects a spreadImage pliego with non-positive dimensions', () {
      const json = '''
      {
        "documentId": "bad",
        "pageSize": { "width": 100, "height": 100 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "spreadImage",
            "assetPath": "/local/x.jpg",
            "spreadWidth": 0,
            "height": 100
          }
        ]
      }
      ''';
      expect(() => parser.parse(json), throwsA(isA<DotsConfigException>()));
    });
  });

  group('DotsTemplate constructor — invariants', () {
    test('accepts pages-only', () {
      const t = DotsTemplate(
        documentId: 'a',
        pageSize: DotsPageSize(width: 100, height: 100),
        pages: <DotsPage>[
          DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
        ],
      );
      expect(t.pliegos, isEmpty);
      expect(t.pages, hasLength(1));
    });

    test('accepts pliegos-only', () {
      const t = DotsTemplate(
        documentId: 'b',
        pageSize: DotsPageSize(width: 100, height: 100),
        pliegos: <DotsPliego>[
          DotsLayoutPliego(
            pliegoNumber: 1,
            left: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
            right: DotsElementsPage(pageNumber: 0, elements: <DotsElement>[]),
          ),
        ],
      );
      expect(t.pages, isEmpty);
      expect(t.pliegos, hasLength(1));
    });

    test('accepts the empty case (both empty)', () {
      const t = DotsTemplate(
        documentId: 'c',
        pageSize: DotsPageSize(width: 100, height: 100),
      );
      expect(t.effectivePages, isEmpty);
    });
  });

  test('module compiles', () {
    expect(MemoryFileSystem.test(), isNotNull);
  });
}
