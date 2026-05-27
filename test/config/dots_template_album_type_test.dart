import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// Base template JSON without albumType, for backwards-compat and hash tests.
const _baseJson = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pages": [
    { "pageNumber": 1, "elements": [] }
  ]
}
''';

void main() {
  const parser = DotsTemplateParser();

  group('DotsTemplateParser — albumType field (R1)', () {
    // ---- round-trip for every enum value ----

    for (final value in DotsAlbumType.values) {
      test('parses albumType "${value.name}" correctly', () {
        final json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "albumType": "${value.name}",
  "pages": [
    { "pageNumber": 1, "elements": [] }
  ]
}
''';
        final template = parser.parse(json);
        expect(template.albumType, equals(value));
      });
    }

    // ---- absent albumType yields null ----

    test('albumType absent yields null', () {
      final template = parser.parse(_baseJson);
      expect(template.albumType, isNull);
    });

    // ---- unknown string raises DotsConfigException ----

    test('unknown albumType raises DotsConfigException at \$.albumType', () {
      const json = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "albumType": "quinceañera",
  "pages": [
    { "pageNumber": 1, "elements": [] }
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
                contains('quinceañera'),
              ),
        ),
      );
    });

    // ---- contentHash differs when albumType differs ----

    test('albumType participates in contentHash', () {
      const withAlbumType = '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "albumType": "boda",
  "pages": [
    { "pageNumber": 1, "elements": [] }
  ]
}
''';
      final withHash = parser.parse(withAlbumType).contentHash;
      final withoutHash = parser.parse(_baseJson).contentHash;
      expect(withHash, isNot(withoutHash));
    });
  });
}
