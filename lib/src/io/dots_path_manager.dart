import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../api/dots_output_mode.dart';

/// Owns every disk-path decision the library makes.
///
/// All accessors are async because directory creation is required to be
/// idempotent — the methods return the directory or file path **after**
/// ensuring the necessary parent directories exist.
///
/// The class accepts an injected [FileSystem] and base [Directory] so it
/// is testable against `MemoryFileSystem` without touching the real FS.
class DotsPathManager {
  /// Creates a path manager rooted under [documentsDir] on [fileSystem].
  DotsPathManager({
    required FileSystem fileSystem,
    required Directory documentsDir,
  })  : _fs = fileSystem,
        _root = documentsDir;

  final FileSystem _fs;
  final Directory _root;

  /// Library-private root: `<documentsDir>/dots_pdf/`.
  Future<Directory> libraryRoot() async {
    final dir = _fs.directory(p.join(_root.path, 'dots_pdf'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory holding whole-document PDFs.
  Future<Directory> wholeDir() async {
    final dir = _fs.directory(p.join((await libraryRoot()).path, 'whole'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory holding the per-document folder of 2-page-pair PDFs.
  Future<Directory> pairsDirFor(String documentId) async {
    final dir = _fs.directory(
      p.join((await libraryRoot()).path, 'pairs', documentId),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory holding the per-document cover PDFs.
  Future<Directory> coverDir() async {
    final dir = _fs.directory(p.join((await libraryRoot()).path, 'cover'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Per-document directory holding rasterized PNG previews.
  ///
  /// Lives at `<dots_pdf>/preview/<documentId>/`. One subtree per
  /// document, regardless of [DotsOutputMode] — whole, pairs and cover
  /// modes all share the same folder so the consuming app has a single
  /// place to look for "what does this document look like".
  Future<Directory> previewDir(final String documentId) async {
    final dir = _fs.directory(
      p.join((await libraryRoot()).path, 'preview', documentId),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Full path to the [pageIndex]-th preview page (1-based) for the
  /// whole / cover pipeline. File name is zero-padded to width 3, matching
  /// the pair naming convention (`page_001.png`, `page_012.png`, …).
  Future<String> previewPagePath(
    final String documentId,
    final int pageIndex,
  ) async {
    final String padded = pageIndex.toString().padLeft(3, '0');
    return p.join((await previewDir(documentId)).path, 'page_$padded.png');
  }

  /// Removes the entire `preview/<documentId>/` tree if it exists.
  ///
  /// Safe to call when the directory has never been created.
  Future<void> deletePreviews(final String documentId) async {
    final dir = _fs.directory(
      p.join((await libraryRoot()).path, 'preview', documentId),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Scratch directory cleared on every successful run or re-generation.
  Future<Directory> tmpDir(String documentId) async {
    final dir = _fs.directory(
      p.join((await libraryRoot()).path, 'tmp', documentId),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Full path to the whole-document PDF for [documentId].
  Future<String> wholePdfPath(String documentId) async =>
      p.join((await wholeDir()).path, '$documentId.pdf');

  /// Full path to the [pairIndex]-th pair PDF (1-based) of [documentId].
  ///
  /// The file name is zero-padded to width 3 (`pair_001.pdf`,
  /// `pair_002.pdf`, …) so directory listings sort naturally.
  Future<String> pairPdfPath(String documentId, int pairIndex) async {
    final padded = pairIndex.toString().padLeft(3, '0');
    return p.join((await pairsDirFor(documentId)).path, 'pair_$padded.pdf');
  }

  /// Full path to the cover PDF for [documentId].
  ///
  /// Lives at `<dots_pdf>/cover/<documentId>.pdf`. The cover is a
  /// separate artifact from the whole-document and pairs outputs and
  /// uses its own subtree under the library root.
  Future<String> coverPdfPath(String documentId) async =>
      p.join((await coverDir()).path, '$documentId.pdf');

  /// Hash sidecar that records the template content hash used to
  /// produce an interior artifact. Used by [DotsCache] to detect
  /// stale outputs in whole or pairs mode.
  Future<String> hashSidecarPath(
    String documentId,
    DotsOutputMode mode,
  ) async {
    final root = await libraryRoot();
    final base = switch (mode) {
      DotsOutputMode.whole => p.join(root.path, 'whole'),
      DotsOutputMode.pairs => p.join(root.path, 'pairs', documentId),
    };
    return p.join(base, '$documentId.hash');
  }

  /// Hash sidecar for the cover artifact of [documentId].
  ///
  /// Lives at `<dots_pdf>/cover/<documentId>.hash`. Mirrors
  /// [hashSidecarPath] for the cover code path; kept as a separate
  /// method because covers are not modelled as a [DotsOutputMode]
  /// value (they have their own input type, [DotsCoverTemplate]).
  Future<String> coverHashSidecarPath(String documentId) async =>
      p.join((await coverDir()).path, '$documentId.hash');

  /// Removes the scratch directory for [documentId]. Safe to call when
  /// the directory does not exist.
  Future<void> clearTmp(String documentId) async {
    final dir = _fs.directory(
      p.join((await libraryRoot()).path, 'tmp', documentId),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Removes any prior artifacts for [documentId] in [mode].
  ///
  /// Whole mode deletes the single PDF; pairs mode deletes the entire
  /// per-document folder. The hash sidecar is removed in both cases.
  Future<void> deleteArtifacts(
    String documentId,
    DotsOutputMode mode,
  ) async {
    switch (mode) {
      case DotsOutputMode.whole:
        final file = _fs.file(await wholePdfPath(documentId));
        if (await file.exists()) await file.delete();
      case DotsOutputMode.pairs:
        final dir = _fs.directory(
          p.join((await libraryRoot()).path, 'pairs', documentId),
        );
        if (await dir.exists()) await dir.delete(recursive: true);
    }
    final sidecar = _fs.file(await hashSidecarPath(documentId, mode));
    if (await sidecar.exists()) await sidecar.delete();
    await deletePreviews(documentId);
  }

  /// Removes the cover PDF and its hash sidecar for [documentId].
  ///
  /// Kept as a dedicated method (rather than overloading
  /// [deleteArtifacts]) because covers are not a [DotsOutputMode]
  /// value — they are their own pipeline with their own template.
  Future<void> deleteCoverArtifact(String documentId) async {
    final pdf = _fs.file(await coverPdfPath(documentId));
    if (await pdf.exists()) await pdf.delete();
    final sidecar = _fs.file(await coverHashSidecarPath(documentId));
    if (await sidecar.exists()) await sidecar.delete();
    await deletePreviews(documentId);
  }
}
