// Layout table for the photo arc/halo on the final p2 spread.
//
// Source: docs/specs/02-pareja.md §final p2 (shared with 03-otros, 05-hijos,
// 06-individual and 04-boda / 07-general-eventos §final p2 — the same 28-slot
// coordinate set). Coordinates are in millimetres from the top-left of the
// spread artboard. All slots share diameter 44.45 mm (uniform — the spec
// does not vary the slot size, so the prior uniform value is preserved).
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

  /// Uniform diameter for every arc photo. The spec (docs/specs/02-pareja.md
  /// §final p2) lists slot coordinates only — it does not vary the slot size —
  /// so all 28 slots keep the established uniform value. Not a constructor
  /// parameter: varying it per-anchor is not supported.
  double get diameterMm => 44.45;
}

/// Canonical 28-slot layout for the final p2 photo arc/halo spread.
///
/// All 28 entries use diameter 44.45 mm. Coordinates are in millimetres from
/// the top-left of the spread artboard. The factory converts mm to PDF points
/// at construction time using `mm * 72 / 25.4`.
///
/// This list is library-private — it is consumed by
/// [DotsAlbumSpreadPage.photoArc] and must NOT be exported from
/// `lib/dots_pdf.dart`.
// All 28 anchors use the spec-mandated uniform 44.45 mm diameter (the default
// on `_PhotoArcAnchor`). Listing it on each entry would be redundant.
const List<_PhotoArcAnchor> kPhotoArcLayout = <_PhotoArcAnchor>[
  _PhotoArcAnchor(xMm: 390, yMm: 57),
  _PhotoArcAnchor(xMm: 362, yMm: 77),
  _PhotoArcAnchor(xMm: 338, yMm: 57),
  _PhotoArcAnchor(xMm: 307, yMm: 94),
  _PhotoArcAnchor(xMm: 266, yMm: 102),
  _PhotoArcAnchor(xMm: 236, yMm: 140),
  _PhotoArcAnchor(xMm: 202, yMm: 128),
  _PhotoArcAnchor(xMm: 205, yMm: 160),
  _PhotoArcAnchor(xMm: 137, yMm: 142),
  _PhotoArcAnchor(xMm: 149, yMm: 142),
  _PhotoArcAnchor(xMm: 163, yMm: 136),
  _PhotoArcAnchor(xMm: 165, yMm: 154),
  _PhotoArcAnchor(xMm: 182, yMm: 157),
  _PhotoArcAnchor(xMm: 177, yMm: 140),
  _PhotoArcAnchor(xMm: 185, yMm: 132),
  _PhotoArcAnchor(xMm: 241, yMm: 186),
  _PhotoArcAnchor(xMm: 389, yMm: 94),
  _PhotoArcAnchor(xMm: 348, yMm: 138),
  _PhotoArcAnchor(xMm: 310, yMm: 194),
  _PhotoArcAnchor(xMm: 271, yMm: 203),
  _PhotoArcAnchor(xMm: 291, yMm: 135),
  _PhotoArcAnchor(xMm: 266, yMm: 151),
  _PhotoArcAnchor(xMm: 307, yMm: 216),
  _PhotoArcAnchor(xMm: 348, yMm: 232),
  _PhotoArcAnchor(xMm: 395, yMm: 139),
  _PhotoArcAnchor(xMm: 369, yMm: 182),
  _PhotoArcAnchor(xMm: 391, yMm: 201),
  _PhotoArcAnchor(xMm: 389, yMm: 238),
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
