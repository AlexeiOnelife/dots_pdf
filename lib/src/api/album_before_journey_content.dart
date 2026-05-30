// Caller-supplied content for the "Antes de empezar el viaje"
// decorative-circles spread rendered by [DotsAlbumSpreadPage.beforeJourney].

import 'package:meta/meta.dart';

/// Content for the "Antes de empezar el viaje" decorative-circles
/// instruction spread. The factory selects per-category canonical
/// Spanish body copy from the source PDFs (pdf02 p.10 / pdf08 p.10 /
/// pdf10 p.8 / pdf04 p.8 / pdf06 p.3 / pdf12 p.3). The only caller
/// input is an optional [bodyOverride] for testing or localisation.
@immutable
class AlbumBeforeJourneyContent {
  /// Creates the spread content.
  const AlbumBeforeJourneyContent({this.bodyOverride});

  /// Optional override of the per-category canonical body text.
  final String? bodyOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumBeforeJourneyContent &&
      other.bodyOverride == bodyOverride;

  @override
  int get hashCode => bodyOverride.hashCode;
}
