// Tests for the buildPageChrome helper (T1.1) and the suppression
// predicate helpers (deriveSuppressHeaderForChrome /
// deriveSuppressFooterForChrome).
//
// `page_chrome.dart` lives under `lib/src/` and is not exported from
// `lib/dots_pdf.dart`, so this test imports it via the `src/` path and
// asserts directly on the returned widget list and the public test
// constants exposed by the helper.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/page_chrome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// 203 × 254 mm trim ≈ 575.43 × 720.0 pt — matches DotsPageGeometry.dotbookDefault().
const PdfPageFormat _format = PdfPageFormat(575.43, 720.0);

// Chrome with every field populated, left page.
const DotsPageChrome _fullLeft = DotsPageChrome(
  pageNumber: '5',
  centerLabel: 'Dotbook',
  wordmark: 'Dots. Memories',
  isLeftPage: true,
);

// Records each fontResolver call so font-role assertions don't have to
// reach into pw.TextStyle.font internals.
pw.Font? Function(DotsFontRole) _recordingResolver(List<DotsFontRole> sink) {
  return (role) {
    sink.add(role);
    return null;
  };
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // T1.1 — buildPageChrome unit tests
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPageChrome', () {
    test('buildPageChrome — background is first widget and has color #fdfefd',
        () {
      final result = buildPageChrome(_fullLeft, _format, (_) => null);
      expect(result, isNotEmpty);
      expect(result.first, isA<pw.Positioned>());
      final pos = result.first as pw.Positioned;
      expect(pos.child, isA<pw.Container>());
      final container = pos.child as pw.Container;
      expect(container.decoration, isA<pw.BoxDecoration>());
      expect(container.decoration!.color, equals(kPageChromeBackgroundColor));
      expect(kPageChromeBackgroundColor, equals(const PdfColor.fromInt(0xfffdfefd)));
    });

    test('buildPageChrome — header Y is 9 mm from top', () {
      final result = buildPageChrome(_fullLeft, _format, (_) => null);
      // result[1] is the first header widget (left-page page-number).
      expect(result[1], isA<pw.Positioned>());
      final hdr = result[1] as pw.Positioned;
      expect(
        hdr.top,
        closeTo(kPageChromeHeaderTopMm * kPageChromeMmToPt, 0.001),
      );
      expect(kPageChromeHeaderTopMm, equals(9.0));
    });

    test('buildPageChrome — header font is p22MackinacBook at 9 pt', () {
      final calls = <DotsFontRole>[];
      // Header-only chrome — no footer — so every recorded call is a header call.
      const headerOnly = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: null,
        isLeftPage: true,
      );
      buildPageChrome(headerOnly, _format, _recordingResolver(calls));
      expect(calls, isNotEmpty);
      expect(
        calls.every((r) => r == DotsFontRole.p22MackinacBook),
        isTrue,
        reason: 'every header label must use p22MackinacBook; got $calls',
      );
      expect(kPageChromeHeaderFontSize, equals(9.0));
    });

    test(
        'buildPageChrome — left page: page number in outer-left, '
        'center label in center', () {
      const left = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: null,
        isLeftPage: true,
      );
      final result = buildPageChrome(left, _format, (_) => null);
      // [bg, pageNumber outer-left, centerLabel center]
      expect(result, hasLength(3));
      final pageNumber = result[1] as pw.Positioned;
      expect(
        pageNumber.left,
        closeTo(kPageChromeOuterMarginMm * kPageChromeMmToPt, 0.001),
      );
      expect(pageNumber.right, isNull);
      final centerLabel = result[2] as pw.Positioned;
      final expectedCenterLeft = _format.width * kPageChromeOuterColRatio;
      expect(centerLabel.left, closeTo(expectedCenterLeft, 0.01));
    });

    test(
        'buildPageChrome — right page: page number in outer-right, '
        'center label in center', () {
      const right = DotsPageChrome(
        pageNumber: '6',
        centerLabel: 'tiempo juntos',
        wordmark: null,
        isLeftPage: false,
      );
      final result = buildPageChrome(right, _format, (_) => null);
      // [bg, centerLabel center, pageNumber outer-right]
      expect(result, hasLength(3));
      final centerLabel = result[1] as pw.Positioned;
      final expectedCenterLeft = _format.width * kPageChromeOuterColRatio;
      expect(centerLabel.left, closeTo(expectedCenterLeft, 0.01));
      final pageNumber = result[2] as pw.Positioned;
      expect(
        pageNumber.right,
        closeTo(kPageChromeOuterMarginMm * kPageChromeMmToPt, 0.001),
      );
      expect(pageNumber.left, isNull);
    });

    test('buildPageChrome — footer font is interSemibold at 7 pt', () {
      final calls = <DotsFontRole>[];
      // Footer-only chrome — every recorded call is the footer call.
      const footerOnly = DotsPageChrome(
        pageNumber: null,
        centerLabel: null,
        wordmark: 'Dots. Memories',
        isLeftPage: true,
      );
      buildPageChrome(footerOnly, _format, _recordingResolver(calls));
      expect(calls, equals(<DotsFontRole>[DotsFontRole.interSemibold]));
      expect(kPageChromeFooterFontSize, equals(7.0));
    });

    test(
        'buildPageChrome — footer is positioned bottom-right at 8 mm from '
        'right and bottom', () {
      const footerOnly = DotsPageChrome(
        pageNumber: null,
        centerLabel: null,
        wordmark: 'Dots. Memories',
        isLeftPage: true,
      );
      final result = buildPageChrome(footerOnly, _format, (_) => null);
      // [bg, footer]
      expect(result, hasLength(2));
      final footer = result[1] as pw.Positioned;
      const expected = kPageChromeOuterMarginMm * kPageChromeMmToPt;
      expect(footer.right, closeTo(expected, 0.001));
      expect(footer.bottom, closeTo(expected, 0.001));
      expect(footer.left, isNull);
      expect(footer.top, isNull);
    });

    test('buildPageChrome — null wordmark produces no footer widget', () {
      const noFooter = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: null,
        isLeftPage: true,
      );
      final result = buildPageChrome(noFooter, _format, (_) => null);
      // [bg, pageNumber, centerLabel] — no footer widget.
      expect(result, hasLength(3));
      // A footer is identifiable as a Positioned with top == null && bottom != null;
      // the background uses Positioned.fill (top == 0, bottom == 0) and the header
      // labels have top set & bottom null.
      final footers = result.whereType<pw.Positioned>().where(
        (w) => w.top == null && w.bottom != null,
      );
      expect(
        footers,
        isEmpty,
        reason: 'no footer widget should be present when wordmark is null',
      );
    });

    test(
        'buildPageChrome — suppressHeader omits header text widgets '
        '(background remains)', () {
      const suppressed = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: 'Dots. Memories',
        isLeftPage: true,
        suppressHeader: true,
      );
      final result = buildPageChrome(suppressed, _format, (_) => null);
      // [bg, footer] — header text widgets are gone, background stays.
      expect(result, hasLength(2));
      final bg = (result.first as pw.Positioned).child as pw.Container;
      expect(bg.decoration!.color, equals(kPageChromeBackgroundColor));
      final footer = result[1] as pw.Positioned;
      expect(footer.bottom, isNotNull);
      expect(footer.top, isNull);
    });

    test(
        'buildPageChrome — suppressFooter omits footer widget '
        '(background remains)', () {
      const suppressed = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: 'Dots. Memories',
        isLeftPage: true,
        suppressFooter: true,
      );
      final result = buildPageChrome(suppressed, _format, (_) => null);
      // [bg, pageNumber, centerLabel] — footer is gone, background stays.
      expect(result, hasLength(3));
      final bg = (result.first as pw.Positioned).child as pw.Container;
      expect(bg.decoration!.color, equals(kPageChromeBackgroundColor));
      final footers = result.whereType<pw.Positioned>().where(
        (w) => w.top == null && w.bottom != null,
      );
      expect(
        footers,
        isEmpty,
        reason: 'footer must be absent when suppressFooter is true',
      );
    });

    test('buildPageChrome — empty chrome returns no widgets (cover guard)', () {
      // Mirror DotsAlbumSpreadPage.cover(): header all-null, wordmark ''.
      const cover = DotsPageChrome(
        pageNumber: null,
        centerLabel: null,
        wordmark: '',
        isLeftPage: true,
      );
      expect(buildPageChrome(cover, _format, (_) => null), isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Suppression predicate helpers
  // ──────────────────────────────────────────────────────────────────────────

  group('deriveSuppressHeaderForChrome / deriveSuppressFooterForChrome', () {
    // ignore: prefer_const_declarations
    final geometry = DotsPageGeometry.dotbookDefault();

    test('header is NOT suppressed when no slot has bleedTop', () {
      const slots = <DotsSlotRect>[
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: 8,
          yMm: 57,
          widthMm: 142,
          heightMm: 189,
        ),
      ];
      expect(deriveSuppressHeaderForChrome(slots, geometry), isFalse);
    });

    test(
        'header IS suppressed when a bleedTop slot starts above the header '
        'band ceiling', () {
      const slots = <DotsSlotRect>[
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: 0,
          yMm: 8, // < geometry.headerBandMm (12 mm)
          widthMm: 203,
          heightMm: 238,
          bleedTop: true,
        ),
      ];
      expect(deriveSuppressHeaderForChrome(slots, geometry), isTrue);
    });

    test(
        'footer is NOT suppressed when no slot has bleedBottom extending past '
        'the live-area floor', () {
      const slots = <DotsSlotRect>[
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: 8,
          yMm: 57,
          widthMm: 142,
          heightMm: 189,
        ),
      ];
      expect(deriveSuppressFooterForChrome(slots, geometry), isFalse);
    });

    test(
        'footer IS suppressed when a bleedBottom slot extends past the '
        'live-area floor', () {
      // liveAreaBottomMm = 254 - 12 = 242. A slot at y=12 height=235 ends at 247.
      const slots = <DotsSlotRect>[
        DotsSlotRect(
          kind: DotsSlotKind.photo,
          xMm: 0,
          yMm: 12,
          widthMm: 203,
          heightMm: 235,
          bleedBottom: true,
        ),
      ];
      expect(deriveSuppressFooterForChrome(slots, geometry), isTrue);
    });
  });
}
