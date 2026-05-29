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

    test('toPages assigns page numbers to DotsAlbumSpreadPage sides', () {
      const header = DotsSpreadHeader(
        leftPageNumber: '01',
        centerLabel: 'foo',
        rightPageNumber: '02',
      );
      const footer = DotsSpreadFooter(wordmark: 'Dots. Memories');
      const pliego = DotsLayoutPliego(
        pliegoNumber: 1,
        left: DotsAlbumSpreadPage(
          pageNumber: 0,
          header: header,
          footer: footer,
          elements: <DotsElement>[],
        ),
        right: DotsAlbumSpreadPage(
          pageNumber: 0,
          header: header,
          footer: footer,
          elements: <DotsElement>[],
        ),
      );
      final pages = pliego.toPages(5);
      expect(pages, hasLength(2));
      expect(pages[0], isA<DotsAlbumSpreadPage>());
      expect(pages[1], isA<DotsAlbumSpreadPage>());
      expect(pages[0].pageNumber, 5);
      expect(pages[1].pageNumber, 6);
      final left = pages[0] as DotsAlbumSpreadPage;
      final right = pages[1] as DotsAlbumSpreadPage;
      expect(left.header, header);
      expect(left.footer, footer);
      expect(left.elements, isEmpty);
      expect(right.header, header);
      expect(right.footer, footer);
      expect(right.elements, isEmpty);
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

    test('DotsTemplate.effectivePages flattens pliegos into pages', () {
      const template = DotsTemplate(
        documentId: 'flat',
        pageSize: DotsPageSize(width: 100, height: 100),
        pliegos: <DotsPliego>[
          DotsLayoutPliego(
            pliegoNumber: 1,
            left: DotsElementsPage(pageNumber: 1, elements: <DotsElement>[]),
            right: DotsElementsPage(pageNumber: 2, elements: <DotsElement>[]),
          ),
        ],
      );
      expect(template.effectivePages, hasLength(2));
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
      final flattened = template.effectivePages;
      expect(flattened, hasLength(4));
      expect(flattened[0].pageNumber, 1);
      expect(flattened[3].pageNumber, 4);
    });

    test('rejects a template that declares the deprecated pages JSON key', () {
      const json = '''
      {
        "documentId": "bad",
        "pageSize": { "width": 100, "height": 100 },
        "pages": []
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('pliegos'),
          ),
        ),
      );
    });

    test('rejects a template that omits pliegos entirely', () {
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
    test('accepts pliegos', () {
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
      expect(t.pliegos, hasLength(1));
    });

    test('accepts the empty case (no pliegos)', () {
      const t = DotsTemplate(
        documentId: 'c',
        pageSize: DotsPageSize(width: 100, height: 100),
      );
      expect(t.effectivePages, isEmpty);
      expect(t.pliegos, isEmpty);
    });
  });

  test('module compiles', () {
    expect(MemoryFileSystem.test(), isNotNull);
  });
}
