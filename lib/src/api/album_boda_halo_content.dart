import 'package:meta/meta.dart';

/// Immutable value object that describes the photo content for the boda
/// final p2 "photo halo" spread (docs/specs/04-boda.md §final p2).
///
/// Pass an instance to [buildBodaHaloPageFor] or directly to
/// [DotsAlbumSpreadPage.bodaHalo] to produce a [DotsAlbumSpreadPage].
///
/// Per the spec the halo is the 28-slot photo arrangement alone — there is no
/// QR card and no title on this page (the QR keep-alive is final p1; see
/// [DotsAlbumSpreadPage.closingQrSpread]). [photoPaths] must therefore have
/// exactly 28 entries (one per halo slot). A [RangeError] is thrown by the
/// factory when the length differs.
@immutable
class AlbumBodaHaloContent {
  /// Creates an [AlbumBodaHaloContent].
  const AlbumBodaHaloContent({
    required this.photoPaths,
  });

  /// Ordered list of photo asset paths; one per halo slot (exactly 28).
  final List<String> photoPaths;

  @override
  bool operator ==(Object other) =>
      other is AlbumBodaHaloContent &&
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
