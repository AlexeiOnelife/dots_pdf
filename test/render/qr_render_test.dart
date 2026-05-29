import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page size matched (roughly) to `DotsPageGeometry.dotbookDefault()`
/// — 203 x 254 mm trim ~= 575.43 x 720.0 pt. Mirrors the value used in
/// `test/render/layout_page_render_test.dart` so the byte-size
/// comparisons below are apples-to-apples.
const DotsPageSize _dotbookPageSize =
    DotsPageSize(width: 575.43, height: 720.0);

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

Future<Uint8List> _renderHito({
  required String documentId,
  required Map<DotsSlotKind, String> captions,
}) async {
  final fs = MemoryFileSystem.test();
  fs.directory('/docs').createSync();
  final generator = DotsGenerator(
    fileSystem: fs,
    documentsDir: fs.directory('/docs'),
  );
  final template = DotsTemplate(
    documentId: documentId,
    pageSize: _dotbookPageSize,
    pliegos: <DotsPliego>[
      DotsLayoutPliego(
        pliegoNumber: 1,
        left: DotsLayoutPage(
          pageNumber: 1,
          layoutCode: DotsLayoutCode.lhito,
          captions: captions,
        ),
        right: const DotsElementsPage(pageNumber: 2, elements: []),
      ),
    ],
  );
  final events = await generator.generateWhole(template: template).toList();
  expect(
    events.last,
    isA<PdfGenerationCompleted>(),
    reason: 'render failed: ${events.last}',
  );
  final outPath = await generator.wholePathFor(documentId);
  return fs.file(outPath).readAsBytes();
}

void main() {
  group('QR slot rendering', () {
    test('lhito with a QR payload renders to a valid PDF', () async {
      final bytes = await _renderHito(
        documentId: 'doc_qr_basic',
        captions: <DotsSlotKind, String>{
          DotsSlotKind.captionTitle: 'A milestone',
          DotsSlotKind.captionDate: '2026-05-17',
          DotsSlotKind.captionBody: 'A short body of text.',
          DotsSlotKind.qrCard: 'https://example.com/album/123',
        },
      );

      expect(
        _hasPdfMagic(bytes),
        isTrue,
        reason: 'output must be a real PDF stream',
      );
      expect(bytes.length, greaterThan(500));
    });

    test(
      'a QR payload measurably enlarges the lhito page output',
      () async {
        // Render the same lhito layout with identical captions, the
        // only difference being whether a QR payload is supplied. A
        // real QR matrix encodes far more drawing operations than the
        // bare layout, so the output should be visibly larger.
        const captionsCommon = <DotsSlotKind, String>{
          DotsSlotKind.captionTitle: 'A milestone',
          DotsSlotKind.captionDate: '2026-05-17',
          DotsSlotKind.captionBody: 'A short body of text.',
        };
        final withoutQr = await _renderHito(
          documentId: 'doc_qr_off',
          captions: captionsCommon,
        );
        final withQr = await _renderHito(
          documentId: 'doc_qr_on',
          captions: <DotsSlotKind, String>{
            ...captionsCommon,
            DotsSlotKind.qrCard: 'https://example.com/album/123',
          },
        );

        expect(_hasPdfMagic(withoutQr), isTrue);
        expect(_hasPdfMagic(withQr), isTrue);
        // The matrix for a 29-char URL at medium ECC is ~25x25 modules
        // — each module is a separate path op, so the delta is well
        // above the 200-byte minimum the task calls for.
        expect(
          withQr.length - withoutQr.length,
          greaterThan(200),
          reason:
              'QR rendering should add far more than 200 bytes; got '
              '${withQr.length - withoutQr.length} byte delta',
        );
      },
    );

    test(
      'different QR payloads produce different byte streams',
      () async {
        final a = await _renderHito(
          documentId: 'doc_qr_a',
          captions: const <DotsSlotKind, String>{
            DotsSlotKind.captionTitle: 'A milestone',
            DotsSlotKind.qrCard: 'https://example.com/album/aaaa',
          },
        );
        final b = await _renderHito(
          documentId: 'doc_qr_b',
          captions: const <DotsSlotKind, String>{
            DotsSlotKind.captionTitle: 'A milestone',
            DotsSlotKind.qrCard:
                'https://example.com/album/this-is-a-much-longer-payload',
          },
        );

        expect(_hasPdfMagic(a), isTrue);
        expect(_hasPdfMagic(b), isTrue);

        // Either the byte length must change (different matrix size /
        // module count) or, at the very minimum, the content must
        // differ. Identical bytes would mean the payload had no effect.
        final differentLength = a.length != b.length;
        final differentBytes = !_bytesEqual(a, b);
        expect(
          differentLength || differentBytes,
          isTrue,
          reason: 'different QR payloads must produce different PDFs',
        );
      },
    );
  });
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
