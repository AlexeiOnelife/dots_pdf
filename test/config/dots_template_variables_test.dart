import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

String _templateWithText(String value) => '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pages": [
    {
      "pageNumber": 1,
      "elements": [
        { "type": "text", "value": "$value", "x": 0, "y": 0, "fontSize": 12 }
      ]
    }
  ]
}
''';

String _templateWithTwoTexts(String v1, String v2) => '''
{
  "documentId": "doc_1",
  "pageSize": { "width": 595.0, "height": 842.0 },
  "pages": [
    {
      "pageNumber": 1,
      "elements": [
        { "type": "text", "value": "$v1", "x": 0, "y": 0, "fontSize": 12 },
        { "type": "text", "value": "$v2", "x": 0, "y": 20, "fontSize": 12 }
      ]
    }
  ]
}
''';

DotsTextElement _firstText(DotsTemplate template) {
  final page = template.pages.single as DotsElementsPage;
  return page.elements.whereType<DotsTextElement>().first;
}

List<DotsTextElement> _allTexts(DotsTemplate template) {
  final page = template.pages.single as DotsElementsPage;
  return page.elements.whereType<DotsTextElement>().toList();
}

void main() {
  const parser = DotsTemplateParser();

  group('DotsTemplateParser — variable substitution (R2)', () {
    // ---- single token substituted ----

    test(
        'DotsTemplateParser — variable substitution replaces single token in text element',
        () {
      final template = parser.parse(
        _templateWithText(r'Hola {Nombre}'),
        variables: const {'{Nombre}': 'María'},
      );
      expect(_firstText(template).value, equals('Hola María'));
    });

    // ---- multiple tokens in one element ----

    test(
        'DotsTemplateParser — variable substitution replaces multiple tokens in one element',
        () {
      final template = parser.parse(
        _templateWithText(r'{Protagonistas} — {Año}'),
        variables: const {
          '{Protagonistas}': 'Ana y Luis',
          '{Año}': '2024',
        },
      );
      expect(_firstText(template).value, equals('Ana y Luis — 2024'));
    });

    // ---- unmatched token left intact ----

    test('DotsTemplateParser — unmatched token left as literal text', () {
      final template = parser.parse(
        _templateWithText(r'Album de {Nombre}'),
        variables: const {},
      );
      expect(_firstText(template).value, equals('Album de {Nombre}'));
    });

    // ---- non-matching keys leave tokens intact ----

    test(
        'variables map with non-matching keys leaves source tokens intact', () {
      final template = parser.parse(
        _templateWithText(r'Hola {Nombre}'),
        variables: const {'{OtherToken}': 'NeverUsed'},
      );
      expect(_firstText(template).value, equals('Hola {Nombre}'));
    });

    // ---- empty map is no-op ----

    test('DotsTemplateParser — empty variables map is a no-op', () {
      const raw = r'Album de {Nombre}';
      final template = parser.parse(
        _templateWithText(raw),
        variables: const {},
      );
      expect(_firstText(template).value, equals(raw));
    });

    // ---- substitution does not cross element boundaries ----

    test(
        'DotsTemplateParser — substitution does not cross element boundaries',
        () {
      // Token is split across two elements: first ends with "{Tok", second
      // starts with "en} suffix". The full token "{Token}" never exists in
      // either element value alone, so neither should be modified.
      final template = parser.parse(
        _templateWithTwoTexts(r'prefix {Tok', r'en} suffix'),
        variables: const {'{Token}': 'REPLACED'},
      );
      final texts = _allTexts(template);
      expect(texts[0].value, equals(r'prefix {Tok'));
      expect(texts[1].value, equals('en} suffix'));
    });

    // ---- NOMBREHIJO treated like any other token ----

    test('DotsTemplateParser — NOMBREHIJO substituted like any other token',
        () {
      final template = parser.parse(
        _templateWithText(r'Para {NOMBREHIJO}'),
        variables: const {'{NOMBREHIJO}': 'Sofía'},
      );
      expect(_firstText(template).value, equals('Para Sofía'));
    });
  });
}
