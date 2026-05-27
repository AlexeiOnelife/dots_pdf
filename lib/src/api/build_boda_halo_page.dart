import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_boda_halo_content.dart';

/// Builds a [DotsAlbumSpreadPage] for the "Boda de Nombre&Nombre"
/// radial halo title spread (boda p.4).
///
/// Supported type: [DotsAlbumType.boda] only.
/// Calling with any other type throws an [ArgumentError] (defense-in-depth;
/// [DotsAlbumSpreadPage.bodaHalo] also guards).
///
/// **Caller contract**: the [DotsTemplate.pageSize] that wraps this page
/// MUST have `width >= 406 mm (1150.87 pt)`. Elements with
/// `x + width > pageWidth` will be clipped silently by the PDF viewer.
///
/// Throws a [RangeError] when `content.photoPaths.length != 10`
/// (defense-in-depth).
DotsAlbumSpreadPage buildBodaHaloPageFor(
  DotsAlbumType type,
  AlbumBodaHaloContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type != DotsAlbumType.boda) {
    throw ArgumentError.value(
      type,
      'type',
      'buildBodaHaloPageFor only supports DotsAlbumType.boda; got $type',
    );
  }
  if (content.photoPaths.length != 10) {
    throw RangeError.value(
      content.photoPaths.length,
      'photoPaths.length',
      'Expected 10 photo paths, got ${content.photoPaths.length}.',
    );
  }
  return DotsAlbumSpreadPage.bodaHalo(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    content: content,
  );
}
