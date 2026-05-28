// Tests for the buildPageChrome helper (T1.1).
//
// Every test in this file is a RED placeholder: it calls
// fail('PR 2: buildPageChrome not implemented') because buildPageChrome
// lives in lib/src/render/page_chrome.dart which is created in PR 2.
// These tests compile on the PR 1 branch and are intentionally FAILING.
//
// When PR 2 implements buildPageChrome, replace fail() bodies with the
// real assertions described in the comments. The import below will be needed
// for the actual chrome/format instances in PR 2.
// ignore: unused_import
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

// ── mm → pt constant (matches page_chrome.dart _kMmToPt) ───────────────────
// Duplicated here so tests can assert geometry without importing internals.
// When PR 2 exports @visibleForTesting constants, replace this with an import
// from page_chrome.dart.
// In PR 1 this constant is referenced only in comments, so it is omitted to
// keep the analyzer clean. Uncomment in PR 2 when the real assertions land.
// const double mmToPt = 2.834645669;

void main() {

  // ──────────────────────────────────────────────────────────────────────────
  // T1.1 — buildPageChrome unit tests (RED in PR 1, GREEN in PR 2)
  // ──────────────────────────────────────────────────────────────────────────

  group('buildPageChrome', () {
    test('buildPageChrome — background is first widget and has color #fdfefd',
        () {
      // R1, R8: background is always result[0], color is #fdfefd.
      // In PR 2: call buildPageChrome(chrome, format, (_) => null) and assert
      //   result.first is pw.Positioned with fill color PdfColor(0xFD/255, 0xFE/255, 0xFD/255).
      fail('PR 2: buildPageChrome not implemented');
    });

    test('buildPageChrome — header Y is 9 mm from top', () {
      // R2: header positioned widget has top == 9 * _kMmToPt.
      // In PR 2: inspect result[1] (first header widget) top offset.
      fail('PR 2: buildPageChrome not implemented');
    });

    test('buildPageChrome — header font is p22MackinacBook at 9 pt', () {
      // R2: all header text widgets use DotsFontRole.p22MackinacBook at 9 pt.
      // In PR 2: collect fontResolver calls; assert all header calls use
      //   p22MackinacBook and none use interSemibold.
      fail('PR 2: buildPageChrome not implemented');
    });

    test(
        'buildPageChrome — left page: page number in outer-left, '
        'center label in center', () {
      // R3: chrome with isLeftPage:true — pageNumber appears at left: 8*mmToPt,
      //   centerLabel at left: outerColWidth.
      fail('PR 2: buildPageChrome not implemented');
    });

    test(
        'buildPageChrome — right page: page number in outer-right, '
        'center label in center', () {
      // R3: chrome with isLeftPage:false — pageNumber appears at right: 8*mmToPt,
      //   centerLabel at left: outerColWidth.
      fail('PR 2: buildPageChrome not implemented');
    });

    test('buildPageChrome — footer font is interSemibold at 7 pt', () {
      // R4: footer widget uses DotsFontRole.interSemibold at 7 pt.
      // In PR 2: collect fontResolver calls for footer; assert interSemibold at 7pt.
      fail('PR 2: buildPageChrome not implemented');
    });

    test(
        'buildPageChrome — footer is positioned bottom-right at 8 mm from '
        'right and bottom', () {
      // R4: footer positioned widget has right: 8*mmToPt, bottom: 8*mmToPt,
      //   textAlign: right.
      fail('PR 2: buildPageChrome not implemented');
    });

    test('buildPageChrome — null wordmark produces no footer widget', () {
      // R4: chrome with wordmark:null → result contains background only
      //   (plus optional header widgets — no footer).
      fail('PR 2: buildPageChrome not implemented');
    });

    test(
        'buildPageChrome — suppressHeader omits header text widgets '
        '(background remains)', () {
      // R5: chrome with suppressHeader:true → result[0] is background,
      //   no header text widgets present, length == 1 (or 2 if footer present).
      fail('PR 2: buildPageChrome not implemented');
    });

    test(
        'buildPageChrome — suppressFooter omits footer widget '
        '(background remains)', () {
      // R5: chrome with suppressFooter:true and non-null wordmark → result
      //   contains background + header widgets but no footer widget.
      fail('PR 2: buildPageChrome not implemented');
    });
  });
}
