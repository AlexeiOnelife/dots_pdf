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

/// Verifies the full block of [slots] is vertically centered within the
/// live area: live-area space above the first slot equals live-area
/// space below the last slot, within [_tolMm].
void _expectLiveAreaCentered(
  List<DotsSlotRect> slots,
  DotsPageGeometry geometry,
) {
  expect(slots, isNotEmpty);
  // Compute the bounding box of all slots.
  double minY = double.infinity;
  double maxY = double.negativeInfinity;
  for (final DotsSlotRect s in slots) {
    if (s.yMm < minY) minY = s.yMm;
    final double bottom = s.yMm + s.heightMm;
    if (bottom > maxY) maxY = bottom;
  }
  final double topMargin = minY - geometry.liveAreaTopMm;
  final double bottomMargin = geometry.liveAreaBottomMm - maxY;
  expect(
    (topMargin - bottomMargin).abs(),
    lessThan(_tolMm),
    reason: 'top margin $topMargin mm should equal bottom margin '
        '$bottomMargin mm',
  );
}

/// Verifies horizontal centering of a single slot on the page.
void _expectPageHorizontallyCentered(
  DotsSlotRect slot,
  DotsPageGeometry geometry,
) {
  final double leftMargin = slot.xMm;
  final double rightMargin =
      geometry.pageWidthMm - (slot.xMm + slot.widthMm);
  expect(
    (leftMargin - rightMargin).abs(),
    lessThan(_tolMm),
    reason: 'left $leftMargin mm should equal right $rightMargin mm',
  );
}

