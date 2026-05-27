@TestOn('vm')
library;

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads a font file from the project's `assets/fonts/` tree.
///
/// This uses `dart:io File` directly because the renderer's
/// `MemoryFileSystem`-backed code path is irrelevant here — we just
/// need the real font bytes off disk to feed into `DotsFontBundle`.
Uint8List _loadProjectFont(String relativePath) {
  final file = io.File('assets/$relativePath');
  if (!file.existsSync()) {
    throw StateError(
      'Required test fixture missing: ${file.absolute.path}. '
      'Run tests from the package root.',
    );
  }
  return file.readAsBytesSync();
}

DotsFontBundle _loadRealBundle() {
  return DotsFontBundle(
    p22MackinacMedium:
        _loadProjectFont('fonts/p22_mackinac/P22Mackinac-Medium_6.ttf'),
    p22MackinacBook:
        _loadProjectFont('fonts/p22_mackinac/P22Mackinac-Book_13.ttf'),
    p22MackinacMediumItalic:
        _loadProjectFont('fonts/p22_mackinac/P22Mackinac-MedItalic_22.ttf'),
    inter: _loadProjectFont('fonts/inter/Inter-VariableFont_opsz,wght.ttf'),
    interItalic:
        _loadProjectFont('fonts/inter/Inter-Italic-VariableFont_opsz,wght.ttf'),
    interSemibold:
        _loadProjectFont('fonts/inter/Inter-SemiBold.ttf'),
    biroScriptPlus:
        _loadProjectFont('fonts/biro_plus/Biro-ScriptPlus-Regular-subset.ttf'),
  );
}

