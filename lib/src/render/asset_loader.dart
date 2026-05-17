import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// Signature of an asynchronous HTTP fetcher used by [DotsAssetLoader] to
/// download URL-sourced images. Defaults to a real `dart:io HttpClient`
/// inside the loader; tests inject a fake to keep the unit suite hermetic.
typedef DotsUrlFetcher = Future<List<int>> Function(Uri url);

/// Resolves an image source — either a local filesystem path or a
/// `http(s)` URL — to its raw bytes.
///
/// URL-sourced assets are downloaded once and persisted to the
/// per-document `tmp/` directory; the surrounding orchestration layer
/// (`DotsGenerator`) is responsible for clearing that directory at the
/// end of every run. Local-path sources are read directly from the
/// injected [FileSystem].
class DotsAssetLoader {
  /// Creates an asset loader rooted at [tmpDir].
  ///
  /// [fileSystem] is the IO abstraction shared with the rest of the
  /// library (so unit tests can plug in `MemoryFileSystem`). [tmpDir]
  /// is the per-document scratch directory; downloaded files are
  /// written underneath it and cleaned up by the caller.
  ///
  /// [urlFetcher] is the network function used for `http(s)` sources.
  /// When omitted, the loader uses `dart:io HttpClient` directly. Unit
  /// tests should always supply a fake fetcher — the default
  /// implementation hits the real network and is not used in tests.
  DotsAssetLoader({
    required FileSystem fileSystem,
    required Directory tmpDir,
    DotsUrlFetcher? urlFetcher,
  })  : _fs = fileSystem,
        _tmpDir = tmpDir,
        _urlFetcher = urlFetcher ?? _defaultUrlFetcher;

  final FileSystem _fs;
  final Directory _tmpDir;
  final DotsUrlFetcher _urlFetcher;

  /// Cache of URL → downloaded local path, keyed by the full URL
  /// string. Ensures the same URL within a single renderer run only
  /// hits the network once, even if it appears on multiple pages.
  final Map<String, String> _downloadedCache = <String, String>{};

  /// Reads bytes for [pathOrUrl].
  ///
  /// When [pathOrUrl] is an `http://` or `https://` URL the loader
  /// downloads it (using the injected [DotsUrlFetcher]) into
  /// `<tmpDir>/dl_<hash>.bin`, then reads the bytes from that file.
  /// The same URL is downloaded at most once per loader instance.
  ///
  /// When [pathOrUrl] is a local path, the bytes are read directly
  /// via the injected [FileSystem].
  Future<Uint8List> loadBytes(String pathOrUrl) async {
    if (isUrl(pathOrUrl)) {
      final cached = _downloadedCache[pathOrUrl];
      if (cached != null) {
        return _fs.file(cached).readAsBytes();
      }
      final uri = Uri.parse(pathOrUrl);
      final bytes = await _urlFetcher(uri);
      if (!await _tmpDir.exists()) {
        await _tmpDir.create(recursive: true);
      }
      final destPath = p.join(
        _tmpDir.path,
        'dl_${_stableHash(pathOrUrl)}.bin',
      );
      await _fs.file(destPath).writeAsBytes(bytes);
      _downloadedCache[pathOrUrl] = destPath;
      return Uint8List.fromList(bytes);
    }
    return _fs.file(pathOrUrl).readAsBytes();
  }

  /// Returns `true` when [value] looks like an `http://` or `https://`
  /// URL. The check is purely syntactic; no network call is made.
  static bool isUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  /// Stable, non-cryptographic hash used to derive scratch file names
  /// from URLs. Equality matters (so re-runs of the same template
  /// land on the same path); cryptographic strength does not.
  static String _stableHash(String value) {
    // Mixes high/low halves of the runtime hash to reduce collisions
    // when two URLs differ only by a trailing query parameter.
    final h1 = value.hashCode & 0xffffffff;
    final h2 = (value.length * 1315423911) & 0xffffffff;
    final mixed = (h1 ^ h2) & 0xffffffff;
    return mixed.toRadixString(16).padLeft(8, '0');
  }
}

Future<List<int>> _defaultUrlFetcher(Uri url) async {
  final client = io.HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'asset URL "$url" returned HTTP ${response.statusCode}',
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  } finally {
    client.close(force: true);
  }
}
