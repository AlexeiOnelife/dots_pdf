// Tests for DotsAlbumSpreadPage.polaroidCollage factory — element emission,
// gradient flag wiring, and coordinate pass-through.
//
// T1.2 — RED until T2.1 + T3 are implemented.
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
  group('polaroidCollage — element emission (R4)', () {
    test('polaroidCollage — 6 photoPaths produces 6 DotsPolaroidElement instances',
        () {
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
      );
      expect(page.elements.length, equals(6));
      for (final e in page.elements) {
        expect(e, isA<DotsPolaroidElement>());
      }
    });

    test('polaroidCollage — additionalSlots extends elements list to 8', () {
      final extraSlot = PolaroidSlotPosition(
        x: 10.0,
        y: 10.0,
        width: kDefaultPolaroidSlots[0].width,
        height: kDefaultPolaroidSlots[0].height,
        angleDegrees: 0.0,
      );
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: const [..._sixPaths, 'photo_7.jpg', 'photo_8.jpg'],
        additionalSlots: <PolaroidSlotPosition>[extraSlot, extraSlot],
      );
      expect(page.elements.length, equals(8));
    });

    test('polaroidCollage — photoPaths length mismatch throws RangeError', () {
      expect(
        () => DotsAlbumSpreadPage.polaroidCollage(
          type: DotsAlbumType.individuales,
          pageNumber: 6,
          contextLabelValue: '2024',
          photoPaths: const [_p1, _p2], // only 2 paths for 6 slots
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('polaroidCollage — gradient flag wiring (R3, R4)', () {
    test('polaroidCollage — polar-2 gradientRtl=true when applyOtrosGradient=true',
        () {
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.otros,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
        applyOtrosGradient: true,
      );
      final elements = page.elements.cast<DotsPolaroidElement>();
      expect(elements[1].gradientRtl, isTrue); // polar-2 is index 1
    });

    test('polaroidCollage — all other slots have gradientRtl=false when applyOtrosGradient=true',
        () {
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.otros,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
        applyOtrosGradient: true,
      );
      final elements = page.elements.cast<DotsPolaroidElement>();
      for (var i = 0; i < elements.length; i++) {
        if (i != 1) {
          expect(elements[i].gradientRtl, isFalse,
              reason: 'element[$i] should have gradientRtl=false');
        }
      }
    });

    test('polaroidCollage — polar-2 gradientRtl=false when applyOtrosGradient=false',
        () {
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
        applyOtrosGradient: false,
      );
      final elements = page.elements.cast<DotsPolaroidElement>();
      expect(elements[1].gradientRtl, isFalse);
    });
  });

  group('polaroidCollage — geometry (R4)', () {
    test('polaroidCollage — individuales and otros produce identical element coordinates',
        () {
      final indiv = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
        applyOtrosGradient: false,
      );
      final otros = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.otros,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
        applyOtrosGradient: false,
      );

      final indivElems = indiv.elements.cast<DotsPolaroidElement>();
      final otrosElems = otros.elements.cast<DotsPolaroidElement>();

      for (var i = 0; i < indivElems.length; i++) {
        expect(indivElems[i].x, closeTo(otrosElems[i].x, 0.001),
            reason: 'element[$i].x should match');
        expect(indivElems[i].y, closeTo(otrosElems[i].y, 0.001),
            reason: 'element[$i].y should match');
        expect(indivElems[i].width, closeTo(otrosElems[i].width, 0.001),
            reason: 'element[$i].width should match');
        expect(indivElems[i].height, closeTo(otrosElems[i].height, 0.001),
            reason: 'element[$i].height should match');
        expect(indivElems[i].angleDegrees,
            closeTo(otrosElems[i].angleDegrees, 0.001),
            reason: 'element[$i].angleDegrees should match');
      }
    });

    test('polaroidCollage — first element coordinates match kDefaultPolaroidSlots[0]',
        () {
      final page = DotsAlbumSpreadPage.polaroidCollage(
        type: DotsAlbumType.individuales,
        pageNumber: 6,
        contextLabelValue: '2024',
        photoPaths: _sixPaths,
      );
      final first = page.elements.first as DotsPolaroidElement;
      final slot = kDefaultPolaroidSlots[0];
      expect(first.x, closeTo(slot.x, 0.001));
      expect(first.y, closeTo(slot.y, 0.001));
      expect(first.width, closeTo(slot.width, 0.001));
      expect(first.height, closeTo(slot.height, 0.001));
      expect(first.angleDegrees, closeTo(slot.angleDegrees, 0.001));
    });
  });
}
