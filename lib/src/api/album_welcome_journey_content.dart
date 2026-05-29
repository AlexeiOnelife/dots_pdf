// Caller-supplied content for the "Bienvenido/a a tu viaje al pasado"
// welcome spread introduced by Task 2 of the `final-render-refinement`
// series — specific to the `generalEventos` category.

import 'package:meta/meta.dart';

/// Content for the "Bienvenido/a a tu viaje al pasado" instruction
/// spread used as initial pliego 2 of the `generalEventos` category.
///
/// Both fields default to the canonical Spanish copy from
/// `pdf12_general_eventos_inicial.pdf`; callers may override either
/// string. The factory body lands in Task 7; in Task 2 the factory
/// constructs cleanly and throws at render time.
@immutable
class AlbumWelcomeJourneyContent {
  /// Creates the welcome-spread content.
  const AlbumWelcomeJourneyContent({
    this.titleOverride,
    this.bodyOverride,
  });

  /// Optional override of the fixed title text.
  final String? titleOverride;

  /// Optional override of the fixed body text.
  final String? bodyOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumWelcomeJourneyContent &&
      other.titleOverride == titleOverride &&
      other.bodyOverride == bodyOverride;

  @override
  int get hashCode => Object.hash(titleOverride, bodyOverride);
}
