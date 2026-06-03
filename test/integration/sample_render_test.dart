// Sample-render integration test.
//
// Produces one PDF per album category exercising every factory that
// applies to that category. Photo content is fetched from picsum.photos
// (deterministic seeds for repeatability). Output lands in
// `build/sample_renders/<category>.pdf`.
//
// Run with:
//   flutter test test/integration/sample_render_test.dart
//
// Network-dependent: requires outbound HTTPS to picsum.photos. Each
// PDF takes a few seconds to render.
//
// Page format: spread (406×254 mm) so the full-spread factories
// (beforeYouStart, closingQrSpread, beforeJourney, photoArc,
// bodaCluster, bodaHalo, etc.) render their right-page elements
// correctly. Single-page factories (cover, dedication, closing,
// photoOnlyCover, welcomeJourney, eventosClosing) show their content
// on the left half with the right half blank — acceptable for a
// visual-QA artefact.
//
// In addition to the per-category PDFs, this test emits
// `general-base-layouts.pdf` exercising every `DotsLayoutCode`
// (l1, l1a-e, l2a-c, l3a, l4a-b, l6a, l7, l8, lhito) — the inner
// body-page layouts shown in `docs/templates/final_templates/
// pdf01_general_base.pdf`. Two layouts per spread page so the
// comparison against the source template is straightforward.
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';

const double _mmToPt = 2.834645669;

/// 406 × 254 mm — full spread, no bleed.
const DotsPageSize _spreadSize = DotsPageSize(
  width: 406 * _mmToPt,
  height: 254 * _mmToPt,
);

/// Deterministic picsum.photos URLs. Seed string is appended to the
/// path so caches stay consistent across runs.
String _photo(String seed, {int w = 600, int h = 400}) =>
    'https://picsum.photos/seed/$seed/$w/$h';

/// Wraps a single [DotsAlbumSpreadPage] into a `DotsLayoutPliego` with
/// a blank counterpart so it renders to its own pdf page. The blank
/// counterpart is an empty `DotsElementsPage`.
DotsLayoutPliego _wrap(DotsAlbumSpreadPage page, int pliegoNumber) =>
    DotsLayoutPliego(
      pliegoNumber: pliegoNumber,
      left: page,
      right: DotsElementsPage(
        pageNumber: page.pageNumber + 1,
        elements: const [],
      ),
    );

/// Reads a font from `assets/fonts/...`.
Uint8List _readFont(String relativePath) {
  final file = io.File(relativePath);
  if (!file.existsSync()) {
    throw StateError(
      'Font asset not found at $relativePath. '
      'Run from the project root or adjust the path.',
    );
  }
  return file.readAsBytesSync();
}

DotsFontBundle _loadBundledFonts() => DotsFontBundle(
      p22MackinacMedium: _readFont(
        'assets/fonts/p22_mackinac/P22Mackinac-Medium_6.ttf',
      ),
      p22MackinacBook: _readFont(
        'assets/fonts/p22_mackinac/P22Mackinac-Book_13.ttf',
      ),
      p22MackinacMediumItalic: _readFont(
        'assets/fonts/p22_mackinac/P22Mackinac-MedItalic_22.ttf',
      ),
      inter: _readFont(
        'assets/fonts/inter/Inter-VariableFont_opsz,wght.ttf',
      ),
      interItalic: _readFont(
        'assets/fonts/inter/Inter-Italic-VariableFont_opsz,wght.ttf',
      ),
      interSemibold: _readFont('assets/fonts/inter/Inter-SemiBold.ttf'),
      biroScriptPlus: _readFont(
        'assets/fonts/biro_plus/Biro-ScriptPlus-Regular-subset.ttf',
      ),
    );

Future<void> _renderCategory({
  required String categoryName,
  required List<DotsAlbumSpreadPage> pages,
  required DotsFontBundle fontBundle,
  required FileSystem fs,
  required Directory outDir,
}) async {
  // Each page becomes the LEFT slot of its own pliego with a blank RIGHT.
  final pliegos = <DotsPliego>[
    for (var i = 0; i < pages.length; i++) _wrap(pages[i], i + 1),
  ];
  final template = DotsTemplate(
    documentId: 'sample_$categoryName',
    pageSize: _spreadSize,
    pliegos: List<DotsPliego>.unmodifiable(pliegos),
  );

  final docsDir = outDir.childDirectory('docs');
  if (!docsDir.existsSync()) docsDir.createSync(recursive: true);

  final generator = DotsGenerator(
    fileSystem: fs,
    documentsDir: docsDir,
    fontBundle: fontBundle,
  );

  await generator.generateWhole(template: template).toList();

  final wholePath = await generator.wholePathFor(template.documentId);
  final destPath = outDir.childFile('$categoryName.pdf').path;
  fs.file(wholePath).copySync(destPath);
  // ignore: avoid_print
  print('  $categoryName → $destPath');
}

