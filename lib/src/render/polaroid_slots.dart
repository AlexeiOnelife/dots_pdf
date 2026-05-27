import 'polaroid_slot_position.dart';

/// Millimetres → PDF points (1 pt = 1/72 inch; 1 inch = 25.4 mm).
const double _mmToPt = 2.834645669;

/// Outer frame width in PDF points (108 mm).
const double _outerWidthPt = 108.0 * _mmToPt; // ~306.14 pt

/// Outer frame height in PDF points (134 mm).
const double _outerHeightPt = 134.0 * _mmToPt; // ~379.84 pt

/// The 6 documented slot positions for the polaroid-collage spread.
///
/// Order is significant — entries are zipped against the caller-supplied
/// photo paths in that order: polar-1 first, then polar-2, …, polar-6.
///
/// Confidence levels (see `docs/templates/extracted_coordinates.md` § 3):
/// - polar-1: MEDIUM (spec callout + shear cross-check ✓)
/// - polar-2: MEDIUM (bleeds off left page edge at +8°); [bleedLeft] = true
/// - polar-3: MEDIUM (spread x midpoint, shear cross-check ✓)
/// - polar-4: LOW (±2 mm visual drift; "85 mm from bottom" ≈ y_top = 35 mm)
/// - polar-5: MEDIUM (spec callouts confirmed)
/// - polar-6: LOW geometry; rotation UNKNOWN → shipped as 0°
///
/// **polar-4 note**: the spec states "bottom y at 85 mm from bottom" which
/// translates to `y_top = 254 − 85 − 134 = 35 mm` from the top trim edge.
/// Render appearance suggests the slot may sit ~6 mm lower due to rotation
/// of a −2.5° frame. LOW confidence; a follow-up measurement pass can
/// correct this.
///
/// **polar-6 note**: rotation is UNKNOWN in the extracted coordinates table.
/// Shipped as 0° — the only defensible default when no callout is available.
/// A follow-up measurement from the source InDesign file can correct this.
const List<PolaroidSlotPosition> kDefaultPolaroidSlots =
    <PolaroidSlotPosition>[
  // polar-1 — L-top-near-gutter
  PolaroidSlotPosition(
    x: 21.0 * _mmToPt,
    y: 18.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -2.5,
  ),
  // polar-2 — L-bottom; bleeds off left page edge at +8°
  PolaroidSlotPosition(
    x: 0.0,
    y: 120.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 8.0,
    bleedLeft: true,
  ),
  // polar-3 — center-top (straddles gutter, ~5 mm on left page)
  PolaroidSlotPosition(
    x: -5.0 * _mmToPt,
    y: 18.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 4.0,
  ),
  // polar-4 — center-bottom (LOW confidence; see dartdoc above)
  PolaroidSlotPosition(
    x: -5.0 * _mmToPt,
    y: 35.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -2.5,
  ),
  // polar-5 — R-top
  PolaroidSlotPosition(
    x: 48.5 * _mmToPt,
    y: 69.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: -3.5,
  ),
  // polar-6 — R-bottom (LOW confidence; rotation UNKNOWN → 0°; see dartdoc)
  PolaroidSlotPosition(
    x: 95.0 * _mmToPt,
    y: 120.0 * _mmToPt,
    width: _outerWidthPt,
    height: _outerHeightPt,
    angleDegrees: 0.0,
  ),
];
