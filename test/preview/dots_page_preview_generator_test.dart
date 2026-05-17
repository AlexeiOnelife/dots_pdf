import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/preview/dots_page_preview_generator.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Deterministic rasterizer that emits [pageCount] flat-coloured RGB
/// pages of size [widthPx]×[heightPx]. Used to exercise the preview
/// pipeline without booting a real PDF engine.
class _FakeRasterizer implements DotsPdfRasterizer {
  _FakeRasterizer({
    required this.pageCount,
    this.widthPx = 200,
    this.heightPx = 280,
  });

  final int pageCount;
  final int widthPx;
  final int heightPx;
  int callCount = 0;
  final List<double> dpis = <double>[];

  @override
  Stream<DotsPdfRasterPage> raster(
    final Uint8List pdfBytes, {
    final double dpi = 150,
  }) async* {
    callCount += 1;
    dpis.add(dpi);
    for (var i = 0; i < pageCount; i++) {
      final img.Image page = img.Image(width: widthPx, height: heightPx);
      // Fill with a distinct flat colour per page so we can sanity-check
      // ordering downstream if we ever want to.
      final int shade = 20 + i * 40;
      img.fill(page, color: img.ColorRgb8(shade, shade, shade));
      final Uint8List png = Uint8List.fromList(img.encodePng(page));
      yield DotsPdfRasterPage(
        widthPx: widthPx,
        heightPx: heightPx,
        pngBytes: png,
      );
    }
  }
}

void main() {
  group('DotsPagePreviewGenerator', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
    });

    test('writes one PNG per page, cropped to remove the 3 mm bleed',
        () async {
      final _FakeRasterizer rasterizer =
          _FakeRasterizer(pageCount: 3);
      final DotsPagePreviewGenerator generator = DotsPagePreviewGenerator(
        fileSystem: fs,
        rasterizer: rasterizer,
        logger: const DotsSilentLogger(),
      );
      final previewDir = fs.directory('/previews');
      final List<String> paths = await generator.generate(
        pdfBytes: Uint8List(0),
        previewDir: previewDir,
        bleedMm: 3,
      );

      expect(paths, hasLength(3));
      expect(paths[0], endsWith('/page_001.png'));
      expect(paths[1], endsWith('/page_002.png'));
      expect(paths[2], endsWith('/page_003.png'));

      // Crop inset for 3 mm @ 150 dpi: 3 * 150 / 25.4 = 17.716… ≈ 18 px.
      // → expected cropped image is 200-36 × 280-36 = 164×244.
      final Uint8List firstBytes =
          await fs.file(paths.first).readAsBytes();
      final img.Image? decoded = img.decodePng(firstBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThan(200));
      expect(decoded.height, lessThan(280));
      expect(decoded.width, 200 - 2 * 18);
      expect(decoded.height, 280 - 2 * 18);
    });

    test('applies a larger inset when wrapMm is non-zero', () async {
      final _FakeRasterizer rasterizer = _FakeRasterizer(
        pageCount: 1,
        widthPx: 400,
        heightPx: 500,
      );
      final DotsPagePreviewGenerator generator = DotsPagePreviewGenerator(
        fileSystem: fs,
        rasterizer: rasterizer,
        logger: const DotsSilentLogger(),
      );
      final List<String> paths = await generator.generate(
        pdfBytes: Uint8List(0),
        previewDir: fs.directory('/previews'),
        bleedMm: 3,
        wrapMm: 20,
      );
      // 23 mm * 150 / 25.4 ≈ 135.83 → 136 px crop inset.
      // → expected cropped image is 400-272 × 500-272 = 128×228.
      final img.Image? decoded =
          img.decodePng(await fs.file(paths.single).readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, 400 - 2 * 136);
      expect(decoded.height, 500 - 2 * 136);
    });

    test('invokes the per-page callback in document order', () async {
      final _FakeRasterizer rasterizer = _FakeRasterizer(pageCount: 2);
      final DotsPagePreviewGenerator generator = DotsPagePreviewGenerator(
        fileSystem: fs,
        rasterizer: rasterizer,
        logger: const DotsSilentLogger(),
      );
      final List<String> observed = <String>[];
      final List<String> paths = await generator.generate(
        pdfBytes: Uint8List(0),
        previewDir: fs.directory('/previews'),
        bleedMm: 3,
        onPageWritten: observed.add,
      );
      expect(observed, paths);
    });

    test('respects a custom filename prefix', () async {
      final _FakeRasterizer rasterizer = _FakeRasterizer(pageCount: 2);
      final DotsPagePreviewGenerator generator = DotsPagePreviewGenerator(
        fileSystem: fs,
        rasterizer: rasterizer,
        logger: const DotsSilentLogger(),
      );
      final List<String> paths = await generator.generate(
        pdfBytes: Uint8List(0),
        previewDir: fs.directory('/previews'),
        bleedMm: 3,
        filenamePrefix: 'pair_007_',
      );
      expect(paths, hasLength(2));
      expect(paths[0], endsWith('/pair_007_page_001.png'));
      expect(paths[1], endsWith('/pair_007_page_002.png'));
    });
  });
}
