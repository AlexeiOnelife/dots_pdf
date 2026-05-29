import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DotsTemplateParser();

  group('DotsAlbumSpreadPage — construction and value access (R4)', () {
    test('album-spread page can be constructed with all four header/footer positions',
        () {
      const page = DotsAlbumSpreadPage(
        pageNumber: 1,
        header: DotsSpreadHeader(
          leftPageNumber: '01',
          centerLabel: '{Protagonistas}',
          rightPageNumber: '02',
        ),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );

      expect(page.pageNumber, equals(1));
      expect(page.header.leftPageNumber, equals('01'));
      expect(page.header.centerLabel, equals('{Protagonistas}'));
      expect(page.header.rightPageNumber, equals('02'));
      expect(page.footer.wordmark, equals('Dots. Memories'));
      expect(page.elements, isEmpty);
    });

    test('DotsAlbumSpreadPage has empty elements list by default', () {
      const page = DotsAlbumSpreadPage(
        pageNumber: 3,
        header: DotsSpreadHeader(),
        footer: DotsSpreadFooter(wordmark: 'Dots. Memories'),
      );
      expect(page.elements, isEmpty);
    });
  });

  group('DotsSpreadHeader — equality and hashCode', () {
    test('equal when all fields match', () {
      const a = DotsSpreadHeader(
        leftPageNumber: '01',
        centerLabel: 'Label',
        rightPageNumber: '02',
      );
      const b = DotsSpreadHeader(
        leftPageNumber: '01',
        centerLabel: 'Label',
        rightPageNumber: '02',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when a field differs', () {
      const a = DotsSpreadHeader(leftPageNumber: '01');
      const b = DotsSpreadHeader(leftPageNumber: '02');
      expect(a, isNot(equals(b)));
    });

    test('null fields are distinct from non-null', () {
      const a = DotsSpreadHeader(centerLabel: 'X');
      const b = DotsSpreadHeader();
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsSpreadFooter — equality and hashCode', () {
    test('equal when wordmark matches', () {
      const a = DotsSpreadFooter(wordmark: 'Dots. Memories');
      const b = DotsSpreadFooter(wordmark: 'Dots. Memories');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when wordmark differs', () {
      const a = DotsSpreadFooter(wordmark: 'Dots. Memories');
      const b = DotsSpreadFooter(wordmark: 'Other');
      expect(a, isNot(equals(b)));
    });
  });

  group('DotsTemplateParser — albumSpread discriminator (R4)', () {
    test('JSON discriminator parses "type": "albumSpread" correctly', () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
      "pageNumber": 1,
      "type": "albumSpread",
      "header": {
        "leftPageNumber": "01",
        "centerLabel": "{Protagonistas}",
        "rightPageNumber": "02"
      },
      "footer": { "wordmark": "Dots. Memories" }
    },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';
      final template = parser.parse(json);
      expect(template.effectivePages, hasLength(2));
      final page = template.effectivePages.first;
      expect(page, isA<DotsAlbumSpreadPage>());
      final spreadPage = page as DotsAlbumSpreadPage;
      expect(spreadPage.header.leftPageNumber, equals('01'));
      expect(spreadPage.header.centerLabel, equals('{Protagonistas}'));
      expect(spreadPage.footer.wordmark, equals('Dots. Memories'));
    });

    test(
        'ambiguous page (explicit type AND legacy "elements" key) raises DotsConfigException',
        () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
      "pageNumber": 1,
      "type": "albumSpread",
      "elements": [],
      "header": { "wordmark": "X" },
      "footer": { "wordmark": "Y" }
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

    test(
        'ambiguous page (explicit type AND legacy "layout" key) raises DotsConfigException',
        () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": {
      "pageNumber": 1,
      "type": "albumSpread",
      "layout": "l1",
      "header": {},
      "footer": { "wordmark": "X" }
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
  });
}
