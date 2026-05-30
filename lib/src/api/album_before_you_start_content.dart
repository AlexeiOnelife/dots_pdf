// Caller-supplied content for the chapter-cluster ("Busca un lugar
// tranquilo / Más allá del papel" or per-category equivalent) instruction
// spread.

import 'package:meta/meta.dart';

/// Content for the photo-grid + chapter-cluster instruction spread
/// rendered by [DotsAlbumSpreadPage.beforeYouStart].
///
/// The Q1/Q2 marker, title, and body copy are NOT caller-editable — the
/// factory selects the canonical per-category Spanish text from the
/// source PDFs (`pdf02` p.9, `pdf08` p.9, `pdf10` p.7, `pdf04` p.7,
/// `pdf12` p.2, `pdf06` p.2). The only caller input is the 10 photo
/// paths for the slot grid.
@immutable
class AlbumBeforeYouStartContent {
  /// Creates the instruction-spread content.
  ///
  /// [photoPaths] must contain exactly 10 entries — the first 5 fill the
  /// left-page slot grid (left-to-right) and the last 5 fill the
  /// right-page grid.
  const AlbumBeforeYouStartContent({
    required this.photoPaths,
  }) : assert(
          photoPaths.length == 10,
          'AlbumBeforeYouStartContent.photoPaths must have exactly 10 entries '
          '(5 for the left page + 5 for the right page).',
        );

  /// 10 asset paths for the photo grid. First 5 fill the left page;
  /// last 5 fill the right page. Each slot is 35 × 46 mm.
  final List<String> photoPaths;

  @override
  bool operator ==(Object other) =>
      other is AlbumBeforeYouStartContent &&
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
