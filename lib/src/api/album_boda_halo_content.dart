import 'package:meta/meta.dart';

/// Immutable value object that describes the photo content and optional
/// settings for the boda-halo spread ("Boda de Nombre&Nombre" title spread,
/// boda p.4).
///
/// Pass an instance to [buildBodaHaloPageFor] or directly to
/// [DotsAlbumSpreadPage.bodaHalo] to produce a [DotsAlbumSpreadPage].
///
/// [photoPaths] must have exactly 10 entries (one per halo radial slot).
/// A [RangeError] is thrown by the factory when the length differs.
///
/// [titleLine1] defaults to `"Boda de"` when not provided.
/// [titleLine2] is required (e.g. `"Ana & Luis"`).
///
/// [qrCaptionLeftOverride] and [qrCaptionRightOverride] — when non-null,
/// these win over the per-type caption defaults resolved by the builder.
@immutable
class AlbumBodaHaloContent {
  /// Creates an [AlbumBodaHaloContent].
  const AlbumBodaHaloContent({
    required this.photoPaths,
    required this.titleLine2,
    required this.dateSubtitle,
    required this.qrPayloadLeft,
    required this.qrPayloadRight,
    this.titleLine1 = 'Boda de',
    this.qrCaptionLeftOverride,
    this.qrCaptionRightOverride,
  });

  /// Ordered list of photo asset paths; one per halo radial slot (exactly 10).
  final List<String> photoPaths;

  /// First title line. Defaults to `"Boda de"`.
  final String titleLine1;

  /// Second title line (e.g. `"Ana & Luis"`).
  final String titleLine2;

  /// Date subtitle text rendered below the title.
  final String dateSubtitle;

  /// QR code payload for the left oval QR card (typically a URL).
  final String qrPayloadLeft;

  /// QR code payload for the right oval QR card (typically a URL).
  final String qrPayloadRight;

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
      other is AlbumBodaHaloContent &&
      _listEquals(other.photoPaths, photoPaths) &&
      other.titleLine1 == titleLine1 &&
      other.titleLine2 == titleLine2 &&
      other.dateSubtitle == dateSubtitle &&
      other.qrPayloadLeft == qrPayloadLeft &&
      other.qrPayloadRight == qrPayloadRight &&
      other.qrCaptionLeftOverride == qrCaptionLeftOverride &&
      other.qrCaptionRightOverride == qrCaptionRightOverride;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(photoPaths),
        titleLine1,
        titleLine2,
        dateSubtitle,
        qrPayloadLeft,
        qrPayloadRight,
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
