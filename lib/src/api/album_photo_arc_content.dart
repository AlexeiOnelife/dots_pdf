import 'package:meta/meta.dart';

/// Immutable value object that describes the photo content and optional
/// settings for a photo-arc spread ("Un año lleno de recuerdos").
///
/// Pass an instance to [buildPhotoArcPageFor] or directly to
/// [DotsAlbumSpreadPage.photoArc] to produce a [DotsAlbumSpreadPage].
///
/// [photoPaths] must have exactly 10 entries (one per arc circle slot).
/// A [RangeError] is thrown by the factory when the length differs.
///
/// [title] defaults to `"Un año lleno de recuerdos"` when not provided.
///
/// [qrCaptionLeftOverride] and [qrCaptionRightOverride] — when non-null,
/// these win over the per-type caption defaults resolved by the builder.
@immutable
class AlbumPhotoArcContent {
  /// Creates an [AlbumPhotoArcContent].
  const AlbumPhotoArcContent({
    required this.photoPaths,
    required this.qrPayloadLeft,
    required this.qrPayloadRight,
    required this.dateSubtitle,
    this.title = 'Un año lleno de recuerdos',
    this.qrCaptionLeftOverride,
    this.qrCaptionRightOverride,
  });

  /// Ordered list of photo asset paths; one per arc circle slot (exactly 10).
  final List<String> photoPaths;

  /// QR code payload for the left oval QR card (typically a URL).
  final String qrPayloadLeft;

  /// QR code payload for the right oval QR card (typically a URL).
  final String qrPayloadRight;

  /// Date subtitle text rendered below the spread title.
  final String dateSubtitle;

  /// Spread title text. Defaults to `"Un año lleno de recuerdos"`.
  final String title;

  /// Optional override for the left QR card caption.
  ///
  /// When non-null, wins over the per-type default resolved by the builder.
  final String? qrCaptionLeftOverride;

  /// Optional override for the right QR card caption.
  ///
  /// When non-null, wins over the per-type default resolved by the builder.
  final String? qrCaptionRightOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumPhotoArcContent &&
      _listEquals(other.photoPaths, photoPaths) &&
      other.qrPayloadLeft == qrPayloadLeft &&
      other.qrPayloadRight == qrPayloadRight &&
      other.dateSubtitle == dateSubtitle &&
      other.title == title &&
      other.qrCaptionLeftOverride == qrCaptionLeftOverride &&
      other.qrCaptionRightOverride == qrCaptionRightOverride;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(photoPaths),
        qrPayloadLeft,
        qrPayloadRight,
        dateSubtitle,
        title,
        qrCaptionLeftOverride,
        qrCaptionRightOverride,
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
