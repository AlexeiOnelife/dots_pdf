// Caller-supplied content for the photo-only cover factory introduced by
// Task 2 of the `final-render-refinement` series.
//
// Tasks 5 (individuales/otros) and 7 (generalEventos) provide the
// rendering geometry; in Task 2 the factory is a stub that throws at
// render time.

import 'package:meta/meta.dart';

/// Content for a photo-only cover spread (no decorative circles).
///
/// Used by `DotsAlbumSpreadPage.photoOnlyCover(...)` for the
/// `individuales`, `otros`, and `generalEventos` categories. The factory
/// body lands in Tasks 5 and 7; in Task 2 the factory constructs cleanly
/// (via `DotsUnimplementedElement`) and throws at render time.
@immutable
class AlbumPhotoOnlyCoverContent {
  /// Creates the cover content.
  const AlbumPhotoOnlyCoverContent({
    required this.photoPath,
    required this.title,
    required this.dateLine,
  });

  /// Asset path to the cover photo (66×86 mm centred slot).
  final String photoPath;

  /// Title text — typically the resolved value of `{NombreDelAlbum}` for
  /// individuales/otros or `{TítuloDelAlbum}` for generalEventos.
  final String title;

  /// Date line — typically the resolved value of
  /// `{DiadeMesdeAñodeFechaDeInicio}`.
  final String dateLine;

  @override
  bool operator ==(Object other) =>
      other is AlbumPhotoOnlyCoverContent &&
      other.photoPath == photoPath &&
      other.title == title &&
      other.dateLine == dateLine;

  @override
  int get hashCode => Object.hash(photoPath, title, dateLine);
}
