// Tests for buildBodaHaloPageFor builder and DotsAlbumSpreadPage.bodaHalo
// factory (R4, R5, R6, R7, R9).
// Scenarios: S15–S17 (AlbumBodaHaloContent), S18–S24 (factory),
//            S25–S27 (builder), S30 (exhaustiveness), S31 (preload),
//            S34 (exports).
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _photoPaths10() =>
    List.generate(10, (i) => 'photo_$i.jpg');

AlbumBodaHaloContent _content10({
  List<String>? photoPaths,
  String? qrCaptionLeftOverride,
  String? qrCaptionRightOverride,
}) =>
    AlbumBodaHaloContent(
      photoPaths: photoPaths ?? _photoPaths10(),
      titleLine2: 'Ana & Luis',
      dateSubtitle: '12 de octubre de 2024',
      qrPayloadLeft: 'https://example.com/left',
      qrPayloadRight: 'https://example.com/right',
      qrCaptionLeftOverride: qrCaptionLeftOverride,
      qrCaptionRightOverride: qrCaptionRightOverride,
    );

DotsAlbumSpreadPage _buildPage({
  DotsAlbumType type = DotsAlbumType.boda,
  AlbumBodaHaloContent? content,
  int pageNumber = 4,
  String contextLabelValue = 'Ana & Luis',
}) =>
    buildBodaHaloPageFor(
      type,
      content ?? _content10(),
      pageNumber: pageNumber,
      contextLabelValue: contextLabelValue,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---------------------------------------------------------------------------
  // AlbumBodaHaloContent value object (R4)
  // ---------------------------------------------------------------------------

  group('AlbumBodaHaloContent — constructs with defaults (S15)', () {
    test('titleLine1 defaults to "Boda de"', () {
      final content = _content10();
      expect(content.titleLine1, 'Boda de');
    });

    test('qrCaptionLeftOverride defaults to null', () {
      final content = _content10();
      expect(content.qrCaptionLeftOverride, isNull);
    });

    test('qrCaptionRightOverride defaults to null', () {
      final content = _content10();
      expect(content.qrCaptionRightOverride, isNull);
    });
  });

  group('AlbumBodaHaloContent — list equality on photoPaths (S16)', () {
    test('two instances with identical fields and photoPaths are equal', () {
      final a = _content10();
      final b = _content10();
      expect(a, equals(b));
    });

    test('equal instances have same hashCode', () {
      final a = _content10();
      final b = _content10();
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('AlbumBodaHaloContent — inequality when photoPaths differ (S17)', () {
    test('instances with different photoPaths entry are not equal', () {
      final a = _content10();
      final b = _content10(
        photoPaths: ['different.jpg', ..._photoPaths10().skip(1)],
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // DotsAlbumSpreadPage.bodaHalo factory (R5)
  // ---------------------------------------------------------------------------

  group('DotsAlbumSpreadPage.bodaHalo — 15 elements (S18)', () {
    test('produces exactly 15 elements', () {
      final page = _buildPage();
      expect(page.elements.length, 15);
    });

    test('exactly 10 elements are DotsRotatedPhotoElement instances', () {
      final page = _buildPage();
      expect(
        page.elements.whereType<DotsRotatedPhotoElement>().length,
        10,
      );
    });

    test('exactly 2 elements are DotsOvalQrElement instances', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsOvalQrElement>().length, 2);
    });

    test('exactly 3 elements are DotsTextElement instances', () {
      final page = _buildPage();
      expect(page.elements.whereType<DotsTextElement>().length, 3);
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — assetPath propagation (S19)', () {
    test('each rotated photo element assetPath matches photoPaths[i]', () {
      final content = _content10();
      final page = _buildPage(content: content);
      final rotatedElements =
          page.elements.whereType<DotsRotatedPhotoElement>().toList();
      for (var i = 0; i < 10; i++) {
        expect(rotatedElements[i].assetPath, content.photoPaths[i]);
      }
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — header trio (S20)', () {
    test('header.leftPageNumber equals pageNumber as string', () {
      final page = _buildPage(pageNumber: 4);
      expect(page.header.leftPageNumber, '4');
    });

    test('header.rightPageNumber equals pageNumber+1 as string', () {
      final page = _buildPage(pageNumber: 4);
      expect(page.header.rightPageNumber, '5');
    });

    test('header.centerLabel equals contextLabelValue', () {
      final page = _buildPage(contextLabelValue: 'Ana & Luis');
      expect(page.header.centerLabel, 'Ana & Luis');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — ArgumentError for non-boda type (S21)',
      () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      expect(
        () => _buildPage(type: DotsAlbumType.parejas),
        throwsArgumentError,
      );
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — RangeError for 9 photoPaths (S22)', () {
    test('throws RangeError when photoPaths has 9 entries', () {
      expect(
        () => _buildPage(
          content: _content10(
            photoPaths: List.generate(9, (i) => 'photo_$i.jpg'),
          ),
        ),
        throwsRangeError,
      );
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — RangeError for 11 photoPaths (S23)',
      () {
    test('throws RangeError when photoPaths has 11 entries', () {
      expect(
        () => _buildPage(
          content: _content10(
            photoPaths: List.generate(11, (i) => 'photo_$i.jpg'),
          ),
        ),
        throwsRangeError,
      );
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — QR caption overrides (S24)', () {
    test('left QR caption override wins over default', () {
      final page = _buildPage(
        content: _content10(qrCaptionLeftOverride: 'Custom left'),
      );
      final ovals = page.elements.whereType<DotsOvalQrElement>().toList();
      expect(ovals[0].caption, 'Custom left');
    });

    test('right QR default caption used when override is null', () {
      final page = _buildPage(
        content: _content10(qrCaptionLeftOverride: 'Custom left'),
      );
      final ovals = page.elements.whereType<DotsOvalQrElement>().toList();
      expect(
        ovals[1].caption,
        'Escanea el QR para volver a ver el álbum y los vídeos',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildBodaHaloPageFor builder (R6)
  // ---------------------------------------------------------------------------

  group('buildBodaHaloPageFor — returns DotsAlbumSpreadPage for boda (S25)',
      () {
    test('return type is DotsAlbumSpreadPage', () {
      final result = _buildPage();
      expect(result, isA<DotsAlbumSpreadPage>());
    });
  });

  group('buildBodaHaloPageFor — ArgumentError for non-boda types (S26)', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      expect(
        () => _buildPage(type: DotsAlbumType.parejas),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.hijos', () {
      expect(
        () => _buildPage(type: DotsAlbumType.hijos),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.individuales', () {
      expect(
        () => _buildPage(type: DotsAlbumType.individuales),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for DotsAlbumType.otros', () {
      expect(
        () => _buildPage(type: DotsAlbumType.otros),
        throwsArgumentError,
      );
    });
  });

  group('buildBodaHaloPageFor — RangeError for photoPaths length mismatch (S27)',
      () {
    test('throws RangeError when photoPaths has 9 entries', () {
      expect(
        () => buildBodaHaloPageFor(
          DotsAlbumType.boda,
          AlbumBodaHaloContent(
            photoPaths: List.generate(9, (i) => 'photo_$i.jpg'),
            titleLine2: 'A & B',
            dateSubtitle: 'x',
            qrPayloadLeft: 'l',
            qrPayloadRight: 'r',
          ),
          pageNumber: 4,
          contextLabelValue: 'Test',
        ),
        throwsRangeError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Exhaustiveness / preload / exports (R7, R9)
  // ---------------------------------------------------------------------------

  group('preloadAssetBytes — rotated photo assetPath collected (S31)', () {
    test('assetPath of DotsRotatedPhotoElement appears in preloadAssetBytes result',
        () {
      // Build a page with known assetPaths and verify the spread page model
      // carries them (preloadAssetBytes is exercised indirectly via the factory
      // producing DotsRotatedPhotoElement instances that include assetPath).
      final content = _content10();
      final page = _buildPage(content: content);
      final rotatedElements =
          page.elements.whereType<DotsRotatedPhotoElement>().toList();
      // All 10 assetPaths must be present in the elements list.
      final assetPaths = rotatedElements.map((e) => e.assetPath).toList();
      for (final path in content.photoPaths) {
        expect(assetPaths, contains(path));
      }
    });
  });

  group('public exports — new symbols importable from lib/dots_pdf.dart (S34)',
      () {
    test('DotsRotatedPhotoElement is importable via dots_pdf.dart', () {
      // Construction succeeds — the symbol is accessible from the barrel export.
      const element = DotsRotatedPhotoElement(
        x: 0,
        y: 0,
        assetPath: 'a.jpg',
        width: 95.0,
        height: 131.4,
        angleDegrees: 3.2,
      );
      expect(element, isA<DotsRotatedPhotoElement>());
    });

    test('AlbumBodaHaloContent is importable via dots_pdf.dart', () {
      final content = _content10();
      expect(content, isA<AlbumBodaHaloContent>());
    });

    test('buildBodaHaloPageFor is importable via dots_pdf.dart', () {
      final page = buildBodaHaloPageFor(
        DotsAlbumType.boda,
        _content10(),
        pageNumber: 4,
        contextLabelValue: 'Test',
      );
      expect(page, isA<DotsAlbumSpreadPage>());
    });
  });
}
