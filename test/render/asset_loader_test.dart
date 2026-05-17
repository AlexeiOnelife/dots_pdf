import 'package:dots_pdf/src/render/asset_loader.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotsAssetLoader.isUrl', () {
    test('returns true for http and https URLs', () {
      expect(DotsAssetLoader.isUrl('http://example.com/a.png'), isTrue);
      expect(DotsAssetLoader.isUrl('https://example.com/a.png'), isTrue);
    });

    test('returns false for local paths', () {
      expect(DotsAssetLoader.isUrl('/abs/path.png'), isFalse);
      expect(DotsAssetLoader.isUrl('relative/path.png'), isFalse);
      expect(DotsAssetLoader.isUrl('file:///tmp/x.png'), isFalse);
    });
  });

  group('DotsAssetLoader.loadBytes', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
    });

    test('reads bytes from a local file via the injected file system',
        () async {
      await fs.directory('/assets').create(recursive: true);
      await fs.file('/assets/img.bin').writeAsBytes(<int>[1, 2, 3, 4]);
      final tmp = await fs.directory('/tmp/doc_a').create(recursive: true);

      final loader = DotsAssetLoader(fileSystem: fs, tmpDir: tmp);
      final bytes = await loader.loadBytes('/assets/img.bin');

      expect(bytes, equals(<int>[1, 2, 3, 4]));
    });

    test('downloads a URL via the injected fetcher and writes it to tmpDir',
        () async {
      final tmp = await fs.directory('/tmp/doc_b').create(recursive: true);
      final fetchedUrls = <Uri>[];
      Future<List<int>> fetcher(Uri url) async {
        fetchedUrls.add(url);
        return <int>[10, 20, 30];
      }

      final loader = DotsAssetLoader(
        fileSystem: fs,
        tmpDir: tmp,
        urlFetcher: fetcher,
      );

      final bytes = await loader.loadBytes('https://example.com/a.png');
      expect(bytes, equals(<int>[10, 20, 30]));
      expect(fetchedUrls, hasLength(1));
      expect(fetchedUrls.single.toString(), 'https://example.com/a.png');

      // The scratch directory now contains a downloaded file.
      final entries = await tmp.list().toList();
      expect(entries, hasLength(1));
      expect(entries.single.path.endsWith('.bin'), isTrue);
    });

    test('downloads the same URL at most once per loader (cached on disk)',
        () async {
      final tmp = await fs.directory('/tmp/doc_c').create(recursive: true);
      var fetchCount = 0;
      Future<List<int>> fetcher(Uri url) async {
        fetchCount++;
        return <int>[7, 7, 7];
      }

      final loader = DotsAssetLoader(
        fileSystem: fs,
        tmpDir: tmp,
        urlFetcher: fetcher,
      );

      final first = await loader.loadBytes('https://example.com/x.png');
      final second = await loader.loadBytes('https://example.com/x.png');

      expect(first, equals(<int>[7, 7, 7]));
      expect(second, equals(<int>[7, 7, 7]));
      expect(
        fetchCount,
        1,
        reason: 'second loadBytes call should re-use the cached download',
      );
    });

    test('throws when the fetcher throws (e.g. non-2xx HTTP response)',
        () async {
      final tmp = await fs.directory('/tmp/doc_d').create(recursive: true);
      Future<List<int>> fetcher(Uri url) async {
        throw Exception('asset URL "$url" returned HTTP 404');
      }

      final loader = DotsAssetLoader(
        fileSystem: fs,
        tmpDir: tmp,
        urlFetcher: fetcher,
      );

      expect(
        () => loader.loadBytes('https://example.com/missing.png'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('404'),
          ),
        ),
      );
    });
  });
}
