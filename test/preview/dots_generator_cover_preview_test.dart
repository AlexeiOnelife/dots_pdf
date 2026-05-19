import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _solidPng({required final int width, required final int height}) {
  final img.Image image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 160, 200));
  return Uint8List.fromList(img.encodePng(image));
}

class _CoverFakeRasterizer implements DotsPdfRasterizer {
  _CoverFakeRasterizer();

  int callCount = 0;

  @override
  Stream<DotsPdfRasterPage> raster(
    final Uint8List pdfBytes, {
    final double dpi = 150,
  }) async* {
    callCount += 1;
    // A cover PDF is one page. Make it large enough that cropping
    // 23 mm (= bleed + wrap) on each side still leaves a visible
    // interior rectangle.
    final img.Image page = img.Image(width: 1200, height: 1600);
    img.fill(page, color: img.ColorRgb8(180, 60, 40));
    yield DotsPdfRasterPage(
      widthPx: page.width,
      heightPx: page.height,
      pngBytes: Uint8List.fromList(img.encodePng(page)),
    );
  }
}

void main() {
  late MemoryFileSystem fs;

  setUp(() async {
    fs = MemoryFileSystem.test();
    await fs.directory('/docs').create(recursive: true);
    await fs.directory('/assets').create(recursive: true);
    await fs.file('/assets/front.png').writeAsBytes(
          _solidPng(
            width: DotsCoverDesign.square.minSourceWidthPx,
            height: DotsCoverDesign.square.minSourceHeightPx,
          ),
        );
  });

  DotsCoverTemplate template({final String documentId = 'doc_cover_pv'}) =>
      DotsCoverTemplate(
        documentId: documentId,
        geometry: DotsCoverGeometry(
          pageCount: 132,
          paperSubstrate: DotsPaperSubstrate.uncoated150,
          supplier: DotsSupplier.europa,
        ),
        design: DotsCoverDesign.square,
        frontArtworkPath: '/assets/front.png',
      );

  group('DotsGenerator.generateCover + preview generation', () {
    test('rasterizes the cover with wrap-aware crop and writes a PNG',
        () async {
      final rasterizer = _CoverFakeRasterizer();
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );

      final events =
          await generator.generateCover(template: template()).toList();

      expect(events.last, isA<PdfGenerationCompleted>());
      final completed = events.last as PdfGenerationCompleted;
      expect(completed.previewPaths, hasLength(1));
      expect(
        completed.previewPaths.single,
        '/docs/dots_pdf/preview/doc_cover_pv/page_001.png',
      );
      expect(rasterizer.callCount, 1);

      // (bleed + wrap) = 23 mm → 23 * 150 / 25.4 ≈ 135.83 → 136 px.
      // Source 1200×1600 → cropped 928×1328.
      final Uint8List bytes =
          await fs.file(completed.previewPaths.single).readAsBytes();
      final img.Image? decoded = img.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1200 - 2 * 136);
      expect(decoded.height, 1600 - 2 * 136);
    });

    test('cache hit returns the cover preview without re-rasterizing',
        () async {
      final rasterizer = _CoverFakeRasterizer();
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: fs.directory('/docs'),
        rasterizer: rasterizer,
      );

      await generator
          .generateCover(template: template(documentId: 'doc_cover_cache'))
          .toList();
      expect(rasterizer.callCount, 1);

      final second = await generator
          .generateCover(template: template(documentId: 'doc_cover_cache'))
          .toList();
      expect(second, hasLength(1));
      final hit = second.single as PdfGenerationCacheHit;
      expect(hit.previewPaths, hasLength(1));
      expect(rasterizer.callCount, 1);
    });
  });
}
