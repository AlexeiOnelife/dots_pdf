// Offline fidelity-check harness (NOT a CI test — a visual QA loop).
//
// Renders text-only album pages (no network photos) to
// `build/fidelity_check/` so layout-fidelity edits can be eyeballed
// against docs/templates/final_templates without hitting picsum.
//
// Run with:
//   flutter test test/integration/fidelity_check_test.dart
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;
const DotsPageSize _singleSize = DotsPageSize(width: 203 * _mmToPt, height: 254 * _mmToPt);
const DotsPageSize _spreadSize = DotsPageSize(width: 406 * _mmToPt, height: 254 * _mmToPt);

Uint8List _readFont(String relativePath) => io.File(relativePath).readAsBytesSync();

DotsFontBundle _loadBundledFonts() => DotsFontBundle(
  p22MackinacMedium: _readFont('assets/fonts/p22_mackinac/P22Mackinac-Medium_6.ttf'),
  p22MackinacBook: _readFont('assets/fonts/p22_mackinac/P22Mackinac-Book_13.ttf'),
  p22MackinacMediumItalic: _readFont('assets/fonts/p22_mackinac/P22Mackinac-MedItalic_22.ttf'),
  inter: _readFont('assets/fonts/inter/Inter-VariableFont_opsz,wght.ttf'),
  interItalic: _readFont('assets/fonts/inter/Inter-Italic-VariableFont_opsz,wght.ttf'),
  interSemibold: _readFont('assets/fonts/inter/Inter-SemiBold.ttf'),
  biroScriptPlus: _readFont('assets/fonts/biro_plus/Biro-ScriptPlus-Regular-subset.ttf'),
);

DotsLayoutPliego _wrap(DotsAlbumSpreadPage page, int pliegoNumber) => DotsLayoutPliego(
  pliegoNumber: pliegoNumber,
  left: page,
  right: DotsElementsPage(pageNumber: page.pageNumber + 1, elements: const []),
);

Future<void> _renderPdf({
  required String name,
  required List<DotsAlbumSpreadPage> pages,
  required DotsFontBundle fontBundle,
  required FileSystem fs,
  required Directory outDir,
  DotsPageSize pageSize = _singleSize,
}) async {
  final pliegos = <DotsPliego>[for (var i = 0; i < pages.length; i++) _wrap(pages[i], i + 1)];
  final template = DotsTemplate(
    documentId: 'fidelity_$name',
    pageSize: pageSize,
    pliegos: List<DotsPliego>.unmodifiable(pliegos),
  );
  final docsDir = outDir.childDirectory('docs');
  if (!docsDir.existsSync()) docsDir.createSync(recursive: true);
  final generator = DotsGenerator(fileSystem: fs, documentsDir: docsDir, fontBundle: fontBundle);
  final events = await generator.generateWhole(template: template).toList();
  final failures = events.whereType<PdfGenerationFailed>().toList();
  expect(failures, isEmpty, reason: '$name generation failed: ${failures.map((f) => f.error)}');
  final wholePath = await generator.wholePathFor(template.documentId);
  fs.file(wholePath).copySync(outDir.childFile('$name.pdf').path);
  // ignore: avoid_print
  print('  $name → ${outDir.childFile('$name.pdf').path}');
}

void main() {
  test('fidelity check — render text-only pages offline', () async {
    const FileSystem fs = LocalFileSystem();
    final outDir = fs.directory('${io.Directory.current.path}/build/fidelity_check');
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    outDir.createSync(recursive: true);
    final fonts = _loadBundledFonts();

    await _renderPdf(
      name: 'dedication-hijos',
      pages: [
        DotsAlbumSpreadPage.dedication(
          type: DotsAlbumType.hijos,
          pageNumber: 3,
          contextLabelValue: 'Mateo',
          title: 'Nuestro mensaje especial',
          body:
              'Hace más de 3 años que te conocí y me parece increíble todo lo que '
              'hemos vivido juntos. Cada etapa que hemos pasado y todo lo que hemos '
              'construido por y para nosotros. Este álbum es solo una parte de todo eso, '
              'es un año lleno de viajes, aventuras, experiencias que nos han hecho '
              'llegar a donde estamos y darnos cuenta también de lo valioso que es el '
              'tiempo juntos, de la suerte de tenerte a mi lado.',
          signature: 'Mamá y Papá',
        ),
      ],
      fontBundle: fonts,
      fs: fs,
      outDir: outDir,
    );

    // Closing QR keep-alive spread (no photos): square QR + decorative
    // circle field. Compare against pdf13_general_eventos_final.pdf p.1.
    await _renderPdf(
      name: 'qr-closing',
      pageSize: _spreadSize,
      pages: [
        DotsAlbumSpreadPage.closingQrSpread(
          type: DotsAlbumType.generalEventos,
          pageNumber: 7,
          contextLabelValue: 'Festival 2024',
          content: const AlbumQrSpreadContent(
            qrPayload: 'https://example.com/qr',
            placement: AlbumQrSpreadPlacement.closing,
          ),
        ),
      ],
      fontBundle: fonts,
      fs: fs,
      outDir: outDir,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
