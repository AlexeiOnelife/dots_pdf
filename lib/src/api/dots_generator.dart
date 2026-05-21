import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../cache/dots_cache.dart';
import '../config/dots_template.dart';
import '../cover/dots_cover_renderer.dart';
import '../cover/dots_cover_template.dart';
import '../events/pdf_generation_event.dart';
import '../io/dots_path_manager.dart';
import '../logging/dots_logger.dart';
import '../preview/dots_page_preview_generator.dart';
import '../preview/dots_pdf_rasterizer.dart';
import '../render/asset_loader.dart';
import '../render/dots_font_bundle.dart';
import '../render/dots_renderer.dart';
import '../render/isolate_synthesis.dart';
import '../render/pair_document_renderer.dart';
import '../render/whole_document_renderer.dart';
import 'dots_output_mode.dart';

/// Public entry point of the library.
///
/// A single [DotsGenerator] instance is safe to reuse across many
/// documents. It owns no per-document state; every call resolves
/// paths and renders independently.
///
/// All long-running work is emitted as a [Stream] of
/// [PdfGenerationEvent]s so callers can render progress without
/// polling.
class DotsGenerator {
  /// Creates a generator.
  ///
  /// [fileSystem] is the `package:file` abstraction the library will
  /// use for every I/O operation; pass `LocalFileSystem()` in app code
  /// and `MemoryFileSystem()` in tests. [documentsDir] is the on-disk
  /// root under which the `dots_pdf/` folder is created — typically
  /// the result of `path_provider.getApplicationDocumentsDirectory()`.
  ///
  /// [useIsolate] — when `true`, the PDF synthesis step (`pw.Document`
  /// build + `doc.save()` + bytes-to-disk) is offloaded to a Dart
  /// isolate via `Isolate.run`. The rasterisation step always stays on
  /// the main isolate because it depends on platform channels.
  ///
  /// **Constraint**: isolate mode requires a real on-disk path writable
  /// by `dart:io`; it does NOT work with `MemoryFileSystem`. Pass
  /// `useIsolate: false` (the default) when constructing the generator
  /// inside tests that use `MemoryFileSystem`.
  DotsGenerator({
    required FileSystem fileSystem,
    required Directory documentsDir,
    DotsLogger logger = const DotsSilentLogger(),
    this.drawCropMarks = false,
    DotsUrlFetcher? urlFetcher,
    DotsFontBundle? fontBundle,
    DotsPdfRasterizer? rasterizer,
    this.previewDpi = 150,
    this.useIsolate = false,
  })  : _fs = fileSystem,
        _logger = logger,
        _urlFetcher = urlFetcher,
        _fontBundle = fontBundle,
        _rasterizer = rasterizer,
        _paths = DotsPathManager(
          fileSystem: fileSystem,
          documentsDir: documentsDir,
        ) {
    _cache = DotsCache(pathManager: _paths, fileSystem: _fs);
  }

  final FileSystem _fs;
  final DotsLogger _logger;
  final DotsPathManager _paths;
  final DotsUrlFetcher? _urlFetcher;
  final DotsFontBundle? _fontBundle;
  final DotsPdfRasterizer? _rasterizer;
  late final DotsCache _cache;

  /// Rasterization density used when producing PNG previews. Defaults
  /// to 150 dpi, a print-quality compromise that still keeps the
  /// per-page bitmap well below 5 MB at A4.
  final double previewDpi;

  /// Whether interior pages are emitted with trim-corner crop marks.
  ///
  /// Callers should derive this from `DotsSupplier.drawsCropMarks` —
  /// europa prints marks, latam does not. Defaults to `false`.
  final bool drawCropMarks;

  /// When `true`, the PDF synthesis step runs in a Dart isolate via
  /// `Isolate.run`. Defaults to `false` for backwards compatibility.
  ///
  /// **Not compatible with `MemoryFileSystem`** — isolate-side writes
  /// go through `dart:io File` directly, bypassing the injected
  /// [FileSystem]. Only enable this with `LocalFileSystem` in
  /// production code.
  final bool useIsolate;

  /// Resolved file path that a whole-document run will write to.
  Future<String> wholePathFor(String documentId) =>
      _paths.wholePdfPath(documentId);

  /// Resolved directory that a pairs run will populate.
  Future<String> pairsDirPathFor(String documentId) async =>
      (await _paths.pairsDirFor(documentId)).path;

