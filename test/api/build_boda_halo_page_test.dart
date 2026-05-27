// RED test scaffolding for buildBodaHaloPageFor builder and
// DotsAlbumSpreadPage.bodaHalo factory (R4, R5, R6, R7, R9).
// All tests in this file use fail('PR 2: ...') placeholders — they will be
// wired in slice 7 PR 2 when AlbumBodaHaloContent, buildBodaHaloPageFor, and
// the DotsAlbumSpreadPage.bodaHalo body are implemented.
//
// Scenarios: S15–S17 (AlbumBodaHaloContent), S18–S24 (factory),
//            S25–S27 (builder), S30 (exhaustiveness), S31 (preload),
//            S34 (exports).
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AlbumBodaHaloContent value object (R4)
  // ---------------------------------------------------------------------------

  group('AlbumBodaHaloContent — constructs with defaults (S15) [PR 2]', () {
    test('titleLine1 defaults to "Boda de"', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });

    test('qrCaptionLeftOverride defaults to null', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });

    test('qrCaptionRightOverride defaults to null', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });
  });

  group('AlbumBodaHaloContent — list equality on photoPaths (S16) [PR 2]', () {
    test('two instances with identical fields and photoPaths are equal', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });

    test('equal instances have same hashCode', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });
  });

  group('AlbumBodaHaloContent — inequality when photoPaths differ (S17) [PR 2]', () {
    test('instances with different photoPaths entry are not equal', () {
      fail('PR 2: implement when AlbumBodaHaloContent is created');
    });
  });

  // ---------------------------------------------------------------------------
  // DotsAlbumSpreadPage.bodaHalo factory (R5)
  // ---------------------------------------------------------------------------

  group('DotsAlbumSpreadPage.bodaHalo — 15 elements (S18) [PR 2]', () {
    test('produces exactly 15 elements', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('exactly 10 elements are DotsRotatedPhotoElement instances', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('exactly 2 elements are DotsOvalQrElement instances', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('exactly 3 elements are DotsTextElement instances', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — assetPath propagation (S19) [PR 2]', () {
    test('each rotated photo element assetPath matches photoPaths[i]', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — header trio (S20) [PR 2]', () {
    test('header.leftPageNumber equals pageNumber as string', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('header.rightPageNumber equals pageNumber+1 as string', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('header.centerLabel equals contextLabelValue', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — ArgumentError for non-boda type (S21) [PR 2]', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — RangeError for 9 photoPaths (S22) [PR 2]', () {
    test('throws RangeError when photoPaths has 9 entries', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — RangeError for 11 photoPaths (S23) [PR 2]', () {
    test('throws RangeError when photoPaths has 11 entries', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  group('DotsAlbumSpreadPage.bodaHalo — QR caption overrides (S24) [PR 2]', () {
    test('left QR caption override wins over default', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });

    test('right QR default caption used when override is null', () {
      fail('PR 2: implement when bodaHalo factory body is complete');
    });
  });

  // ---------------------------------------------------------------------------
  // buildBodaHaloPageFor builder (R6)
  // ---------------------------------------------------------------------------

  group('buildBodaHaloPageFor — returns DotsAlbumSpreadPage for boda (S25) [PR 2]', () {
    test('return type is DotsAlbumSpreadPage', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });
  });

  group('buildBodaHaloPageFor — ArgumentError for non-boda types (S26) [PR 2]', () {
    test('throws ArgumentError for DotsAlbumType.parejas', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });

    test('throws ArgumentError for DotsAlbumType.hijos', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });

    test('throws ArgumentError for DotsAlbumType.individuales', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });

    test('throws ArgumentError for DotsAlbumType.otros', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });
  });

  group('buildBodaHaloPageFor — RangeError for photoPaths length mismatch (S27) [PR 2]', () {
    test('throws RangeError when photoPaths has 9 entries', () {
      fail('PR 2: implement when buildBodaHaloPageFor is created');
    });
  });

  // ---------------------------------------------------------------------------
  // Exhaustiveness / preload / exports (R7, R9)
  // ---------------------------------------------------------------------------

  group('preloadAssetBytes — rotated photo assetPath collected (S31) [PR 2]', () {
    test('assetPath of DotsRotatedPhotoElement appears in preloadAssetBytes result', () {
      fail('PR 2: implement after bodaHalo factory + preload arm verified end-to-end');
    });
  });

  group('public exports — new symbols importable from lib/dots_pdf.dart (S34) [PR 2]', () {
    test('DotsRotatedPhotoElement is importable via dots_pdf.dart', () {
      fail('PR 2: implement after exports are added in T5.1');
    });

    test('AlbumBodaHaloContent is importable via dots_pdf.dart', () {
      fail('PR 2: implement after exports are added in T5.1');
    });

    test('buildBodaHaloPageFor is importable via dots_pdf.dart', () {
      fail('PR 2: implement after exports are added in T5.1');
    });
  });
}