/// Builds one `DotsLayoutPage` for the given [code], populating the
/// exact number of photo paths and captions the layout requires.
///
/// Captions are sample strings ("Layout L2.A", a fake date, lorem-ipsum
/// body, an example.com URL for the QR card) — they exist to make the
/// rendered output visually comparable against `pdf01_general_base.pdf`.
DotsLayoutPage _generalBaseLayoutPage(
  DotsLayoutCode code, {
  required int pageNumber,
}) {
  final requirements = code.requirements;
  final photoPaths = <String>[
    for (var i = 0; i < requirements.photoCount; i++)
      _photo('gb_${code.name}_$i'),
  ];
  final captions = <DotsSlotKind, String>{
    for (final kind in requirements.allCaptionKinds)
      kind: _generalBaseCaption(kind, code),
  };
  return DotsLayoutPage(
    pageNumber: pageNumber,
    layoutCode: code,
    photoAssetPaths: photoPaths,
    captions: captions,
  );
}

String _generalBaseCaption(DotsSlotKind kind, DotsLayoutCode code) {
  switch (kind) {
    case DotsSlotKind.captionTitle:
      return 'Layout ${code.name.toUpperCase()}';
    case DotsSlotKind.captionDate:
      return '12 de marzo de 2024';
    case DotsSlotKind.captionBody:
      return 'Texto de muestra para demostrar este layout. '
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
          'sed do eiusmod tempor incididunt ut labore et dolore magna '
          'aliqua. Ut enim ad minim veniam, quis nostrud exercitation.';
    case DotsSlotKind.qrCard:
      return 'https://example.com/${code.name}';
    case DotsSlotKind.photo:
      // Photos come through `photoAssetPaths`; this branch is unreachable
      // because `allCaptionKinds` never includes `DotsSlotKind.photo`.
      return '';
  }
}

Future<void> _renderGeneralBaseLayoutsPdf({
  required DotsFontBundle fontBundle,
  required FileSystem fs,
  required Directory outDir,
}) async {
  // One DotsLayoutPage per DotsLayoutCode, in enum declaration order.
  final pages = <DotsLayoutPage>[
    for (var i = 0; i < DotsLayoutCode.values.length; i++)
      _generalBaseLayoutPage(
        DotsLayoutCode.values[i],
        // Start at page 2 so page 1 stays reserved (matches pdf01 source).
        pageNumber: i + 2,
      ),
  ];

  // Pair layouts onto spreads: layout[2k] on the LEFT, layout[2k+1] on
  // the RIGHT. If there's an odd one out, the right is a blank elements
  // page so the trailing layout still gets a full LEFT-page render.
  final pliegos = <DotsPliego>[];
  for (var i = 0; i < pages.length; i += 2) {
    final left = pages[i];
    final DotsPage right = (i + 1 < pages.length)
        ? pages[i + 1]
        : DotsElementsPage(
            pageNumber: left.pageNumber + 1,
            elements: const [],
          );
    pliegos.add(DotsLayoutPliego(
      pliegoNumber: (i ~/ 2) + 1,
      left: left,
      right: right,
    ));
  }

  final template = DotsTemplate(
    documentId: 'sample_general_base_layouts',
    pageSize: _spreadSize,
    pliegos: List<DotsPliego>.unmodifiable(pliegos),
  );

  final docsDir = outDir.childDirectory('docs');
  if (!docsDir.existsSync()) docsDir.createSync(recursive: true);

  final generator = DotsGenerator(
    fileSystem: fs,
    documentsDir: docsDir,
    fontBundle: fontBundle,
  );

  await generator.generateWhole(template: template).toList();

  final wholePath = await generator.wholePathFor(template.documentId);
  final destPath = outDir.childFile('general-base-layouts.pdf').path;
  fs.file(wholePath).copySync(destPath);
  // ignore: avoid_print
  print('  general-base-layouts → $destPath');
}

// ── Per-category page builders ────────────────────────────────────────────

