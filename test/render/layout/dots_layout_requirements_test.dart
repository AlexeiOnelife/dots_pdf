import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsLayoutCode.requirements', () {
    test('photo-only layouts declare zero captions', () {
      final photoOnly = <DotsLayoutCode>[
        DotsLayoutCode.l1, DotsLayoutCode.l1a, DotsLayoutCode.l1b,
        DotsLayoutCode.l1c, DotsLayoutCode.l1d, DotsLayoutCode.l1e,
        DotsLayoutCode.l2a, DotsLayoutCode.l2b, DotsLayoutCode.l2c,
        DotsLayoutCode.l3a, DotsLayoutCode.l4a, DotsLayoutCode.l4b,
        DotsLayoutCode.l6a, DotsLayoutCode.l8,
      ];
      for (final code in photoOnly) {
        final r = code.requirements;
        expect(r.requiredCaptionKinds, isEmpty, reason: code.name);
        expect(r.optionalCaptionKinds, isEmpty, reason: code.name);
      }
    });

    test('photo counts match the solver output', () {
      const solver = DotsLayoutSolver();
      final geometry = DotsPageGeometry.dotbookDefault();
      for (final code in DotsLayoutCode.values) {
        final slots = solver.solve(code, geometry);
        final photoSlots =
            slots.where((s) => s.kind == DotsSlotKind.photo).length;
        expect(
          code.requirements.photoCount,
          photoSlots,
          reason: 'photoCount mismatch for ${code.name}',
        );
      }
    });

    test('L_hito requires title + body; date and qr are optional', () {
      final r = DotsLayoutCode.lhito.requirements;
      expect(r.photoCount, 0);
      expect(
        r.requiredCaptionKinds,
        containsAll(<DotsSlotKind>[
          DotsSlotKind.captionTitle,
          DotsSlotKind.captionBody,
        ]),
      );
      expect(
        r.optionalCaptionKinds,
        containsAll(<DotsSlotKind>[
          DotsSlotKind.captionDate,
          DotsSlotKind.qrCard,
        ]),
      );
    });

    test('L7 declares optional date + body; nothing required', () {
      final r = DotsLayoutCode.l7.requirements;
      expect(r.photoCount, 2);
      expect(r.requiredCaptionKinds, isEmpty);
      expect(
        r.optionalCaptionKinds,
        containsAll(<DotsSlotKind>[
          DotsSlotKind.captionDate,
          DotsSlotKind.captionBody,
        ]),
      );
    });

    test('parser rejects an L_hito missing the required title caption', () {
      const parser = DotsTemplateParser();
      const json = '''
      {
        "documentId": "d",
        "pageSize": { "width": 100, "height": 100 },
        "pages": [
          {
            "pageNumber": 1,
            "layout": "lhito",
            "captions": {
              "date": "May 17, 2026",
              "body": "Body without a title."
            }
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
            contains('captionTitle'),
          ),
        ),
      );
    });

    test('parser accepts an L_hito missing only optional captions', () {
      const parser = DotsTemplateParser();
      const json = '''
      {
        "documentId": "d",
        "pageSize": { "width": 100, "height": 100 },
        "pages": [
          {
            "pageNumber": 1,
            "layout": "lhito",
            "captions": {
              "title": "A milestone",
              "body": "Body without date or QR."
            }
          }
        ]
      }
      ''';
      // Should not throw.
      final template = parser.parse(json);
      final page = template.pages.single as DotsLayoutPage;
      expect(page.captions[DotsSlotKind.captionTitle], 'A milestone');
      expect(page.captions[DotsSlotKind.captionDate], isNull);
    });
  });

  // Sanity: existing tests still build. Force MemoryFileSystem import so
  // the package barrel doesn't drop unused.
  test('module compiles', () {
    expect(MemoryFileSystem.test(), isNotNull);
  });
}
