// Layout table for the 7 photo cluster slots on the boda-cluster spread page
// (boda p.3 "Antes de empezar el viaje").
//
// Source: extracted_coordinates.md §1. Coordinates are right-page-relative
// (gutter = x 0). The factory [DotsAlbumSpreadPage.bodaCluster] translates
// to spread coordinates by adding 203 mm to each x value.
//
// This file is library-private: kBodaClusterLayout is NOT exported from
// lib/dots_pdf.dart.

// ignore_for_file: library_private_types_in_public_api

import 'package:meta/meta.dart';

import '../config/dots_template.dart';

@immutable
class _BodaClusterAnchor {
  const _BodaClusterAnchor({
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.opacityGradientStart = 1.0,
    this.opacityGradientEnd = 1.0,
    this.opacityGradientDirection = DotsGradientDirection.topToBottom,
    this.bleedTop = false,
  });

  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;

  /// Opacity at the gradient start edge (1.0 = full opacity).
  final double opacityGradientStart;

  /// Opacity at the gradient end edge.
  final double opacityGradientEnd;

  /// Direction the opacity gradient runs.
  final DotsGradientDirection opacityGradientDirection;

  /// Whether the slot extends into the bleed above its top edge.
  /// True only for slot 1 (y = −7.8 mm above trim).
  final bool bleedTop;

  /// All slots share the same Gaussian fade width (spec: 1.764 mm).
  double get gaussianFadeMm => 1.764;
}

/// Canonical 7-slot layout for the boda-cluster spread page.
///
/// Coordinates are right-page-relative (gutter = x 0, mm). The factory
/// [DotsAlbumSpreadPage.bodaCluster] adds 203 mm to each [_BodaClusterAnchor.xMm]
/// when composing spread-relative [DotsClusterPhotoElement] instances.
///
/// Slot 1 has `bleedTop: true` because y = −7.8 mm extends above the trim
/// edge. All other slots are within the trim.
///
/// This list is library-private — consumed by [DotsAlbumSpreadPage.bodaCluster]
/// and MUST NOT be exported from `lib/dots_pdf.dart`.
const List<_BodaClusterAnchor> kBodaClusterLayout = <_BodaClusterAnchor>[
  // Slot 1: bleeds above trim; gradient bottomToTop 100 %→10 %
  _BodaClusterAnchor(
    xMm: 94.6,
    yMm: -7.8,
    widthMm: 27.5,
    heightMm: 33.9,
    opacityGradientStart: 1.0,
    opacityGradientEnd: 0.1,
    opacityGradientDirection: DotsGradientDirection.bottomToTop,
    bleedTop: true,
  ),
  // Slot 2: no gradient (full opacity)
  _BodaClusterAnchor(
    xMm: 86.3,
    yMm: 59.6,
    widthMm: 5.0,
    heightMm: 5.8,
  ),
  // Slot 3: no gradient (full opacity)
  _BodaClusterAnchor(
    xMm: 90.0,
    yMm: 31.4,
    widthMm: 20.3,
    heightMm: 24.7,
  ),
  // Slot 4: no gradient (full opacity)
  _BodaClusterAnchor(
    xMm: 87.4,
    yMm: 71.3,
    widthMm: 12.8,
    heightMm: 15.2,
  ),
  // Slot 5: gradient topToBottom 100 %→30 %
  _BodaClusterAnchor(
    xMm: 103.1,
    yMm: 88.9,
    widthMm: 13.7,
    heightMm: 16.2,
    opacityGradientStart: 1.0,
    opacityGradientEnd: 0.3,
  ),
  // Slot 6: gradient topToBottom 100 %→30 %
  _BodaClusterAnchor(
    xMm: 90.4,
    yMm: 103.3,
    widthMm: 9.0,
    heightMm: 10.6,
    opacityGradientStart: 1.0,
    opacityGradientEnd: 0.3,
  ),
  // Slot 7: gradient topToBottom 100 %→0 %
  _BodaClusterAnchor(
    xMm: 103.1,
    yMm: 116.6,
    widthMm: 7.8,
    heightMm: 9.2,
    opacityGradientStart: 1.0,
    opacityGradientEnd: 0.0,
  ),
];

// ---------------------------------------------------------------------------
// @visibleForTesting accessor
// Tests import this file directly; since _BodaClusterAnchor is private the
// fields are projected through named records so tests can assert without
// depending on the private class name.
// ---------------------------------------------------------------------------

/// Projected row for test inspection.
/// Exposed only for `boda_cluster_layout_test.dart`.
typedef BodaClusterAnchorForTest = ({
  double xMm,
  double yMm,
  double widthMm,
  double heightMm,
  double opacityGradientStart,
  double opacityGradientEnd,
  DotsGradientDirection opacityGradientDirection,
  bool bleedTop,
  double gaussianFadeMm,
});

/// Returns [kBodaClusterLayout] as an unmodifiable list of named records so
/// tests can inspect each anchor without coupling to the private
/// [_BodaClusterAnchor] class.
@visibleForTesting
List<BodaClusterAnchorForTest> get kBodaClusterLayoutForTest =>
    List<BodaClusterAnchorForTest>.unmodifiable(
      kBodaClusterLayout.map(
        (a) => (
          xMm: a.xMm,
          yMm: a.yMm,
          widthMm: a.widthMm,
          heightMm: a.heightMm,
          opacityGradientStart: a.opacityGradientStart,
          opacityGradientEnd: a.opacityGradientEnd,
          opacityGradientDirection: a.opacityGradientDirection,
          bleedTop: a.bleedTop,
          gaussianFadeMm: a.gaussianFadeMm,
        ),
      ),
    );