List<DotsAlbumSpreadPage> _parejasPages() => [
      DotsAlbumSpreadPage.cover(
        type: DotsAlbumType.parejas,
        pageNumber: 1,
        title: 'Nuestra historia juntos',
        dateLine: '14 de febrero de 2024 — 14 de febrero de 2025',
      ),
      DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.parejas,
        pageNumber: 3,
        contextLabelValue: 'Ana y Luis',
        title: 'Nuestro mensaje especial',
        body: 'Hace más de 3 años que te conocí y me parece increible '
            'todo lo que hemos vivido juntos. Cada etapa que hemos '
            'pasado y todo lo que hemos construido por y para nosotros.',
        signature: 'Ana',
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.parejas,
        pageNumber: 5,
        content: AlbumBeforeYouStartContent(
          photoPaths: [
            for (var i = 0; i < 10; i++) _photo('parejas_$i'),
          ],
        ),
        contextLabelValue: 'Ana y Luis',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.parejas,
        pageNumber: 7,
        contextLabelValue: 'Ana y Luis',
      ),
      DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.parejas,
        pageNumber: 9,
        contextLabelValue: 'Ana y Luis',
        content: AlbumPhotoArcContent(
          photoPaths: [for (var i = 0; i < 28; i++) _photo('parejas_arc_$i')],
        ),
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.parejas,
        pageNumber: 11,
        contextLabelValue: 'Ana y Luis',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/parejas-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.parejas,
        pageNumber: 13,
        contextLabelValue: 'Ana y Luis',
        photoPath: _photo('parejas_closing'),
        title: 'Vividlo de nuevo',
        subtitle: 'Ana y Luis',
      ),
    ];

List<DotsAlbumSpreadPage> _hijosPages() => [
      DotsAlbumSpreadPage.cover(
        type: DotsAlbumType.hijos,
        pageNumber: 1,
        title: 'Mateo, tu primer año',
        dateLine: '5 de marzo de 2024 — 5 de marzo de 2025',
      ),
      DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.hijos,
        pageNumber: 3,
        contextLabelValue: 'Mateo',
        title: 'Para ti, mi pequeño',
        body: 'Desde el día en que llegaste a nuestras vidas todo cambió. '
            'Cada sonrisa, cada paso, cada palabra nueva nos ha enseñado '
            'lo que es el amor incondicional.',
        signature: 'Mamá y Papá',
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.hijos,
        pageNumber: 5,
        content: AlbumBeforeYouStartContent(
          photoPaths: [for (var i = 0; i < 10; i++) _photo('hijos_$i')],
        ),
        contextLabelValue: 'Mateo',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.hijos,
        pageNumber: 7,
        contextLabelValue: 'Mateo',
      ),
      DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.hijos,
        pageNumber: 9,
        contextLabelValue: 'Mateo',
        content: AlbumPhotoArcContent(
          photoPaths: [for (var i = 0; i < 28; i++) _photo('hijos_arc_$i')],
        ),
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.hijos,
        pageNumber: 11,
        contextLabelValue: 'Mateo',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/hijos-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.hijos,
        pageNumber: 13,
        contextLabelValue: 'Mateo',
        photoPath: _photo('hijos_closing'),
        title: 'Y la vida sigue',
        subtitle: 'Con todo el amor de papá y mamá',
      ),
    ];

List<DotsAlbumSpreadPage> _individualesPages() => [
      DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.individuales,
        pageNumber: 1,
        content: AlbumPhotoOnlyCoverContent(
          photoPath: _photo('individuales_cover', w: 800, h: 1000),
          title: 'Mi viaje al pasado',
          dateLine: 'Enero 2024 — Diciembre 2024',
        ),
        contextLabelValue: '2024',
      ),
      DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.individuales,
        pageNumber: 3,
        contextLabelValue: '2024',
        title: 'Un año para mí',
        body: 'Estas páginas son el reflejo de un año que decidí vivir '
            'con intención. Cada foto guarda una pequeña victoria, '
            'una lección, un momento que merece ser recordado.',
        signature: '',
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.individuales,
        pageNumber: 5,
        content: AlbumBeforeYouStartContent(
          photoPaths: [
            for (var i = 0; i < 10; i++) _photo('individuales_$i'),
          ],
        ),
        contextLabelValue: '2024',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.individuales,
        pageNumber: 7,
        contextLabelValue: '2024',
      ),
      DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 9,
        contextLabelValue: '2024',
        photoPaths: [
          for (var i = 0; i < 6; i++) _photo('individuales_polaroid_$i'),
        ],
      ),
      DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.individuales,
        pageNumber: 11,
        contextLabelValue: '2024',
        content: AlbumPhotoArcContent(
          photoPaths: [
            for (var i = 0; i < 28; i++) _photo('individuales_arc_$i'),
          ],
        ),
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.individuales,
        pageNumber: 13,
        contextLabelValue: '2024',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/individuales-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.individuales,
        pageNumber: 15,
        contextLabelValue: '2024',
        photoPath: _photo('individuales_closing'),
        title: 'Hasta el próximo año',
        subtitle: '',
      ),
    ];

