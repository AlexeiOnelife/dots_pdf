import 'dots_layout_code.dart';
import 'dots_page_geometry.dart';
import 'dots_slot_rect.dart';

/// Pure-math solver that emits the slot rectangles for a given layout.
///
/// The solver does no rendering and no I/O. Given a [DotsLayoutCode] and a
/// [DotsPageGeometry], it returns the list of [DotsSlotRect]s the page
/// renderer should draw into. Slots are ordered top-to-bottom and then
/// left-to-right; caption-related slots immediately follow their
/// associated photo in the list.
///
/// Dimensions are sourced verbatim from
/// `docs/templates/SPECS_interior.md`; `AUTO` margins in the spec are
/// resolved here by centering the slot block in the live area.
class DotsLayoutSolver {
  /// Creates a solver. Stateless; callers can reuse a single instance.
  const DotsLayoutSolver();

  /// Returns the slot rectangles for [code], centered within
  /// [geometry]'s live area.
  ///
  /// Throws [StateError] if the layout's specified dimensions do not fit
  /// the supplied geometry (the brief forbids silent shrinking).
  List<DotsSlotRect> solve(DotsLayoutCode code, DotsPageGeometry geometry) {
    switch (code) {
      case DotsLayoutCode.l1:
        return _singlePhotoCentered(geometry, widthMm: 142, heightMm: 189);
      case DotsLayoutCode.l1a:
        return _singlePhotoCentered(geometry, widthMm: 113, heightMm: 152);
      case DotsLayoutCode.l1b:
        return _l1bOversizedBleed(geometry);
      case DotsLayoutCode.l1c:
        return _singlePhotoCentered(geometry, widthMm: 175, heightMm: 196);
      case DotsLayoutCode.l1d:
        return _singlePhotoCentered(geometry, widthMm: 107, heightMm: 107);
      case DotsLayoutCode.l1e:
        return _singlePhotoCentered(geometry, widthMm: 107, heightMm: 152);
      case DotsLayoutCode.l2a:
        return _l2aSideBySide(geometry);
      case DotsLayoutCode.l2b:
        return _l2bStacked(geometry);
      case DotsLayoutCode.l2c:
        return _l2cStacked(geometry);
      case DotsLayoutCode.l3a:
        return _l3aRow(geometry);
      case DotsLayoutCode.l4a:
        return _l4aGrid(geometry);
      case DotsLayoutCode.l4b:
        return _l4bHalfSpread(geometry);
      case DotsLayoutCode.l6a:
        return _l6aHalfSpread(geometry);
      case DotsLayoutCode.l7:
        return _l7HalfSpread(geometry);
      case DotsLayoutCode.l8:
        return _l8HalfSpread(geometry);
      case DotsLayoutCode.lhito:
        return _lhito(geometry);
    }
  }

