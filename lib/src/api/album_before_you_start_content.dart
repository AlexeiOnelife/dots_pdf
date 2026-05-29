// Caller-supplied content for the "Busca un lugar tranquilo / Más allá
// del papel" instruction spread introduced by Task 2 of the
// `final-render-refinement` series.

import 'package:meta/meta.dart';

/// Content for the "Busca un lugar tranquilo / Más allá del papel"
/// instruction spread shared by `parejas`, `hijos`, `individuales`,
/// `otros`, and `generalEventos`.
///
/// Both fields default to the canonical Spanish copy from the source
/// templates; callers may override either string for testing or
/// localisation. The factory body lands in Tasks 4, 5, and 7; in Task 2
/// the factory constructs cleanly and throws at render time.
@immutable
class AlbumBeforeYouStartContent {
  /// Creates the instruction-spread content.
  ///
  /// [photoPaths] must contain exactly 10 entries — the first 5 fill the
  /// left-page slot grid (left-to-right) and the last 5 fill the
  /// right-page grid. The asserted length aligns with the 10-slot
  /// design specified in `pdf02_pareja_inicial.pdf` / `pdf08_hijos_inicial.pdf`.
  const AlbumBeforeYouStartContent({
    required this.photoPaths,
    this.titleOverride,
    this.bodyOverride,
  }) : assert(
          photoPaths.length == 10,
          'AlbumBeforeYouStartContent.photoPaths must have exactly 10 entries '
          '(5 for the left page + 5 for the right page).',
        );

  /// 10 asset paths for the photo grid. First 5 fill the left page;
  /// last 5 fill the right page. Each slot is 35 × 46 mm.
  final List<String> photoPaths;

  /// Optional override of the fixed left-page title.
  final String? titleOverride;

  /// Optional override of the fixed right-page body block.
  final String? bodyOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumBeforeYouStartContent &&
      _listEquals(other.photoPaths, photoPaths) &&
      other.titleOverride == titleOverride &&
      other.bodyOverride == bodyOverride;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(photoPaths), titleOverride, bodyOverride);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