void main() {
  group('DotsFontBundle', () {
    test('roleFromFamily maps common family strings to font roles', () {
      expect(
        DotsFontBundle.roleFromFamily('P22 Mackinac'),
        DotsFontRole.p22MackinacMedium,
      );
      expect(
        DotsFontBundle.roleFromFamily('P22 Mackinac Book'),
        DotsFontRole.p22MackinacBook,
      );
      expect(
        DotsFontBundle.roleFromFamily('P22 Mackinac Medium Italic'),
        DotsFontRole.p22MackinacMediumItalic,
      );
      expect(
        DotsFontBundle.roleFromFamily('Inter'),
        DotsFontRole.inter,
      );
      expect(
        DotsFontBundle.roleFromFamily('Inter Italic'),
        DotsFontRole.interItalic,
      );
      expect(
        DotsFontBundle.roleFromFamily('Biro Script Plus'),
        DotsFontRole.biroScriptPlus,
      );
      expect(DotsFontBundle.roleFromFamily(null), isNull);
      expect(DotsFontBundle.roleFromFamily('Comic Sans'), isNull);
    });

    test('roleFromFamily maps Inter SemiBold variants to interSemibold', () {
      // Canonical casing from the design spec.
      expect(
        DotsFontBundle.roleFromFamily('Inter SemiBold'),
        DotsFontRole.interSemibold,
      );
      // All-lowercase variant (used in JSON templates).
      expect(
        DotsFontBundle.roleFromFamily('inter semibold'),
        DotsFontRole.interSemibold,
      );
      // Alternative casing "Inter Semibold" (both S/B variations lower identically).
      expect(
        DotsFontBundle.roleFromFamily('Inter Semibold'),
        DotsFontRole.interSemibold,
      );
      // Must NOT fall through to the plain inter catch-all.
      expect(
        DotsFontBundle.roleFromFamily('Inter SemiBold'),
        isNot(DotsFontRole.inter),
      );
    });

    test('bytesFor returns the matching field per role', () {
      final bundle = DotsFontBundle(
        p22MackinacMedium: Uint8List.fromList(<int>[1]),
        p22MackinacBook: Uint8List.fromList(<int>[2]),
        p22MackinacMediumItalic: Uint8List.fromList(<int>[3]),
        inter: Uint8List.fromList(<int>[4]),
        interItalic: Uint8List.fromList(<int>[5]),
        interSemibold: Uint8List.fromList(<int>[7]),
        biroScriptPlus: Uint8List.fromList(<int>[6]),
        assertSupportedFormats: false,
      );
      expect(
        bundle.bytesFor(DotsFontRole.p22MackinacMedium).single,
        1,
      );
      expect(bundle.bytesFor(DotsFontRole.p22MackinacBook).single, 2);
      expect(
        bundle.bytesFor(DotsFontRole.p22MackinacMediumItalic).single,
        3,
      );
      expect(bundle.bytesFor(DotsFontRole.inter).single, 4);
      expect(bundle.bytesFor(DotsFontRole.interItalic).single, 5);
      expect(bundle.bytesFor(DotsFontRole.interSemibold).single, 7);
      expect(bundle.bytesFor(DotsFontRole.biroScriptPlus).single, 6);
    });

    test('constructor rejects CFF-flavored OpenType (.otf) bytes', () {
      final otfBytes = Uint8List.fromList(<int>[
        // 'OTTO' magic = CFF-flavored OpenType.
        0x4F, 0x54, 0x54, 0x4F,
        // Pad to look minimally font-like.
        0, 0, 0, 0,
      ]);
      final ttfBytes = Uint8List.fromList(<int>[
        0x00, 0x01, 0x00, 0x00, 0, 0, 0, 0,
      ]);
      expect(
        () => DotsFontBundle(
          p22MackinacMedium: otfBytes,
          p22MackinacBook: ttfBytes,
          p22MackinacMediumItalic: ttfBytes,
          inter: ttfBytes,
          interItalic: ttfBytes,
          interSemibold: ttfBytes,
          biroScriptPlus: ttfBytes,
        ),
        throwsA(
          isA<DotsConfigException>().having(
            (e) => e.message,
            'message',
            allOf(contains('CFF'), contains('otf2ttf')),
          ),
        ),
      );
    });

    test('constructor rejects unknown SFNT magic', () {
      final junk = Uint8List.fromList(<int>[0xDE, 0xAD, 0xBE, 0xEF, 0, 0, 0, 0]);
      final ttfBytes = Uint8List.fromList(<int>[
        0x00, 0x01, 0x00, 0x00, 0, 0, 0, 0,
      ]);
      expect(
        () => DotsFontBundle(
          p22MackinacMedium: ttfBytes,
          p22MackinacBook: ttfBytes,
          p22MackinacMediumItalic: ttfBytes,
          inter: junk,
          interItalic: ttfBytes,
          interSemibold: ttfBytes,
          biroScriptPlus: ttfBytes,
        ),
        throwsA(isA<DotsConfigException>()),
      );
    });

    test('constructor accepts TrueType (.ttf) bytes', () {
      final ttfBytes = Uint8List.fromList(<int>[
        0x00, 0x01, 0x00, 0x00, 0, 0, 0, 0,
      ]);
      // Should not throw.
      DotsFontBundle(
        p22MackinacMedium: ttfBytes,
        p22MackinacBook: ttfBytes,
        p22MackinacMediumItalic: ttfBytes,
        inter: ttfBytes,
        interItalic: ttfBytes,
        interSemibold: ttfBytes,
        biroScriptPlus: ttfBytes,
      );
    });
  });

  group('Renderer with real fonts', () {
    late DotsFontBundle bundle;

    setUpAll(() {
      bundle = _loadRealBundle();
    });

    test('loading the project fonts produces non-empty byte streams', () {
      expect(bundle.p22MackinacMedium.lengthInBytes, greaterThan(10000));
      expect(bundle.p22MackinacBook.lengthInBytes, greaterThan(10000));
      expect(
        bundle.p22MackinacMediumItalic.lengthInBytes,
        greaterThan(10000),
      );
      expect(bundle.inter.lengthInBytes, greaterThan(100000));
      expect(bundle.interItalic.lengthInBytes, greaterThan(100000));
      expect(bundle.interSemibold.lengthInBytes, greaterThan(10000));
      expect(bundle.biroScriptPlus.lengthInBytes, greaterThan(10000));
    });

    test('bytesFor(interSemibold) returns the same bytes as the field', () {
      expect(
        bundle.bytesFor(DotsFontRole.interSemibold),
        same(bundle.interSemibold),
      );
    });

    test('layout page with bundle renders larger PDF than without', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/docs').createSync();

      const template = DotsTemplate(
        documentId: 'font_test',
        pageSize: DotsPageSize(width: 400, height: 600),
        pages: <DotsPage>[
          DotsLayoutPage(
            pageNumber: 1,
            layoutCode: DotsLayoutCode.lhito,
            captions: <DotsSlotKind, String>{
              DotsSlotKind.captionTitle: 'A milestone',
              DotsSlotKind.captionDate: 'May 17, 2026',
              DotsSlotKind.captionBody:
                  'Some body text to exercise the Inter font role.',
            },
          ),
        ],
      );

      Future<int> render({required bool withBundle}) async {
        final docs = fs.directory('/docs');
        final generator = DotsGenerator(
          fileSystem: fs,
          documentsDir: docs,
          fontBundle: withBundle ? bundle : null,
        );
        await generator
            .generateWhole(template: template, forceRegenerate: true)
            .toList();
        final path = await generator.wholePathFor('font_test');
        return (await fs.file(path).readAsBytes()).length;
      }

      final without = await render(withBundle: false);
      final with_ = await render(withBundle: true);
      // Embedded fonts add bytes; with proper TTF subsetting the
      // delta on a short lhito page is ~6-10 KB. The lower bound
      // here is deliberately conservative — the point is that
      // glyph tables are actually embedded, not that the embedding
      // is a particular size.
      expect(with_ - without, greaterThan(1000));
    });

    test('text element fontFamily routes to bundled font', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/docs').createSync();

      const template = DotsTemplate(
        documentId: 'family_test',
        pageSize: DotsPageSize(width: 400, height: 600),
        pages: <DotsPage>[
          DotsElementsPage(
            pageNumber: 1,
            elements: <DotsElement>[
              DotsTextElement(
                x: 36,
                y: 72,
                value: 'P22 sample',
                fontSize: 18,
                fontFamily: 'P22 Mackinac',
              ),
              DotsTextElement(
                x: 36,
                y: 100,
                value: 'Inter sample',
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ],
          ),
        ],
      );

      final docs = fs.directory('/docs');
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: docs,
        fontBundle: bundle,
      );
      await generator.generateWhole(template: template).toList();
      final bytes = await fs
          .file(await generator.wholePathFor('family_test'))
          .readAsBytes();

      // Sanity: %PDF magic + a non-trivial byte stream. Lower bound
      // is conservative — what matters is that subsetting works.
      expect(bytes[0], 0x25);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x44);
      expect(bytes[3], 0x46);
      expect(bytes.length, greaterThan(3000));
    });
  });
}
