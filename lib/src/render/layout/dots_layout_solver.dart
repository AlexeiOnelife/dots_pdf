import 'package:meta/meta.dart';

import 'dots_layout_code.dart';
import 'dots_page_geometry.dart';
import 'dots_slot_rect.dart';

/// Pure-math solver that emits the slot rectangles for a given layout.
///
/// The solver does no rendering and no I/O. Given a [DotsLayoutCode], a
/// [DotsPageGeometry], and an `isLeftPage` flag, it returns the list of
/// [DotsSlotRect]s the page renderer should draw into. Slots are ordered
/// top-to-bottom and then left-to-right; caption-related slots
/// immediately follow their associated photo in the list.
///
/// Dimensions are sourced verbatim from
/// `docs/templates/final_templates/pdf01_general_base.pdf` (the printed
/// design ground truth — see Task 3 of the `final-render-refinement`
/// series). All photo layouts align to the outer (non-binding) trim
/// edge by `geometry.outerMarginMm` (8 mm by default); the
/// [_outerAlignedX] helper resolves the per-page parity.
class DotsLayoutSolver {
  /// Creates a solver. Stateless; callers can reuse a single instance.
  const DotsLayoutSolver();

  /// Returns the slot rectangles for [code] aligned to the outer edge of
  /// the page that [isLeftPage] selects.
  ///
  /// Throws [StateError] if the layout's specified dimensions do not fit
  /// the supplied geometry (the brief forbids silent shrinking).
  List<DotsSlotRect> solve(
    DotsLayoutCode code,
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    switch (code) {
      case DotsLayoutCode.l1:
        return _l1(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l1a:
        return _l1a(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l1b:
        return _l1bOversizedBleed(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l1c:
        return _l1c(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l1d:
        return _l1d(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l1e:
        return _l1e(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l2a:
        return _l2aSideBySide(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l2b:
        return _l2bStacked(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l2c:
        return _l2cStacked(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l3a:
        return _l3aRow(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l4a:
        return _l4aGrid(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l4b:
        return _l4bStacked(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l6a:
        return _l6aHalfSpread(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l7:
        return _l7HalfSpread(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.l8:
        return _l8HalfSpread(geometry, isLeftPage: isLeftPage);
      case DotsLayoutCode.lhito:
        return _lhito(geometry);
    }
  }

  // ---------------------------------------------------------------------
  // Outer-edge alignment helper.
  // ---------------------------------------------------------------------

  /// Returns the x-coordinate in mm at which a block of [blockWidthMm]
  /// must start so that the block is anchored to the outer (non-binding)
  /// edge of the page selected by [isLeftPage].
  ///
  /// Left page → outer edge is the LEFT edge → `x = outerMarginMm`.
  /// Right page → outer edge is the RIGHT edge → `x = pageWidth - outerMargin - blockWidth`.
  static double _outerAlignedX(
    DotsPageGeometry geometry,
    double blockWidthMm, {
    required bool isLeftPage,
  }) {
    if (isLeftPage) return geometry.outerMarginMm;
    return geometry.pageWidthMm - geometry.outerMarginMm - blockWidthMm;
  }

  /// @visibleForTesting Test-only accessor for the outer-edge x formula.
  @visibleForTesting
  static double outerAlignedXForTest(
    DotsPageGeometry geometry,
    double blockWidthMm, {
    required bool isLeftPage,
  }) =>
      _outerAlignedX(geometry, blockWidthMm, isLeftPage: isLeftPage);

  // ---------------------------------------------------------------------
  // L1 family — single outer-aligned photo with optional captions.
  // ---------------------------------------------------------------------

  // L1: 142×189 mm photo at y=57 mm, outer-aligned x. Caption date
  // sits above the photo (P22 Mackinac medium 11 pt) with a captionBody
  // block above the date that grows upward (Inter Book 9 pt / 10.8 pt,
  // 86 mm wide, max 400 chars). The body slot reserves a single 10.8 pt
  // line; the renderer wraps and overflows upward inside that slot's
  // SizedBox if more text fits — the slot rect itself is the anchor.
  List<DotsSlotRect> _l1(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 142;
    const double heightMm = 189;
    const double yMm = 57;
    // L1's photo is anchored at y=57 mm and extends ~4 mm into the
    // footer band — by design per the PDF spec sheet. The fit check
    // validates the width and photo-only height against the live area.
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: 'L1 single-photo',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    // Caption block: date is 8.098 mm tall (P22 Mackinac medium 11 pt /
    // 13.2 pt — one line), body is 86 mm wide and grows upward.
    // The captionDate sits 4 mm above the photo; the captionBody sits
    // immediately above the date.
    const double captionDateHeightMm = 8.098;
    const double captionBodyHeightMm = 10.8 * 0.352777778; // single line.
    const double captionGapMm = 4;
    const double captionWidthMm = 86;
    final double captionXMm = _outerAlignedX(
      geometry,
      captionWidthMm,
      isLeftPage: isLeftPage,
    );
    const double dateYMm = yMm - captionGapMm - captionDateHeightMm;
    const double bodyYMm = dateYMm - captionBodyHeightMm;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionDate,
        xMm: captionXMm,
        yMm: dateYMm,
        widthMm: captionWidthMm,
        heightMm: captionDateHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionBody,
        xMm: captionXMm,
        yMm: bodyYMm,
        widthMm: captionWidthMm,
        heightMm: captionBodyHeightMm,
      ),
    ];
  }

  // L1A: 113×152 mm photo at y=33.5 mm, outer-aligned x. Caption sits
  // in a side column (82 mm wide) on the binding-side of the photo.
  List<DotsSlotRect> _l1a(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 113;
    const double heightMm = 152;
    const double yMm = 33.5;
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: 'L1A single-photo with side caption',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    // Side caption column lives on the binding side of the photo:
    // for a left page, photo at x=8mm so caption sits to the right of
    // the photo; for a right page, photo at x=(203-8-113)=82mm so the
    // caption sits to the LEFT of the photo.
    const double captionWidthMm = 82;
    final double captionXMm = isLeftPage
        ? xMm + widthMm + 0 // caption immediately right of photo.
        : xMm - captionWidthMm;
    const double captionDateHeightMm = 8.098;
    const double captionBodyHeightMm = 10.8 * 0.352777778;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionDate,
        xMm: captionXMm,
        yMm: yMm,
        widthMm: captionWidthMm,
        heightMm: captionDateHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionBody,
        xMm: captionXMm,
        yMm: yMm + captionDateHeightMm,
        widthMm: captionWidthMm,
        heightMm: captionBodyHeightMm,
      ),
    ];
  }

  // L1B: 175×238 mm oversized photo with bleed on top, bottom, and the
  // OUTER edge only. The binding edge does NOT bleed. y=8 mm from trim
  // top; x outer-aligned.
  List<DotsSlotRect> _l1bOversizedBleed(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 175;
    const double heightMm = 238;
    const double yMm = 8;
    if (widthMm > geometry.pageWidthMm) {
      throw StateError(
        'L1.B width $widthMm mm does not fit page width '
        '${geometry.pageWidthMm} mm.',
      );
    }
    if (heightMm > geometry.pageHeightMm) {
      throw StateError(
        'L1.B height $heightMm mm does not fit page height '
        '${geometry.pageHeightMm} mm.',
      );
    }
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
        bleedTop: true,
        bleedBottom: true,
        // Outer edge only: left bleeds for a left page, right for a right page.
        bleedLeft: isLeftPage,
        bleedRight: !isLeftPage,
      ),
    ];
  }

  // L1C: 175×196 mm photo, canonical y=23 mm, outer-aligned x.
  List<DotsSlotRect> _l1c(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) =>
      _outerAlignedSinglePhoto(
        geometry,
        widthMm: 175,
        heightMm: 196,
        yMm: 23,
        isLeftPage: isLeftPage,
        layoutLabel: 'L1C',
      );

  // L1D: 107×107 mm square photo, centered vertically in live area.
  // PDF position unconfirmed; outer-aligned x applied per spec.
  List<DotsSlotRect> _l1d(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 107;
    const double heightMm = 107;
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: 'L1D 107×107 square',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    final double yMm =
        geometry.liveAreaTopMm + (geometry.liveAreaHeightMm - heightMm) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
    ];
  }

  // L1E: 107×152 mm photo with a side caption column (by analogy with
  // L1A — PDF-unconfirmed but the structural pattern matches L1A).
  List<DotsSlotRect> _l1e(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 107;
    const double heightMm = 152;
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: 'L1E side-caption photo',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    final double yMm =
        geometry.liveAreaTopMm + (geometry.liveAreaHeightMm - heightMm) / 2;
    const double captionWidthMm = 82;
    final double captionXMm =
        isLeftPage ? xMm + widthMm : xMm - captionWidthMm;
    const double captionDateHeightMm = 8.098;
    const double captionBodyHeightMm = 10.8 * 0.352777778;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionDate,
        xMm: captionXMm,
        yMm: yMm,
        widthMm: captionWidthMm,
        heightMm: captionDateHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionBody,
        xMm: captionXMm,
        yMm: yMm + captionDateHeightMm,
        widthMm: captionWidthMm,
        heightMm: captionBodyHeightMm,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L2 family.
  // ---------------------------------------------------------------------

  // L2A: 2× 86×110 mm photos side-by-side with 16 mm gutter.
  // Block width = 86+16+86 = 188 mm → 7.5 mm side margin if centered.
  // Outer-aligned: block starts at 8 mm from outer edge.
  List<DotsSlotRect> _l2aSideBySide(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double slotW = 86;
    const double slotH = 110;
    const double gutter = 16;
    const double blockWidth = slotW * 2 + gutter;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: slotH,
      layoutLabel: 'L2.A side-by-side',
    );
    final double startX =
        _outerAlignedX(geometry, blockWidth, isLeftPage: isLeftPage);
    final double y = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - slotH) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: startX,
        yMm: y,
        widthMm: slotW,
        heightMm: slotH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: startX + slotW + gutter,
        yMm: y,
        widthMm: slotW,
        heightMm: slotH,
      ),
    ];
  }

  // L2B: 175×107 mm landscape × 2 stacked vertically with 3 mm gap.
  // y=29 mm top, 3 mm gap, second photo at y=139 mm, 8 mm bottom margin
  // (29+107+3+107+8 = 254). Outer-aligned x.
  List<DotsSlotRect> _l2bStacked(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 175;
    const double heightMm = 107;
    const double topYMm = 29;
    const double gapMm = 3;
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm * 2 + gapMm,
      layoutLabel: 'L2.B landscape stacked',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: topYMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: topYMm + heightMm + gapMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
    ];
  }

  // L2C: 65×74 mm × 2 stacked with 3 mm gap. Outer-aligned x.
  List<DotsSlotRect> _l2cStacked(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double widthMm = 65;
    const double heightMm = 74;
    const double gapMm = 3;
    const double blockHeight = heightMm * 2 + gapMm;
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: blockHeight,
      layoutLabel: 'L2.C stacked',
    );
    final double xMm = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: startY,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: startY + heightMm + gapMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L3 — row of three 60.27 × 82 mm at y=86 mm.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l3aRow(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double slotW = 60.27;
    const double slotH = 82;
    const double gap = 3;
    const double blockWidth = slotW * 3 + gap * 2;
    const double yMm = 86;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: slotH,
      layoutLabel: 'L3.A row',
    );
    // L3.A block width 186.81mm — centering and outer-edge alignment
    // both yield ≈8 mm side margin (coincidence). We use the outer-edge
    // helper for explicit intent.
    final double startX =
        _outerAlignedX(geometry, blockWidth, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      for (int i = 0; i < 3; i++)
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: startX + i * (slotW + gap),
          yMm: yMm,
          widthMm: slotW,
          heightMm: slotH,
        ),
    ];
  }

  // ---------------------------------------------------------------------
  // L4 family.
  // ---------------------------------------------------------------------

  // L4A: 86×86 mm SQUARE × 2×2 grid with 3 mm gaps. y=71 mm.
  // Block = 86+3+86 = 175 mm wide, same tall. 71+175+8 = 254 mm.
  List<DotsSlotRect> _l4aGrid(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double slotW = 86;
    const double slotH = 86;
    const double gap = 3;
    const double blockWidth = slotW * 2 + gap;
    const double blockHeight = slotH * 2 + gap;
    const double yMm = 71;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: blockHeight,
      layoutLabel: 'L4.A 2x2 square grid',
    );
    final double startX =
        _outerAlignedX(geometry, blockWidth, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      for (int row = 0; row < 2; row++)
        for (int col = 0; col < 2; col++)
          DotsSlotRect(
            kind: DotsSlotKind.photo,
            xMm: startX + col * (slotW + gap),
            yMm: yMm + row * (slotH + gap),
            widthMm: slotW,
            heightMm: slotH,
          ),
    ];
  }

