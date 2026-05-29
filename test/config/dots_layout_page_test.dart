import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DotsTemplateParser();

  group('DotsTemplateParser — layout-driven pages', () {
    test('parses a valid layout-driven page', () {
      const json = '''
      {
        "documentId": "doc_layout",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "l1",
            "photos": ["/assets/a.jpg"]
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';

      final template = parser.parse(json);
      expect(template.effectivePages, hasLength(2));
      final page = template.effectivePages.first;
      expect(page, isA<DotsLayoutPage>());
      final layoutPage = page as DotsLayoutPage;
      expect(layoutPage.pageNumber, 1);
      expect(layoutPage.layoutCode, DotsLayoutCode.l1);
      expect(layoutPage.photoAssetPaths, ['/assets/a.jpg']);
      expect(layoutPage.captions, isEmpty);
    });

    test('parses captions and maps JSON keys to slot kinds', () {
      const json = '''
      {
        "documentId": "doc_hito",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "lhito",
            "captions": {
              "title": "T",
              "date": "D",
              "body": "B",
              "qr": "https://example.com"
            }
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      final page = parser.parse(json).effectivePages.first as DotsLayoutPage;
      expect(page.captions, <DotsSlotKind, String>{
        DotsSlotKind.captionTitle: 'T',
        DotsSlotKind.captionDate: 'D',
        DotsSlotKind.captionBody: 'B',
        DotsSlotKind.qrCard: 'https://example.com',
      });
      expect(page.photoAssetPaths, isEmpty);
    });

    test('"layout" + "elements" together → throws', () {
      const json = '''
      {
        "documentId": "doc_mixed",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "l1",
            "elements": []
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('unknown layout code → throws', () {
      const json = '''
      {
        "documentId": "doc_bad_layout",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "lxx"
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('unknown layout code'),
          ),
        ),
      );
    });

    test('photos/slot-count mismatch (too few) → throws', () {
      const json = '''
      {
        "documentId": "doc_short",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "l4a",
            "photos": ["/a.jpg"]
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('expects 4 photo'),
          ),
        ),
      );
    });

    test('photos/slot-count mismatch (too many) → throws', () {
      const json = '''
      {
        "documentId": "doc_long",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "l1",
            "photos": ["/a.jpg", "/b.jpg"]
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('caption key not matching layout slots → throws', () {
      const json = '''
      {
        "documentId": "doc_bad_caption",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "l1",
            "photos": ["/a.jpg"],
            "captions": { "title": "nope" }
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('no slot for caption kind'),
          ),
        ),
      );
    });

    test('unknown caption JSON key → throws', () {
      const json = '''
      {
        "documentId": "doc_bad_key",
        "pageSize": { "width": 575.43, "height": 720.0 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "layout": "lhito",
            "captions": { "subtitle": "x" }
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            contains('unknown caption key'),
          ),
        ),
      );
    });

    test('elements-page path is unaffected', () {
      const json = '''
      {
        "documentId": "doc_explicit",
        "pageSize": { "width": 100, "height": 100 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
            "pageNumber": 1,
            "elements": [
              { "type": "text", "value": "x", "x": 0, "y": 0, "fontSize": 10 }
            ]
          },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
      }
      ''';
      final page = parser.parse(json).effectivePages.first;
      expect(page, isA<DotsElementsPage>());
    });
  });
}