  /// Resolved file path that a cover run will write to.
  Future<String> coverPathFor(String documentId) =>
      _paths.coverPdfPath(documentId);

  /// Generates a single whole-document PDF for [template].
  ///
  /// Emits a [PdfGenerationEvent] stream. When [forceRegenerate] is
  /// `false` (default) and the artifact is already cached on disk
  /// against the same content hash, the stream emits a single
  /// [PdfGenerationCacheHit] and closes — no rendering occurs.
  Stream<PdfGenerationEvent> generateWhole({
    required DotsTemplate template,
    bool forceRegenerate = false,
  }) =>
      _run(
        template: template,
        mode: DotsOutputMode.whole,
        forceRegenerate: forceRegenerate,
      );

  /// Generates one PDF per 2-page pair into the pairs directory.
  ///
  /// Behavior mirrors [generateWhole]. The trailing pair contains a
  /// single page when the template has an odd page count.
  Stream<PdfGenerationEvent> generatePairs({
    required DotsTemplate template,
    bool forceRegenerate = false,
  }) =>
      _run(
        template: template,
        mode: DotsOutputMode.pairs,
        forceRegenerate: forceRegenerate,
      );

  /// Generates the cover PDF for [template].
  ///
  /// Emits a [PdfGenerationEvent] stream that mirrors [generateWhole]:
  /// `Started → Progress(1/1) → Completed` for a fresh run, or a
  /// single [PdfGenerationCacheHit] when the previously generated
  /// cover is still valid. The "1/1" progress unit reflects that a
  /// cover is a single 1-page PDF — there is nothing finer to report
  /// on during rendering.
  Stream<PdfGenerationEvent> generateCover({
    required DotsCoverTemplate template,
    bool forceRegenerate = false,
  }) =>
      _runCover(template: template, forceRegenerate: forceRegenerate);

