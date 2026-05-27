import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsAlbumType contextLabel — context-label resolver (R3)', () {
    // ---- per-value correct token ----

    test('DotsAlbumType contextLabel — boda returns {Protagonistas}', () {
      expect(DotsAlbumType.boda.contextLabelToken, equals('{Protagonistas}'));
    });

    test('DotsAlbumType contextLabel — parejas returns {tiempojuntos}', () {
      expect(
        DotsAlbumType.parejas.contextLabelToken,
        equals('{tiempojuntos}'),
      );
    });

    test('DotsAlbumType contextLabel — hijos returns {Protagonistas}', () {
      expect(DotsAlbumType.hijos.contextLabelToken, equals('{Protagonistas}'));
    });

    test('DotsAlbumType contextLabel — individuales returns {Año}', () {
      expect(DotsAlbumType.individuales.contextLabelToken, equals('{Año}'));
    });

    test('DotsAlbumType contextLabel — otros returns {Año}', () {
      expect(DotsAlbumType.otros.contextLabelToken, equals('{Año}'));
    });

    // ---- exhaustiveness: every enum value returns a non-null, non-empty string ----

    test('DotsAlbumType contextLabel — exhaustive (all enum values covered)',
        () {
      for (final value in DotsAlbumType.values) {
        final token = value.contextLabelToken;
        expect(
          token,
          isNotEmpty,
          reason: '${value.name}.contextLabelToken must be non-empty',
        );
      }
    });
  });
}
