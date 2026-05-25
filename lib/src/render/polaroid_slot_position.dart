import 'package:meta/meta.dart';

/// Geometric descriptor for one slot in a polaroid-collage spread.
///
/// Carries the same fields as [DotsPolaroidElement] minus [assetPath].
/// This is the "slot template" — geometry plus a pre-determined overlay
/// flag, but no photo. The factory zips a [List<String>] of photo paths
/// against a list of [PolaroidSlotPosition] entries to produce the
/// final [DotsPolaroidElement] instances.
///
/// All dimensional fields ([x], [y], [width], [height]) are in PDF points.
/// Use `mm * 2.834645669` to convert millimetres to points.
@immutable
class PolaroidSlotPosition {
  /// Creates a polaroid slot position.
  const PolaroidSlotPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.angleDegrees,
    this.gradientRtl = false,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  /// Horizontal position of the un-rotated outer frame, in PDF points.
  final double x;

  /// Vertical position of the un-rotated outer frame, in PDF points.
  final double y;

  /// Outer frame width in PDF points (typically 108 mm × _mmToPt ≈ 306.14 pt).
  final double width;

  /// Outer frame height in PDF points (typically 134 mm × _mmToPt ≈ 379.84 pt).
  final double height;

  /// Signed rotation angle in degrees. Positive = clockwise.
  final double angleDegrees;

  /// When `true`, the factory will set `gradientRtl: true` on the
  /// [DotsPolaroidElement] produced from this slot when the spread-level
  /// `applyOtrosGradient` flag is active.
  final bool gradientRtl;

  /// Whether the un-rotated frame extends into the bleed beyond its left edge.
  final bool bleedLeft;

  /// Whether the un-rotated frame extends into the bleed beyond its right edge.
  final bool bleedRight;

  /// Whether the un-rotated frame extends into the bleed above its top edge.
  final bool bleedTop;

  /// Whether the un-rotated frame extends into the bleed below its bottom edge.
  final bool bleedBottom;

  @override
  bool operator ==(Object other) =>
      other is PolaroidSlotPosition &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.angleDegrees == angleDegrees &&
      other.gradientRtl == gradientRtl &&
      other.bleedLeft == bleedLeft &&
      other.bleedRight == bleedRight &&
      other.bleedTop == bleedTop &&
      other.bleedBottom == bleedBottom;

  @override
  int get hashCode => Object.hash(
        x,
        y,
        width,
        height,
        angleDegrees,
        gradientRtl,
        bleedLeft,
        bleedRight,
        bleedTop,
        bleedBottom,
      );
}
