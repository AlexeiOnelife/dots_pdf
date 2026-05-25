// Tests for buildPhotoArcPageFor — builder contract, per-type QR caption
// defaults, overrides, and ArgumentError for boda (R7, R8, T1.5).
//
// All tests in this file are RED until PR 2 implements:
//   - AlbumPhotoArcContent public export in lib/dots_pdf.dart (T5.2)
//   - DotsAlbumSpreadPage.photoArc factory (T4.2)
//   - buildPhotoArcPageFor top-level builder (T4.3)
//
// Placeholder bodies use fail('PR 2: ...') so the file compiles cleanly and
// shows as expected-RED in the test runner until those tasks land.
//
// Fixtures and helpers are intentionally absent in PR 1 — all symbols
// (AlbumPhotoArcContent, buildPhotoArcPageFor) are added to the public
// API in PR 2 (T5.2, T4.3).
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // buildPhotoArcPageFor — builder contract (R8)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — builder contract (R8)', () {
    test('returns DotsAlbumSpreadPage', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('throws ArgumentError for DotsAlbumType.boda', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Per-type QR caption defaults (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — per-type QR caption defaults (R7)', () {
    test('parejas left caption defaults to "Vuestro álbum en digital"', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('hijos left caption defaults to "Tu album en digital"', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('individuales left caption defaults to "Tu album en digital"', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('otros left caption defaults to "Tu album en digital"', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test(
        'right caption defaults to "Todos tus hitos en un lugar" for all 4 types',
        () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Caption overrides (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — caption overrides (R7)', () {
    test('qrCaptionLeftOverride wins over per-type default', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('qrCaptionRightOverride wins over per-type default', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Geometry parity across types (R8)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPhotoArcPageFor — geometry identical for all 4 supported types',
      () {
    test('all 4 types produce identical DotsPhotoCircleElement coordinates',
        () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });

    test('all 4 types produce identical DotsOvalQrElement geometry', () {
      fail('PR 2: buildPhotoArcPageFor not yet implemented (T4.3)');
    });
  });
}
