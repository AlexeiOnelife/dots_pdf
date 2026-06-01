// Caller-supplied content for the generalEventos-specific closing
// spread variant introduced by Task 2 of the `final-render-refinement`
// series.

import 'package:meta/meta.dart';

/// Content for the `generalEventos` closing spread variant — photo +
/// `{TítuloDelAlbum}` title + dual-signature subtitle "Vivido con mucho
/// amor por: {Firma 1} y {Firma 2}".
///
/// Distinct from `DotsAlbumSpreadPage.closing(...)` because the
/// dual-signature subtitle is unique to the generalEventos category.
/// The factory body lands in Task 7; in Task 2 the factory constructs
/// cleanly and throws at render time.
@immutable
class AlbumEventosClosingContent {
  /// Creates the generalEventos closing content.
  const AlbumEventosClosingContent({
    this.photoPath,
    required this.title,
    required this.signature1,
    required this.signature2,
  });

  /// Optional 66×86 mm photo. When null, the slot is omitted.
  final String? photoPath;

  /// Title text — typically the resolved value of `{TítuloDelAlbum}`.
  final String title;

  /// First signature — typically the resolved value of `{Firma 1}`.
  final String signature1;

  /// Second signature — typically the resolved value of `{Firma 2}`.
  final String signature2;

  @override
  bool operator ==(Object other) =>
      other is AlbumEventosClosingContent &&
      other.photoPath == photoPath &&
      other.title == title &&
      other.signature1 == signature1 &&
      other.signature2 == signature2;

  @override
  int get hashCode => Object.hash(photoPath, title, signature1, signature2);
}
