// Layout table for the boda final p2 "photo halo" spread.
//
// Source: docs/specs/04-boda.md §final p2 — "Same 28-slot coordinate set as
// 02-pareja.md §final p2". Boda's final back matter matches the shared final:
// the photo halo is the 28-slot arrangement alone (no QR card, no title — the
// QR keep-alive is final p1; see DotsAlbumSpreadPage.closingQrSpread).
//
// A prior revision of this file modelled a stale "Boda de Nombre&Nombre"
// radial title spread (10 rotated photos + 2 oval QR cards + 3 title texts).
// That page does not exist in the current spec — boda inicial is the short
// three-page front matter (welcome, instructions, antes-cluster) and the boda
// final mirrors the shared final. The layout has been reconciled to the
// canonical 28-slot halo coordinate set per docs/specs/04-boda.md §final p2.
//
// Coordinates are in millimetres from the top-left of the spread artboard.
// All slots share diameter 44.45 mm (uniform — the spec lists slot
// coordinates only and does not vary the slot size), matching the shared
// photo-arc layout (see lib/src/render/photo_arc_layout.dart).
//
// This file is library-private: kBodaHaloLayout is NOT exported from
// lib/dots_pdf.dart.

// ignore_for_file: library_private_types_in_public_api

import 'package:meta/meta.dart';

@immutable
class _BodaHaloAnchor {
  const _BodaHaloAnchor({required this.xMm, required this.yMm});

  final double xMm;
  final double yMm;

  /// Uniform diameter for every halo photo. The spec
  /// (docs/specs/04-boda.md §final p2) lists slot coordinates only — it does
  /// not vary the slot size — so all 28 slots keep the established uniform
  /// value, matching the shared photo-arc layout.
  double get diameterMm => 44.45;
}

/// Canonical 28-slot layout for the boda final p2 photo halo spread.
///
/// All 28 entries use diameter 44.45 mm. Coordinates are in millimetres from
/// the top-left of the spread artboard. The factory
/// [DotsAlbumSpreadPage.bodaHalo] converts mm to PDF points at construction
/// time using `mm * 72 / 25.4`.
///
/// Per docs/specs/04-boda.md §final p2 this is the same 28-slot set as
/// docs/specs/02-pareja.md §final p2 (the shared photo arc/halo).
///
/// This list is library-private — it is consumed by
/// [DotsAlbumSpreadPage.bodaHalo] and MUST NOT be exported from
/// `lib/dots_pdf.dart`.
const List<_BodaHaloAnchor> kBodaHaloLayout = <_BodaHaloAnchor>[
  _BodaHaloAnchor(xMm: 390, yMm: 57),
  _BodaHaloAnchor(xMm: 362, yMm: 77),
  _BodaHaloAnchor(xMm: 338, yMm: 57),
  _BodaHaloAnchor(xMm: 307, yMm: 94),
  _BodaHaloAnchor(xMm: 266, yMm: 102),
  _BodaHaloAnchor(xMm: 236, yMm: 140),
  _BodaHaloAnchor(xMm: 202, yMm: 128),
  _BodaHaloAnchor(xMm: 205, yMm: 160),
  _BodaHaloAnchor(xMm: 137, yMm: 142),
  _BodaHaloAnchor(xMm: 149, yMm: 142),
  _BodaHaloAnchor(xMm: 163, yMm: 136),
  _BodaHaloAnchor(xMm: 165, yMm: 154),
  _BodaHaloAnchor(xMm: 182, yMm: 157),
  _BodaHaloAnchor(xMm: 177, yMm: 140),
  _BodaHaloAnchor(xMm: 185, yMm: 132),
  _BodaHaloAnchor(xMm: 241, yMm: 186),
  _BodaHaloAnchor(xMm: 389, yMm: 94),
  _BodaHaloAnchor(xMm: 348, yMm: 138),
  _BodaHaloAnchor(xMm: 310, yMm: 194),
  _BodaHaloAnchor(xMm: 271, yMm: 203),
  _BodaHaloAnchor(xMm: 291, yMm: 135),
  _BodaHaloAnchor(xMm: 266, yMm: 151),
  _BodaHaloAnchor(xMm: 307, yMm: 216),
  _BodaHaloAnchor(xMm: 348, yMm: 232),
  _BodaHaloAnchor(xMm: 395, yMm: 139),
  _BodaHaloAnchor(xMm: 369, yMm: 182),
  _BodaHaloAnchor(xMm: 391, yMm: 201),
  _BodaHaloAnchor(xMm: 389, yMm: 238),
];

// ---------------------------------------------------------------------------
// @visibleForTesting accessor
// Tests import this file directly; since _BodaHaloAnchor is private the
// fields are projected through named records so tests can assert without
// depending on the private class name.
// ---------------------------------------------------------------------------

/// Projected row for test inspection: x (mm), y (mm), diameter (mm).
/// Exposed only for `boda_halo_layout_test.dart`.
typedef BodaHaloAnchorForTest = ({
  double xMm,
  double yMm,
  double diameterMm,
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
          diameterMm: a.diameterMm,
        ),
      ),
    );
