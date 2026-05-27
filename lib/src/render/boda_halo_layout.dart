// Layout table for the 10 rotated photo slots on the boda-halo spread page
// (boda p.4 "Boda de Nombre&Nombre" radial halo title spread).
//
// Source: extracted_coordinates.md §2 (AABB positions) converted to unrotated
// top-left coords via center-preserving rotation arithmetic (design D1):
//
//   center      = (aabbX + aabbW/2, aabbY + aabbH/2)
//   unrotatedTL = (center_x − widthMm/2, center_y − heightMm/2)
//
// Confidence: MEDIUM (±0.5 mm). Deferred follow-up to verify against the
// InDesign/Illustrator source (Q3). The InDesign anchor (x = 37.477 mm,
// y = 50.388 mm) cannot be matched to the PDF content stream; this discrepancy
// is documented here pending access to the source file.
//
// This file is library-private: kBodaHaloLayout is NOT exported from
// lib/dots_pdf.dart.

// ignore_for_file: library_private_types_in_public_api

import 'package:meta/meta.dart';

@immutable
class _BodaHaloAnchor {
  const _BodaHaloAnchor({
    required this.xMm,
    required this.yMm,
    required this.angleDegrees,
    this.bleedBottom = false,
  });

  final double xMm;
  final double yMm;
  final double angleDegrees;
  final bool bleedBottom;

  /// Uniform unrotated width for every halo photo (33.5 mm = 95.0 pt).
  static const double widthMm = 33.5;

  /// Uniform unrotated height for every halo photo (46.4 mm = 131.4 pt).
  static const double heightMm = 46.4;
}

/// Canonical 10-slot layout for the boda-halo spread page.
///
/// Each entry stores the **unrotated** top-left (xMm, yMm) in mm, a signed
/// [angleDegrees], and a [bleedBottom] flag.
///
/// All 10 slots share uniform unrotated dimensions:
///   - width  = 33.5 mm ([_BodaHaloAnchor.widthMm])
///   - height = 46.4 mm ([_BodaHaloAnchor.heightMm])
///
/// Indices 0–4 are right-page-relative (R1–R5, positive angles).
/// Indices 5–9 are left-page-relative (L1–L5, negative angles).
/// The factory [DotsAlbumSpreadPage.bodaHalo] adds 203 mm to R-slot x values
/// when composing spread-relative [DotsRotatedPhotoElement] instances.
///
/// Slots at indices 4 (R5) and 9 (L5) have [bleedBottom] = true because
/// they extend below the 254 mm page trim; [pw.Stack] does not clip, so
/// this flag is informational only.
///
/// **Confidence: MEDIUM.** Coords derived from PDF content-stream AABBs ±0.5 mm.
/// Deferred InDesign source verification per open question Q3.
///
/// This list is library-private — consumed by [DotsAlbumSpreadPage.bodaHalo]
/// and MUST NOT be exported from `lib/dots_pdf.dart`.
const List<_BodaHaloAnchor> kBodaHaloLayout = <_BodaHaloAnchor>[
  // R1 — right page, slot 1
  _BodaHaloAnchor(xMm: 15.30, yMm: 94.95, angleDegrees: 3.2),
  // R2 — right page, slot 2
  _BodaHaloAnchor(xMm: 63.30, yMm: 111.30, angleDegrees: 20.7),
  // R3 — right page, slot 3
  _BodaHaloAnchor(xMm: 104.75, yMm: 141.00, angleDegrees: 37.2),
  // R4 — right page, slot 4
  _BodaHaloAnchor(xMm: 134.00, yMm: 181.90, angleDegrees: 55.2),
  // R5 — right page, slot 5 (bleedBottom: extends below trim)
  _BodaHaloAnchor(xMm: 151.80, yMm: 228.75, angleDegrees: 68.3, bleedBottom: true),
  // L1 — left page, slot 1
  _BodaHaloAnchor(xMm: 154.30, yMm: 94.20, angleDegrees: -3.2),
  // L2 — left page, slot 2
  _BodaHaloAnchor(xMm: 118.90, yMm: 108.80, angleDegrees: -20.7),
  // L3 — left page, slot 3
  _BodaHaloAnchor(xMm: 76.55, yMm: 138.50, angleDegrees: -37.2),
  // L4 — left page, slot 4
  _BodaHaloAnchor(xMm: 25.50, yMm: 179.10, angleDegrees: -55.2),
  // L5 — left page, slot 5 (bleedBottom: extends below trim)
  _BodaHaloAnchor(xMm: 17.90, yMm: 230.30, angleDegrees: -68.3, bleedBottom: true),
];

// ---------------------------------------------------------------------------
// @visibleForTesting accessor
// Tests import this file directly; since _BodaHaloAnchor is private the
// fields are projected through named records so tests can assert without
// depending on the private class name.
// ---------------------------------------------------------------------------

/// Projected row for test inspection.
/// Exposed only for `boda_halo_layout_test.dart`.
typedef BodaHaloAnchorForTest = ({
  double xMm,
  double yMm,
  double angleDegrees,
  bool bleedBottom,
  double widthMm,
  double heightMm,
});

/// Returns [kBodaHaloLayout] as an unmodifiable list of named records so
/// tests can inspect each anchor without coupling to the private
/// [_BodaHaloAnchor] class.
@visibleForTesting
List<BodaHaloAnchorForTest> get kBodaHaloLayoutForTest =>
    List<BodaHaloAnchorForTest>.unmodifiable(
      kBodaHaloLayout.map(
        (a) => (
          xMm: a.xMm,
          yMm: a.yMm,
          angleDegrees: a.angleDegrees,
          bleedBottom: a.bleedBottom,
          widthMm: _BodaHaloAnchor.widthMm,
          heightMm: _BodaHaloAnchor.heightMm,
        ),
      ),
    );
