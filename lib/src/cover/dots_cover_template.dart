import 'package:meta/meta.dart';

import 'dots_cover_design.dart';
import 'dots_cover_geometry.dart';

/// Immutable input bundle for [DotsCoverRenderer].
///
/// A cover is a single 1-page PDF whose dimensions come from
/// [geometry] (not from a `DotsTemplate`, which describes interior
/// body pages). Authoring is purely declarative:
///
/// - [design] selects the visual layout used to position artwork on
///   the cover (see [DotsCoverDesign]). The interpretation of
///   [frontArtworkPath] / [backArtworkPath] depends on this choice:
///   `square` and `circle` only consume the front artwork; `linen`
///   consumes the front artwork and renders it as a strip spanning
///   the whole cover (back artwork is ignored).
/// - [frontArtworkPath] / [backArtworkPath] reference image assets on
///   the injected file system.
/// - [backgroundColorHex] paints the cover behind the artwork. For
///   `square` and `circle` this fills the panel area not covered by
///   the centered shape; for `linen` it fills the area above/below the
///   strip. Defaults to white (`#FFFFFF`).
/// - [spineTitle] is optional. When `null` or empty, no spine text is
///   drawn; per `SPECS.md` resolved clarification #5, the spine title
///   is a caller-owned string.
/// - [spineArtworkPath] is an optional decorative spine background
///   image. When `null` the spine area remains blank.
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
    required this.design,
    required this.frontArtworkPath,
    this.backArtworkPath,
    this.backgroundColorHex = '#FFFFFF',
    this.spineTitle,
    this.spineTitleFontSize = 12,
    this.spineArtworkPath,
  });

  /// Caller-supplied identifier reused by `DotsPathManager` and
  /// `DotsCache` when resolving the cover artifact path on disk.
  final String documentId;

  /// Pure-math geometry that drives the cover page size and per-panel
  /// rectangles. The renderer reads every dimension from this instance.
  final DotsCoverGeometry geometry;

  /// Visual design used to lay out artwork on the cover.
  final DotsCoverDesign design;

  /// File-system path of the front-cover artwork.
  ///
  /// Interpretation depends on [design]:
  ///   - `square`/`circle`: rendered as the centered shape on the front panel.
  ///   - `linen`: rendered as the horizontal strip spanning both covers.
  final String frontArtworkPath;

  /// File-system path of the back-cover artwork.
  ///
  /// Only consumed by `classic`-style full-bleed designs (currently
  /// none of [DotsCoverDesign]'s variants). `square`, `circle`, and
  /// `linen` ignore this field; it is kept optional so callers can
  /// supply or omit it depending on the design.
  final String? backArtworkPath;

  /// Background color (RGB hex, e.g. `#FFFFFF`) painted behind the
  /// artwork on areas the design does not cover. Defaults to white.
  final String backgroundColorHex;

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
  /// Used by `DotsCache` to detect template-content changes between
  /// generator runs — when this value changes for the same
  /// [documentId], the previously cached cover PDF is treated as stale
  /// and re-rendered from scratch.
  int get contentHash => Object.hash(
        documentId,
        geometry,
        design,
        frontArtworkPath,
        backArtworkPath,
        backgroundColorHex,
        spineTitle,
        spineTitleFontSize,
        spineArtworkPath,
      );

  @override
  bool operator ==(final Object other) =>
      other is DotsCoverTemplate &&
      other.documentId == documentId &&
      other.geometry == geometry &&
      other.design == design &&
      other.frontArtworkPath == frontArtworkPath &&
      other.backArtworkPath == backArtworkPath &&
      other.backgroundColorHex == backgroundColorHex &&
      other.spineTitle == spineTitle &&
      other.spineTitleFontSize == spineTitleFontSize &&
      other.spineArtworkPath == spineArtworkPath;

  @override
  int get hashCode => contentHash;

  @override
  String toString() =>
      'DotsCoverTemplate(documentId: $documentId, '
      'geometry: $geometry, '
      'design: $design, '
      'frontArtworkPath: $frontArtworkPath, '
      'backArtworkPath: $backArtworkPath, '
      'backgroundColorHex: $backgroundColorHex, '
      'spineTitle: $spineTitle, '
      'spineTitleFontSize: $spineTitleFontSize, '
      'spineArtworkPath: $spineArtworkPath)';
}
