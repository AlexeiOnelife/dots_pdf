// Coverage table for the 14 decorative circles on the parejas/hijos cover page.
//
// Source: SPECS_album_types.md parejas p.4 table.
// Coordinates are in millimetres from the top-left of the 203 mm-wide page.
// The factory in DotsAlbumSpreadPage.cover() converts mm → pt using _mmToPt.
//
// This file is library-private: kCoverCircleLayout is NOT exported from
// lib/dots_pdf.dart.

// ignore_for_file: library_private_types_in_public_api

import 'package:meta/meta.dart';

@immutable
class _CoverCircleAnchor {
  const _CoverCircleAnchor({
    required this.diameterMm,
    required this.xMm,
    required this.yMm,
    this.bleedLeft = false,
    this.bleedRight = false,
    this.bleedTop = false,
    this.bleedBottom = false,
  });

  final double diameterMm;
  final double xMm;
  final double yMm;
  final bool bleedLeft;
  final bool bleedRight;
  final bool bleedTop;
  final bool bleedBottom;
}

/// Canonical 14-circle layout for the album cover page.
///
/// Diameter tiers: 47 mm (×5), 28 mm (×4), 16 mm (×5).
/// Color for all circles: `#CDE7F2`. GaussianFadeMm: 1.764.
///
/// Bleed flags are set for every circle whose bounding box exceeds the
/// 203 × 254 mm trim:
///   - Circle #3  (x=210, d=47) → right edge at 257 mm > 203 mm → bleedRight
///   - Circle #4  (x=-13, d=47) → left  edge at -13 mm < 0 mm   → bleedLeft
///   - Circle #5  (x=200, y=240, d=47) → right at 247 mm, bottom at 287 mm → bleedRight + bleedBottom
///   - Circle #2  (y=4, d=47) → top edge at 4 mm (spec assumption: bleedTop)
///   - Circle #9  (y=225, d=28) → bottom at 253 mm ≈ 254 mm trim → bleedBottom
///   - Circle #14 (y=273, d=16) → bottom at 289 mm > 254 mm    → bleedBottom
const List<_CoverCircleAnchor> kCoverCircleLayout = <_CoverCircleAnchor>[
  // ── 47 mm tier (5 circles) ─────────────────────────────────────────────────
  _CoverCircleAnchor(diameterMm: 47, xMm: 8, yMm: 43),
  _CoverCircleAnchor(diameterMm: 47, xMm: 141, yMm: 4, bleedTop: true),
  _CoverCircleAnchor(diameterMm: 47, xMm: 210, yMm: 33, bleedRight: true),
  _CoverCircleAnchor(diameterMm: 47, xMm: -13, yMm: 169, bleedLeft: true),
  _CoverCircleAnchor(
    diameterMm: 47,
    xMm: 200,
    yMm: 240,
    bleedRight: true,
    bleedBottom: true,
  ),

  // ── 28 mm tier (4 circles) ─────────────────────────────────────────────────
  _CoverCircleAnchor(diameterMm: 28, xMm: 36, yMm: 109),
  _CoverCircleAnchor(diameterMm: 28, xMm: 176, yMm: 91),
  _CoverCircleAnchor(diameterMm: 28, xMm: 49, yMm: 193),
  _CoverCircleAnchor(diameterMm: 28, xMm: 138, yMm: 225, bleedBottom: true),

  // ── 16 mm tier (5 circles) ─────────────────────────────────────────────────
  _CoverCircleAnchor(diameterMm: 16, xMm: 70, yMm: 48),
  _CoverCircleAnchor(diameterMm: 16, xMm: 124, yMm: 68),
  _CoverCircleAnchor(diameterMm: 16, xMm: 170, yMm: 140),
  _CoverCircleAnchor(diameterMm: 16, xMm: 109, yMm: 181),
  _CoverCircleAnchor(diameterMm: 16, xMm: 50, yMm: 273, bleedBottom: true),
];

// ---------------------------------------------------------------------------
// @visibleForTesting accessors
// Tests import this file directly; since _CoverCircleAnchor is private the
// fields are projected through named records so tests can assert without
// depending on the private class name.
// ---------------------------------------------------------------------------

/// Projected row for test inspection: diameter (mm), x (mm), y (mm), and the
/// four bleed flags. Exposed only for `cover_circles_test.dart`.
typedef CoverCircleAnchorForTest = ({
  double diameterMm,
  double xMm,
  double yMm,
  bool bleedLeft,
  bool bleedRight,
  bool bleedTop,
  bool bleedBottom,
});

/// Returns [kCoverCircleLayout] as an unmodifiable list of named records
/// so tests can inspect each anchor without coupling to the private
/// `_CoverCircleAnchor` class.
@visibleForTesting
List<CoverCircleAnchorForTest> get kCoverCircleLayoutForTest =>
    List<CoverCircleAnchorForTest>.unmodifiable(
      kCoverCircleLayout.map(
        (a) => (
          diameterMm: a.diameterMm,
          xMm: a.xMm,
          yMm: a.yMm,
          bleedLeft: a.bleedLeft,
          bleedRight: a.bleedRight,
          bleedTop: a.bleedTop,
          bleedBottom: a.bleedBottom,
        ),
      ),
    );