  Stream<PdfGenerationEvent> _run({
    required DotsTemplate template,
    required DotsOutputMode mode,
    required bool forceRegenerate,
  }) async* {
    final documentId = template.documentId;
    final hash = template.contentHash;
    final totalStart = DateTime.now().millisecondsSinceEpoch;

    try {
      if (!forceRegenerate) {
        final status = await _cache.lookup(
          documentId: documentId,
          mode: mode,
          contentHash: hash,
          requirePreviews: _rasterizer != null,
        );
        if (status == DotsCacheStatus.hit) {
          yield PdfGenerationCacheHit(
            documentId: documentId,
            artifactPaths: await _collectArtifactPaths(documentId, mode),
            previewPaths: await _collectPreviewPaths(documentId),
          );
          return;
        }
      }

      await _paths.deleteArtifacts(documentId, mode);
      await _paths.clearTmp(documentId);

      yield PdfGenerationStarted(
        documentId: documentId,
        totalPages: template.effectivePages.length,
      );

      try {
        final tmpDir = await _paths.tmpDir(documentId);
        final artifactPaths = <String>[];
        final previewPaths = <String>[];
        // Photo-slot failures collected by the renderer are drained into
        // PdfPhotoSlotSkipped events after each render call so the
        // front-end can show non-fatal warnings without aborting the run.
        final photoFailures = <({String assetPath, Object error})>[];
        void onPhotoFailure(final String assetPath, final Object error) {
          photoFailures.add((assetPath: assetPath, error: error));
        }

        // Perf counters (ms); populated below per mode.
        int synthMs = 0;
        int saveMs = 0;
        int rasterMs = 0;
        int pageCount = 0;

        switch (mode) {
          case DotsOutputMode.whole:
            final pages = template.effectivePages;
            pageCount = pages.length;

            final finalPath = await _paths.wholePdfPath(documentId);
            final tempPath = await _tempPathFor(documentId, 'whole.pdf');

            if (useIsolate) {
              final preloaded = await preloadAssetBytes(
                pages: pages,
                fileSystem: _fs,
                tmpDir: tmpDir,
                urlFetcher: _urlFetcher,
              );
              final result = await synthesizePdfInIsolate(
                template: template,
                pages: pages,
                outputPath: tempPath,
                preloadedBytes: preloaded,
                drawCropMarks: drawCropMarks,
                fontBundle: _fontBundle,
              );
              synthMs += result.synthMs;
              saveMs += result.saveMs;
              for (final f in result.photoFailures) {
                photoFailures.add(f);
              }
            } else {
              final renderer = WholeDocumentRenderer(
                fileSystem: _fs,
                logger: _logger,
                drawCropMarks: drawCropMarks,
                tmpDir: tmpDir,
                urlFetcher: _urlFetcher,
                fontBundle: _fontBundle,
                onPhotoSlotFailure: onPhotoFailure,
              );
              final sw = Stopwatch()..start();
              await renderer.render(
                template: template,
                pages: pages,
                outputPath: tempPath,
              );
              synthMs = sw.elapsedMilliseconds;
            }

            await _atomicMove(tempPath, finalPath);
            artifactPaths.add(finalPath);
            yield PdfGenerationProgress(
              documentId: documentId,
              completedUnits: 1,
              totalUnits: 1,
            );
            for (final failure in photoFailures) {
              yield PdfPhotoSlotSkipped(
                documentId: documentId,
                assetPath: failure.assetPath,
                error: failure.error,
              );
            }
            photoFailures.clear();

            final rasterStart = DateTime.now().millisecondsSinceEpoch;
            yield* _emitPreviews(
              documentId: documentId,
              pdfPath: finalPath,
              bleedMm: 3,
              wrapMm: 0,
              accumulator: previewPaths,
            );
            rasterMs += DateTime.now().millisecondsSinceEpoch - rasterStart;

          case DotsOutputMode.pairs:
            final renderer = useIsolate
                ? null
                : PairDocumentRenderer(
                    fileSystem: _fs,
                    logger: _logger,
                    drawCropMarks: drawCropMarks,
                    tmpDir: tmpDir,
                    urlFetcher: _urlFetcher,
                    fontBundle: _fontBundle,
                    onPhotoSlotFailure: onPhotoFailure,
                  );
            final slices = _pairSlices(template.effectivePages);
            pageCount = template.effectivePages.length;

            for (var i = 0; i < slices.length; i++) {
              final pair = slices[i];
              final pairIndex = i + 1;
              final finalPath =
                  await _paths.pairPdfPath(documentId, pairIndex);
              final tempPath = await _tempPathFor(
                documentId,
                'pair_${pairIndex.toString().padLeft(3, '0')}.pdf',
              );

              if (useIsolate) {
                final preloaded = await preloadAssetBytes(
                  pages: pair,
                  fileSystem: _fs,
                  tmpDir: tmpDir,
                  urlFetcher: _urlFetcher,
                );
                final result = await synthesizePdfInIsolate(
                  template: template,
                  pages: pair,
                  outputPath: tempPath,
                  preloadedBytes: preloaded,
                  drawCropMarks: drawCropMarks,
                  fontBundle: _fontBundle,
                );
                synthMs += result.synthMs;
                saveMs += result.saveMs;
                for (final f in result.photoFailures) {
                  photoFailures.add(f);
                }
              } else {
                final sw = Stopwatch()..start();
                await renderer!.render(
                  template: template,
                  pages: pair,
                  outputPath: tempPath,
                );
                synthMs += sw.elapsedMilliseconds;
              }

              await _atomicMove(tempPath, finalPath);
              artifactPaths.add(finalPath);
              yield PdfGenerationProgress(
                documentId: documentId,
                completedUnits: pairIndex,
                totalUnits: slices.length,
              );
              for (final failure in photoFailures) {
                yield PdfPhotoSlotSkipped(
                  documentId: documentId,
                  assetPath: failure.assetPath,
                  error: failure.error,
                );
              }
              photoFailures.clear();

              final rasterStart = DateTime.now().millisecondsSinceEpoch;
              yield* _emitPreviews(
                documentId: documentId,
                pdfPath: finalPath,
                bleedMm: 3,
                wrapMm: 0,
                accumulator: previewPaths,
                filenamePrefix:
                    'pair_${pairIndex.toString().padLeft(3, '0')}_',
              );
              rasterMs += DateTime.now().millisecondsSinceEpoch - rasterStart;
            }
        }

        await _cache.recordHash(
          documentId: documentId,
          mode: mode,
          contentHash: hash,
        );

        final totalMs = DateTime.now().millisecondsSinceEpoch - totalStart;
        final isolateLabel = useIsolate ? 'on' : 'off';
        final modeLabel = mode == DotsOutputMode.whole ? 'whole' : 'pairs';
        _logger.info(
          '[dots_pdf] perf documentId=$documentId isolate=$isolateLabel\n'
          '  synth=${synthMs}ms save=${saveMs}ms '
          'raster=${rasterMs}ms total=${totalMs}ms\n'
          '  pages=$pageCount mode=$modeLabel',
        );

        yield PdfGenerationCompleted(
          documentId: documentId,
          artifactPaths: artifactPaths,
          previewPaths: previewPaths,
        );
      } finally {
        await _paths.clearTmp(documentId);
      }
    } catch (error, stackTrace) {
      _logger.error('generation failed for "$documentId"', error, stackTrace);
      yield PdfGenerationFailed(
        documentId: documentId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Stream<PdfGenerationEvent> _runCover({
    required DotsCoverTemplate template,
    required bool forceRegenerate,
  }) async* {
    final documentId = template.documentId;
    final hash = template.contentHash;
    final totalStart = DateTime.now().millisecondsSinceEpoch;

    try {
      if (!forceRegenerate) {
        final status = await _cache.lookupCover(
          documentId: documentId,
          contentHash: hash,
          requirePreviews: _rasterizer != null,
        );
        if (status == DotsCacheStatus.hit) {
          yield PdfGenerationCacheHit(
            documentId: documentId,
            artifactPaths: <String>[await _paths.coverPdfPath(documentId)],
            previewPaths: await _collectPreviewPaths(documentId),
          );
          return;
        }
      }

      await _paths.deleteCoverArtifact(documentId);
      await _paths.clearTmp(documentId);

      yield PdfGenerationStarted(
        documentId: documentId,
        // Cover output is always a single 1-page PDF.
        totalPages: 1,
      );

      try {
        final finalPath = await _paths.coverPdfPath(documentId);
        final tempPath = await _tempPathFor(documentId, 'cover.pdf');

        int synthMs = 0;
        int saveMs = 0;
        int rasterMs = 0;

        if (useIsolate) {
          // Pre-load all artwork bytes on the main isolate.
          final preloaded = await _preloadCoverBytes(template);
          final result = await synthesizeCoverInIsolate(
            template: template,
            outputPath: tempPath,
            preloadedBytes: preloaded,
            fontBundle: _fontBundle,
          );
          synthMs = result.synthMs;
          saveMs = result.saveMs;
        } else {
          final renderer = DotsCoverRenderer(
            fileSystem: _fs,
            logger: _logger,
            fontBundle: _fontBundle,
          );
          final sw = Stopwatch()..start();
          await renderer.render(template: template, outputPath: tempPath);
          synthMs = sw.elapsedMilliseconds;
        }

        await _atomicMove(tempPath, finalPath);

        yield PdfGenerationProgress(
          documentId: documentId,
          completedUnits: 1,
          totalUnits: 1,
        );

        final previewPaths = <String>[];
        final rasterStart = DateTime.now().millisecondsSinceEpoch;
        yield* _emitPreviews(
          documentId: documentId,
          pdfPath: finalPath,
          // Crop both the outer bleed and the wrap so the preview shows
          // only the bound book's visible outer surface (front + spine
          // + back panels).
          bleedMm: 3,
          wrapMm: 20,
          accumulator: previewPaths,
        );
        rasterMs = DateTime.now().millisecondsSinceEpoch - rasterStart;

        await _cache.recordCoverHash(
          documentId: documentId,
          contentHash: hash,
        );

        final totalMs = DateTime.now().millisecondsSinceEpoch - totalStart;
        final isolateLabel = useIsolate ? 'on' : 'off';
        _logger.info(
          '[dots_pdf] perf documentId=$documentId isolate=$isolateLabel\n'
          '  synth=${synthMs}ms save=${saveMs}ms '
          'raster=${rasterMs}ms total=${totalMs}ms\n'
          '  pages=1 mode=cover',
        );

        yield PdfGenerationCompleted(
          documentId: documentId,
          artifactPaths: <String>[finalPath],
          previewPaths: previewPaths,
        );
      } finally {
        await _paths.clearTmp(documentId);
      }
    } catch (error, stackTrace) {
      _logger.error(
        'cover generation failed for "$documentId"',
        error,
        stackTrace,
      );
      yield PdfGenerationFailed(
        documentId: documentId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Pre-loads all artwork byte arrays referenced by [template] from the
  /// injected [FileSystem] on the main isolate.
  ///
  /// Called before handing off to [synthesizeCoverInIsolate] so the
  /// isolate never touches platform channels or [FileSystem].
  Future<Map<String, Uint8List>> _preloadCoverBytes(
    DotsCoverTemplate template,
  ) async {
    final result = <String, Uint8List>{};
    result[template.frontArtworkPath] =
        await _fs.file(template.frontArtworkPath).readAsBytes();
    final spine = template.spineArtworkPath;
    if (spine != null && spine.isNotEmpty) {
      result[spine] = await _fs.file(spine).readAsBytes();
    }
    return result;
  }

  /// Rasterizes [pdfPath] into PNG previews under
  /// `preview/<documentId>/`. Emits one [PdfPreviewProgress] per page.
  ///
  /// No-op when no rasterizer was injected on this generator — the
  /// stream emits nothing in that case and the caller's accumulator
  /// remains empty, preserving the pre-preview behaviour.
  Stream<PdfGenerationEvent> _emitPreviews({
    required final String documentId,
    required final String pdfPath,
    required final double bleedMm,
    required final double wrapMm,
    required final List<String> accumulator,
    final String filenamePrefix = '',
  }) async* {
    final DotsPdfRasterizer? rasterizer = _rasterizer;
    if (rasterizer == null) return;

    final Uint8List pdfBytes = await _fs.file(pdfPath).readAsBytes();
    final Directory previewDir = await _paths.previewDir(documentId);
    final DotsPagePreviewGenerator preview = DotsPagePreviewGenerator(
      fileSystem: _fs,
      rasterizer: rasterizer,
      logger: _logger,
      dpi: previewDpi,
    );

    // Rasterize all pages first (the generator itself is memory-tight
    // — one decoded image alive at a time), then emit progress events
    // synchronously so callers see consistent (completed, total) pairs.
    final List<String> written = await preview.generate(
      pdfBytes: pdfBytes,
      previewDir: previewDir,
      bleedMm: bleedMm,
      wrapMm: wrapMm,
      filenamePrefix: filenamePrefix,
    );
    accumulator.addAll(written);

    final int total = written.length;
    for (var i = 0; i < total; i++) {
      yield PdfPreviewProgress(
        documentId: documentId,
        completedPages: i + 1,
        totalPages: total,
      );
    }
  }

  /// Returns the on-disk PNG previews for [documentId] in lexicographic
  /// order. Used when servicing cache hits so the caller still sees the
  /// preview tree that was generated alongside the cached PDF.
  ///
  /// Looks the directory up without creating it — callers reach this on
  /// the cache-hit path, where the preview tree was either populated by
  /// a prior run or never existed at all.
  Future<List<String>> _collectPreviewPaths(final String documentId) async {
    final Directory libRoot = await _paths.libraryRoot();
    final Directory dir =
        _fs.directory(p.join(libRoot.path, 'preview', documentId));
    if (!await dir.exists()) return const <String>[];
    final List<FileSystemEntity> entries = await dir.list().toList();
    final List<String> pngs = entries
        .whereType<File>()
        .where((final File f) => f.path.endsWith('.png'))
        .map((final File f) => f.path)
        .toList()
      ..sort();
    return pngs;
  }

  /// Splits [pages] into consecutive 2-page pairs. The trailing slice
  /// has length 1 when the page count is odd.
  List<List<DotsPage>> _pairSlices(List<DotsPage> pages) {
    final result = <List<DotsPage>>[];
    for (var i = 0; i < pages.length; i += 2) {
      final end = (i + 2 <= pages.length) ? i + 2 : pages.length;
      result.add(pages.sublist(i, end));
    }
    return result;
  }

  Future<String> _tempPathFor(String documentId, String filename) async {
    final dir = await _paths.tmpDir(documentId);
    return p.join(dir.path, filename);
  }

  Future<void> _atomicMove(String fromPath, String toPath) async {
    final source = _fs.file(fromPath);
    // Ensure destination parent exists. The path manager already
    // creates the whole/ and pairs/<id>/ directories on lookup, so
    // this is a defensive no-op in the common case.
    final destParent = _fs.directory(p.dirname(toPath));
    if (!await destParent.exists()) {
      await destParent.create(recursive: true);
    }
    await source.rename(toPath);
  }

  Future<List<String>> _collectArtifactPaths(
    String documentId,
    DotsOutputMode mode,
  ) async {
    switch (mode) {
      case DotsOutputMode.whole:
        return [await _paths.wholePdfPath(documentId)];
      case DotsOutputMode.pairs:
        final dir = await _paths.pairsDirFor(documentId);
        final entries = await dir.list().toList();
        final files = entries
            .whereType<File>()
            .where((f) => f.path.endsWith('.pdf'))
            .map((f) => f.path)
            .toList()
          ..sort();
        return files;
    }
  }
}
