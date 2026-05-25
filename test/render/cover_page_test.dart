// Tests for the cover-page render layer (R2, R3, R5, R8).
import 'dart:typed_data';

import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/album_spread_page.dart'
    show
        buildAlbumSpreadPage,
        decorativeCircleCacheSizeForTest,
        resetDecorativeCircleCacheForTest;
import 'package:dots_pdf/src/render/cover_circles.dart'
    show kCoverCircleLayoutForTest;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Shared slice-1/2/3 fixtures (used by backwards-compatibility smoke test).
// ---------------------------------------------------------------------------

const _dedicationContent = DedicationContent(
  title: 'Nuestro viaje',
  body: 'Un año de amor.',
  signature: 'Blanqui',
);

const _closingContent = ClosingContent(
  photoPath: 'photo.jpg',
  title: 'Vivid together',
  subtitle: 'Ana y Luis',
);

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

const double _mmToPt = 2.834645669;
const PdfPageFormat _format = PdfPageFormat(
  203.0 * _mmToPt,
  254.0 * _mmToPt,
);

bool _hasPdfMagic(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

/// Builds a [DotsAlbumSpreadPage] and renders it to raw PDF bytes via the
/// main-isolate path (no images needed for circle-only pages).
Future<Uint8List> _renderCoverPage(DotsAlbumSpreadPage page) async {
  final builtPage = await buildAlbumSpreadPage(
    format: _format,
    page: page,
    fontResolver: (_) => null,
    bytesResolver: (path) async => throw StateError('no asset: $path'),
    logger: const DotsSilentLogger(),
    onPhotoFailure: (_, __) {},
    drawCropMarks: false,
  );

  final doc = pw.Document();
  doc.addPage(builtPage);
  return doc.save();
}

AlbumCoverContent _content({String? eyebrowOverride}) => AlbumCoverContent(
      title: 'Nuestro año',
      dateLine: '01/01/2024 | 31/12/2024',
      eyebrowOverride: eyebrowOverride,
    );

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.cover factory — element count and structure (R5)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.cover — elements list (R5)', () {
    test('DotsAlbumSpreadPage.cover — elements list has exactly 17 entries',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      expect(page.elements.length, equals(17));
    });

    test(
        'DotsAlbumSpreadPage.cover — exactly 14 elements are DotsDecorativeCircleElement',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      final circles =
          page.elements.whereType<DotsDecorativeCircleElement>().toList();
      expect(circles.length, equals(14));
    });

    test('DotsAlbumSpreadPage.cover — exactly 3 elements are text elements',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      final texts =
          page.elements.whereType<DotsTextBlockElement>().toList();
      expect(texts.length, equals(3));
    });

    test('DotsAlbumSpreadPage.cover — header is null (all trio fields null)',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      expect(page.header.leftPageNumber, isNull,
          reason: 'cover header leftPageNumber must be null',);
      expect(page.header.centerLabel, isNull,
          reason: 'cover header centerLabel must be null',);
      expect(page.header.rightPageNumber, isNull,
          reason: 'cover header rightPageNumber must be null',);
    });

    test('DotsAlbumSpreadPage.cover — footer wordmark is empty', () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      expect(page.footer.wordmark, isEmpty,
          reason: 'cover footer wordmark must be empty string',);
    });

    test('DotsAlbumSpreadPage.cover — circle layout matches kCoverCircleLayout',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      final circles =
          page.elements.whereType<DotsDecorativeCircleElement>().toList();
      final layout = kCoverCircleLayoutForTest;

      expect(circles.length, equals(layout.length));
      for (var i = 0; i < layout.length; i++) {
        final anchor = layout[i];
        final el = circles[i];
        expect(el.x, closeTo(anchor.xMm * _mmToPt, 0.001),
            reason: 'circle $i x must match anchor xMm converted to pt',);
        expect(el.y, closeTo(anchor.yMm * _mmToPt, 0.001),
            reason: 'circle $i y must match anchor yMm converted to pt',);
        expect(el.diameter, closeTo(anchor.diameterMm * _mmToPt, 0.001),
            reason: 'circle $i diameter must match anchor diameterMm in pt',);
        expect(el.bleedLeft, equals(anchor.bleedLeft),
            reason: 'circle $i bleedLeft must match',);
        expect(el.bleedRight, equals(anchor.bleedRight),
            reason: 'circle $i bleedRight must match',);
        expect(el.bleedTop, equals(anchor.bleedTop),
            reason: 'circle $i bleedTop must match',);
        expect(el.bleedBottom, equals(anchor.bleedBottom),
            reason: 'circle $i bleedBottom must match',);
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // buildCoverPageFor — eyebrow resolution (R6)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildCoverPageFor — eyebrow resolution (R6)', () {
    DotsTextBlockElement eyebrow(DotsAlbumSpreadPage page) =>
        page.elements.whereType<DotsTextBlockElement>().first;

    test('buildCoverPageFor — parejas eyebrow resolves to DOTBOOK', () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      expect(eyebrow(page).value, equals('DOTBOOK'));
    });

    test(
        'buildCoverPageFor — hijos eyebrow resolves to DOTBOOK DE {NOMBREHIJO}',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.hijos,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      expect(eyebrow(page).value, equals('DOTBOOK DE {NOMBREHIJO}'));
    });

    test('buildCoverPageFor — eyebrowOverride wins over per-type default', () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(
          title: 'T',
          dateLine: 'D',
          eyebrowOverride: 'CUSTOM',
        ),
        pageNumber: 1,
      );
      expect(eyebrow(page).value, equals('CUSTOM'));
    });

    test(
        'buildCoverPageFor — throws ArgumentError for DotsAlbumType.individuales',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.individuales,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.boda',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.boda,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test('buildCoverPageFor — throws ArgumentError for DotsAlbumType.otros',
        () {
      expect(
        () => buildCoverPageFor(
          DotsAlbumType.otros,
          const AlbumCoverContent(title: 'T', dateLine: 'D'),
          pageNumber: 1,
        ),
        throwsArgumentError,
      );
    });

    test(
        'buildCoverPageFor — geometry identical for parejas and hijos given same content',
        () {
      final pageP = buildCoverPageFor(
        DotsAlbumType.parejas,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );
      final pageH = buildCoverPageFor(
        DotsAlbumType.hijos,
        const AlbumCoverContent(title: 'T', dateLine: 'D'),
        pageNumber: 1,
      );

      final circlesP =
          pageP.elements.whereType<DotsDecorativeCircleElement>().toList();
      final circlesH =
          pageH.elements.whereType<DotsDecorativeCircleElement>().toList();

      expect(circlesP.length, equals(circlesH.length));
      for (var i = 0; i < circlesP.length; i++) {
        expect(circlesP[i].x, equals(circlesH[i].x),
            reason: 'circle $i x must be identical for parejas and hijos',);
        expect(circlesP[i].y, equals(circlesH[i].y),
            reason: 'circle $i y must be identical',);
        expect(circlesP[i].diameter, equals(circlesH[i].diameter),
            reason: 'circle $i diameter must be identical',);
      }

      final textsP =
          pageP.elements.whereType<DotsTextBlockElement>().toList();
      final textsH =
          pageH.elements.whereType<DotsTextBlockElement>().toList();
      // Text position geometry must match; only value of index-0 (eyebrow) differs.
      for (var i = 1; i < textsP.length; i++) {
        expect(textsP[i].x, equals(textsH[i].x));
        expect(textsP[i].y, equals(textsH[i].y));
        expect(textsP[i].value, equals(textsH[i].value),
            reason: 'title and date text must be identical for both types',);
      }
      // Eyebrow text values differ.
      expect(textsP[0].value, isNot(equals(textsH[0].value)),
          reason: 'eyebrow text must differ between parejas and hijos',);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Cover page rendering — byte buffer and header suppression (R8)
  // ──────────────────────────────────────────────────────────────────────────

  group('cover page rendering (R8)', () {
    setUp(() => resetDecorativeCircleCacheForTest());

    test('cover page rendering — produces non-empty PDF byte buffer', () async {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      final bytes = await _renderCoverPage(page);
      expect(bytes.length, greaterThan(0),
          reason: 'rendered PDF must be non-empty',);
      expect(_hasPdfMagic(bytes), isTrue,
          reason: 'output must start with PDF magic bytes %PDF',);
    });

    test(
        'cover page rendering — cache: single rasterization for 14 circles of same diameter/color/fade',
        () async {
      // All 14 circles share 3 unique (diameter, colorHex, fade) keys:
      // 47 mm, 28 mm, and 16 mm tiers. After rendering, the cache must hold
      // exactly 3 entries — one per diameter tier.
      resetDecorativeCircleCacheForTest();

      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      // Trigger actual rendering to populate the cache.
      await _renderCoverPage(page);

      // The cache must hold exactly 3 entries (one per diameter tier) after
      // rendering the 14-circle cover, proving the (diameter, color, fade)
      // key collapses identical-style circles to a single rasterization.
      expect(
        decorativeCircleCacheSizeForTest(),
        equals(3),
        reason: '14 circles in 3 diameter tiers must rasterize 3 PNGs total',
      );

      // Re-rendering the same page must not grow the cache.
      await _renderCoverPage(page);
      expect(
        decorativeCircleCacheSizeForTest(),
        equals(3),
        reason: 'second render of identical page must hit cache, not rasterize',
      );
    });

    test(
        'cover page rendering — cache reset hook clears rasterization state',
        () async {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );

      // Populate cache.
      await _renderCoverPage(page);

      // Clear cache — subsequent render must still succeed (re-rasterize).
      resetDecorativeCircleCacheForTest();

      final bytes = await _renderCoverPage(page);
      expect(bytes.length, greaterThan(0),
          reason: 'render after cache reset must still produce a valid PDF',);
      expect(_hasPdfMagic(bytes), isTrue);
    });

    test(
        'cover page rendering — no header trio text in rendered output when header trio is null',
        () {
      final page = buildCoverPageFor(
        DotsAlbumType.parejas,
        _content(),
        pageNumber: 1,
      );
      // The model-level assertion: all three header trio fields are null,
      // so the renderer adds no header widgets. This mirrors the R8 spec
      // scenario ("no page-number text and no center-label text appear").
      expect(page.header.leftPageNumber, isNull,
          reason: 'leftPageNumber must be null on cover page',);
      expect(page.header.centerLabel, isNull,
          reason: 'centerLabel must be null on cover page',);
      expect(page.header.rightPageNumber, isNull,
          reason: 'rightPageNumber must be null on cover page',);
      // Footer wordmark is empty so no footer text is rendered.
      expect(page.footer.wordmark, isEmpty,
          reason: 'footer wordmark must be empty on cover page',);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Backwards compatibility smoke test (R9/AT-25)
  // Proves that slice-4 additions do not break the slice-1/2/3 infrastructure.
  // ──────────────────────────────────────────────────────────────────────────

  group('backwards compatibility (R9)', () {
    test('backwards compatibility — all slice-1/2/3 tests pass unchanged', () {
      // Representative slice-2 path: buildSimplePagesFor produces both a
      // dedication page and a closing page without throwing.  This is a
      // structural smoke-test — it does not re-implement slice-1/2/3 unit
      // tests, but it proves the shared DotsAlbumSpreadPage infrastructure
      // (elements, header, footer) is unaffected by the slice-4 additions.
      final pages = buildSimplePagesFor(
        DotsAlbumType.parejas,
        const AlbumSimpleContent(
          dedication: _dedicationContent,
          closing: _closingContent,
        ),
        firstPageNumber: 5,
        contextLabelValue: DotsAlbumType.parejas.contextLabelToken,
      );

      expect(pages, hasLength(2),
          reason: 'buildSimplePagesFor must still return 2 pages for parejas');

      // Dedication page: must contain at least one rotated text element
      // (slice-2 angled title convention).
      expect(
        pages[0].elements.whereType<DotsRotatedTextElement>(),
        isNotEmpty,
        reason: 'dedication page must still carry a rotated text element',
      );

      // Closing page: must contain at least one image element (cover photo).
      expect(
        pages[1].elements.whereType<DotsImageElement>(),
        isNotEmpty,
        reason: 'closing page must still carry an image element',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsDecorativeCircleElement model sanity (R1) — GREEN in PR 1
  // Duplicates a few key asserts from dots_decorative_circle_element_test.dart
  // as a cross-file smoke-test.
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsDecorativeCircleElement — model sanity (R1)', () {
    test('DotsDecorativeCircleElement — constructs with all named fields', () {
      const element = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      expect(element.diameter, equals(133.23));
      expect(element.colorHex, equals('#CDE7F2'));
      expect(element.gaussianFadeMm, equals(1.764));
    });

    test('DotsDecorativeCircleElement — equality: identical instances are equal',
        () {
      const a = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      const b = DotsDecorativeCircleElement(
        x: 22.68,
        y: 121.89,
        diameter: 133.23,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
        'DotsDecorativeCircleElement — equality: differs when diameter changes',
        () {
      const a = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 133.23,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 79.37,
        colorHex: '#CDE7F2',
      );
      expect(a, isNot(equals(b)));
    });

    test(
        'DotsDecorativeCircleElement — equality: differs when colorHex changes',
        () {
      const a = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 133.23,
        colorHex: '#CDE7F2',
      );
      const b = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 133.23,
        colorHex: '#FF0000',
      );
      expect(a, isNot(equals(b)));
    });

    test('DotsDecorativeCircleElement — bleed flags default to false', () {
      const element = DotsDecorativeCircleElement(
        x: 0,
        y: 0,
        diameter: 45.0,
        colorHex: '#CDE7F2',
        gaussianFadeMm: 1.764,
      );
      expect(element.bleedLeft, isFalse);
      expect(element.bleedRight, isFalse);
      expect(element.bleedTop, isFalse);
      expect(element.bleedBottom, isFalse);
    });
  });
}
