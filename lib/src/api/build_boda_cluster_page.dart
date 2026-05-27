import '../api/dots_album_type.dart';
import '../config/dots_template.dart';
import 'album_boda_cluster_content.dart';

/// Builds a [DotsAlbumSpreadPage] for the boda-cluster layout
/// ("Antes de empezar el viaje").
///
/// Supported type: [DotsAlbumType.boda] only. Throws [ArgumentError] for any
/// other type (defense-in-depth: the factory also validates this).
///
/// **Caller contract**: the [DotsTemplate.pageSize] that wraps this page MUST
/// have `width >= 406 mm (1150.87 pt)`. Cluster elements whose x + width
/// exceeds the page width will be clipped silently by the PDF viewer.
///
/// Throws a [RangeError] when `content.photoPaths.length != 7`
/// (defense-in-depth: the factory also validates this).
DotsAlbumSpreadPage buildBodaClusterPageFor(
  DotsAlbumType type,
  AlbumBodaClusterContent content, {
  required int pageNumber,
  required String contextLabelValue,
}) {
  if (type != DotsAlbumType.boda) {
    throw ArgumentError.value(
      type,
      'type',
      'buildBodaClusterPageFor only supports DotsAlbumType.boda.',
    );
  }
  if (content.photoPaths.length != 7) {
    throw RangeError.value(
      content.photoPaths.length,
      'photoPaths.length',
      'Expected 7 photo paths, got ${content.photoPaths.length}.',
    );
  }
  return DotsAlbumSpreadPage.bodaCluster(
    type: type,
    pageNumber: pageNumber,
    contextLabelValue: contextLabelValue,
    content: content,
  );
}
