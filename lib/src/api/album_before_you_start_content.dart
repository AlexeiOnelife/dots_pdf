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
  const AlbumBeforeYouStartContent({
    this.titleOverride,
    this.bodyOverride,
  });

  /// Optional override of the fixed left-page title.
  final String? titleOverride;

  /// Optional override of the fixed right-page body block.
  final String? bodyOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumBeforeYouStartContent &&
      other.titleOverride == titleOverride &&
      other.bodyOverride == bodyOverride;

  @override
  int get hashCode => Object.hash(titleOverride, bodyOverride);
}
