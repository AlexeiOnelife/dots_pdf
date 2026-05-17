import 'dart:convert';
import 'dart:typed_data';

import 'package:dots_pdf/src/cover/dots_cover_geometry.dart';
import 'package:dots_pdf/src/cover/dots_cover_renderer.dart';
import 'package:dots_pdf/src/cover/dots_cover_template.dart';
import 'package:dots_pdf/src/cover/dots_paper_substrate.dart';
import 'package:dots_pdf/src/cover/dots_supplier.dart';
import 'package:dots_pdf/src/logging/dots_logger.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 transparent PNG, base64-encoded; the smallest valid PNG.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjC'
    'B0C8AAAAASUVORK5CYII=';

Uint8List _onePixelPng() => base64Decode(_onePixelPngBase64);

bool _hasPdfMagic(final Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 && // '%'
    bytes[1] == 0x50 && // 'P'
    bytes[2] == 0x44 && // 'D'
    bytes[3] == 0x46; // 'F'

Future<void> _seedArtworks(final MemoryFileSystem fs) async {
  await fs.directory('/assets').create(recursive: true);
  await fs.file('/assets/front.png').writeAsBytes(_onePixelPng());
  await fs.file('/assets/back.png').writeAsBytes(_onePixelPng());
  await fs.file('/assets/spine.png').writeAsBytes(_onePixelPng());
}

DotsCoverGeometry _geometry132({
  final DotsSupplier supplier = DotsSupplier.europa,
}) =>
    DotsCoverGeometry(
      pageCount: 132,
      paperSubstrate: DotsPaperSubstrate.uncoated150,
      supplier: supplier,
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

  group('DotsCoverRenderer', () {
    test('produces a valid cover PDF (132 pages, europa, uncoated150)',
        () async {
      final DotsCoverTemplate template = DotsCoverTemplate(
        documentId: 'cover_basic',
        geometry: _geometry132(),
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
      );

      const String outPath = '/out/cover_basic.pdf';
      await renderer.render(template: template, outputPath: outPath);

      final bytes = await fs.file(outPath).readAsBytes();
      expect(await fs.file(outPath).exists(), isTrue);
      expect(_hasPdfMagic(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });

    test('spineTitle adds bytes vs. the no-title baseline', () async {
      final DotsCoverGeometry geometry = _geometry132();
      final DotsCoverTemplate withoutTitle = DotsCoverTemplate(
        documentId: 'cover_no_title',
        geometry: geometry,
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
      );
      final DotsCoverTemplate withTitle = DotsCoverTemplate(
        documentId: 'cover_with_title',
        geometry: geometry,
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
        spineTitle: 'Memories 2024',
      );

      await renderer.render(
        template: withoutTitle,
        outputPath: '/out/no_title.pdf',
      );
      await renderer.render(
        template: withTitle,
        outputPath: '/out/with_title.pdf',
      );

      final int noTitleBytes =
          (await fs.file('/out/no_title.pdf').readAsBytes()).length;
      final int withTitleBytes =
          (await fs.file('/out/with_title.pdf').readAsBytes()).length;

      // The spine text widget adds at minimum a few dozen bytes worth
      // of content stream + glyph references.
      expect(withTitleBytes, greaterThanOrEqualTo(noTitleBytes + 50));
    });

    test('latam omits crop marks; europa includes them', () async {
      final DotsCoverTemplate europaTemplate = DotsCoverTemplate(
        documentId: 'cover_europa',
        geometry: _geometry132(),
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
      );
      final DotsCoverTemplate latamTemplate = DotsCoverTemplate(
        documentId: 'cover_latam',
        geometry: _geometry132(supplier: DotsSupplier.latam),
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
      );

      await renderer.render(
        template: europaTemplate,
        outputPath: '/out/europa.pdf',
      );
      await renderer.render(
        template: latamTemplate,
        outputPath: '/out/latam.pdf',
      );

      final int europaBytes =
          (await fs.file('/out/europa.pdf').readAsBytes()).length;
      final int latamBytes =
          (await fs.file('/out/latam.pdf').readAsBytes()).length;

      // Crop marks add eight thin filled rectangles to the page
      // content stream. The Europa PDF must therefore be strictly
      // larger than the Latam PDF rendered from the same artwork.
      expect(
        latamBytes,
        lessThan(europaBytes),
        reason: 'latam should not draw crop marks',
      );
    });

    test('optional spine artwork is rendered when provided', () async {
      final DotsCoverGeometry geometry = _geometry132();
      final DotsCoverTemplate withoutSpine = DotsCoverTemplate(
        documentId: 'cover_no_spine_art',
        geometry: geometry,
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
      );
      final DotsCoverTemplate withSpine = DotsCoverTemplate(
        documentId: 'cover_with_spine_art',
        geometry: geometry,
        frontArtworkPath: '/assets/front.png',
        backArtworkPath: '/assets/back.png',
        spineArtworkPath: '/assets/spine.png',
      );

      await renderer.render(
        template: withoutSpine,
        outputPath: '/out/no_spine.pdf',
      );
      await renderer.render(
        template: withSpine,
        outputPath: '/out/spine.pdf',
      );

      final int withoutBytes =
          (await fs.file('/out/no_spine.pdf').readAsBytes()).length;
      final int withBytes =
          (await fs.file('/out/spine.pdf').readAsBytes()).length;

      expect(withBytes, greaterThan(withoutBytes));
    });
  });
}
