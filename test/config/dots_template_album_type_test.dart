import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// Base template JSON without category, for default-value and hash tests.
const _baseJson = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": { "pageNumber": 1, "elements": [] },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';

void main() {
  const parser = DotsTemplateParser();

  group('DotsTemplateParser — category field (R1)', () {
    // ---- round-trip for every enum value ----

    for (final value in DotsAlbumType.values) {
      test('parses category "${value.name}" correctly', () {
        final json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "category": "${value.name}",
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": { "pageNumber": 1, "elements": [] },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';
        final template = parser.parse(json);
        expect(template.category, equals(value));
      });
    }

    // ---- absent category defaults to generalEventos ----

    test('category absent yields generalEventos default', () {
      final template = parser.parse(_baseJson);
      expect(template.category, equals(DotsAlbumType.generalEventos));
    });

    // ---- deprecated albumType key is rejected with a migration hint ----

    test('albumType key is rejected with a migration hint', () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "albumType": "boda",
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": { "pageNumber": 1, "elements": [] },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>()
              .having(
                (e) => e.pointer,
                'pointer',
                contains(r'$.albumType'),
              )
              .having(
                (e) => e.message,
                'message',
                contains('category'),
              ),
        ),
      );
    });

    // ---- unknown category string raises DotsConfigException ----

    test('unknown category raises DotsConfigException at \$.category', () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "category": "quinceañera",
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": { "pageNumber": 1, "elements": [] },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>()
              .having(
                (e) => e.pointer,
                'pointer',
                contains(r'$.category'),
              )
              .having(
                (e) => e.message,
                'message',
                contains('quinceañera'),
              ),
        ),
      );
    });

    // ---- contentHash differs when category differs ----

    test('category participates in contentHash', () {
      const withBoda = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "category": "boda",
  "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "layout",
            "left": { "pageNumber": 1, "elements": [] },
            "right": { "pageNumber": 0, "elements": [] }
          }
        ]
}
''';
      final bodaHash = parser.parse(withBoda).contentHash;
      final defaultHash = parser.parse(_baseJson).contentHash;
      expect(bodaHash, isNot(defaultHash));
    });
  });
}
