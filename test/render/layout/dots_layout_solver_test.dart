import 'package:dots_pdf/src/render/layout/dots_layout_code.dart';
import 'package:dots_pdf/src/render/layout/dots_layout_solver.dart';
import 'package:dots_pdf/src/render/layout/dots_page_geometry.dart';
import 'package:dots_pdf/src/render/layout/dots_slot_rect.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tolerance for floating-point equality on millimeter values.
const double _tolMm = 0.001;

DotsPageGeometry _geometry() => DotsPageGeometry.dotbookDefault();

const DotsLayoutSolver _solver = DotsLayoutSolver();

/// Returns the list of photo-kind slots in [slots] (order preserved).
List<DotsSlotRect> _photos(List<DotsSlotRect> slots) =>
    slots.where((DotsSlotRect s) => s.kind == DotsSlotKind.photo).toList();

void _expectOuterAligned(
  DotsSlotRect slot,
  DotsPageGeometry geometry, {
  required bool isLeftPage,
}) {
  final double expectedX = isLeftPage
      ? geometry.outerMarginMm
      : geometry.pageWidthMm - geometry.outerMarginMm - slot.widthMm;
  expect(
    (slot.xMm - expectedX).abs(),
    lessThan(_tolMm),
    reason: 'slot x=$slot.xMm should equal outer-aligned x=$expectedX '
        '(isLeftPage=$isLeftPage)',
  );
}

