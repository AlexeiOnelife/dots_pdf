import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_cover_content.dart';

/// Builds a single [DotsAlbumSpreadPage] for an album cover.
///
/// Supports [DotsAlbumType.parejas] and [DotsAlbumType.hijos] only.
/// Throws [ArgumentError] for any other type.
///
/// Delegates to [DotsAlbumSpreadPage.cover], which resolves the eyebrow text,
/// maps [kCoverCircleLayout] to 14 [DotsDecorativeCircleElement] instances,
/// and emits the 3 centred text elements (eyebrow / title / date).
DotsAlbumSpreadPage buildCoverPageFor(
  DotsAlbumType type,
  AlbumCoverContent content, {
  required int pageNumber,
  String contextLabelValue = '',
}) {
  if (type != DotsAlbumType.parejas && type != DotsAlbumType.hijos) {
    throw ArgumentError.value(
      type,
      'type',
      'buildCoverPageFor only supports '
          'DotsAlbumType.parejas and DotsAlbumType.hijos',
    );
  }
  return DotsAlbumSpreadPage.cover(
    type: type,
    pageNumber: pageNumber,
    title: content.title,
    dateLine: content.dateLine,
    contextLabelValue: contextLabelValue,
    eyebrowOverride: content.eyebrowOverride,
  );
}