  // L4B: 86×110 mm × 2 stacked vertically, canonical y=23 mm.
  // 23+110+3+110+8 = 254 mm. Outer-aligned x. The lower variant
  // (y=136 mm) is caption-driven and deferred to a renderer-level rule.
  List<DotsSlotRect> _l4bStacked(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double slotW = 86;
    const double slotH = 110;
    const double gap = 3;
    const double topYMm = 23;
    _requireFits(
      geometry,
      requiredWidth: slotW,
      requiredHeight: slotH * 2 + gap,
      layoutLabel: 'L4.B stacked',
    );
    final double xMm = _outerAlignedX(geometry, slotW, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: topYMm,
        widthMm: slotW,
        heightMm: slotH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: topYMm + slotH + gap,
        widthMm: slotW,
        heightMm: slotH,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L6.A — per-page slice of 3×2 spread (2 photos top + 1 photo bottom).
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l6aHalfSpread(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double slotW = 86;
    const double slotH = 110;
    const double gap = 3;
    const double topRowWidth = slotW * 2 + gap;
    const double blockHeight = slotH * 2 + gap;
    _requireFits(
      geometry,
      requiredWidth: topRowWidth,
      requiredHeight: blockHeight,
      layoutLabel: 'L6.A per-page',
    );
    final double topStartX =
        _outerAlignedX(geometry, topRowWidth, isLeftPage: isLeftPage);
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    final double bottomX =
        _outerAlignedX(geometry, slotW, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: topStartX,
        yMm: startY,
        widthMm: slotW,
        heightMm: slotH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: topStartX + slotW + gap,
        yMm: startY,
        widthMm: slotW,
        heightMm: slotH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: bottomX,
        yMm: startY + slotH + gap,
        widthMm: slotW,
        heightMm: slotH,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L7 — per-page slice of the four-pane caption spread (2 panes/page).
  // 86×110 mm photos, 7.5 mm photo-to-caption gap.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l7HalfSpread(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double photoW = 86;
    const double photoH = 110;
    const double interPaneGap = 3;
    const double photoToDateGap = 7.5;
    const double captionDateH = 4; // one line at 11 pt.
    // Body grows downward — slot reserves a single 10.8 pt line; the
    // renderer wraps and overflows below the slot when more text fits.
    const double captionBodyH = 10.8 * 0.352777778;
    const double paneHeight =
        photoH + photoToDateGap + captionDateH + captionBodyH;
    const double blockHeight = paneHeight * 2 + interPaneGap;
    // The L7 caption stacks can overflow below the live area; the
    // renderer treats per-pane SizedBox as a layout anchor and lets
    // text continue past the slot edge. Only photo width + per-photo
    // height are validated against the live area.
    _requireFits(
      geometry,
      requiredWidth: photoW,
      requiredHeight: photoH,
      layoutLabel: 'L7 per-page',
    );
    // Silence linter: `blockHeight` is the documented total stack height
    // for downstream renderer reference but not used as a fit constraint.
    assert(blockHeight > 0);
    final double startX =
        _outerAlignedX(geometry, photoW, isLeftPage: isLeftPage);
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    final List<DotsSlotRect> slots = <DotsSlotRect>[];
    for (int pane = 0; pane < 2; pane++) {
      final double paneTop = startY + pane * (paneHeight + interPaneGap);
      slots
        ..add(
          DotsSlotRect(
            kind: DotsSlotKind.photo,
            xMm: startX,
            yMm: paneTop,
            widthMm: photoW,
            heightMm: photoH,
          ),
        )
        ..add(
          DotsSlotRect(
            kind: DotsSlotKind.captionDate,
            xMm: startX,
            yMm: paneTop + photoH + photoToDateGap,
            widthMm: photoW,
            heightMm: captionDateH,
          ),
        )
        ..add(
          DotsSlotRect(
            kind: DotsSlotKind.captionBody,
            xMm: startX,
            yMm: paneTop + photoH + photoToDateGap + captionDateH,
            widthMm: photoW,
            heightMm: captionBodyH,
          ),
        );
    }
    return slots;
  }

  // ---------------------------------------------------------------------
  // L8 — top row of two 86×110 photos, bottom row of one 175×115.5.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l8HalfSpread(
    DotsPageGeometry geometry, {
    required bool isLeftPage,
  }) {
    const double topW = 86;
    const double topH = 110;
    const double topGap = 3;
    const double bottomW = 175;
    const double bottomH = 115.5;
    const double rowGap = 3;
    const double topBlockW = topW * 2 + topGap;
    const double blockW = topBlockW > bottomW ? topBlockW : bottomW;
    const double blockH = topH + rowGap + bottomH;
    _requireFits(
      geometry,
      requiredWidth: blockW,
      requiredHeight: blockH,
      layoutLabel: 'L8 per-page',
    );
    final double topStartX =
        _outerAlignedX(geometry, topBlockW, isLeftPage: isLeftPage);
    final double bottomX =
        _outerAlignedX(geometry, bottomW, isLeftPage: isLeftPage);
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockH) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: topStartX,
        yMm: startY,
        widthMm: topW,
        heightMm: topH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: topStartX + topW + topGap,
        yMm: startY,
        widthMm: topW,
        heightMm: topH,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: bottomX,
        yMm: startY + topH + rowGap,
        widthMm: bottomW,
        heightMm: bottomH,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L_hito — milestone text page (centered; not outer-aligned).
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _lhito(DotsPageGeometry geometry) {
    // Spec dimensions (PDF p.83):
    //   TITULO   P22 Mackinac medium 20 / 24 pt, max 80 chars, width 149 mm.
    //   SUBTÍTULO P22 Mackinac regular 20 / 24 pt, width 149 mm.
    //              (rendered via _captionFontSizeFor((captionDate, lhito)) → 20.0)
    //   TEXTO    Inter Book 9 / 10.8 pt, max 800 chars, width 122 mm.
    //   QR       container width 130 mm, inner box 105.5 mm.
    const double titleSubtitleWidthMm = 149;
    const double bodyWidthMm = 122;
    const double qrContainerWidthMm = 130;
    const double qrInnerBoxMm = 105.5;
    // 24 pt leading -> 8.467 mm per line. Title and subtitle each
    // reserve 2 lines.
    const double titleHeightMm = 24 * 0.352777778 * 2;
    const double subtitleHeightMm = 24 * 0.352777778 * 2;
    // 800 chars at ~50 chars/line on 122 mm -> ~16 lines * 3.81 mm.
    const double bodyHeightMm = 10.8 * 0.352777778 * 16;
    const double titleToSubtitleGap = 4;
    const double subtitleToBodyGap = 4;
    const double bodyToQrGap = 10;
    const double textBlockHeight = titleHeightMm +
        titleToSubtitleGap +
        subtitleHeightMm +
        subtitleToBodyGap +
        bodyHeightMm;
    const double totalHeight = textBlockHeight + bodyToQrGap + qrInnerBoxMm;
    _requireFits(
      geometry,
      requiredWidth: qrContainerWidthMm,
      requiredHeight: totalHeight,
      layoutLabel: 'L_hito',
    );
    final double titleX =
        (geometry.pageWidthMm - titleSubtitleWidthMm) / 2;
    final double bodyX = (geometry.pageWidthMm - bodyWidthMm) / 2;
    final double qrX = (geometry.pageWidthMm - qrContainerWidthMm) / 2;
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - totalHeight) / 2;
    final double subtitleY = startY + titleHeightMm + titleToSubtitleGap;
    final double bodyY = subtitleY + subtitleHeightMm + subtitleToBodyGap;
    final double qrY = bodyY + bodyHeightMm + bodyToQrGap;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.captionTitle,
        xMm: titleX,
        yMm: startY,
        widthMm: titleSubtitleWidthMm,
        heightMm: titleHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionDate,
        xMm: titleX,
        yMm: subtitleY,
        widthMm: titleSubtitleWidthMm,
        heightMm: subtitleHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionBody,
        xMm: bodyX,
        yMm: bodyY,
        widthMm: bodyWidthMm,
        heightMm: bodyHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.qrCard,
        xMm: qrX,
        yMm: qrY,
        widthMm: qrContainerWidthMm,
        heightMm: qrInnerBoxMm,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Shared helpers.
  // ---------------------------------------------------------------------

  /// Emits a single outer-aligned photo slot with [yMm] from the page
  /// top, used by the simpler L1.x layouts that have no captions.
  List<DotsSlotRect> _outerAlignedSinglePhoto(
    DotsPageGeometry geometry, {
    required double widthMm,
    required double heightMm,
    required double yMm,
    required bool isLeftPage,
    required String layoutLabel,
  }) {
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: layoutLabel,
    );
    final double xMm =
        _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage);
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: xMm,
        yMm: yMm,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
    ];
  }

  void _requireFits(
    DotsPageGeometry geometry, {
    required double requiredWidth,
    required double requiredHeight,
    required String layoutLabel,
  }) {
    if (requiredWidth > geometry.liveAreaWidthMm) {
      throw StateError(
        '$layoutLabel width $requiredWidth mm exceeds live area width '
        '${geometry.liveAreaWidthMm} mm.',
      );
    }
    if (requiredHeight > geometry.liveAreaHeightMm) {
      throw StateError(
        '$layoutLabel height $requiredHeight mm exceeds live area height '
        '${geometry.liveAreaHeightMm} mm.',
      );
    }
  }
}