List<DotsAlbumSpreadPage> _otrosPages() => [
      DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.otros,
        pageNumber: 1,
        content: AlbumPhotoOnlyCoverContent(
          photoPath: _photo('otros_cover', w: 800, h: 1000),
          title: 'Nuestro viaje juntos',
          dateLine: 'Verano 2024 — Verano 2025',
        ),
        contextLabelValue: '2024 — 2025',
      ),
      DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.otros,
        pageNumber: 3,
        contextLabelValue: '2024 — 2025',
        title: 'Para todos los que pasaron por aquí',
        body: 'Estas páginas son la historia de un grupo, de unos viajes, '
            'de una etapa compartida. Cada foto es una memoria de algo '
            'vivido entre todos.',
        signature: '',
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.otros,
        pageNumber: 5,
        content: AlbumBeforeYouStartContent(
          photoPaths: [for (var i = 0; i < 10; i++) _photo('otros_$i')],
        ),
        contextLabelValue: 'Todos',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.otros,
        pageNumber: 7,
        contextLabelValue: 'Todos',
      ),
      DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.otros,
        pageNumber: 9,
        contextLabelValue: 'Todos',
        photoPaths: [
          for (var i = 0; i < 6; i++) _photo('otros_polaroid_$i'),
        ],
        applyOtrosGradient: true,
      ),
      DotsAlbumSpreadPage.photoArc(
        type: DotsAlbumType.otros,
        pageNumber: 11,
        contextLabelValue: 'Todos',
        content: AlbumPhotoArcContent(
          photoPaths: [
            for (var i = 0; i < 28; i++) _photo('otros_arc_$i'),
          ],
        ),
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.otros,
        pageNumber: 13,
        contextLabelValue: 'Todos',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/otros-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.otros,
        pageNumber: 15,
        contextLabelValue: 'Todos',
        photoPath: _photo('otros_closing'),
        title: 'Hasta la próxima',
        subtitle: '',
      ),
    ];

List<DotsAlbumSpreadPage> _bodaPages() => [
      DotsAlbumSpreadPage.dedication(
        type: DotsAlbumType.boda,
        pageNumber: 1,
        contextLabelValue: 'Ana y Luis',
        title: 'Para siempre',
        body: 'El día en que nos casamos cambió todo. Estas páginas son '
            'el inicio de una nueva historia: la de un nosotros que '
            'empieza con un sí.',
        signature: 'Ana y Luis',
      ),
      DotsAlbumSpreadPage.bodaCluster(
        type: DotsAlbumType.boda,
        pageNumber: 3,
        contextLabelValue: 'Ana y Luis',
        content: AlbumBodaClusterContent(
          photoPaths: [
            for (var i = 0; i < 7; i++) _photo('boda_cluster_$i'),
          ],
          title: 'Antes de empezar',
          titleItalicLine: 'el viaje',
          body: 'Antes de revivir aquel día, párate un momento. Respira. '
              'Y vuelve a entrar en él como si fuera la primera vez.',
        ),
      ),
      DotsAlbumSpreadPage.bodaHalo(
        type: DotsAlbumType.boda,
        pageNumber: 5,
        contextLabelValue: 'Ana y Luis',
        content: AlbumBodaHaloContent(
          photoPaths: [for (var i = 0; i < 28; i++) _photo('boda_halo_$i')],
        ),
      ),
      DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.boda,
        pageNumber: 7,
        contextLabelValue: 'Ana y Luis',
        content: const AlbumWelcomeJourneyContent(),
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.boda,
        pageNumber: 9,
        content: AlbumBeforeYouStartContent(
          photoPaths: [for (var i = 0; i < 10; i++) _photo('boda_$i')],
        ),
        contextLabelValue: 'Ana y Luis',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.boda,
        pageNumber: 11,
        contextLabelValue: 'Ana y Luis',
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.boda,
        pageNumber: 13,
        contextLabelValue: 'Ana y Luis',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/boda-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.closing(
        type: DotsAlbumType.boda,
        pageNumber: 15,
        contextLabelValue: 'Ana y Luis',
        photoPath: _photo('boda_closing'),
        title: 'Que la vida siga reencontrándoos, una y otra vez',
        subtitle: '',
      ),
    ];

