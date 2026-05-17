import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/io/dots_path_manager.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late DotsPathManager paths;

  setUp(() {
    fs = MemoryFileSystem.test();
    final docs = fs.directory('/docs')..createSync();
    paths = DotsPathManager(fileSystem: fs, documentsDir: docs);
  });

  group('DotsPathManager', () {
    test('libraryRoot creates dots_pdf/ under documents dir', () async {
      final root = await paths.libraryRoot();
      expect(root.path, '/docs/dots_pdf');
      expect(await fs.directory('/docs/dots_pdf').exists(), isTrue);
    });

    test('wholeDir creates dots_pdf/whole/', () async {
      final dir = await paths.wholeDir();
      expect(dir.path, '/docs/dots_pdf/whole');
      expect(await fs.directory(dir.path).exists(), isTrue);
    });

    test('pairsDirFor creates a document-scoped folder', () async {
      final dir = await paths.pairsDirFor('book_42');
      expect(dir.path, '/docs/dots_pdf/pairs/book_42');
      expect(await fs.directory(dir.path).exists(), isTrue);
    });

    test('pairPdfPath uses zero-padded index', () async {
      expect(await paths.pairPdfPath('b', 1), endsWith('/pair_001.pdf'));
      expect(await paths.pairPdfPath('b', 12), endsWith('/pair_012.pdf'));
      expect(await paths.pairPdfPath('b', 123), endsWith('/pair_123.pdf'));
    });

    test('clearTmp is a no-op when directory does not exist', () async {
      await paths.clearTmp('never_existed');
    });

    test('deleteArtifacts removes whole-mode PDF and sidecar', () async {
      final pdfPath = await paths.wholePdfPath('doc');
      await fs.file(pdfPath).create(recursive: true);
      await fs
          .file(await paths.hashSidecarPath('doc', DotsOutputMode.whole))
          .writeAsString('123');

      await paths.deleteArtifacts('doc', DotsOutputMode.whole);

      expect(await fs.file(pdfPath).exists(), isFalse);
      expect(
        await fs
            .file(await paths.hashSidecarPath('doc', DotsOutputMode.whole))
            .exists(),
        isFalse,
      );
    });

    test('deleteArtifacts removes the whole pairs/<doc>/ tree', () async {
      await paths.pairsDirFor('doc');
      await fs.file(await paths.pairPdfPath('doc', 1)).create(recursive: true);
      await fs.file(await paths.pairPdfPath('doc', 2)).create(recursive: true);

      await paths.deleteArtifacts('doc', DotsOutputMode.pairs);

      expect(
        await fs.directory('/docs/dots_pdf/pairs/doc').exists(),
        isFalse,
      );
    });

    test('coverDir creates dots_pdf/cover/', () async {
      final dir = await paths.coverDir();
      expect(dir.path, '/docs/dots_pdf/cover');
      expect(await fs.directory(dir.path).exists(), isTrue);
    });

    test('coverPdfPath lives under cover/', () async {
      final path = await paths.coverPdfPath('book_42');
      expect(path, '/docs/dots_pdf/cover/book_42.pdf');
    });

    test('coverHashSidecarPath lives next to the cover PDF', () async {
      final path = await paths.coverHashSidecarPath('book_42');
      expect(path, '/docs/dots_pdf/cover/book_42.hash');
    });

    test('deleteCoverArtifact removes cover PDF and sidecar', () async {
      final pdfPath = await paths.coverPdfPath('doc');
      await fs.file(pdfPath).create(recursive: true);
      await fs
          .file(await paths.coverHashSidecarPath('doc'))
          .writeAsString('999');

      await paths.deleteCoverArtifact('doc');

      expect(await fs.file(pdfPath).exists(), isFalse);
      expect(
        await fs.file(await paths.coverHashSidecarPath('doc')).exists(),
        isFalse,
      );
    });

    test('deleteCoverArtifact is a no-op when nothing is on disk', () async {
      // Should not throw even if the cover/ tree has never been touched.
      await paths.deleteCoverArtifact('never_existed');
    });

    test('previewDir creates a per-document folder under preview/', () async {
      final dir = await paths.previewDir('book_42');
      expect(dir.path, '/docs/dots_pdf/preview/book_42');
      expect(await fs.directory(dir.path).exists(), isTrue);
    });

    test('previewPagePath uses zero-padded index', () async {
      expect(await paths.previewPagePath('b', 1), endsWith('/page_001.png'));
      expect(await paths.previewPagePath('b', 9), endsWith('/page_009.png'));
      expect(await paths.previewPagePath('b', 99), endsWith('/page_099.png'));
    });

    test('deletePreviews removes the entire preview/<doc>/ tree', () async {
      await fs
          .file(await paths.previewPagePath('doc', 1))
          .create(recursive: true);
      await fs
          .file(await paths.previewPagePath('doc', 2))
          .create(recursive: true);
      await paths.deletePreviews('doc');
      expect(
        await fs.directory('/docs/dots_pdf/preview/doc').exists(),
        isFalse,
      );
    });

    test('deletePreviews is a no-op when the tree has never been created',
        () async {
      await paths.deletePreviews('never_existed');
    });

    test('deleteArtifacts also wipes the preview tree', () async {
      await fs
          .file(await paths.previewPagePath('doc', 1))
          .create(recursive: true);
      await paths.deleteArtifacts('doc', DotsOutputMode.whole);
      expect(
        await fs.directory('/docs/dots_pdf/preview/doc').exists(),
        isFalse,
      );
    });

    test('deleteCoverArtifact also wipes the preview tree', () async {
      await fs
          .file(await paths.previewPagePath('doc', 1))
          .create(recursive: true);
      await paths.deleteCoverArtifact('doc');
      expect(
        await fs.directory('/docs/dots_pdf/preview/doc').exists(),
        isFalse,
      );
    });
  });
}
