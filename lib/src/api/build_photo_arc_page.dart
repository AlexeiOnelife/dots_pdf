import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_photo_arc_content.dart';

/// Builds a [DotsAlbumSpreadPage] for the "Un año lleno de recuerdos"
/// photo-arc layout.
///
/// Supported types: [DotsAlbumType.parejas], [DotsAlbumType.hijos],
/// [DotsAlbumType.individuales], and [DotsAlbumType.otros].
/// Calling with [DotsAlbumType.boda] throws an [ArgumentError].
///
/// **Caller contract**: the [DotsTemplate.pageSize] that wraps this page
/// MUST have `width >= 406 mm (1150.87 pt)`. Elements with
/// `x + diameter > pageWidth` will be clipped silently by the PDF viewer.
///
/// Throws a [RangeError] when `content.photoPaths.length != 10`.
DotsAlbumSpreadPage buildPhotoArcPageFor(
  DotsAlbumType type,
  AlbumPhotoArcContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type == DotsAlbumType.boda) {
    throw ArgumentError.value(
      type,
      'type',
      'buildPhotoArcPageFor does not support DotsAlbumType.boda; '
          "boda's analogue (p.4 radial halo) is not implemented.",
    );
  }
  return DotsAlbumSpreadPage.photoArc(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    content: content,
  );
}
