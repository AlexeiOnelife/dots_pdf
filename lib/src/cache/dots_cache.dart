import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../api/dots_output_mode.dart';
import '../io/dots_path_manager.dart';

/// Outcome of a cache lookup.
enum DotsCacheStatus {
  /// Artifact exists on disk and its sidecar hash matches the current
  /// template content hash — the caller should return the stored path
  /// directly.
  hit,

  /// No artifact on disk: a full generation pipeline run is required.
  missing,

  /// Artifact exists but the sidecar hash differs from the current
  /// content hash — the artifact must be deleted and re-rendered.
  stale,
}

/// Checks whether a previously generated artifact can be reused.
///
/// The cache key is implicitly `(documentId, mode, contentHash)`; the
/// hash is stored in a small sidecar file written next to the artifact
/// at generation time. There is no in-memory cache — disk is the source
/// of truth, which matches the library's memory budget.
class DotsCache {
  /// Creates a cache backed by [pathManager] on [fileSystem].
  const DotsCache({
    required DotsPathManager pathManager,
    required FileSystem fileSystem,
  })  : _paths = pathManager,
        _fs = fileSystem;

  final DotsPathManager _paths;
  final FileSystem _fs;

  /// Returns the cache status for the given key.
  ///
  /// When [requirePreviews] is `true`, a status of [DotsCacheStatus.hit]
  /// additionally requires that the per-document preview directory
  /// exists and contains at least one `.png` file; if previews are
  /// missing, the result is downgraded to [DotsCacheStatus.stale] so a
  /// fresh run can repopulate them. Callers that don't generate
  /// previews (no rasterizer wired in) should leave this off so they
  /// keep getting cache hits on rerun.
  Future<DotsCacheStatus> lookup({
    required String documentId,
    required DotsOutputMode mode,
    required int contentHash,
    bool requirePreviews = false,
  }) async {
    final bool artifactExists;
    switch (mode) {
      case DotsOutputMode.whole:
        artifactExists =
            await _fs.file(await _paths.wholePdfPath(documentId)).exists();
      case DotsOutputMode.pairs:
        final dir = await _paths.pairsDirFor(documentId);
        artifactExists = await dir.list().any(
              (entry) => entry is File && entry.path.endsWith('.pdf'),
            );
    }
    if (!artifactExists) return DotsCacheStatus.missing;

    final sidecar = _fs.file(await _paths.hashSidecarPath(documentId, mode));
    if (!await sidecar.exists()) return DotsCacheStatus.stale;

    final stored = int.tryParse((await sidecar.readAsString()).trim());
    if (stored != contentHash) return DotsCacheStatus.stale;

    if (requirePreviews && !await _hasAtLeastOnePreview(documentId)) {
      return DotsCacheStatus.stale;
    }
    return DotsCacheStatus.hit;
  }

  /// Writes the sidecar hash file for a freshly generated artifact.
  Future<void> recordHash({
    required String documentId,
    required DotsOutputMode mode,
    required int contentHash,
  }) async {
    final sidecar = _fs.file(await _paths.hashSidecarPath(documentId, mode));
    await sidecar.writeAsString(contentHash.toString(), flush: true);
  }

  /// Returns the cache status for the cover artifact of [documentId].
  ///
  /// The cache key is implicitly `(documentId, "cover", contentHash)`.
  /// Kept as a dedicated method rather than coercing covers into
  /// [DotsOutputMode], because covers are driven by a different
  /// template type ([DotsCoverTemplate]). When [requirePreviews] is
  /// `true` a hit also requires the preview directory to contain at
  /// least one PNG, matching the behaviour of [lookup].
  Future<DotsCacheStatus> lookupCover({
    required String documentId,
    required int contentHash,
    bool requirePreviews = false,
  }) async {
    final pdfExists =
        await _fs.file(await _paths.coverPdfPath(documentId)).exists();
    if (!pdfExists) return DotsCacheStatus.missing;

    final sidecar =
        _fs.file(await _paths.coverHashSidecarPath(documentId));
    if (!await sidecar.exists()) return DotsCacheStatus.stale;

    final stored = int.tryParse((await sidecar.readAsString()).trim());
    if (stored != contentHash) return DotsCacheStatus.stale;

    if (requirePreviews && !await _hasAtLeastOnePreview(documentId)) {
      return DotsCacheStatus.stale;
    }
    return DotsCacheStatus.hit;
  }

  /// Whether `preview/<documentId>/` exists and contains at least one
  /// `.png`. Used to downgrade an otherwise-fresh artifact to stale so
  /// the pipeline re-renders the previews next time.
  ///
  /// The path is reconstructed manually so a missing preview tree
  /// stays missing — using [DotsPathManager.previewDir] would create
  /// the directory as a side effect, which would mask the negative.
  Future<bool> _hasAtLeastOnePreview(final String documentId) async {
    final Directory libRoot = await _paths.libraryRoot();
    final Directory dir =
        _fs.directory(p.join(libRoot.path, 'preview', documentId));
    if (!await dir.exists()) return false;
    return dir.list().any(
          (final FileSystemEntity entry) =>
              entry is File && entry.path.endsWith('.png'),
        );
  }

  /// Writes the cover hash sidecar for a freshly generated cover PDF.
  Future<void> recordCoverHash({
    required String documentId,
    required int contentHash,
  }) async {
    final sidecar =
        _fs.file(await _paths.coverHashSidecarPath(documentId));
    await sidecar.writeAsString(contentHash.toString(), flush: true);
  }
}
