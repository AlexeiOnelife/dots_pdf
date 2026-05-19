import 'dart:typed_data';

import 'package:dots_pdf/src/config/dots_config_exception.dart';
import 'package:dots_pdf/src/cover/dots_cover_design.dart';
import 'package:dots_pdf/src/cover/dots_cover_geometry.dart';
import 'package:dots_pdf/src/cover/dots_cover_renderer.dart';
import 'package:dots_pdf/src/cover/dots_cover_template.dart';
import 'package:dots_pdf/src/cover/dots_paper_substrate.dart';
import 'package:dots_pdf/src/cover/dots_supplier.dart';
import 'package:dots_pdf/src/logging/dots_logger.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Encodes a solid-color PNG at the given pixel dimensions. Used to
/// seed cover-artwork fixtures that meet each design's minimum source
/// size while keeping the byte payload small.
Uint8List _solidPng({required final int width, required final int height}) {
  final img.Image image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 160, 200));
  return Uint8List.fromList(img.encodePng(image));
}

bool _hasPdfMagic(final Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

Future<void> _seedArtworks(final MemoryFileSystem fs) async {
  await fs.directory('/assets').create(recursive: true);
  // One file per design, sized at the per-design minimum.
  await fs.file('/assets/square.png').writeAsBytes(
        _solidPng(
          width: DotsCoverDesign.square.minSourceWidthPx,
          height: DotsCoverDesign.square.minSourceHeightPx,
        ),
      );
  await fs.file('/assets/circle.png').writeAsBytes(
        _solidPng(
          width: DotsCoverDesign.circle.minSourceWidthPx,
          height: DotsCoverDesign.circle.minSourceHeightPx,
        ),
      );
  await fs.file('/assets/linen.png').writeAsBytes(
        _solidPng(
          width: DotsCoverDesign.linen.minSourceWidthPx,
          height: DotsCoverDesign.linen.minSourceHeightPx,
        ),
      );
  await fs.file('/assets/spine.png').writeAsBytes(
        _solidPng(width: 200, height: 800),
      );
  // Intentionally below every design's minimum so validation tests can
  // exercise the failure path.
  await fs.file('/assets/tiny.png').writeAsBytes(
        _solidPng(width: 100, height: 100),
      );
}

DotsCoverGeometry _geometry132({
  final DotsSupplier supplier = DotsSupplier.europa,
}) =>
    DotsCoverGeometry(
      pageCount: 132,
      paperSubstrate: DotsPaperSubstrate.uncoated150,
      supplier: supplier,
    );

String _artworkFor(final DotsCoverDesign design) {
  switch (design) {
    case DotsCoverDesign.square:
      return '/assets/square.png';
    case DotsCoverDesign.circle:
      return '/assets/circle.png';
    case DotsCoverDesign.linen:
      return '/assets/linen.png';
  }
}

DotsCoverTemplate _template({
  required final DotsCoverDesign design,
  final String documentId = 'cover',
  final DotsSupplier supplier = DotsSupplier.europa,
  final String? spineTitle,
  final String? spineArtworkPath,
  final String backgroundColorHex = '#FFFFFF',
  final String? frontArtworkPathOverride,
}) =>
    DotsCoverTemplate(
      documentId: documentId,
      geometry: _geometry132(supplier: supplier),
      design: design,
      frontArtworkPath: frontArtworkPathOverride ?? _artworkFor(design),
      backgroundColorHex: backgroundColorHex,
      spineTitle: spineTitle,
      spineArtworkPath: spineArtworkPath,
    );

void main() {
  late MemoryFileSystem fs;
  late DotsCoverRenderer renderer;

  setUp(() async {
    fs = MemoryFileSystem.test();
    await fs.directory('/out').create(recursive: true);
    await _seedArtworks(fs);
    renderer = DotsCoverRenderer(
      fileSystem: fs,
      logger: const DotsSilentLogger(),
    );
  });

  group('DotsCoverRenderer — produces a valid PDF for every design', () {
    for (final design in DotsCoverDesign.values) {
      test('design = ${design.name}', () async {
        final outPath = '/out/${design.name}.pdf';
        await renderer.render(
          template: _template(design: design, documentId: design.name),
          outputPath: outPath,
        );
        final bytes = await fs.file(outPath).readAsBytes();
        expect(_hasPdfMagic(bytes), isTrue);
        expect(bytes.length, greaterThan(500));
      });
    }
  });

  group('DotsCoverRenderer — common features', () {
    test('spineTitle adds bytes vs. the no-title baseline', () async {
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'no_title',
        ),
        outputPath: '/out/no_title.pdf',
      );
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'with_title',
          spineTitle: 'Memories 2024',
        ),
        outputPath: '/out/with_title.pdf',
      );

      final int noTitleBytes =
          (await fs.file('/out/no_title.pdf').readAsBytes()).length;
      final int withTitleBytes =
          (await fs.file('/out/with_title.pdf').readAsBytes()).length;

      expect(withTitleBytes, greaterThanOrEqualTo(noTitleBytes + 50));
    });

    test('latam omits crop marks; europa includes them', () async {
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'europa',
          supplier: DotsSupplier.europa,
        ),
        outputPath: '/out/europa.pdf',
      );
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'latam',
          supplier: DotsSupplier.latam,
        ),
        outputPath: '/out/latam.pdf',
      );

      final int europaBytes =
          (await fs.file('/out/europa.pdf').readAsBytes()).length;
      final int latamBytes =
          (await fs.file('/out/latam.pdf').readAsBytes()).length;

      expect(
        latamBytes,
        lessThan(europaBytes),
        reason: 'latam should not draw crop marks',
      );
    });

    test('optional spine artwork is rendered when provided', () async {
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'no_spine_art',
        ),
        outputPath: '/out/no_spine.pdf',
      );
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.square,
          documentId: 'with_spine_art',
          spineArtworkPath: '/assets/spine.png',
        ),
        outputPath: '/out/spine.pdf',
      );

      final int withoutBytes =
          (await fs.file('/out/no_spine.pdf').readAsBytes()).length;
      final int withBytes =
          (await fs.file('/out/spine.pdf').readAsBytes()).length;

      expect(withBytes, greaterThan(withoutBytes));
    });

    test('non-default background color changes the rendered PDF', () async {
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.circle,
          documentId: 'bg_white',
        ),
        outputPath: '/out/bg_white.pdf',
      );
      await renderer.render(
        template: _template(
          design: DotsCoverDesign.circle,
          documentId: 'bg_black',
          backgroundColorHex: '#000000',
        ),
        outputPath: '/out/bg_black.pdf',
      );

      final Uint8List whiteBytes =
          await fs.file('/out/bg_white.pdf').readAsBytes();
      final Uint8List blackBytes =
          await fs.file('/out/bg_black.pdf').readAsBytes();
      expect(whiteBytes, isNot(equals(blackBytes)));
    });
  });

  group('DotsCoverRenderer — image-dimension validation', () {
    for (final design in DotsCoverDesign.values) {
      test(
          'rejects an undersized source for ${design.name} '
          'with DotsConfigException', () async {
        expect(
          () => renderer.render(
            template: _template(
              design: design,
              documentId: '${design.name}_tiny',
              frontArtworkPathOverride: '/assets/tiny.png',
            ),
            outputPath: '/out/${design.name}_tiny.pdf',
          ),
          throwsA(
            isA<DotsConfigException>().having(
              (final e) => e.message,
              'message',
              contains(design.name),
            ),
          ),
        );
      });
    }
  });
}
