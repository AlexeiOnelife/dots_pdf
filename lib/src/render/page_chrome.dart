import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_template.dart';
import 'dots_font_bundle.dart';
import 'layout/dots_page_geometry.dart';
import 'layout/dots_slot_rect.dart';

// ---------------------------------------------------------------------------
// Chrome geometry constants
// ---------------------------------------------------------------------------

/// Millimetres → PDF points (1 pt = 1/72 inch; 1 inch = 25.4 mm).
const double _kMmToPt = 2.834645669;

/// Full-bleed background colour applied to every interior page — `#fdfefd`.
const PdfColor _kBackgroundColor = PdfColor(
  0xFD / 255,
  0xFE / 255,
  0xFD / 255,
);

/// Y offset of the header band from the top of the page, in millimetres.
///
/// Fixes bug 1: the old inline chrome placed the header at 8 mm; the
/// correct value per the design spec is 9 mm.
const double _kHeaderTopMm = 9.0;

/// Height of the header text band, in millimetres.
const double _kHeaderBandHeightMm = 3.0;

/// Outer horizontal margin (left for a left page, right for a right page)
/// and both the bottom and right footer margin, in millimetres.
const double _kOuterMarginMm = 8.0;

/// Fraction of the page width occupied by each outer column
/// (outer-left and outer-right).
const double _kOuterColRatio = 0.27585;

/// Fraction of the page width occupied by the centre column.
const double _kCenterColRatio = 0.4483;

/// Font size for header labels (P22 Mackinac Book), in PDF points.
///
/// Fixes bug 2: the old inline chrome used the same font size as the
/// footer (7 pt). The correct value per the design spec is 9 pt.
const double _kHeaderFontSize = 9.0;

/// Line-height multiplier for header labels (9 pt × 1.2 = 10.8 pt leading).
const double _kHeaderLineHeight = 1.2;

/// Font size for the footer wordmark (Inter Semibold), in PDF points.
const double _kFooterFontSize = 7.0;

/// Line-height multiplier for the footer wordmark (7 pt × 1.2 = 8.4 pt leading).
const double _kFooterLineHeight = 1.2;

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

/// Returns the chrome widget list for a single interior page.
///
/// The returned list is intended to be **prepended** to the page's
/// [pw.Stack] children so that the background sits below all other content
/// and crop marks (appended last) remain on top.
///
/// **Cover guard**: if [DotsPageChrome.pageNumber], [DotsPageChrome.centerLabel],
/// and [DotsPageChrome.wordmark] are ALL `null` or empty, this function returns
/// an empty list — no widgets, not even the background. This is the contract
/// for cover pages built via `DotsAlbumSpreadPage.cover()`, which deliberately
/// set all three header/footer fields to null/empty to stay chrome-free (R1).
///
/// Return order for non-cover pages:
///   1. Full-bleed `#fdfefd` background — always present, even when
///      [DotsPageChrome.suppressHeader] or [DotsPageChrome.suppressFooter]
///      is `true`.
///   2. Header text widgets (three [pw.Positioned] widgets for outer column,
///      centre column, and the empty outer column) — omitted when
///      [DotsPageChrome.suppressHeader] is `true` or when both
///      [DotsPageChrome.pageNumber] and [DotsPageChrome.centerLabel] are
///      `null` or empty.
///   3. Footer wordmark widget — omitted when [DotsPageChrome.suppressFooter]
///      is `true` or when [DotsPageChrome.wordmark] is `null` or empty.
///
/// [fontResolver] is called with a [DotsFontRole] for each text widget.
/// Returning `null` falls back to the pdf package's built-in Helvetica.
List<pw.Widget> buildPageChrome(
  DotsPageChrome chrome,
  PdfPageFormat format,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final split = buildPageChromeSplit(chrome, format, fontResolver);
  return [...split.background, ...split.foreground];
}