List<DotsAlbumSpreadPage> _generalEventosPages() => [
      DotsAlbumSpreadPage.openingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 1,
        contextLabelValue: 'Festival 2024',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/eventos-opening',
          placement: AlbumQrSpreadPlacement.opening,
        ),
      ),
      DotsAlbumSpreadPage.photoOnlyCover(
        type: DotsAlbumType.generalEventos,
        pageNumber: 3,
        content: AlbumPhotoOnlyCoverContent(
          photoPath: _photo('eventos_cover', w: 800, h: 1000),
          title: 'Festival de Verano',
          dateLine: '12 — 14 de julio de 2024',
        ),
        contextLabelValue: 'Festival 2024',
      ),
      DotsAlbumSpreadPage.welcomeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 5,
        contextLabelValue: 'Festival 2024',
        content: const AlbumWelcomeJourneyContent(),
      ),
      DotsAlbumSpreadPage.beforeYouStart(
        type: DotsAlbumType.generalEventos,
        pageNumber: 7,
        content: AlbumBeforeYouStartContent(
          photoPaths: [for (var i = 0; i < 10; i++) _photo('eventos_$i')],
        ),
        contextLabelValue: 'Festival 2024',
      ),
      DotsAlbumSpreadPage.beforeJourney(
        type: DotsAlbumType.generalEventos,
        pageNumber: 9,
        contextLabelValue: 'Festival 2024',
      ),
      DotsAlbumSpreadPage.closingQrSpread(
        type: DotsAlbumType.generalEventos,
        pageNumber: 11,
        contextLabelValue: 'Festival 2024',
        content: const AlbumQrSpreadContent(
          qrPayload: 'https://example.com/eventos-final',
          placement: AlbumQrSpreadPlacement.closing,
        ),
      ),
      DotsAlbumSpreadPage.eventosClosing(
        type: DotsAlbumType.generalEventos,
        pageNumber: 13,
        contextLabelValue: 'Festival 2024',
        content: AlbumEventosClosingContent(
          photoPath: _photo('eventos_closing'),
          title: 'Festival de Verano 2024',
          signature1: 'María',
          signature2: 'José',
        ),
      ),
    ];

void main() {
  test('sample render — emits one PDF per category with every factory '
      'exercised against picsum.photos photos', () async {
    const FileSystem fs = LocalFileSystem();
    final projectRoot = io.Directory.current.path;
    final outDir = fs.directory('$projectRoot/build/sample_renders');
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    outDir.createSync(recursive: true);

    // ignore: avoid_print
    print('Sample-render output dir: ${outDir.path}');

    final fontBundle = _loadBundledFonts();

    final categories = <String, List<DotsAlbumSpreadPage>>{
      'parejas': _parejasPages(),
      'hijos': _hijosPages(),
      'individuales': _individualesPages(),
      'otros': _otrosPages(),
      'boda': _bodaPages(),
      'generalEventos': _generalEventosPages(),
    };

    for (final entry in categories.entries) {
      await _renderCategory(
        categoryName: entry.key,
        pages: entry.value,
        fontBundle: fontBundle,
        fs: fs,
        outDir: outDir,
      );
    }

    // Companion PDF: every DotsLayoutCode rendered in enum order, two
    // layouts per spread page, for visual diff against pdf01_general_base.
    await _renderGeneralBaseLayoutsPdf(
      fontBundle: fontBundle,
      fs: fs,
      outDir: outDir,
    );

    // Assert each PDF was actually produced and has the PDF magic header.
    final expectedPdfs = <String>[
      ...categories.keys,
      'general-base-layouts',
    ];
    for (final name in expectedPdfs) {
      final pdf = fs.file('${outDir.path}/$name.pdf');
      expect(pdf.existsSync(), isTrue, reason: '$name.pdf should exist');
      final bytes = pdf.readAsBytesSync();
      expect(bytes.length, greaterThan(1000),
          reason: '$name.pdf should be > 1 KB');
      expect(
        String.fromCharCodes(bytes.sublist(0, 4)),
        equals('%PDF'),
        reason: '$name.pdf should start with the PDF magic',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
