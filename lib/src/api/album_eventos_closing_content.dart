// Caller-supplied content for the generalEventos-specific closing
// spread variant introduced by Task 2 of the `final-render-refinement`
// series.

import 'package:meta/meta.dart';

/// Content for the `generalEventos` closing spread variant — a photo +
/// `{TítuloDelAlbum}` title.
///
/// Distinct from `DotsAlbumSpreadPage.closing(...)` because the
/// generalEventos closing uses the `{TítuloDelAlbum}` title at P22
/// Mackinac medium 20/24 pt in a 115 mm box per
/// `docs/specs/07-general-eventos.md` §final p3. The base-truth PDF p3
/// carries no signature subtitle.
@immutable
class AlbumEventosClosingContent {
  /// Creates the generalEventos closing content.
  const AlbumEventosClosingContent({
    this.photoPath,
    required this.title,
  });

  /// Optional 66×86 mm photo. When null, the slot is omitted.
  final String? photoPath;

  /// Title text — typically the resolved value of `{TítuloDelAlbum}`.
  final String title;

  @override
  bool operator ==(Object other) =>
      other is AlbumEventosClosingContent &&
      other.photoPath == photoPath &&
      other.title == title;

  @override
  int get hashCode => Object.hash(photoPath, title);
}
