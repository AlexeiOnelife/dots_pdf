import 'package:meta/meta.dart';

import '../render/polaroid_slot_position.dart';

/// Immutable value object that describes the photo content and optional
/// settings for a polaroid-collage spread.
///
/// Pass an instance to [buildPolaroidCollagePageFor] or directly to
/// [DotsAlbumSpreadPage.polaroidCollage] to produce a
/// [DotsAlbumSpreadPage].
///
/// [photoPaths] must have exactly `kDefaultPolaroidSlots.length +
/// additionalSlots.length` entries; a [RangeError] is thrown otherwise.
///
/// [applyOtrosGradient] — when `true`, the slot at index 1 (polar-2)
/// carries a right-to-left opacity gradient. Intended for the `otros`
/// album type's p.6 bottom-left slot.
///
/// [additionalSlots] — optional caller-supplied slot positions appended
/// after the 6 default slots. Entries are matched in order against
/// `photoPaths[6:]`.
@immutable
class AlbumCollageContent {
  /// Creates an [AlbumCollageContent].
  const AlbumCollageContent({
    required this.photoPaths,
    this.applyOtrosGradient = false,
    this.additionalSlots = const <PolaroidSlotPosition>[],
  });

  /// Ordered list of photo asset paths; one per slot.
  final List<String> photoPaths;

  /// When `true`, the polar-2 slot carries `gradientRtl: true`.
  final bool applyOtrosGradient;

  /// Optional extra slot positions appended after the 6 default slots.
  final List<PolaroidSlotPosition> additionalSlots;

  @override
  bool operator ==(Object other) =>
      other is AlbumCollageContent &&
      _listEquals(other.photoPaths, photoPaths) &&
      other.applyOtrosGradient == applyOtrosGradient &&
      _listEquals(other.additionalSlots, additionalSlots);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(photoPaths),
        applyOtrosGradient,
        Object.hashAll(additionalSlots),
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