/// Split-pass variant of [buildPageChrome] returning the background
/// pass (full-bleed page fill) separately from the foreground pass
/// (header trio + footer wordmark).
///
/// Callers that want decorative elements to render BETWEEN the page
/// background and the chrome text widgets (e.g.
/// [DotsAlbumSpreadPage.beforeJourney] with its full-page LEFT-side
/// light-blue rectangle) can interleave:
///   1. background widgets (the #fdfefd page fill),
///   2. their own decorative elements,
///   3. foreground widgets (page numbers, centre label, footer
///      wordmark) — drawn LAST so text is never hidden.
///
/// Cover guard: when every chrome field is null/empty, returns two
/// empty lists — matching the original [buildPageChrome] cover-page
/// contract.
({List<pw.Widget> background, List<pw.Widget> foreground})
    buildPageChromeSplit(
  DotsPageChrome chrome,
  PdfPageFormat format,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  // ── Cover guard ────────────────────────────────────────────────────────────
  // Return no widgets (not even the background) when every chrome field is
  // null or empty. This is the cover-page contract: DotsAlbumSpreadPage.cover()
  // sets header trio all-null and wordmark to '', so cover pages stay chrome-free.
  final hasPageNumber =
      chrome.pageNumber != null && chrome.pageNumber!.isNotEmpty;
  final hasRightPageNumber =
      chrome.rightPageNumber != null && chrome.rightPageNumber!.isNotEmpty;
  final hasCenterLabel =
      chrome.centerLabel != null && chrome.centerLabel!.isNotEmpty;
  final hasWordmark = chrome.wordmark != null && chrome.wordmark!.isNotEmpty;

  if (!hasPageNumber && !hasRightPageNumber && !hasCenterLabel && !hasWordmark) {
    return (background: const [], foreground: const []);
  }

  final background = <pw.Widget>[];
  final widgets = <pw.Widget>[]; // foreground accumulator.

  // ── 1. Background — always first ──────────────────────────────────────────
  // The colour is wrapped in a BoxDecoration so tests can read it back via
  // `container.decoration` (pw.Container does not expose `color` as a getter).
  background.add(pw.Positioned.fill(
    child: pw.Container(
      decoration: const pw.BoxDecoration(color: _kBackgroundColor),
    ),
  ));

  // ── 2. Header ─────────────────────────────────────────────────────────────
  if (!chrome.suppressHeader &&
      (hasPageNumber || hasRightPageNumber || hasCenterLabel)) {
    final headerFont = fontResolver(DotsFontRole.p22MackinacBook);
    final headerStyle = pw.TextStyle(
      font: headerFont,
      fontSize: _kHeaderFontSize,
      lineSpacing: _kHeaderFontSize * (_kHeaderLineHeight - 1),
    );

    const topPt = _kHeaderTopMm * _kMmToPt;
    const heightPt = _kHeaderBandHeightMm * _kMmToPt;
    const outerMarginPt = _kOuterMarginMm * _kMmToPt;
    final outerColWidth = format.width * _kOuterColRatio;
    final centerColWidth = format.width * _kCenterColRatio;
    final centerColLeft = outerColWidth;

    if (chrome.isLeftPage) {
      // Left page: page number in outer-LEFT column, centre label in centre.
      if (hasPageNumber) {
        widgets.add(pw.Positioned(
          left: outerMarginPt,
          top: topPt,
          child: pw.SizedBox(
            width: outerColWidth - outerMarginPt,
            height: heightPt,
            child: pw.Text(chrome.pageNumber!, style: headerStyle),
          ),
        ));
      }
      if (hasCenterLabel) {
        widgets.add(pw.Positioned(
          left: centerColLeft,
          top: topPt,
          child: pw.SizedBox(
            width: centerColWidth,
            height: heightPt,
            child: pw.Text(chrome.centerLabel!, style: headerStyle),
          ),
        ));
      }
    } else {
      // Right page: page number in outer-RIGHT column, centre label in centre.
      if (hasCenterLabel) {
        widgets.add(pw.Positioned(
          left: centerColLeft,
          top: topPt,
          child: pw.SizedBox(
            width: centerColWidth,
            height: heightPt,
            child: pw.Text(chrome.centerLabel!, style: headerStyle),
          ),
        ));
      }
      if (hasPageNumber) {
        widgets.add(pw.Positioned(
          right: outerMarginPt,
          top: topPt,
          child: pw.SizedBox(
            width: outerColWidth - outerMarginPt,
            height: heightPt,
            child: pw.Text(
              chrome.pageNumber!,
              style: headerStyle,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ));
      }
    }

    // ── Spread chrome: render the second page number at the right outer
    //    column whenever [rightPageNumber] is set. This composes on top
    //    of the existing single-page rendering — when both `pageNumber`
    //    and `rightPageNumber` are set, the first lands at the left
    //    outer column (per `isLeftPage`) and this second one lands at
    //    the right outer column.
    if (hasRightPageNumber) {
      widgets.add(pw.Positioned(
        right: outerMarginPt,
        top: topPt,
        child: pw.SizedBox(
          width: outerColWidth - outerMarginPt,
          height: heightPt,
          child: pw.Text(
            chrome.rightPageNumber!,
            style: headerStyle,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ));
    }
  }

  // ── 3. Footer ─────────────────────────────────────────────────────────────
  if (!chrome.suppressFooter && hasWordmark) {
    final footerFont = fontResolver(DotsFontRole.interSemibold);
    final footerStyle = pw.TextStyle(
      font: footerFont,
      fontSize: _kFooterFontSize,
      lineSpacing: _kFooterFontSize * (_kFooterLineHeight - 1),
    );
    const marginPt = _kOuterMarginMm * _kMmToPt;

    widgets.add(pw.Positioned(
      right: marginPt,
      bottom: marginPt,
      child: pw.Text(
        chrome.wordmark!,
        style: footerStyle,
        textAlign: pw.TextAlign.right,
      ),
    ));
  }

  return (background: background, foreground: widgets);
}

// ---------------------------------------------------------------------------
// Suppression predicates
// ---------------------------------------------------------------------------

/// Returns `true` when any slot's bleed-top region intrudes into the
/// header band, signalling that the header chrome text should be
/// suppressed for that page.
///
/// A slot suppresses the header iff `bleedTop == true` and its top edge
/// (`yMm`) is above the header band ceiling (`geometry.headerBandMm`).
bool deriveSuppressHeaderForChrome(
  Iterable<DotsSlotRect> slots,
  DotsPageGeometry geometry,
) =>
    slots.any((s) => s.bleedTop && s.yMm < geometry.headerBandMm);

/// Returns `true` when any slot's bleed-bottom region intrudes into the
/// footer band, signalling that the footer wordmark should be suppressed
/// for that page.
///
/// A slot suppresses the footer iff `bleedBottom == true` and its bottom
/// edge (`yMm + heightMm`) extends past the live-area floor
/// (`geometry.liveAreaBottomMm`).
bool deriveSuppressFooterForChrome(
  Iterable<DotsSlotRect> slots,
  DotsPageGeometry geometry,
) =>
    slots.any(
      (s) => s.bleedBottom && s.yMm + s.heightMm > geometry.liveAreaBottomMm,
    );

// ---------------------------------------------------------------------------
// Test-only constant accessors
// ---------------------------------------------------------------------------
// `page_chrome.dart` is not exported from `lib/dots_pdf.dart`; these
// constants are public only so that tests under `test/` can assert the
// chrome contract without reaching into private internals. They MUST stay
// in lockstep with the corresponding `_k…` constants above.

/// Test-only alias for the mm→pt conversion factor used by the chrome.
const double kPageChromeMmToPt = _kMmToPt;

/// Test-only alias for the chrome background colour (`#fdfefd`).
const PdfColor kPageChromeBackgroundColor = _kBackgroundColor;

/// Test-only alias for the header band Y offset, in millimetres (9 mm).
const double kPageChromeHeaderTopMm = _kHeaderTopMm;

/// Test-only alias for the outer header/footer margin, in millimetres (8 mm).
const double kPageChromeOuterMarginMm = _kOuterMarginMm;

/// Test-only alias for the outer column ratio (≈27.585%).
const double kPageChromeOuterColRatio = _kOuterColRatio;

/// Test-only alias for the header font size, in PDF points (9 pt).
const double kPageChromeHeaderFontSize = _kHeaderFontSize;

/// Test-only alias for the footer font size, in PDF points (7 pt).
const double kPageChromeFooterFontSize = _kFooterFontSize;
