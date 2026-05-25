// Tests for DotsAlbumSpreadPage.photoArc factory and photo-arc rendering
// (R6, R9, R10, R11, T1.4).
//
// All tests in this file are RED until PR 2 implements:
//   - DotsAlbumSpreadPage.photoArc factory (T4.2)
//   - _buildPhotoCircleElement renderer (T3.2)
//   - _buildOvalQrElement renderer (T3.3)
//   - width-warning check (T3.5)
//
// Placeholder bodies use fail('PR 2: ...') so the file compiles cleanly and
// shows as expected-RED in the test runner until those tasks land.
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures and helpers are intentionally absent in PR 1: the factory
// (DotsAlbumSpreadPage.photoArc), the renderer helpers, and the public
// AlbumPhotoArcContent export all land in PR 2 (T4.2, T3.x, T5.2).
// All test bodies below use fail() so the file compiles cleanly now.
// ---------------------------------------------------------------------------

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.photoArc factory — element emission (R6)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.photoArc — elements list (R6)', () {
    test('elements list has exactly 14 entries', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('exactly 10 elements are DotsPhotoCircleElement', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('exactly 2 elements are DotsOvalQrElement', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('exactly 2 elements are DotsTextElement', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('circle elements match kPhotoArcLayout coordinates', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('header.centerLabel equals contextLabelValue', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('footer.wordmark equals "Dots. Memories"', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DotsAlbumSpreadPage.photoArc — error contracts (R6, R10)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsAlbumSpreadPage.photoArc — error contracts', () {
    test('throws ArgumentError for DotsAlbumType.boda', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('throws RangeError when photoPaths.length == 9', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('throws RangeError when photoPaths.length == 11', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });

    test('no error when photoPaths.length == 10', () {
      fail('PR 2: DotsAlbumSpreadPage.photoArc factory not yet implemented (T4.2)');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Photo-arc rendering (R9, R11)
  // ──────────────────────────────────────────────────────────────────────────

  group('photo-arc rendering (R9)', () {
    test('render via main-isolate produces non-empty PDF byte buffer', () {
      fail('PR 2: _buildPhotoCircleElement / _buildOvalQrElement not yet implemented (T3.2, T3.3)');
    });

    test('render via worker-isolate produces non-empty PDF byte buffer', () {
      fail('PR 2: _buildPhotoCircleElement / _buildOvalQrElement not yet implemented (T3.2, T3.3)');
    });

    test('photo decode failure skips element and fires onPhotoFailure', () {
      fail('PR 2: _buildPhotoCircleElement not yet implemented (T3.2)');
    });

    test('logger warns when page width < 406 mm (R11)', () {
      fail('PR 2: width-warning check not yet implemented (T3.5)');
    });
  });
}
