import 'package:dots_pdf/dots_pdf.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.directory('/docs').createSync();
  });

  group('Interior crop marks', () {
    const template = DotsTemplate(
      documentId: 'crop_test',
      pageSize: DotsPageSize(width: 200, height: 300),
      pages: [
        DotsElementsPage(pageNumber: 1, elements: []),
      ],
    );

    Future<int> renderAndMeasure({required bool drawCropMarks}) async {
      final docs = fs.directory('/docs');
      final generator = DotsGenerator(
        fileSystem: fs,
        documentsDir: docs,
        drawCropMarks: drawCropMarks,
      );
      await generator
          .generateWhole(template: template, forceRegenerate: true)
          .toList();
      final path = await generator.wholePathFor('crop_test');
      final bytes = await fs.file(path).readAsBytes();
      return bytes.length;
    }

    test('drawing crop marks produces a larger PDF than the baseline',
        () async {
      final without = await renderAndMeasure(drawCropMarks: false);
      final with_ = await renderAndMeasure(drawCropMarks: true);
      expect(with_, greaterThan(without));
      // 8 stroke rectangles materially affect the content stream; the
      // delta should not be a single byte either.
      expect(with_ - without, greaterThan(50));
    });

    test('omitting crop marks produces a deterministic byte size', () async {
      final first = await renderAndMeasure(drawCropMarks: false);
      final second = await renderAndMeasure(drawCropMarks: false);
      expect(first, equals(second));
    });
  });
}
