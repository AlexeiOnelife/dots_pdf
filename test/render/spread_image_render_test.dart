import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG (smallest valid payload).
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

void main() {
  late MemoryFileSystem fs;

  setUp(() async {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
    await fs.directory('/assets').create(recursive: true);
    await fs.file('/assets/spread.png').writeAsBytes(_onePixelPng());
  });

  group('DotsSpreadImageElement rendering via DotsGenerator.generatePairs', () {
    test(
      'pair_001.pdf contains both halves of the spread image and is larger '
      'than the equivalent pair without it',
      () async {
        final docs = fs.directory('/docs');
        final generator = DotsGenerator(fileSystem: fs, documentsDir: docs);

        const baselineTemplate = DotsTemplate(
          documentId: 'doc_no_spread',
          pageSize: DotsPageSize(width: 400, height: 300),
          pages: [
            DotsElementsPage(pageNumber: 1, elements: []),
            DotsElementsPage(pageNumber: 2, elements: []),
          ],
        );
        const spreadTemplate = DotsTemplate(
          documentId: 'doc_spread',
          pageSize: DotsPageSize(width: 400, height: 300),
          pages: [
            DotsElementsPage(
              pageNumber: 1,
              elements: [
                DotsSpreadImageElement(
                  x: 0,
                  y: 0,
                  assetPath: '/assets/spread.png',
                  spreadWidth: 800,
                  height: 300,
                  half: DotsSpreadHalf.left,
                ),
              ],
            ),
            DotsElementsPage(
              pageNumber: 2,
              elements: [
                DotsSpreadImageElement(
                  x: 0,
                  y: 0,
                  assetPath: '/assets/spread.png',
                  spreadWidth: 800,
                  height: 300,
                  half: DotsSpreadHalf.right,
                ),
              ],
            ),
          ],
        );

        final baselineEvents =
            await generator.generatePairs(template: baselineTemplate).toList();
        expect(baselineEvents.last, isA<PdfGenerationCompleted>());

        final spreadEvents =
            await generator.generatePairs(template: spreadTemplate).toList();
        expect(
          spreadEvents.last,
          isA<PdfGenerationCompleted>(),
          reason: 'spread generation should succeed, got ${spreadEvents.last}',
        );

        final baselineDir =
            await generator.pairsDirPathFor('doc_no_spread');
        final spreadDir = await generator.pairsDirPathFor('doc_spread');

        final baselinePair = fs.file('$baselineDir/pair_001.pdf');
        final spreadPair = fs.file('$spreadDir/pair_001.pdf');
        expect(await baselinePair.exists(), isTrue);
        expect(await spreadPair.exists(), isTrue);

        final baselineBytes = await baselinePair.readAsBytes();
        final spreadBytes = await spreadPair.readAsBytes();
        expect(_hasPdfMagic(spreadBytes), isTrue);
        expect(
          spreadBytes.length,
          greaterThan(baselineBytes.length),
          reason: 'spread-image pair should be larger than the empty pair',
        );
      },
    );

    test(
      'a URL-sourced spreadImage is fetched once and rendered into the PDF',
      () async {
        final docs = fs.directory('/docs');
        final fetched = <Uri>[];
        Future<List<int>> fetcher(Uri url) async {
          fetched.add(url);
          return _onePixelPng();
        }

        final generator = DotsGenerator(
          fileSystem: fs,
          documentsDir: docs,
          urlFetcher: fetcher,
        );

        const template = DotsTemplate(
          documentId: 'doc_url_spread',
          pageSize: DotsPageSize(width: 400, height: 300),
          pages: [
            DotsElementsPage(
              pageNumber: 1,
              elements: [
                DotsSpreadImageElement(
                  x: 0,
                  y: 0,
                  assetPath: 'https://example.com/wide.png',
                  spreadWidth: 800,
                  height: 300,
                  half: DotsSpreadHalf.left,
                ),
              ],
            ),
            DotsElementsPage(
              pageNumber: 2,
              elements: [
                DotsSpreadImageElement(
                  x: 0,
                  y: 0,
                  assetPath: 'https://example.com/wide.png',
                  spreadWidth: 800,
                  height: 300,
                  half: DotsSpreadHalf.right,
                ),
              ],
            ),
          ],
        );

        final events =
            await generator.generatePairs(template: template).toList();
        expect(
          events.last,
          isA<PdfGenerationCompleted>(),
          reason: 'expected success, got ${events.last}',
        );

        // The renderer caches the download per-URL inside its asset
        // loader, so two pages referencing the same URL share one
        // network fetch.
        expect(fetched, hasLength(1));
        expect(
          fetched.single.toString(),
          'https://example.com/wide.png',
        );

        final dir = await generator.pairsDirPathFor('doc_url_spread');
        final bytes = await fs.file('$dir/pair_001.pdf').readAsBytes();
        expect(_hasPdfMagic(bytes), isTrue);
      },
    );
  });
}
