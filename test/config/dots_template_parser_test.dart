import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DotsTemplateParser();

  group('DotsTemplateParser', () {
    test('parses a minimal valid template', () {
      const json = '''
      {
        "documentId": "doc_1",
        "pageSize": { "width": 595.0, "height": 842.0 },
        "pages": [
          {
            "pageNumber": 1,
            "elements": [
              { "type": "text", "value": "hi", "x": 10, "y": 20, "fontSize": 12 },
              { "type": "image", "assetPath": "a.png", "x": 0, "y": 0, "width": 50, "height": 50 }
            ]
          }
        ]
      }
      ''';

      final template = parser.parse(json);

      expect(template.documentId, 'doc_1');
      expect(template.pageSize, const DotsPageSize(width: 595, height: 842));
      expect(template.pages, hasLength(1));
      final page = template.pages.single as DotsElementsPage;
      expect(page.elements, hasLength(2));
      expect(page.elements.first, isA<DotsTextElement>());
      expect(page.elements.last, isA<DotsImageElement>());
    });

    test('throws DotsConfigException on missing documentId', () {
      const json = '''
      { "pageSize": { "width": 1, "height": 1 }, "pages": [] }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('throws DotsConfigException on unknown element type', () {
      const json = '''
      {
        "documentId": "d",
        "pageSize": { "width": 1, "height": 1 },
        "pages": [
          { "pageNumber": 1, "elements": [ { "type": "rectangle", "x": 0, "y": 0 } ] }
        ]
      }
      ''';
      expect(
        () => parser.parse(json),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.pointer,
            'pointer',
            contains('elements[0].type'),
          ),
        ),
      );
    });

    test('throws DotsConfigException on malformed JSON', () {
      expect(
        () => parser.parse('{ not json'),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('content hash is stable across equal templates', () {
      const json = '''
      {
        "documentId": "doc_1",
        "pageSize": { "width": 100, "height": 200 },
        "pages": [
          { "pageNumber": 1, "elements": [] }
        ]
      }
      ''';
      final a = parser.parse(json);
      final b = parser.parse(json);
      expect(a.contentHash, b.contentHash);
    });

    test('parses image bleed flags (all default to false when omitted)', () {
      const json = '''
      {
        "documentId": "d",
        "pageSize": { "width": 1, "height": 1 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "image", "assetPath": "a.png",
              "x": 0, "y": 0, "width": 10, "height": 10 }
          ] }
        ]
      }
      ''';
      final page = parser.parse(json).pages.single as DotsElementsPage;
      final image = page.elements.single as DotsImageElement;
      expect(image.bleedTop, isFalse);
      expect(image.bleedBottom, isFalse);
      expect(image.bleedLeft, isFalse);
      expect(image.bleedRight, isFalse);
    });

    test('parses explicit image bleed flags', () {
      const json = '''
      {
        "documentId": "d",
        "pageSize": { "width": 1, "height": 1 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "image", "assetPath": "a.png",
              "x": 0, "y": 0, "width": 10, "height": 10,
              "bleedTop": true, "bleedRight": true }
          ] }
        ]
      }
      ''';
      final page = parser.parse(json).pages.single as DotsElementsPage;
      final image = page.elements.single as DotsImageElement;
      expect(image.bleedTop, isTrue);
      expect(image.bleedRight, isTrue);
      expect(image.bleedBottom, isFalse);
      expect(image.bleedLeft, isFalse);
    });

    test('bleed flags participate in equality and contentHash', () {
      const base = '''
      {
        "documentId": "d",
        "pageSize": { "width": 1, "height": 1 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "image", "assetPath": "a.png",
              "x": 0, "y": 0, "width": 10, "height": 10 }
          ] }
        ]
      }
      ''';
      const bled = '''
      {
        "documentId": "d",
        "pageSize": { "width": 1, "height": 1 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "image", "assetPath": "a.png",
              "x": 0, "y": 0, "width": 10, "height": 10,
              "bleedTop": true }
          ] }
        ]
      }
      ''';
      expect(
        parser.parse(base).contentHash,
        isNot(parser.parse(bled).contentHash),
      );
    });

    test('content hash changes when content changes', () {
      const base = '''
      {
        "documentId": "doc_1",
        "pageSize": { "width": 100, "height": 200 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "text", "value": "a", "x": 0, "y": 0, "fontSize": 10 }
          ] }
        ]
      }
      ''';
      const mutated = '''
      {
        "documentId": "doc_1",
        "pageSize": { "width": 100, "height": 200 },
        "pages": [
          { "pageNumber": 1, "elements": [
            { "type": "text", "value": "b", "x": 0, "y": 0, "fontSize": 10 }
          ] }
        ]
      }
      ''';
      expect(
        parser.parse(base).contentHash,
        isNot(parser.parse(mutated).contentHash),
      );
    });
  });

  // ---- R5: backwards-compat — existing fixtures parse unchanged ----

  group('DotsTemplateParser — backwards compatibility (R5)', () {
    // Fixture: a template with no albumType and no variable tokens.
    // The parser must accept it without error and produce identical output
    // whether or not the new albumType/variables plumbing exists.
    const existingFixture = '''
{
  "documentId": "doc_existing",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pages": [
    {
      "pageNumber": 1,
      "elements": [
        { "type": "text", "value": "hello world", "x": 10, "y": 20, "fontSize": 12 },
        { "type": "image", "assetPath": "a.png", "x": 0, "y": 0, "width": 50, "height": 50 }
      ]
    }
  ]
}
''';

    test(
        'DotsTemplateParser — existing fixture parses unchanged after slice (backwards compat)',
        () {
      // Must not throw.
      final template = parser.parse(existingFixture);

      // category must be null — no albumType key in JSON.
      expect(template.category, isNull);

      // All existing fields must be intact.
      expect(template.documentId, equals('doc_existing'));
      expect(template.pages, hasLength(1));
      final page = template.pages.single as DotsElementsPage;
      expect(page.elements, hasLength(2));
      final text = page.elements.first as DotsTextElement;
      // Literal text must be unchanged (no substitution with empty map).
      expect(text.value, equals('hello world'));
    });

    test(
        'DotsTemplateParser — template without variables map parses unchanged',
        () {
      // Calling parseMap without the variables argument (default const {})
      // must leave all DotsTextElement.value strings as-is.
      final template = parser.parse(existingFixture);
      final page = template.pages.single as DotsElementsPage;
      final text = page.elements.first as DotsTextElement;
      expect(text.value, equals('hello world'));
    });
  });
}
