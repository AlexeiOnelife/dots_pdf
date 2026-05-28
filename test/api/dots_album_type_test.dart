// Tests for DotsAlbumType — enum values and contextLabelToken (R3, T1.4).
//
// These tests are GREEN in PR 1.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsAlbumType', () {
    test('DotsAlbumType — has exactly six values including generalEventos', () {
      expect(DotsAlbumType.values, hasLength(6));
      expect(DotsAlbumType.values, contains(DotsAlbumType.generalEventos));
    });

    test('DotsAlbumType.generalEventos — contextLabelToken is {Protagonistas}',
        () {
      expect(
        DotsAlbumType.generalEventos.contextLabelToken,
        equals('{Protagonistas}'),
      );
    });

    // Triangulation: verify all six values have non-empty tokens and that
    // no other arm was accidentally broken.
    test('DotsAlbumType — all six values have non-empty contextLabelToken', () {
      for (final value in DotsAlbumType.values) {
        expect(
          value.contextLabelToken,
          isNotEmpty,
          reason: '${value.name}.contextLabelToken must be non-empty',
        );
      }
    });
  });
}
