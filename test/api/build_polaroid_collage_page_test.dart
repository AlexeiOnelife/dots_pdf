// Tests for buildPolaroidCollagePageFor, AlbumCollageContent, and
// PolaroidSlotPosition value objects.
//
// T1.3 — RED until T4 is implemented.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

const _p1 = 'photo_1.jpg';
const _p2 = 'photo_2.jpg';
const _p3 = 'photo_3.jpg';
const _p4 = 'photo_4.jpg';
const _p5 = 'photo_5.jpg';
const _p6 = 'photo_6.jpg';

const _sixPaths = <String>[_p1, _p2, _p3, _p4, _p5, _p6];

void main() {
  group('buildPolaroidCollagePageFor — builder behavior (R7)', () {
    test('buildPolaroidCollagePageFor — returns DotsAlbumSpreadPage', () {
      final result = buildPolaroidCollagePageFor(
        DotsAlbumType.individuales,
        const AlbumCollageContent(photoPaths: _sixPaths),
        pageNumber: 6,
        contextLabelValue: '2024',
      );
      expect(result, isA<DotsAlbumSpreadPage>());
    });

    test('buildPolaroidCollagePageFor — header.centerLabel equals contextLabelValue',
        () {
      final result = buildPolaroidCollagePageFor(
        DotsAlbumType.individuales,
        const AlbumCollageContent(photoPaths: _sixPaths),
        pageNumber: 6,
        contextLabelValue: '2024',
      );
      expect(result.header.centerLabel, equals('2024'));
    });

    test('buildPolaroidCollagePageFor — pageNumber is correctly forwarded', () {
      final result = buildPolaroidCollagePageFor(
        DotsAlbumType.individuales,
        const AlbumCollageContent(photoPaths: _sixPaths),
        pageNumber: 12,
        contextLabelValue: 'Ana',
      );
      expect(result.pageNumber, equals(12));
    });

    test('buildPolaroidCollagePageFor — individuales and otros geometry identical when applyOtrosGradient=false',
        () {
      const content = AlbumCollageContent(photoPaths: _sixPaths);
      final indiv = buildPolaroidCollagePageFor(
        DotsAlbumType.individuales,
        content,
        pageNumber: 6,
        contextLabelValue: '2024',
      );
      final otros = buildPolaroidCollagePageFor(
        DotsAlbumType.otros,
        content,
        pageNumber: 6,
        contextLabelValue: '2024',
      );

      final indivElems = indiv.elements.cast<DotsPolaroidElement>();
      final otrosElems = otros.elements.cast<DotsPolaroidElement>();
      expect(indivElems.length, equals(otrosElems.length));

      for (var i = 0; i < indivElems.length; i++) {
        expect(indivElems[i].x, closeTo(otrosElems[i].x, 0.001));
        expect(indivElems[i].y, closeTo(otrosElems[i].y, 0.001));
        expect(indivElems[i].width, closeTo(otrosElems[i].width, 0.001));
        expect(indivElems[i].height, closeTo(otrosElems[i].height, 0.001));
        expect(indivElems[i].angleDegrees,
            closeTo(otrosElems[i].angleDegrees, 0.001));
      }
    });

    test('buildPolaroidCollagePageFor — only polar-2 differs when applyOtrosGradient=true',
        () {
      final indiv = buildPolaroidCollagePageFor(
        DotsAlbumType.individuales,
        const AlbumCollageContent(photoPaths: _sixPaths),
        pageNumber: 6,
        contextLabelValue: '2024',
      );
      final otros = buildPolaroidCollagePageFor(
        DotsAlbumType.otros,
        const AlbumCollageContent(
          photoPaths: _sixPaths,
          applyOtrosGradient: true,
        ),
        pageNumber: 6,
        contextLabelValue: '2024',
      );

      final indivElems = indiv.elements.cast<DotsPolaroidElement>();
      final otrosElems = otros.elements.cast<DotsPolaroidElement>();

      // polar-2 (index 1) differs in gradientRtl
      expect(indivElems[1].gradientRtl, isFalse);
      expect(otrosElems[1].gradientRtl, isTrue);

      // All other elements are identical
      for (var i = 0; i < indivElems.length; i++) {
        if (i == 1) continue;
        expect(indivElems[i].gradientRtl, isFalse);
        expect(otrosElems[i].gradientRtl, isFalse);
      }
    });

    test('buildPolaroidCollagePageFor — photoPaths length mismatch throws RangeError',
        () {
      expect(
        () => buildPolaroidCollagePageFor(
          DotsAlbumType.individuales,
          const AlbumCollageContent(photoPaths: [_p1, _p2]),
          pageNumber: 6,
          contextLabelValue: '2024',
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('AlbumCollageContent — value object (R5)', () {
    test('AlbumCollageContent — two instances with same fields are equal', () {
      const a = AlbumCollageContent(
        photoPaths: _sixPaths,
        applyOtrosGradient: false,
        additionalSlots: [],
      );
      const b = AlbumCollageContent(
        photoPaths: _sixPaths,
        applyOtrosGradient: false,
        additionalSlots: [],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('AlbumCollageContent — applyOtrosGradient defaults to false', () {
      const c = AlbumCollageContent(photoPaths: _sixPaths);
      expect(c.applyOtrosGradient, isFalse);
      expect(c.additionalSlots, isEmpty);
    });
  });

  group('PolaroidSlotPosition — value object (R6)', () {
    test('PolaroidSlotPosition — constructs with all fields and exposes them correctly',
        () {
      const slot = PolaroidSlotPosition(
        x: 95.0,
        y: 120.0,
        width: 306.14,
        height: 379.84,
        angleDegrees: 0.0,
        gradientRtl: false,
        bleedLeft: false,
        bleedRight: false,
        bleedTop: false,
        bleedBottom: false,
      );
      expect(slot.x, equals(95.0));
      expect(slot.y, equals(120.0));
      expect(slot.width, equals(306.14));
      expect(slot.height, equals(379.84));
      expect(slot.angleDegrees, equals(0.0));
      expect(slot.gradientRtl, isFalse);
      expect(slot.bleedLeft, isFalse);
    });

    test('PolaroidSlotPosition — two equal instances have same hashCode', () {
      const a = PolaroidSlotPosition(
        x: 95.0,
        y: 120.0,
        width: 306.14,
        height: 379.84,
        angleDegrees: 0.0,
      );
      const b = PolaroidSlotPosition(
        x: 95.0,
        y: 120.0,
        width: 306.14,
        height: 379.84,
        angleDegrees: 0.0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
