// Tests for DotsGradientDirection — 4 enum values, exhaustiveness,
// name strings (R1/D2).
// GREEN immediately: the enum exists after T2.1.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsGradientDirection — enum values (D2)', () {
    test('has exactly 4 values', () {
      expect(DotsGradientDirection.values.length, 4);
    });

    test('contains topToBottom', () {
      expect(DotsGradientDirection.values, contains(DotsGradientDirection.topToBottom));
    });

    test('contains bottomToTop', () {
      expect(DotsGradientDirection.values, contains(DotsGradientDirection.bottomToTop));
    });

    test('contains leftToRight', () {
      expect(DotsGradientDirection.values, contains(DotsGradientDirection.leftToRight));
    });

    test('contains rightToLeft', () {
      expect(DotsGradientDirection.values, contains(DotsGradientDirection.rightToLeft));
    });

    test('name strings match enum value names', () {
      expect(DotsGradientDirection.topToBottom.name, 'topToBottom');
      expect(DotsGradientDirection.bottomToTop.name, 'bottomToTop');
      expect(DotsGradientDirection.leftToRight.name, 'leftToRight');
      expect(DotsGradientDirection.rightToLeft.name, 'rightToLeft');
    });

    test('exhaustiveness: switch covers all 4 values without default', () {
      // If the enum gains a 5th value this switch would fail to compile,
      // giving early warning of exhaustiveness breakage.
      for (final direction in DotsGradientDirection.values) {
        final label = switch (direction) {
          DotsGradientDirection.topToBottom => 'topToBottom',
          DotsGradientDirection.bottomToTop => 'bottomToTop',
          DotsGradientDirection.leftToRight => 'leftToRight',
          DotsGradientDirection.rightToLeft => 'rightToLeft',
        };
        expect(label, direction.name);
      }
    });
  });
}
