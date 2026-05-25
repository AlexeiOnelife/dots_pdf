// Tests for kCoverCircleLayout — entry count, diameter tiers, and bleed flags
// (R1, T1.2).
//
// These tests are GREEN as soon as T2.2 lands (which it has in this PR batch).
import 'package:dots_pdf/src/render/cover_circles.dart'
    show kCoverCircleLayoutForTest;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kCoverCircleLayout — structure (R1)', () {
    test('exactly 14 entries', () {
      expect(kCoverCircleLayoutForTest.length, equals(14));
    });

    test('diameter tier set equals {47, 28, 16}', () {
      final tiers = kCoverCircleLayoutForTest.map((e) => e.diameterMm).toSet();
      expect(tiers, equals(<double>{47, 28, 16}));
    });

    test('exactly 5 circles at 47 mm', () {
      final count =
          kCoverCircleLayoutForTest.where((e) => e.diameterMm == 47).length;
      expect(count, equals(5));
    });

    test('exactly 4 circles at 28 mm', () {
      final count =
          kCoverCircleLayoutForTest.where((e) => e.diameterMm == 28).length;
      expect(count, equals(4));
    });

    test('exactly 5 circles at 16 mm', () {
      final count =
          kCoverCircleLayoutForTest.where((e) => e.diameterMm == 16).length;
      expect(count, equals(5));
    });
  });

  group('kCoverCircleLayout — bleed flags per spec table', () {
    // Helper: find the anchor closest to the given (x, y, d) spec values.
    _Anchor findAnchor(double d, double x, double y) {
      final match = kCoverCircleLayoutForTest.firstWhere(
        (e) => e.diameterMm == d && e.xMm == x && e.yMm == y,
        orElse: () => throw TestFailure(
          'No circle found with diameterMm=$d xMm=$x yMm=$y',
        ),
      );
      return (
        bleedLeft: match.bleedLeft,
        bleedRight: match.bleedRight,
        bleedTop: match.bleedTop,
        bleedBottom: match.bleedBottom,
      );
    }

    test('circle #1 (d=47, x=8, y=43) — all bleed flags false', () {
      final f = findAnchor(47, 8, 43);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedRight, isFalse);
      expect(f.bleedTop, isFalse);
      expect(f.bleedBottom, isFalse);
    });

    test('circle #2 (d=47, x=141, y=4) — bleedTop true', () {
      final f = findAnchor(47, 141, 4);
      expect(f.bleedTop, isTrue);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedRight, isFalse);
      expect(f.bleedBottom, isFalse);
    });

    test('circle #3 (d=47, x=210, y=33) — bleedRight true', () {
      final f = findAnchor(47, 210, 33);
      expect(f.bleedRight, isTrue);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedTop, isFalse);
      expect(f.bleedBottom, isFalse);
    });

    test('circle #4 (d=47, x=-13, y=169) — bleedLeft true', () {
      final f = findAnchor(47, -13, 169);
      expect(f.bleedLeft, isTrue);
      expect(f.bleedRight, isFalse);
      expect(f.bleedTop, isFalse);
      expect(f.bleedBottom, isFalse);
    });

    test('circle #5 (d=47, x=200, y=240) — bleedRight and bleedBottom true',
        () {
      final f = findAnchor(47, 200, 240);
      expect(f.bleedRight, isTrue);
      expect(f.bleedBottom, isTrue);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedTop, isFalse);
    });

    test('circle #9 (d=28, x=138, y=225) — bleedBottom true', () {
      final f = findAnchor(28, 138, 225);
      expect(f.bleedBottom, isTrue);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedRight, isFalse);
      expect(f.bleedTop, isFalse);
    });

    test('circle #14 (d=16, x=50, y=273) — bleedBottom true', () {
      final f = findAnchor(16, 50, 273);
      expect(f.bleedBottom, isTrue);
      expect(f.bleedLeft, isFalse);
      expect(f.bleedRight, isFalse);
      expect(f.bleedTop, isFalse);
    });

    test('all other circles have all bleed flags false', () {
      // The circles that have at least one bleed flag set, by (d, x, y).
      // Not const: Dart records override == / hashCode and cannot be const.
      final bleedingCircles = <(double, double, double)>{
        (47, 141, 4),   // #2 bleedTop
        (47, 210, 33),  // #3 bleedRight
        (47, -13, 169), // #4 bleedLeft
        (47, 200, 240), // #5 bleedRight+bleedBottom
        (28, 138, 225), // #9 bleedBottom
        (16, 50, 273),  // #14 bleedBottom
      };

      for (final anchor in kCoverCircleLayoutForTest) {
        final key = (anchor.diameterMm, anchor.xMm, anchor.yMm);
        if (bleedingCircles.contains(key)) continue;
        expect(
          anchor.bleedLeft || anchor.bleedRight ||
              anchor.bleedTop || anchor.bleedBottom,
          isFalse,
          reason:
              'Expected no bleed flags for circle at '
              '(d=${anchor.diameterMm}, x=${anchor.xMm}, y=${anchor.yMm})',
        );
      }
    });
  });
}

// Local typedef so the helper closure compiles without referencing the
// exported record type by its full name every time.
typedef _Anchor = ({
  bool bleedLeft,
  bool bleedRight,
  bool bleedTop,
  bool bleedBottom,
});
