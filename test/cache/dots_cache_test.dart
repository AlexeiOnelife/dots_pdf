import 'package:dots_pdf/dots_pdf.dart';
import 'package:dots_pdf/src/cache/dots_cache.dart';
import 'package:dots_pdf/src/io/dots_path_manager.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late DotsPathManager paths;
  late DotsCache cache;

  setUp(() {
    fs = MemoryFileSystem.test();
    final docs = fs.directory('/docs')..createSync();
    paths = DotsPathManager(fileSystem: fs, documentsDir: docs);
    cache = DotsCache(pathManager: paths, fileSystem: fs);
  });

  group('DotsCache (whole mode)', () {
    test('reports missing when no artifact on disk', () async {
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 1,
        ),
        DotsCacheStatus.missing,
      );
    });

    test('reports stale when artifact exists but sidecar missing', () async {
      await fs.file(await paths.wholePdfPath('d')).create(recursive: true);
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 1,
        ),
        DotsCacheStatus.stale,
      );
    });

    test('reports stale when sidecar hash differs', () async {
      await fs.file(await paths.wholePdfPath('d')).create(recursive: true);
      await cache.recordHash(
        documentId: 'd',
        mode: DotsOutputMode.whole,
        contentHash: 1,
      );
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 2,
        ),
        DotsCacheStatus.stale,
      );
    });

    test('reports hit when sidecar matches', () async {
      await fs.file(await paths.wholePdfPath('d')).create(recursive: true);
      await cache.recordHash(
        documentId: 'd',
        mode: DotsOutputMode.whole,
        contentHash: 42,
      );
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 42,
        ),
        DotsCacheStatus.hit,
      );
    });

    test(
        'reports stale when requirePreviews is true and no previews on disk',
        () async {
      await fs.file(await paths.wholePdfPath('d')).create(recursive: true);
      await cache.recordHash(
        documentId: 'd',
        mode: DotsOutputMode.whole,
        contentHash: 42,
      );
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 42,
          requirePreviews: true,
        ),
        DotsCacheStatus.stale,
      );
    });

    test(
        'reports hit when requirePreviews is true and previews exist',
        () async {
      await fs.file(await paths.wholePdfPath('d')).create(recursive: true);
      await cache.recordHash(
        documentId: 'd',
        mode: DotsOutputMode.whole,
        contentHash: 42,
      );
      await fs
          .file(await paths.previewPagePath('d', 1))
          .create(recursive: true);
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.whole,
          contentHash: 42,
          requirePreviews: true,
        ),
        DotsCacheStatus.hit,
      );
    });
  });

  group('DotsCache (pairs mode)', () {
    test('reports missing for an empty pairs directory', () async {
      await paths.pairsDirFor('d');
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.pairs,
          contentHash: 1,
        ),
        DotsCacheStatus.missing,
      );
    });

    test('reports hit when any pair PDF + matching sidecar exist', () async {
      await fs.file(await paths.pairPdfPath('d', 1)).create(recursive: true);
      await cache.recordHash(
        documentId: 'd',
        mode: DotsOutputMode.pairs,
        contentHash: 7,
      );
      expect(
        await cache.lookup(
          documentId: 'd',
          mode: DotsOutputMode.pairs,
          contentHash: 7,
        ),
        DotsCacheStatus.hit,
      );
    });
  });
}
