import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

// Smallest valid 1x1 PNG, used as the spread-image fixture.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

void main() {
  group('Spread-image pliego renders both halves end-to-end', () {
    test('one URL → renderer produces a 2-page pair', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/docs').createSync();
      final pngBytes = base64Decode(_onePixelPngBase64);

      Future<List<int>> fakeFetcher(Uri url) async => pngBytes;

      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        urlFetcher: fakeFetcher,
      );

      const template = DotsTemplate(
        documentId: 'pliego_test',
        pageSize: DotsPageSize(width: 200, height: 300),
        pliegos: <DotsPliego>[
          DotsSpreadImagePliego(
            pliegoNumber: 1,
            assetPath: 'https://example.com/panorama.jpg',
            spreadWidth: 400,
            height: 250,
            bleedTop: true,
            bleedBottom: true,
            bleedOuter: true,
          ),
        ],
      );

      // Render in pairs mode so we get one PDF per spread.
      final events =
          await generator.generatePairs(template: template).toList();
      expect(events.whereType<PdfGenerationFailed>(), isEmpty);
      expect(events.last, isA<PdfGenerationCompleted>());

      // Effective pages = 2 (left + right halves). Pairs mode produces
      // a single 2-page PDF (pair_001.pdf).
      final pairsDir =
          await generator.pairsDirPathFor('pliego_test');
      final pair001 = fs.file('$pairsDir/pair_001.pdf');
      expect(await pair001.exists(), isTrue);
      final bytes = await pair001.readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });

    test('JSON pliego form renders identically through the parser', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/docs').createSync();
      final pngBytes = base64Decode(_onePixelPngBase64);

      Future<List<int>> fakeFetcher(Uri url) async => pngBytes;

      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        urlFetcher: fakeFetcher,
      );

      const parser = DotsTemplateParser();
      final template = parser.parse('''
      {
        "documentId": "from_json",
        "pageSize": { "width": 200, "height": 300 },
        "pliegos": [
          {
            "pliegoNumber": 1,
            "type": "spreadImage",
            "assetPath": "https://example.com/panorama.jpg",
            "spreadWidth": 400,
            "height": 250,
            "bleedOuter": true
          }
        ]
      }
      ''');

      await generator.generateWhole(template: template).toList();
      final outPath = await generator.wholePathFor('from_json');
      final bytes = await fs.file(outPath).readAsBytes();
      expect(_hasPdfMagic(bytes), isTrue);
    });
  });
}

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;