void main() {
  // ---------------------------------------------------------------------
  // Helper unit test — the outer-edge alignment formula is the single
  // shared positioning rule across every photo layout.
  // ---------------------------------------------------------------------
  group('DotsLayoutSolver.outerAlignedX', () {
    final DotsPageGeometry g = _geometry();

    test('left page: returns outerMarginMm regardless of block width', () {
      expect(
        DotsLayoutSolver.outerAlignedXForTest(g, 142, isLeftPage: true),
        equals(g.outerMarginMm),
      );
      expect(
        DotsLayoutSolver.outerAlignedXForTest(g, 86, isLeftPage: true),
        equals(g.outerMarginMm),
      );
    });

    test('right page: returns pageWidth - outerMargin - blockWidth', () {
      expect(
        DotsLayoutSolver.outerAlignedXForTest(g, 142, isLeftPage: false),
        equals(g.pageWidthMm - g.outerMarginMm - 142),
      );
      expect(
        DotsLayoutSolver.outerAlignedXForTest(g, 86, isLeftPage: false),
        equals(g.pageWidthMm - g.outerMarginMm - 86),
      );
    });
  });

  // ---------------------------------------------------------------------
  // L1 — 142×189 mm photo with captionDate + captionBody above the photo.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1 (142×189 + captions)', () {
    test('left page: photo at outer-left + caption stack above', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l1, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].kind, DotsSlotKind.photo);
      expect(slots[0].widthMm, 142);
      expect(slots[0].heightMm, 189);
      expect((slots[0].yMm - 57).abs(), lessThan(_tolMm));
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[2].kind, DotsSlotKind.captionBody);
      // Caption stack sits above the photo (lower y values).
      expect(slots[1].yMm, lessThan(slots[0].yMm));
      expect(slots[2].yMm, lessThan(slots[1].yMm));
    });

    test('right page: photo mirrored to outer-right', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l1, g, isLeftPage: false);
      _expectOuterAligned(slots[0], g, isLeftPage: false);
    });
  });

  // ---------------------------------------------------------------------
  // L1A — 113×152 mm photo with side caption column (82 mm).
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1a (113×152 + side caption)', () {
    test('left page: photo at outer-left, caption to the right (binding side)',
        () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l1a, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].kind, DotsSlotKind.photo);
      expect(slots[0].widthMm, 113);
      expect(slots[0].heightMm, 152);
      expect((slots[0].yMm - 33.5).abs(), lessThan(_tolMm));
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      // Caption column is 82 mm wide and sits to the binding side of
      // the photo (right of the photo on a left page).
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[1].widthMm, 82);
      expect(slots[1].xMm, greaterThan(slots[0].xMm + slots[0].widthMm - _tolMm));
    });

    test('right page: caption column flips to the left of the photo', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l1a, g, isLeftPage: false);
      // Caption column sits LEFT of the photo on a right page.
      expect(slots[1].xMm, lessThan(slots[0].xMm));
    });
  });

  // ---------------------------------------------------------------------
  // L1B — 175×238 mm full-outer-bleed.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1b (175×238 outer-bleed)', () {
    test('left page: bleeds top + bottom + LEFT (the outer edge)', () {
      final DotsPageGeometry g = _geometry();
      final slot =
          _solver.solve(DotsLayoutCode.l1b, g, isLeftPage: true).single;
      expect(slot.widthMm, 175);
      expect(slot.heightMm, 238);
      expect((slot.yMm - 8).abs(), lessThan(_tolMm));
      expect(slot.bleedTop, isTrue);
      expect(slot.bleedBottom, isTrue);
      expect(slot.bleedLeft, isTrue);
      expect(slot.bleedRight, isFalse);
      _expectOuterAligned(slot, g, isLeftPage: true);
    });

    test('right page: bleeds top + bottom + RIGHT (the outer edge)', () {
      final DotsPageGeometry g = _geometry();
      final slot =
          _solver.solve(DotsLayoutCode.l1b, g, isLeftPage: false).single;
      expect(slot.bleedLeft, isFalse);
      expect(slot.bleedRight, isTrue);
      _expectOuterAligned(slot, g, isLeftPage: false);
    });
  });

  // ---------------------------------------------------------------------
  // L1C — 175×196 mm photo at y=23 mm.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1c (175×196 at y=23)', () {
    test('photo at outer-left and y=23', () {
      final DotsPageGeometry g = _geometry();
      final slot =
          _solver.solve(DotsLayoutCode.l1c, g, isLeftPage: true).single;
      expect(slot.widthMm, 175);
      expect(slot.heightMm, 196);
      expect((slot.yMm - 23).abs(), lessThan(_tolMm));
      _expectOuterAligned(slot, g, isLeftPage: true);
    });
  });

  // ---------------------------------------------------------------------
  // L1D — 107×107 mm square (PDF-unconfirmed, outer-aligned applied).
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1d (107×107 square)', () {
    test('photo at outer-left, vertically centered', () {
      final DotsPageGeometry g = _geometry();
      final slot =
          _solver.solve(DotsLayoutCode.l1d, g, isLeftPage: true).single;
      expect(slot.widthMm, 107);
      expect(slot.heightMm, 107);
      _expectOuterAligned(slot, g, isLeftPage: true);
    });
  });

  // ---------------------------------------------------------------------
  // L1E — 107×152 mm + side caption (PDF-unconfirmed, by analogy with L1A).
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l1e (107×152 + side caption)', () {
    test('photo at outer-left with caption column to the right', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l1e, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].widthMm, 107);
      expect(slots[0].heightMm, 152);
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[1].widthMm, 82);
    });
  });

  // ---------------------------------------------------------------------
  // L2A — 2× 86×110 mm side-by-side with 16 mm gutter.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l2a (2× 86×110, 16 mm gutter)', () {
    test('two photos side-by-side, block outer-left aligned', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l2a, g, isLeftPage: true);
      expect(slots, hasLength(2));
      expect(slots[0].widthMm, 86);
      expect(slots[0].heightMm, 110);
      // Block (2*86 + 16 = 188 mm) outer-aligned at 8 mm from left.
      expect((slots[0].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
      final double gap = slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      expect((gap - 16).abs(), lessThan(_tolMm));
      expect(slots[0].yMm, slots[1].yMm);
    });
  });

  // ---------------------------------------------------------------------
  // L2B — 175×107 mm landscape × 2 stacked, y=29 mm top.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l2b (175×107 landscape stacked)', () {
    test('two landscape photos stacked vertically with 3 mm gap', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l2b, g, isLeftPage: true);
      expect(slots, hasLength(2));
      expect(slots[0].widthMm, 175);
      expect(slots[0].heightMm, 107);
      expect((slots[0].yMm - 29).abs(), lessThan(_tolMm));
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      _expectOuterAligned(slots[1], g, isLeftPage: true);
    });
  });

  // ---------------------------------------------------------------------
  // L2C — 65×74 mm × 2 stacked.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l2c (65×74 stacked)', () {
    test('two stacked photos, block outer-aligned', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l2c, g, isLeftPage: true);
      expect(slots, hasLength(2));
      expect(slots[0].widthMm, 65);
      expect(slots[0].heightMm, 74);
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
    });
  });

  // ---------------------------------------------------------------------
  // L3A — 3× 60.27×82 mm row at y=86.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l3a (3× 60.27×82 at y=86)', () {
    test('three photos in a row with 3 mm gaps, y=86', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l3a, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].widthMm, 60.27);
      expect(slots[0].heightMm, 82);
      expect((slots[0].yMm - 86).abs(), lessThan(_tolMm));
      // Block width = 60.27 * 3 + 3 * 2 = 186.81; outer-aligned at 8 mm.
      expect((slots[0].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
      for (int i = 1; i < 3; i++) {
        final double gap =
            slots[i].xMm - (slots[i - 1].xMm + slots[i - 1].widthMm);
        expect((gap - 3).abs(), lessThan(_tolMm));
      }
    });
  });

  // ---------------------------------------------------------------------
  // L4A — 86×86 mm SQUARE × 2×2 at y=71.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l4a (86×86 SQUARE 2×2 grid at y=71)', () {
    test('left page: four squares with 3 mm gaps starting y=71', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l4a, g, isLeftPage: true);
      expect(slots, hasLength(4));
      expect(slots[0].widthMm, 86);
      expect(slots[0].heightMm, 86);
      expect((slots[0].yMm - 71).abs(), lessThan(_tolMm));
      // Top-left photo outer-aligned at 8 mm from left.
      expect((slots[0].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
      // 3 mm gaps everywhere.
      expect((slots[1].xMm - (slots[0].xMm + 86) - 3).abs(), lessThan(_tolMm));
      expect((slots[2].yMm - (slots[0].yMm + 86) - 3).abs(), lessThan(_tolMm));
    });

    test('right page: grid mirrors so the OUTER-right column is at the trim',
        () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l4a, g, isLeftPage: false);
      // Block width = 86 * 2 + 3 = 175. Outer-right (right edge of block)
      // sits at pageWidth - outerMargin = 203 - 8 = 195.
      final double rightEdge = slots[1].xMm + slots[1].widthMm;
      expect(
        (rightEdge - (g.pageWidthMm - g.outerMarginMm)).abs(),
        lessThan(_tolMm),
      );
    });
  });

  // ---------------------------------------------------------------------
  // L4B — 86×110 mm × 2 stacked vertically, canonical y=23.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l4b (86×110 stacked, y=23 canonical)', () {
    test('two stacked photos starting y=23, outer-aligned', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l4b, g, isLeftPage: true);
      expect(slots, hasLength(2));
      expect(slots[0].widthMm, 86);
      expect(slots[0].heightMm, 110);
      expect((slots[0].yMm - 23).abs(), lessThan(_tolMm));
      _expectOuterAligned(slots[0], g, isLeftPage: true);
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
    });
  });

  // ---------------------------------------------------------------------
  // L6A — 2+1 arrangement, 86×110 mm.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l6a (2+1 arrangement, 86×110)', () {
    test('three photos in a 2+1 arrangement, outer-aligned', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l6a, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].widthMm, 86);
      expect(slots[0].heightMm, 110);
      // Top row outer-aligned at 8 mm.
      expect((slots[0].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
      expect(slots[0].yMm, slots[1].yMm);
      // Bottom photo also outer-aligned.
      expect((slots[2].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
    });
  });

  // ---------------------------------------------------------------------
  // L7 — 86×110 panes with 7.5 mm photo-to-caption gap.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l7 (86×110 panes + captions)', () {
    test('two panes, each with photo + captionDate + captionBody', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l7, g, isLeftPage: true);
      final photos = _photos(slots);
      expect(photos, hasLength(2));
      expect(photos[0].widthMm, 86);
      expect(photos[0].heightMm, 110);
      _expectOuterAligned(photos[0], g, isLeftPage: true);
      // Caption-related slots follow their photo in the list.
      expect(slots[0].kind, DotsSlotKind.photo);
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[2].kind, DotsSlotKind.captionBody);
      // 7.5 mm photo-to-date gap.
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 7.5).abs(), lessThan(_tolMm));
    });
  });

  // ---------------------------------------------------------------------
  // L8 — 2× 86×110 top + 1× 175×115.5 bottom.
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.l8 (2× top + 1× bottom)', () {
    test('left page: top row + bottom slab, outer-aligned', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l8, g, isLeftPage: true);
      expect(slots, hasLength(3));
      expect(slots[0].widthMm, 86);
      expect(slots[0].heightMm, 110);
      expect(slots[2].widthMm, 175);
      expect(slots[2].heightMm, 115.5);
      // Top row block outer-aligned at 8 mm from left.
      expect((slots[0].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
      // Bottom slab outer-aligned at 8 mm from left.
      expect((slots[2].xMm - g.outerMarginMm).abs(), lessThan(_tolMm));
    });

    test('right page: bottom slab right-edge sits at pageWidth - 8 mm', () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.l8, g, isLeftPage: false);
      final double bottomRight = slots[2].xMm + slots[2].widthMm;
      expect(
        (bottomRight - (g.pageWidthMm - g.outerMarginMm)).abs(),
        lessThan(_tolMm),
      );
    });
  });

  // ---------------------------------------------------------------------
  // L_hito — milestone text page (centered, NOT outer-aligned).
  // ---------------------------------------------------------------------
  group('DotsLayoutCode.lhito (milestone, no photo)', () {
    test('emits title + subtitle + body + qrCard, 149 mm title/subtitle width',
        () {
      final DotsPageGeometry g = _geometry();
      final slots = _solver.solve(DotsLayoutCode.lhito, g, isLeftPage: true);
      expect(slots, hasLength(4));
      expect(_photos(slots), isEmpty);
      expect(slots[0].kind, DotsSlotKind.captionTitle);
      expect(slots[1].kind, DotsSlotKind.captionDate); // subtitle slot.
      expect(slots[2].kind, DotsSlotKind.captionBody);
      expect(slots[3].kind, DotsSlotKind.qrCard);
      // Title and subtitle widths corrected to 149 mm.
      expect(slots[0].widthMm, 149);
      expect(slots[1].widthMm, 149);
      // Body remains 122 mm and QR container 130 mm.
      expect(slots[2].widthMm, 122);
      expect(slots[3].widthMm, 130);
      // Box heights are the verbatim page-83 callouts: title 5.92 mm,
      // subtitle (date) 2.701 mm — they are distinct anchor boxes.
      expect((slots[0].heightMm - 5.92).abs(), lessThan(_tolMm));
      expect((slots[1].heightMm - 2.701).abs(), lessThan(_tolMm));
    });
  });
}
