import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:printing/printing.dart';

/// One rasterized page emitted by a [DotsPdfRasterizer].
///
/// The image is encoded as PNG so callers can hand it straight to a
/// decoder (e.g. `package:image`) or write it to disk. Width and height
/// describe the full raster — for cover PDFs this includes the bleed
/// and wrap, which the preview generator crops out later.
@immutable
class DotsPdfRasterPage {
  /// Creates a raster page descriptor.
  const DotsPdfRasterPage({
    required this.widthPx,
    required this.heightPx,
    required this.pngBytes,
  });

  /// Full raster width in pixels (includes bleed/wrap for the cover).
  final int widthPx;

  /// Full raster height in pixels (includes bleed/wrap for the cover).
  final int heightPx;

  /// PNG-encoded bytes of the rasterized page.
  final Uint8List pngBytes;
}

/// Renders a PDF byte stream into one PNG per page.
///
/// This is the rasterization seam used by the library so tests can
/// inject a deterministic fake. The default implementation is
/// [DotsPdfRasterizer.printing], which wraps the `printing` package
/// and only works inside a real Flutter runtime (it relies on a
/// platform channel that is not present in `flutter test`).
abstract class DotsPdfRasterizer {
  /// Renders [pdfBytes] one page at a time at [dpi].
  ///
  /// The stream emits one [DotsPdfRasterPage] per page in document
  /// order. Implementations should stream rather than buffer all pages
  /// in memory.
  Stream<DotsPdfRasterPage> raster(Uint8List pdfBytes, {double dpi});

  /// Convenience factory wired to the `printing` package's
  /// `Printing.raster()`. Works in real Flutter apps but NOT in pure
  /// `flutter test` (no platform channel). Tests should inject a fake.
  factory DotsPdfRasterizer.printing() = _PrintingRasterizer;
}

/// `printing`-backed rasterizer used in real Flutter apps.
///
/// Kept package-private: callers go through
/// [DotsPdfRasterizer.printing]. The implementation streams pages from
/// `Printing.raster` and converts each one to a PNG via the page's
/// `toPng()` method, which performs the encoding on the platform side
/// and returns the bytes directly.
class _PrintingRasterizer implements DotsPdfRasterizer {
  _PrintingRasterizer();

  @override
  Stream<DotsPdfRasterPage> raster(
    final Uint8List pdfBytes, {
    final double dpi = 150,
  }) async* {
    final Stream<PdfRaster> source = Printing.raster(pdfBytes, dpi: dpi);
    await for (final PdfRaster raster in source) {
      final Uint8List png = await raster.toPng();
      yield DotsPdfRasterPage(
        widthPx: raster.width,
        heightPx: raster.height,
        pngBytes: png,
      );
    }
  }
}
