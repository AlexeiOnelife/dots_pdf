// Caller-supplied content for the deferred boda cover factory
// introduced by Task 2 of the `final-render-refinement` series.

import 'package:meta/meta.dart';

/// Stub content class for the deferred boda cover (Task 6).
///
/// The boda cover layout is deferred per the existing album-type series
/// memo: boda p.1/p.2/p.5 lack coordinate extraction. Today the class
/// exists only so the factory signature is stable and downstream code
/// can declare typed inputs; when Task 6 unfreezes boda coordinates,
/// the fields will be tightened.
@immutable
class AlbumBodaCoverContent {
  /// Creates the (deferred) boda cover content.
  const AlbumBodaCoverContent({
    this.title,
    this.dateLine,
  });

  /// Optional title text for the future boda cover layout.
  final String? title;

  /// Optional date line for the future boda cover layout.
  final String? dateLine;

  @override
  bool operator ==(Object other) =>
      other is AlbumBodaCoverContent &&
      other.title == title &&
      other.dateLine == dateLine;

  @override
  int get hashCode => Object.hash(title, dateLine);
}
