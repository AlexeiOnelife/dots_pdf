import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../logging/dots_logger.dart';
import 'dots_pdf_rasterizer.dart';

/// Renders a freshly generated PDF to one PNG per page, cropping the
/// print-only bleed (and, for the cover, the wrap) off every edge.
///
/// The generator streams pages one at a time through the injected
/// [DotsPdfRasterizer] so only a single decoded [img.Image] is ever
/// alive in memory. Callers receive the list of written file paths in
/// document order.
class DotsPagePreviewGenerator {
  /// Creates a preview generator.
  ///
  /// [fileSystem] is the `package:file` abstraction used for every I/O
  /// operation, [rasterizer] is the seam that turns PDF bytes into
  /// page PNGs, and [logger] receives non-fatal status messages.
  /// [dpi] is the rasterization density passed to the rasterizer.
  DotsPagePreviewGenerator({
    required final FileSystem fileSystem,
    required this.rasterizer,
    required final DotsLogger logger,
    this.dpi = 150,
  })  : fs = fileSystem,
        log = logger;

  /// File-system seam the generator writes through.
  final FileSystem fs;

  /// Rasterizer that turns PDF bytes into PNG pages.
  final DotsPdfRasterizer rasterizer;

  /// Logger for non-fatal diagnostics.
  final DotsLogger log;

  /// Rasterization density in dots per inch.
  final double dpi;

  /// Millimetres per inch — used to convert the bleed/wrap inset into
  /// raster pixels at the chosen [dpi].
  static const double _mmPerInch = 25.4;

  /// Rasterizes [pdfBytes], crops the bleed (and wrap, if [wrapMm] > 0)
  /// off every page, and writes `<previewDir>/<prefix>page_001.png`,
  /// `<prefix>page_002.png`, … in document order. The prefix is
  /// empty by default but callers (e.g. the pairs pipeline) may pass
  /// e.g. `'pair_001_'` to disambiguate alongside other pairs.
  ///
  /// [onPageWritten], when provided, is invoked once per written file
  /// in document order so callers can drive a per-page progress UI
  /// without buffering the entire result set first.
  ///
  /// Returns the list of written file paths in the same order the
  /// rasterizer emitted them.
  Future<List<String>> generate({
    required final Uint8List pdfBytes,
    required final Directory previewDir,
    required final double bleedMm,
    final double wrapMm = 0,
    final String filenamePrefix = '',
    final void Function(String path)? onPageWritten,
  }) async {
    if (!await previewDir.exists()) {
      await previewDir.create(recursive: true);
    }

    final double cropInsetPx = (bleedMm + wrapMm) * dpi / _mmPerInch;
    final int cropInset = cropInsetPx.round();

    final List<String> writtenPaths = <String>[];
    var pageIndex = 0;

    await for (final DotsPdfRasterPage page
        in rasterizer.raster(pdfBytes, dpi: dpi)) {
      pageIndex += 1;
      final String paddedIndex = pageIndex.toString().padLeft(3, '0');
      final String filename = '${filenamePrefix}page_$paddedIndex.png';
      final String outPath = p.join(previewDir.path, filename);

      // Decode → crop → encode → write. The `decoded` and `cropped`
      // locals fall out of scope before the next loop iteration, so
      // only one decoded image is alive at a time.
      final img.Image? decoded = img.decodePng(page.pngBytes);
      if (decoded == null) {
        log.warn(
          'preview: failed to decode page $pageIndex PNG '
          '(${page.pngBytes.length} bytes)',
        );
        continue;
      }

      final int width = decoded.width;
      final int height = decoded.height;
      final int cropX = cropInset.clamp(0, width).toInt();
      final int cropY = cropInset.clamp(0, height).toInt();
      final int cropW = (width - 2 * cropInset).clamp(1, width).toInt();
      final int cropH = (height - 2 * cropInset).clamp(1, height).toInt();

      final img.Image cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
      final Uint8List pngBytes = Uint8List.fromList(img.encodePng(cropped));

      await fs.file(outPath).writeAsBytes(pngBytes, flush: true);
      writtenPaths.add(outPath);
      onPageWritten?.call(outPath);
    }

    return writtenPaths;
  }
}
