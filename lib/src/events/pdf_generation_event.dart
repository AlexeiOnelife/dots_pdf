import 'package:meta/meta.dart';

/// Progress event emitted by the generator pipeline.
///
/// Callers should pattern-match the sealed subclasses to drive UI.
@immutable
sealed class PdfGenerationEvent {
  /// Base constructor for sealed subclasses.
  const PdfGenerationEvent({required this.documentId});

  /// Document the event refers to.
  final String documentId;
}

/// Emitted exactly once when generation begins.
final class PdfGenerationStarted extends PdfGenerationEvent {
  /// Creates a start event.
  const PdfGenerationStarted({
    required super.documentId,
    required this.totalPages,
  });

  /// Total page count the pipeline plans to emit.
  final int totalPages;
}

/// Emitted once per page (whole mode) or once per pair (pairs mode).
final class PdfGenerationProgress extends PdfGenerationEvent {
  /// Creates a progress event.
  const PdfGenerationProgress({
    required super.documentId,
    required this.completedUnits,
    required this.totalUnits,
  });

  /// Units (pages or pairs) completed so far.
  final int completedUnits;

  /// Total units the pipeline will emit.
  final int totalUnits;

  /// Fraction in `[0.0, 1.0]`.
  double get fraction => totalUnits == 0 ? 1 : completedUnits / totalUnits;
}

/// Emitted on a fast-path cache hit; no rendering happened.
final class PdfGenerationCacheHit extends PdfGenerationEvent {
  /// Creates a cache-hit event.
  const PdfGenerationCacheHit({
    required super.documentId,
    required this.artifactPaths,
    this.previewPaths = const <String>[],
  });

  /// Paths returned by the cache. One entry for whole mode, N for pairs.
  final List<String> artifactPaths;

  /// Per-page PNG preview paths that were already on disk for this
  /// document. Empty when no rasterizer was wired in at the time the
  /// artifact was first generated.
  final List<String> previewPaths;
}

/// Emitted while the post-PDF preview rasterization runs.
///
/// Decoupled from [PdfGenerationProgress] so callers can drive a
/// separate UI affordance ("generating previews…") without conflating
/// it with PDF-page progress.
final class PdfPreviewProgress extends PdfGenerationEvent {
  /// Creates a preview-progress event.
  const PdfPreviewProgress({
    required super.documentId,
    required this.completedPages,
    required this.totalPages,
  });

  /// Pages whose PNG preview has been written so far (1-based).
  final int completedPages;

  /// Total pages the preview pipeline will emit for this artifact.
  /// Always `>= 1` — when no previews would be produced (e.g. no
  /// rasterizer wired in) the pipeline simply omits the event.
  final int totalPages;

  /// Fraction in `[0.0, 1.0]`.
  double get fraction =>
      totalPages == 0 ? 1 : completedPages / totalPages;
}

/// Emitted exactly once when generation succeeds.
final class PdfGenerationCompleted extends PdfGenerationEvent {
  /// Creates a completion event.
  const PdfGenerationCompleted({
    required super.documentId,
    required this.artifactPaths,
    this.previewPaths = const <String>[],
  });

  /// Final artifact paths produced by the pipeline.
  final List<String> artifactPaths;

  /// Per-page PNG preview paths produced by the rasterization step.
  /// Empty when no rasterizer was wired into the [DotsGenerator].
  final List<String> previewPaths;
}

/// Emitted when the pipeline fails. The stream closes immediately after.
final class PdfGenerationFailed extends PdfGenerationEvent {
  /// Creates a failure event.
  const PdfGenerationFailed({
    required super.documentId,
    required this.error,
    required this.stackTrace,
  });

  /// Caught error object.
  final Object error;

  /// Stack trace captured at the failure site.
  final StackTrace stackTrace;
}