void main() {
  group('DotsLayoutCode.l1 (1 photo, 142 x 189)', () {
    test('emits one centered photo slot at spec dimensions', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1, g);
      expect(slots, hasLength(1));
      expect(slots.single.kind, DotsSlotKind.photo);
      expect(slots.single.widthMm, 142);
      expect(slots.single.heightMm, 189);
      expect(slots.single.bleedTop, isFalse);
      expect(slots.single.bleedBottom, isFalse);
      expect(slots.single.bleedLeft, isFalse);
      expect(slots.single.bleedRight, isFalse);
      _expectPageHorizontallyCentered(slots.single, g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l1a (1 photo, 113 x 152)', () {
    test('emits one centered photo slot at spec dimensions', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1a, g);
      expect(slots, hasLength(1));
      expect(slots.single.widthMm, 113);
      expect(slots.single.heightMm, 152);
      _expectPageHorizontallyCentered(slots.single, g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l1b (1 photo, 175 x 238, edge-bleed)', () {
    test('emits one oversized slot with bleed flags', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1b, g);
      expect(slots, hasLength(1));
      final DotsSlotRect slot = slots.single;
      expect(slot.kind, DotsSlotKind.photo);
      expect(slot.widthMm, 175);
      expect(slot.heightMm, 238);
      expect(slot.bleedTop, isTrue);
      expect(slot.bleedBottom, isTrue);
      expect(slot.bleedLeft, isTrue);
      expect(slot.bleedRight, isTrue);
      _expectPageHorizontallyCentered(slot, g);
      // Vertically centered on the FULL page (not the live area) because
      // the slot bleeds top + bottom.
      final double topMargin = slot.yMm;
      final double bottomMargin =
          g.pageHeightMm - (slot.yMm + slot.heightMm);
      expect((topMargin - bottomMargin).abs(), lessThan(_tolMm));
    });
  });

  group('DotsLayoutCode.l1c (1 photo, 175 x 196)', () {
    test('emits one centered photo slot at spec dimensions', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1c, g);
      expect(slots, hasLength(1));
      expect(slots.single.widthMm, 175);
      expect(slots.single.heightMm, 196);
      _expectPageHorizontallyCentered(slots.single, g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l1d (1 photo, 107 x 107)', () {
    test('emits one centered square slot at spec dimensions', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1d, g);
      expect(slots, hasLength(1));
      expect(slots.single.widthMm, 107);
      expect(slots.single.heightMm, 107);
      _expectPageHorizontallyCentered(slots.single, g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l1e (1 photo, 107 x 152)', () {
    test('emits one centered photo slot at spec dimensions', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l1e, g);
      expect(slots, hasLength(1));
      expect(slots.single.widthMm, 107);
      expect(slots.single.heightMm, 152);
      _expectPageHorizontallyCentered(slots.single, g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l2a (2 photos, 86 x 110, 16 mm gutter)', () {
    test('emits two side-by-side photo slots with a 16 mm gap', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l2a, g);
      expect(slots, hasLength(2));
      expect(slots.first.widthMm, 86);
      expect(slots.first.heightMm, 110);
      final double gap = slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      expect((gap - 16).abs(), lessThan(_tolMm));
      // Both slots share the same y.
      expect(slots[0].yMm, slots[1].yMm);
      // Block is horizontally centered.
      final double blockWidth =
          (slots[1].xMm + slots[1].widthMm) - slots[0].xMm;
      final double leftMargin = slots[0].xMm;
      final double rightMargin = g.pageWidthMm -
          (slots[0].xMm + blockWidth);
      expect((leftMargin - rightMargin).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l2b (2 photos, 115.5 x 86, 3 mm v-gap)', () {
    test('emits two stacked photos with 3 mm gap', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l2b, g);
      expect(slots, hasLength(2));
      expect(slots.first.widthMm, 115.5);
      expect(slots.first.heightMm, 86);
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
      _expectPageHorizontallyCentered(slots[0], g);
      _expectPageHorizontallyCentered(slots[1], g);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l2c (2 photos, 65 x 74, 3 mm gap)', () {
    test('emits two stacked photos with 3 mm gap', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l2c, g);
      expect(slots, hasLength(2));
      expect(slots.first.widthMm, 65);
      expect(slots.first.heightMm, 74);
      final double gap = slots[1].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l3a (3 photos, 60.27 x 82, 3 mm gaps)', () {
    test('emits three photos in a row with 3 mm horizontal gaps', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l3a, g);
      expect(slots, hasLength(3));
      expect(slots.first.widthMm, 60.27);
      expect(slots.first.heightMm, 82);
      for (int i = 1; i < 3; i++) {
        final double gap =
            slots[i].xMm - (slots[i - 1].xMm + slots[i - 1].widthMm);
        expect(
          (gap - 3).abs(),
          lessThan(_tolMm),
          reason: 'gap between slot ${i - 1} and $i should be 3 mm',
        );
        expect(slots[i].yMm, slots[i - 1].yMm);
      }
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l4a (4 photos, 86 x 110, 2 x 2, 3 mm gaps)', () {
    test('emits four photos in a 2x2 grid with 3 mm gaps', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l4a, g);
      expect(slots, hasLength(4));
      expect(slots.first.widthMm, 86);
      expect(slots.first.heightMm, 110);
      // Slots are top-left, top-right, bottom-left, bottom-right.
      final double hGapTop =
          slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      final double hGapBottom =
          slots[3].xMm - (slots[2].xMm + slots[2].widthMm);
      final double vGapLeft =
          slots[2].yMm - (slots[0].yMm + slots[0].heightMm);
      final double vGapRight =
          slots[3].yMm - (slots[1].yMm + slots[1].heightMm);
      expect((hGapTop - 3).abs(), lessThan(_tolMm));
      expect((hGapBottom - 3).abs(), lessThan(_tolMm));
      expect((vGapLeft - 3).abs(), lessThan(_tolMm));
      expect((vGapRight - 3).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l4b (per-page slice: 2 photos, 86 x 110)', () {
    test('emits two side-by-side photos with 3 mm gap', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l4b, g);
      expect(slots, hasLength(2));
      expect(slots.first.widthMm, 86);
      expect(slots.first.heightMm, 110);
      final double gap = slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      expect((gap - 3).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l6a (per-page slice: 3 photos, 86 x 110)', () {
    test('emits three photos in a 2+1 arrangement with 3 mm gaps', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l6a, g);
      expect(slots, hasLength(3));
      expect(slots.first.widthMm, 86);
      expect(slots.first.heightMm, 110);
      // Top row: slot[0] and slot[1] share y, 3 mm horizontal gap.
      expect(slots[0].yMm, slots[1].yMm);
      final double topGap =
          slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      expect((topGap - 3).abs(), lessThan(_tolMm));
      // Bottom photo sits 3 mm below the top row.
      final double rowGap =
          slots[2].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((rowGap - 3).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l7 (per-page slice: 2 panes, 142 x 105)', () {
    test('emits two photo slots plus caption slots per pane', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l7, g);
      final List<DotsSlotRect> photos = _photos(slots);
      expect(photos, hasLength(2));
      expect(photos.first.widthMm, 142);
      expect(photos.first.heightMm, 105);
      // Caption-related slots follow their photo in the list.
      expect(slots.first.kind, DotsSlotKind.photo);
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[2].kind, DotsSlotKind.captionBody);
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.l8 (per-page slice: 2 top + 1 bottom)', () {
    test('emits two top photos with 3 mm gap + one bottom photo', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots = _solver.solve(DotsLayoutCode.l8, g);
      expect(slots, hasLength(3));
      expect(slots.first.widthMm, 86);
      expect(slots.first.heightMm, 110);
      expect(slots[2].widthMm, 175);
      expect(slots[2].heightMm, 115.5);
      // Top row 3 mm horizontal gap.
      final double topGap =
          slots[1].xMm - (slots[0].xMm + slots[0].widthMm);
      expect((topGap - 3).abs(), lessThan(_tolMm));
      // 3 mm vertical row gap between top row and bottom.
      final double rowGap =
          slots[2].yMm - (slots[0].yMm + slots[0].heightMm);
      expect((rowGap - 3).abs(), lessThan(_tolMm));
      _expectLiveAreaCentered(slots, g);
    });
  });

  group('DotsLayoutCode.lhito (milestone, no photo)', () {
    test('emits title + date + body + qrCard, no photo slot', () {
      final DotsPageGeometry g = _geometry();
      final List<DotsSlotRect> slots =
          _solver.solve(DotsLayoutCode.lhito, g);
      expect(slots, hasLength(4));
      expect(_photos(slots), isEmpty);
      expect(slots[0].kind, DotsSlotKind.captionTitle);
      expect(slots[1].kind, DotsSlotKind.captionDate);
      expect(slots[2].kind, DotsSlotKind.captionBody);
      expect(slots[3].kind, DotsSlotKind.qrCard);
      // Body width per spec.
      expect(slots[2].widthMm, 122);
      // QR card width per spec.
      expect(slots[3].widthMm, 130);
      // Whole stack vertically centered in live area: distance from
      // live-area top to first slot equals distance from last slot to
      // live-area bottom.
      final double topMargin = slots.first.yMm - g.liveAreaTopMm;
      final double bottomMargin = g.liveAreaBottomMm -
          (slots.last.yMm + slots.last.heightMm);
      expect((topMargin - bottomMargin).abs(), lessThan(_tolMm));
      // All text slots horizontally centered.
      _expectPageHorizontallyCentered(slots[0], g);
      _expectPageHorizontallyCentered(slots[1], g);
      _expectPageHorizontallyCentered(slots[2], g);
      _expectPageHorizontallyCentered(slots[3], g);
    });
  });
}
