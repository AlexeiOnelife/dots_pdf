// Foundation conformance — locks the page-source contract defined in
// `docs/specs/00-foundation.md` against the code constants and the chrome
// helper output. The spec is authoritative: if a value here disagrees with
// the spec, the spec wins.
//
// `page_chrome.dart` is not exported from `lib/dots_pdf.dart`, so this test
// imports it via the `src/` path to read its public test constants.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/render/page_chrome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// 1 mm in PDF points (the global units row of docs/specs/README.md).
const double _kSpecMmToPt = 2.834645669;

// Single-page media (with 3 mm bleed): 209 × 260 mm → 592.441 × 737.008 pt.
const PdfPageFormat _mediaFormat = PdfPageFormat(592.441, 737.008);

// Reads the TextStyle attached to a `pw.Text` (a RichText whose span carries
// the style).
pw.TextStyle _styleOf(pw.Widget w) {
  final richText = w as pw.RichText;
  final span = richText.text as pw.TextSpan;
  return span.style!;
}

void main() {
  group('00-foundation — units & background', () {
    test('mm→pt conversion factor matches the spec (2.834645669)', () {
      expect(kPageChromeMmToPt, equals(_kSpecMmToPt));
    });

    test('background colour is #fdfefd on every page', () {
      expect(
        kPageChromeBackgroundColor,
        equals(const PdfColor.fromInt(0xfffdfefd)),
      );
    });
  });

  group('00-foundation — header chrome (§3)', () {
    test('header insets: 8 mm from page edges, 9 mm down', () {
      expect(kPageChromeOuterMarginMm, equals(8.0));
      expect(kPageChromeHeaderTopMm, equals(9.0));
    });

    test('Dotbook name / context label: P22 Mackinac book 9 / 10.8 pt', () {
      const headerOnly = DotsPageChrome(
        pageNumber: '5',
        centerLabel: 'Dotbook',
        wordmark: null,
        isLeftPage: true,
      );
      final roles = <DotsFontRole>[];
      final result = buildPageChrome(headerOnly, _mediaFormat, (r) {
        roles.add(r);
        return null;
      });

      // Every header label resolves the P22 Mackinac book role at 9 pt.
      expect(roles, isNotEmpty);
      expect(roles.every((r) => r == DotsFontRole.p22MackinacBook), isTrue);
      expect(kPageChromeHeaderFontSize, equals(9.0));

      // result[1] = page-number Positioned → SizedBox → Text. Read its style.
      final pageNumberBox =
          (result[1] as pw.Positioned).child! as pw.SizedBox;
      final style = _styleOf(pageNumberBox.child!);
      expect(style.fontSize, equals(9.0));
      // Leading 10.8 pt = 9 pt + lineSpacing (9 × 0.2 = 1.8 pt).
      expect(style.fontSize! + style.lineSpacing!, closeTo(10.8, 0.001));
    });
  });

  group('00-foundation — footer chrome (§3)', () {
    test('brand: Inter Semibold 7 / 8.4 pt', () {
      const footerOnly = DotsPageChrome(
        pageNumber: null,
        centerLabel: null,
        wordmark: 'Dots. Memories',
        isLeftPage: true,
      );
      final roles = <DotsFontRole>[];
      final result = buildPageChrome(footerOnly, _mediaFormat, (r) {
        roles.add(r);
        return null;
      });

      expect(roles, equals(<DotsFontRole>[DotsFontRole.interSemibold]));
      expect(kPageChromeFooterFontSize, equals(7.0));

      final style = _styleOf((result[1] as pw.Positioned).child!);
      expect(style.fontSize, equals(7.0));
      // Leading 8.4 pt = 7 pt + lineSpacing (7 × 0.2 = 1.4 pt).
      expect(style.fontSize! + style.lineSpacing!, closeTo(8.4, 0.001));
    });

    test('footer sits 5 mm above the bottom trim', () {
      // On a media page (3 mm bleed), 5 mm from the bottom trim equals
      // 3 + 5 = 8 mm from the bottom page edge.
      const footerOnly = DotsPageChrome(
        pageNumber: null,
        centerLabel: null,
        wordmark: 'Dots. Memories',
        isLeftPage: true,
      );
      final result = buildPageChrome(footerOnly, _mediaFormat, (_) => null);
      final footer = result[1] as pw.Positioned;
      const bleedMm = 3.0;
      const footerTrimInsetMm = 5.0;
      expect(
        footer.bottom,
        closeTo((bleedMm + footerTrimInsetMm) * kPageChromeMmToPt, 0.001),
      );
    });
  });

  group('00-foundation — font registry (§4)', () {
    test('every registry role exists in DotsFontRole', () {
      const expected = <DotsFontRole>{
        DotsFontRole.p22MackinacMedium,
        DotsFontRole.p22MackinacBook,
        DotsFontRole.p22MackinacMediumItalic,
        DotsFontRole.inter,
        DotsFontRole.interSemibold,
        DotsFontRole.biroScriptPlus,
      };
      expect(DotsFontRole.values.toSet().containsAll(expected), isTrue);
    });

    test('family strings map to the registry roles', () {
      expect(
        DotsFontBundle.roleFromFamily('P22 Mackinac Book'),
        equals(DotsFontRole.p22MackinacBook),
      );
      expect(
        DotsFontBundle.roleFromFamily('Inter Semibold'),
        equals(DotsFontRole.interSemibold),
      );
      expect(
        DotsFontBundle.roleFromFamily('Inter Book'),
        equals(DotsFontRole.inter),
      );
      expect(
        DotsFontBundle.roleFromFamily('Biro Script Plus'),
        equals(DotsFontRole.biroScriptPlus),
      );
    });
  });
}
