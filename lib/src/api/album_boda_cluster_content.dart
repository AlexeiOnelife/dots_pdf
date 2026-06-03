import 'package:meta/meta.dart';

/// Immutable value object that describes the photo and text content for a
/// boda-cluster spread page ("Antes de empezar el viaje").
///
/// Pass an instance to [buildBodaClusterPageFor] or directly to
/// [DotsAlbumSpreadPage.bodaCluster] to produce a [DotsAlbumSpreadPage].
///
/// [photoPaths] must have exactly 7 entries (one per cluster slot).
/// A [RangeError] is thrown by the factory when the length differs.
///
/// [title] defaults to `"Antes de empezar"`.
/// [titleItalicLine] defaults to `"el viaje"`.
@immutable
class AlbumBodaClusterContent {
  /// Creates an [AlbumBodaClusterContent].
  const AlbumBodaClusterContent({
    required this.photoPaths,
    this.title = 'Antes de empezar',
    this.titleItalicLine = 'el viaje',
    required this.body,
  });

  /// Ordered list of photo asset paths; one per cluster slot (exactly 7).
  final List<String> photoPaths;

  /// Title line 1 rendered in P22 Mackinac Medium 27pt.
  /// Defaults to `"Antes de empezar"`.
  final String title;

  /// Title line 2 rendered in P22 Mackinac Medium Italic 27pt.
  /// Defaults to `"el viaje"`.
  final String titleItalicLine;

  /// Body text rendered in Inter Book 9pt, 95 mm wide.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is AlbumBodaClusterContent &&
      _listEquals(other.photoPaths, photoPaths) &&
      other.title == title &&
      other.titleItalicLine == titleItalicLine &&
      other.body == body;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(photoPaths),
        title,
        titleItalicLine,
        body,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
