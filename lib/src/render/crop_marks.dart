import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 3 mm tick length, expressed in PDF points.
const double _tickLengthPt = 8.503936;

/// 0.25 mm stroke thickness, expressed in PDF points.
const double _tickStrokePt = 0.708661;

/// Returns the widgets that draw four L-shaped trim-corner ticks on a
/// page sized [pageWidthPt] × [pageHeightPt], with [trimMarginPt] of
/// bleed between the trim rectangle and the page edge.
///
/// Each corner gets two perpendicular rectangles forming an "L" that
/// sits **outside** the trim rectangle (inside the bleed). This matches
/// the supplier-facing convention for europa: marks are drawn in the
/// printable area but outside the final trim, so they're cut away
/// during finishing.
///
/// The returned widgets are intended to be appended on top of the page
/// content stack so they always print above any artwork.
List<pw.Widget> dotsCropMarks({
  required double pageWidthPt,
  required double pageHeightPt,
  required double trimMarginPt,
}) {
  // Position of the trim rectangle inside the page.
  final trimLeft = trimMarginPt;
  final trimTop = trimMarginPt;
  final trimRight = pageWidthPt - trimMarginPt;
  final trimBottom = pageHeightPt - trimMarginPt;

  pw.Widget hLine(double left, double top, double length) => pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: length,
          height: _tickStrokePt,
          color: PdfColors.black,
        ),
      );

  pw.Widget vLine(double left, double top, double length) => pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: _tickStrokePt,
          height: length,
          color: PdfColors.black,
        ),
      );

  return <pw.Widget>[
    // Top-left corner: horizontal tick going left from the trim corner,
    // vertical tick going up from the trim corner.
    hLine(trimLeft - _tickLengthPt, trimTop - _tickStrokePt / 2, _tickLengthPt),
    vLine(trimLeft - _tickStrokePt / 2, trimTop - _tickLengthPt, _tickLengthPt),
    // Top-right
    hLine(trimRight, trimTop - _tickStrokePt / 2, _tickLengthPt),
    vLine(trimRight - _tickStrokePt / 2, trimTop - _tickLengthPt, _tickLengthPt),
    // Bottom-left
    hLine(trimLeft - _tickLengthPt, trimBottom - _tickStrokePt / 2, _tickLengthPt),
    vLine(trimLeft - _tickStrokePt / 2, trimBottom, _tickLengthPt),
    // Bottom-right
    hLine(trimRight, trimBottom - _tickStrokePt / 2, _tickLengthPt),
    vLine(trimRight - _tickStrokePt / 2, trimBottom, _tickLengthPt),
  ];
}
