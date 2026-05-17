import 'package:meta/meta.dart';

import 'dots_cover_geometry.dart';

/// Immutable input bundle for [DotsCoverRenderer].
///
/// A cover is a single 1-page PDF whose dimensions come from
/// [geometry] (not from a `DotsTemplate`, which describes interior
/// body pages). Authoring is purely declarative:
///
/// - [frontArtworkPath] / [backArtworkPath] reference image assets on
///   the injected file system. Each artwork is expected to be authored
///   at the panel's **board** dimensions (e.g. front = 199 × 260 mm);
///   the renderer extends the image into the surrounding wrap.
/// - [spineTitle] is optional. When `null` or empty, no spine text is
///   drawn; per `SPECS.md` resolved clarification #5, the spine title
///   is a caller-owned string.
/// - [spineArtworkPath] is an optional decorative spine background
///   image. When `null` the spine area remains blank.
///
/// Per `SPECS.md` resolved clarification #6, the front and back
/// artworks are modelled as two distinct inputs rather than a single
/// pre-composed wide image.
///
/// Value equality plus [contentHash] participate in cache
/// invalidation downstream — two templates that hash equal and
/// compare `==` may reuse a previously generated cover PDF.
@immutable
class DotsCoverTemplate {
  /// Creates a cover template.
  ///
  /// All paths are interpreted against the file system the renderer is
  /// constructed with; the template itself does no I/O.
  const DotsCoverTemplate({
    required this.documentId,
    required this.geometry,
    required this.frontArtworkPath,
    required this.backArtworkPath,
    this.spineTitle,
    this.spineTitleFontSize = 12,
    this.spineArtworkPath,
  });

  /// Caller-supplied identifier reused by [DotsPathManager] and
  /// [DotsCache] when resolving the cover artifact path on disk.
  final String documentId;

  /// Pure-math geometry that drives the cover page size and per-panel
  /// rectangles. The renderer reads every dimension from this instance.
  final DotsCoverGeometry geometry;

  /// File-system path of the front-cover artwork (board-sized image).
  final String frontArtworkPath;

  /// File-system path of the back-cover artwork (board-sized image).
  final String backArtworkPath;

  /// Optional spine title. `null` or empty means no text is rendered
  /// on the spine.
  final String? spineTitle;

  /// Spine-title font size in PDF points. Ignored when [spineTitle] is
  /// `null` or empty.
  final double spineTitleFontSize;

  /// Optional decorative spine artwork. `null` leaves the spine blank.
  final String? spineArtworkPath;

  /// Hash that summarises every field that affects rendering.
  ///
  /// Used by [DotsCache] to detect template-content changes between
  /// generator runs — when this value changes for the same
  /// [documentId], the previously cached cover PDF is treated as stale
  /// and re-rendered from scratch.
  int get contentHash => Object.hash(
        documentId,
        geometry,
        frontArtworkPath,
        backArtworkPath,
        spineTitle,
        spineTitleFontSize,
        spineArtworkPath,
      );

  @override
  bool operator ==(final Object other) =>
      other is DotsCoverTemplate &&
      other.documentId == documentId &&
      other.geometry == geometry &&
      other.frontArtworkPath == frontArtworkPath &&
      other.backArtworkPath == backArtworkPath &&
      other.spineTitle == spineTitle &&
      other.spineTitleFontSize == spineTitleFontSize &&
      other.spineArtworkPath == spineArtworkPath;

  @override
  int get hashCode => contentHash;

  @override
  String toString() =>
      'DotsCoverTemplate(documentId: $documentId, '
      'geometry: $geometry, '
      'frontArtworkPath: $frontArtworkPath, '
      'backArtworkPath: $backArtworkPath, '
      'spineTitle: $spineTitle, '
      'spineTitleFontSize: $spineTitleFontSize, '
      'spineArtworkPath: $spineArtworkPath)';
}
