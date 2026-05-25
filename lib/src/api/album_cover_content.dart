import 'package:meta/meta.dart';

/// Immutable value object that describes the text content for an album
/// cover page.
///
/// Pass an instance to [buildCoverPageFor] or directly to
/// [DotsAlbumSpreadPage.cover] to produce a [DotsAlbumSpreadPage].
///
/// [eyebrowOverride] — when non-null, overrides the per-type default eyebrow
/// string. When null, the factory resolves the default:
///   - [DotsAlbumType.parejas] → `"DOTBOOK"`
///   - [DotsAlbumType.hijos]   → `"DOTBOOK DE {NOMBREHIJO}"`
@immutable
class AlbumCoverContent {
  /// Creates an [AlbumCoverContent].
  const AlbumCoverContent({
    required this.title,
    required this.dateLine,
    this.eyebrowOverride,
  });

  /// Album title string shown in the centre of the cover.
  final String title;

  /// Date-range string shown below the title (e.g. `"01/01/2024 | 31/12/2024"`).
  final String dateLine;

  /// When non-null, overrides the per-type default eyebrow label.
  final String? eyebrowOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumCoverContent &&
      other.title == title &&
      other.dateLine == dateLine &&
      other.eyebrowOverride == eyebrowOverride;

  @override
  int get hashCode => Object.hash(title, dateLine, eyebrowOverride);
}
