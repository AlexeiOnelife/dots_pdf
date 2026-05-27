import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_collage_content.dart';

/// Builds a single [DotsAlbumSpreadPage] for a polaroid-collage spread.
///
/// Delegates to [DotsAlbumSpreadPage.polaroidCollage]. The returned page's
/// `header.centerLabel` equals [contextLabelValue].
///
/// [content.photoPaths] must have exactly
/// `kDefaultPolaroidSlots.length + content.additionalSlots.length` entries;
/// a [RangeError] is thrown otherwise.
DotsAlbumSpreadPage buildPolaroidCollagePageFor(
  DotsAlbumType type,
  AlbumCollageContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  return DotsAlbumSpreadPage.polaroidCollage(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    photoPaths: content.photoPaths,
    applyOtrosGradient: content.applyOtrosGradient,
    additionalSlots: content.additionalSlots,
  );
}