  // ---------------------------------------------------------------------
  // L1 family — single centered photo.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _singlePhotoCentered(
    DotsPageGeometry geometry, {
    required double widthMm,
    required double heightMm,
  }) {
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: heightMm,
      layoutLabel: 'single-photo ${widthMm}x$heightMm',
    );
    final double x = (geometry.pageWidthMm - widthMm) / 2;
    final double y = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - heightMm) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: x,
        yMm: y,
        widthMm: widthMm,
        heightMm: heightMm,
      ),
    ];
  }

  List<DotsSlotRect> _l1bOversizedBleed(DotsPageGeometry geometry) {
    // L1.B is the only oversized variant in the spec: 175 x 238 mm with
    // edge bleed on top, bottom and the outer edge. The 238 mm height
    // exceeds the 230 mm live area; centering uses the full page height
    // because the slot bleeds top + bottom.
    const double widthMm = 175;
    const double heightMm = 238;
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
    final double x = (geometry.pageWidthMm - widthMm) / 2;
    final double y = (geometry.pageHeightMm - heightMm) / 2;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.photo,
        xMm: x,
        yMm: y,
        widthMm: widthMm,
        heightMm: heightMm,
        bleedTop: true,
        bleedBottom: true,
        // "Outer edge" is the non-binding side; on the canonical
        // right-hand page that is the right edge. We flag both outer
        // edges so the renderer can mirror per left/right page.
        bleedLeft: true,
        bleedRight: true,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L2 family — two-photo arrangements.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l2aSideBySide(DotsPageGeometry geometry) {
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
    final double startX = (geometry.pageWidthMm - blockWidth) / 2;
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

  List<DotsSlotRect> _l2bStacked(DotsPageGeometry geometry) =>
      _verticalStack(
        geometry,
        widthMm: 115.5,
        heightMm: 86,
        count: 2,
        gapMm: 3,
        layoutLabel: 'L2.B stacked',
      );

  List<DotsSlotRect> _l2cStacked(DotsPageGeometry geometry) =>
      _verticalStack(
        geometry,
        widthMm: 65,
        heightMm: 74,
        count: 2,
        gapMm: 3,
        layoutLabel: 'L2.C stacked',
      );

  // ---------------------------------------------------------------------
  // L3 — row of three.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l3aRow(DotsPageGeometry geometry) {
    const double slotW = 60.27;
    const double slotH = 82;
    const double gap = 3;
    const double blockWidth = slotW * 3 + gap * 2;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: slotH,
      layoutLabel: 'L3.A row',
    );
    final double startX = (geometry.pageWidthMm - blockWidth) / 2;
    final double y = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - slotH) / 2;
    return <DotsSlotRect>[
      for (int i = 0; i < 3; i++)
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: startX + i * (slotW + gap),
          yMm: y,
          widthMm: slotW,
          heightMm: slotH,
        ),
    ];
  }

  // ---------------------------------------------------------------------
  // L4 family.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l4aGrid(DotsPageGeometry geometry) {
    const double slotW = 86;
    const double slotH = 110;
    const double gap = 3;
    const double blockWidth = slotW * 2 + gap;
    const double blockHeight = slotH * 2 + gap;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: blockHeight,
      layoutLabel: 'L4.A 2x2 grid',
    );
    final double startX = (geometry.pageWidthMm - blockWidth) / 2;
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    return <DotsSlotRect>[
      for (int row = 0; row < 2; row++)
        for (int col = 0; col < 2; col++)
          DotsSlotRect(
            kind: DotsSlotKind.photo,
            xMm: startX + col * (slotW + gap),
            yMm: startY + row * (slotH + gap),
            widthMm: slotW,
            heightMm: slotH,
          ),
    ];
  }

  List<DotsSlotRect> _l4bHalfSpread(DotsPageGeometry geometry) {
    // L4.B is described as "same dimensions but rendered across a spread
    // (4 photos = 2 per page)". Per-page interpretation: a single row of
    // two 86 x 110 mm photos with a 3 mm horizontal gap, centered.
    const double slotW = 86;
    const double slotH = 110;
    const double gap = 3;
    const double blockWidth = slotW * 2 + gap;
    _requireFits(
      geometry,
      requiredWidth: blockWidth,
      requiredHeight: slotH,
      layoutLabel: 'L4.B per-page',
    );
    final double startX = (geometry.pageWidthMm - blockWidth) / 2;
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
        xMm: startX + slotW + gap,
        yMm: y,
        widthMm: slotW,
        heightMm: slotH,
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // L6.A — per-page slice of 3x2 spread.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l6aHalfSpread(DotsPageGeometry geometry) {
    // Per-page interpretation: 3 photos in a 2 (top row) + 1 (bottom,
    // horizontally centered) arrangement, all at the spec's 86 x 110 mm
    // with 3 mm gaps. This is the only per-page composition of three
    // 86 x 110 photos with 3 mm gaps that fits a 203 x 230 live area.
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
    final double topStartX = (geometry.pageWidthMm - topRowWidth) / 2;
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    final double bottomX = (geometry.pageWidthMm - slotW) / 2;
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
  // L7 — per-page slice of the four-pane caption spread.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l7HalfSpread(DotsPageGeometry geometry) {
    // Per-page interpretation: 2 panes stacked vertically with 3 mm gap.
    // Each pane = one 142 x 105 mm photo + a caption-date slot + a
    // caption-body slot. The four panes referenced by the spec live
    // across the spread (2 per page). Caption reservations are
    // compressed to fit the live area: text-flow detail (wrapping,
    // widow-prevention) is the renderer's responsibility.
    const double photoW = 142;
    const double photoH = 105;
    const double interPaneGap = 3;
    const double photoToDateGap = 1;
    const double captionDateH = 4; // one line at 11 pt.
    const double captionBodyH = 3.5; // one line at 9 pt.
    const double paneHeight =
        photoH + photoToDateGap + captionDateH + captionBodyH;
    const double blockHeight = paneHeight * 2 + interPaneGap;
    _requireFits(
      geometry,
      requiredWidth: photoW,
      requiredHeight: blockHeight,
      layoutLabel: 'L7 per-page',
    );
    final double startX = (geometry.pageWidthMm - photoW) / 2;
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
  // L8 — quad-top + double-bottom per-page slice.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _l8HalfSpread(DotsPageGeometry geometry) {
    // Spec: top row of four 86 x 110 photos spans the spread; bottom
    // row of two 175 x 115.5 photos spans the spread. Per-page slice:
    // top row = 2 photos with 3 mm gap; bottom row = 1 photo of
    // 175 x 115.5 mm. Vertical gap top -> bottom row = 3 mm.
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
    final double topStartX = (geometry.pageWidthMm - topBlockW) / 2;
    final double bottomX = (geometry.pageWidthMm - bottomW) / 2;
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
  // L_hito — milestone text page.
  // ---------------------------------------------------------------------

  List<DotsSlotRect> _lhito(DotsPageGeometry geometry) {
    // Spec dimensions:
    //   title  P22 Mackinac medium 20 / 24 pt, max 80 chars, no break.
    //   date   P22 Mackinac book 9 / 10.8 pt.
    //   body   Inter Book 9 / 10.8 pt, max 800 chars, width 122 mm.
    //   qr     container width 130 mm, inner box 105.5 mm.
    // The slot's height is a conservative typographic reserve; the
    // renderer will lay the text inside.
    const double textBlockWidthMm = 122;
    const double qrContainerWidthMm = 130;
    const double qrInnerBoxMm = 105.5;
    // 24 pt leading -> 24 * 0.352778 = 8.467 mm per line.
    // Title reserves 2 lines (worst-case wrap of an 80-char title).
    const double titleHeightMm = 24 * 0.352777778 * 2;
    // 10.8 pt leading -> 3.81 mm per line.
    const double dateHeightMm = 10.8 * 0.352777778;
    // 800 chars at ~50 chars/line on 122 mm -> ~16 lines * 3.81 mm.
    const double bodyHeightMm = 10.8 * 0.352777778 * 16;
    const double titleToDateGap = 4;
    const double dateToBodyGap = 4;
    const double bodyToQrGap = 10;
    const double textBlockHeight = titleHeightMm +
        titleToDateGap +
        dateHeightMm +
        dateToBodyGap +
        bodyHeightMm;
    const double totalHeight = textBlockHeight + bodyToQrGap + qrInnerBoxMm;
    _requireFits(
      geometry,
      requiredWidth: qrContainerWidthMm,
      requiredHeight: totalHeight,
      layoutLabel: 'L_hito',
    );
    final double textX = (geometry.pageWidthMm - textBlockWidthMm) / 2;
    final double qrX = (geometry.pageWidthMm - qrContainerWidthMm) / 2;
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - totalHeight) / 2;
    final double dateY = startY + titleHeightMm + titleToDateGap;
    final double bodyY = dateY + dateHeightMm + dateToBodyGap;
    final double qrY = bodyY + bodyHeightMm + bodyToQrGap;
    return <DotsSlotRect>[
      DotsSlotRect(
        kind: DotsSlotKind.captionTitle,
        xMm: textX,
        yMm: startY,
        widthMm: textBlockWidthMm,
        heightMm: titleHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionDate,
        xMm: textX,
        yMm: dateY,
        widthMm: textBlockWidthMm,
        heightMm: dateHeightMm,
      ),
      DotsSlotRect(
        kind: DotsSlotKind.captionBody,
        xMm: textX,
        yMm: bodyY,
        widthMm: textBlockWidthMm,
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

  List<DotsSlotRect> _verticalStack(
    DotsPageGeometry geometry, {
    required double widthMm,
    required double heightMm,
    required int count,
    required double gapMm,
    required String layoutLabel,
  }) {
    final double blockHeight = heightMm * count + gapMm * (count - 1);
    _requireFits(
      geometry,
      requiredWidth: widthMm,
      requiredHeight: blockHeight,
      layoutLabel: layoutLabel,
    );
    final double x = (geometry.pageWidthMm - widthMm) / 2;
    final double startY = geometry.liveAreaTopMm +
        (geometry.liveAreaHeightMm - blockHeight) / 2;
    return <DotsSlotRect>[
      for (int i = 0; i < count; i++)
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: x,
          yMm: startY + i * (heightMm + gapMm),
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
