import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_boda_halo_content.dart';

/// Builds a [DotsAlbumSpreadPage] for the boda final p2 "photo halo" spread
/// (docs/specs/04-boda.md §final p2 — the shared 28-slot halo).
///
/// Supported type: [DotsAlbumType.boda] only.
/// Calling with any other type throws an [ArgumentError] (defense-in-depth;
/// [DotsAlbumSpreadPage.bodaHalo] also guards).
///
/// **Caller contract**: the [DotsTemplate.pageSize] that wraps this page
/// MUST have `width >= 406 mm (1150.87 pt)`. Elements with
/// `x + diameter > pageWidth` will be clipped silently by the PDF viewer.
///
/// Throws a [RangeError] when `content.photoPaths.length != 28`
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
  if (content.photoPaths.length != 28) {
    throw RangeError.value(
      content.photoPaths.length,
      'photoPaths.length',
      'Expected 28 photo paths, got ${content.photoPaths.length}.',
    );
  }
  return DotsAlbumSpreadPage.bodaHalo(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    content: content,
  );
}
