import 'package:meta/meta.dart';

/// Payload for a dedication page.
@immutable
class DedicationContent {
  /// Creates a dedication page payload.
  const DedicationContent({
    required this.title,
    required this.body,
    required this.signature,
  });

  /// Title text, rendered in P22 Mackinac Medium 23pt.
  final String title;

  /// Body text, rendered in Inter Book 9pt within a 102mm column.
  final String body;

  /// Signature text, rendered rotated 2° in Biro Script Plus 12pt.
  ///
  /// When empty, no rotated element is added to the page.
  final String signature;

  @override
  bool operator ==(Object other) =>
      other is DedicationContent &&
      other.title == title &&
      other.body == body &&
      other.signature == signature;

  @override
  int get hashCode => Object.hash(title, body, signature);
}

/// Payload for a closing page.
@immutable
class ClosingContent {
  /// Creates a closing page payload.
  const ClosingContent({
    required this.photoPath,
    required this.title,
    required this.subtitle,
  });

  /// Path or asset key for the main photo slot (66×86 mm).
  ///
  /// When `null`, the photo slot is omitted; the page still renders
  /// title and subtitle without error.
  final String? photoPath;

  /// Title text. Font size is 12pt for [DotsAlbumType.boda] and 20pt
  /// for all other types; resolved by [DotsAlbumSpreadPage.closing].
  final String title;

  /// Subtitle text, rendered in P22 Mackinac Book 9pt.
  final String subtitle;

  @override
  bool operator ==(Object other) =>
      other is ClosingContent &&
      other.photoPath == photoPath &&
      other.title == title &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(photoPath, title, subtitle);
}

/// Immutable value object carrying optional dedication and closing page
/// payloads for an album type's simple-pages section.
///
/// Both pages are optional. Pass `null` for pages the caller does not
/// want to emit; [buildSimplePagesFor] skips absent pages automatically.
@immutable
class AlbumSimpleContent {
  /// Creates an album simple content.
  const AlbumSimpleContent({
    this.dedication,
    this.closing,
  });

  /// Dedication-page payload. When `null`, no dedication page is emitted.
  final DedicationContent? dedication;

  /// Closing-page payload. When `null`, no closing page is emitted.
  final ClosingContent? closing;

  @override
  bool operator ==(Object other) =>
      other is AlbumSimpleContent &&
      other.dedication == dedication &&
      other.closing == closing;

  @override
  int get hashCode => Object.hash(dedication, closing);
}
