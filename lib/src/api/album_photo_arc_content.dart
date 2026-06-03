import 'package:meta/meta.dart';

/// Immutable value object that describes the photo content for the final p2
/// photo arc/halo spread.
///
/// Pass an instance to [buildPhotoArcPageFor] or directly to
/// [DotsAlbumSpreadPage.photoArc] to produce a [DotsAlbumSpreadPage].
///
/// Per docs/specs/02-pareja.md §final p2 (shared across otros/hijos/individual
/// and boda/general-eventos), the photo arc/halo is the **halo alone** — the
/// QR keep-alive (title, body, caption, QR card) lives on final p1
/// ([DotsAlbumSpreadPage.closingQrSpread]). This content therefore carries
/// only the ordered photo slot paths.
///
/// [photoPaths] must have exactly 28 entries (one per arc slot). A
/// [RangeError] is thrown by the factory when the length differs.
@immutable
class AlbumPhotoArcContent {
  /// Creates an [AlbumPhotoArcContent].
  const AlbumPhotoArcContent({
    required this.photoPaths,
  });

  /// Ordered list of photo asset paths; one per arc slot (exactly 28).
  final List<String> photoPaths;

  @override
  bool operator ==(Object other) =>
      other is AlbumPhotoArcContent &&
      _listEquals(other.photoPaths, photoPaths);

  @override
  int get hashCode => Object.hashAll(photoPaths);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
