import 'package:dots_pdf/src/cover/dots_cover_design.dart';
import 'package:dots_pdf/src/cover/dots_cover_geometry.dart';
import 'package:dots_pdf/src/cover/dots_cover_template.dart';
import 'package:dots_pdf/src/cover/dots_paper_substrate.dart';
import 'package:dots_pdf/src/cover/dots_supplier.dart';
import 'package:flutter_test/flutter_test.dart';

DotsCoverGeometry _geometry132() => DotsCoverGeometry(
      pageCount: 132,
      paperSubstrate: DotsPaperSubstrate.uncoated150,
      supplier: DotsSupplier.europa,
    );

DotsCoverTemplate _baseTemplate({
  final DotsCoverDesign design = DotsCoverDesign.square,
  final String backgroundColorHex = '#FFFFFF',
  final String? spineTitle,
  final double spineTitleFontSize = 12,
  final String? spineArtworkPath,
}) =>
    DotsCoverTemplate(
      documentId: 'doc',
      geometry: _geometry132(),
      design: design,
      frontArtworkPath: '/assets/front.png',
      backgroundColorHex: backgroundColorHex,
      spineTitle: spineTitle,
      spineTitleFontSize: spineTitleFontSize,
      spineArtworkPath: spineArtworkPath,
    );

void main() {
  group('DotsCoverTemplate — value semantics', () {
    test('two templates with identical fields compare ==', () {
      final DotsCoverTemplate a = _baseTemplate();
      final DotsCoverTemplate b = _baseTemplate();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('contentHash is stable across equal instances', () {
      final DotsCoverTemplate a = _baseTemplate(spineTitle: 'Memories 2024');
      final DotsCoverTemplate b = _baseTemplate(spineTitle: 'Memories 2024');
      expect(a.contentHash, b.contentHash);
    });

    test('contentHash changes when spineTitle changes', () {
      final DotsCoverTemplate a = _baseTemplate(spineTitle: 'Memories 2024');
      final DotsCoverTemplate b = _baseTemplate(spineTitle: 'Other Title');
      expect(a.contentHash, isNot(b.contentHash));
      expect(a == b, isFalse);
    });

    test('contentHash changes when font size changes', () {
      final DotsCoverTemplate a =
          _baseTemplate(spineTitle: 't', spineTitleFontSize: 12);
      final DotsCoverTemplate b =
          _baseTemplate(spineTitle: 't', spineTitleFontSize: 24);
      expect(a.contentHash, isNot(b.contentHash));
    });

    test('contentHash changes when spineArtworkPath is added', () {
      final DotsCoverTemplate withoutArt = _baseTemplate();
      final DotsCoverTemplate withArt =
          _baseTemplate(spineArtworkPath: '/assets/spine.png');
      expect(withoutArt.contentHash, isNot(withArt.contentHash));
      expect(withoutArt == withArt, isFalse);
    });

    test('contentHash changes when design changes', () {
      final DotsCoverTemplate square =
          _baseTemplate(design: DotsCoverDesign.square);
      final DotsCoverTemplate circle =
          _baseTemplate(design: DotsCoverDesign.circle);
      expect(square.contentHash, isNot(circle.contentHash));
      expect(square == circle, isFalse);
    });

    test('contentHash changes when backgroundColorHex changes', () {
      final DotsCoverTemplate white = _baseTemplate();
      final DotsCoverTemplate black =
          _baseTemplate(backgroundColorHex: '#000000');
      expect(white.contentHash, isNot(black.contentHash));
      expect(white == black, isFalse);
    });

    test('toString includes the document id and design name', () {
      final String s = _baseTemplate(design: DotsCoverDesign.linen).toString();
      expect(s, contains('documentId: doc'));
      expect(s, contains('linen'));
    });
  });
}
