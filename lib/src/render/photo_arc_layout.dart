// Layout table for the 10 photo circles on the photo-arc spread page.
//
// Source: parejas p.9 table. Coordinates are in millimetres from the
// top-left of the 406 mm-wide spread. All circles share diameter 44.45 mm
// (uniform — locked by slice 1 decision).
//
// This file is library-private: kPhotoArcLayout is NOT exported from
// lib/dots_pdf.dart.

// ignore_for_file: library_private_types_in_public_api

import 'package:meta/meta.dart';

@immutable
class _PhotoArcAnchor {
  const _PhotoArcAnchor({required this.xMm, required this.yMm});

  final double xMm;
  final double yMm;

  /// Uniform diameter for every arc photo per slice-1 user decision.
  /// Not a constructor parameter — the spec locks all 10 circles to
  /// this value; varying it per-anchor is not supported.
  double get diameterMm => 44.45;
}

/// Canonical 10-circle layout for the photo-arc spread page.
///
/// All 10 entries use diameter 44.45 mm. Coordinates are in millimetres
/// from the top-left of the 406 × 254 mm spread. The factory converts mm
/// to PDF points at construction time using `mm * 72 / 25.4`.
///
/// This list is library-private — it is consumed by
/// [DotsAlbumSpreadPage.photoArc] and must NOT be exported from
/// `lib/dots_pdf.dart`.
// All 10 anchors use the spec-mandated uniform 44.45 mm diameter (the default
// on `_PhotoArcAnchor`). Listing it on each entry would be redundant.
const List<_PhotoArcAnchor> kPhotoArcLayout = <_PhotoArcAnchor>[
  _PhotoArcAnchor(xMm: 29.59, yMm: 273.28),
  _PhotoArcAnchor(xMm: 376.17, yMm: 273.28),
  _PhotoArcAnchor(xMm: 45.09, yMm: 224.02),
  _PhotoArcAnchor(xMm: 360.66, yMm: 224.02),
  _PhotoArcAnchor(xMm: 77.97, yMm: 180.93),
  _PhotoArcAnchor(xMm: 327.79, yMm: 180.93),
  _PhotoArcAnchor(xMm: 120.96, yMm: 150.11),
  _PhotoArcAnchor(xMm: 284.79, yMm: 150.11),
  _PhotoArcAnchor(xMm: 171.04, yMm: 134.01),
  _PhotoArcAnchor(xMm: 234.72, yMm: 134.01),
];

// ---------------------------------------------------------------------------
// @visibleForTesting accessor
// Tests import this file directly; since _PhotoArcAnchor is private the
// fields are projected through named records so tests can assert without
// depending on the private class name.
// ---------------------------------------------------------------------------

/// Projected row for test inspection: x (mm), y (mm), diameter (mm).
/// Exposed only for `photo_arc_layout_test.dart`.
typedef PhotoArcAnchorForTest = ({
  double xMm,
  double yMm,
  double diameterMm,
});

/// Returns [kPhotoArcLayout] as an unmodifiable list of named records so
/// tests can inspect each anchor without coupling to the private
/// [_PhotoArcAnchor] class.
@visibleForTesting
List<PhotoArcAnchorForTest> get kPhotoArcLayoutForTest =>
    List<PhotoArcAnchorForTest>.unmodifiable(
      kPhotoArcLayout.map(
        (a) => (
          xMm: a.xMm,
          yMm: a.yMm,
          diameterMm: a.diameterMm,
        ),
      ),
    );
