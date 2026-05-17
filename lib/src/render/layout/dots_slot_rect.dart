import 'package:meta/meta.dart';

/// Kind of content a [DotsSlotRect] is intended to receive.
enum DotsSlotKind {
  /// A photographic image slot. Receives a `DotsPhotoSlot`-style image.
  photo,

  /// Caption title text run (P22 Mackinac medium, layout-specific size).
  captionTitle,

  /// Caption date / subtitle text run (P22 Mackinac, 9 - 11 pt).
  captionDate,

  /// Caption body text run (Inter Book 9 pt).
  captionBody,

  /// QR card container slot (stroke + inner box for the QR icon).
  qrCard,
}

/// A typed rectangle on an interior page, in millimeters.
///
/// Coordinates are page-origin (top-left = 0, 0). Bleed flags mark which
/// edges of the slot extend 3 mm beyond the trim and must be drawn with
/// the page's bleed allowance; flags are layout-driven (see
/// `docs/templates/SPECS_interior.md` "Crop / fill / bleed rules").
@immutable
class DotsSlotRect {
  /// Creates a slot rectangle.
  const DotsSlotRect({
    required this.kind,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.bleedTop = false,
    this.bleedBottom = false,
    this.bleedLeft = false,
    this.bleedRight = false,
  });

  /// Kind of content this slot accepts.
  final DotsSlotKind kind;

  /// Left edge of the slot in millimeters, measured from the page's
  /// top-left origin.
  final double xMm;

  /// Top edge of the slot in millimeters, measured from the page's
  /// top-left origin.
  final double yMm;

  /// Slot width in millimeters (inside trim; bleed extends beyond when
  /// the corresponding flag is set).
  final double widthMm;

  /// Slot height in millimeters (inside trim; bleed extends beyond when
  /// the corresponding flag is set).
  final double heightMm;

  /// Whether the slot bleeds 3 mm past the trim on the top edge.
  final bool bleedTop;

  /// Whether the slot bleeds 3 mm past the trim on the bottom edge.
  final bool bleedBottom;

  /// Whether the slot bleeds 3 mm past the trim on the left edge.
  final bool bleedLeft;

  /// Whether the slot bleeds 3 mm past the trim on the right edge.
  final bool bleedRight;

  @override
  bool operator ==(Object other) =>
      other is DotsSlotRect &&
      other.kind == kind &&
      other.xMm == xMm &&
      other.yMm == yMm &&
      other.widthMm == widthMm &&
      other.heightMm == heightMm &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight;

  @override
  int get hashCode => Object.hash(
        kind,
        xMm,
        yMm,
        widthMm,
        heightMm,
        bleedTop,
        bleedBottom,
        bleedLeft,
        bleedRight,
      );
}
