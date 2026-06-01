// Caller-supplied content for the shared "Porque algunos recuerdos
// merecen seguir vivos" QR spread introduced by Task 2 of the
// `final-render-refinement` series.

import 'package:meta/meta.dart';

/// Identifies whether an [AlbumQrSpreadContent] is used as the opening
/// spread (generalEventos only) or the closing spread (all categories).
///
/// The two placements share the same content shape but render different
/// visual layouts.
enum AlbumQrSpreadPlacement {
  /// Opening spread — used as initial pliego 1 of the `generalEventos`
  /// category. Visual layout differs from the closing variant: QR block
  /// sits on the LEFT page, decorative circles on the RIGHT.
  opening,

  /// Closing spread — used as the penultimate pliego of EVERY category.
  /// Visual layout: QR block on the left page, decorative circles on the
  /// right.
  closing,
}

/// Content for a "Porque algunos recuerdos merecen seguir vivos"
/// QR-bearing spread.
///
/// The factory body lands in Tasks 4–7 (per category); in Task 2 the
/// factory constructs cleanly and throws at render time.
@immutable
class AlbumQrSpreadContent {
  /// Creates the QR-spread content.
  const AlbumQrSpreadContent({
    required this.qrPayload,
    required this.placement,
    this.captionOverride,
    this.bottomTextOverride,
  });

  /// Payload encoded into the QR code on the spread.
  final String qrPayload;

  /// Whether this is the opening or closing QR spread.
  final AlbumQrSpreadPlacement placement;

  /// Optional override for the fixed caption beside the QR block.
  final String? captionOverride;

  /// Optional override for the bottom variable text line — the
  /// `"{Protagonistas}, disfruta de está última experiencia."` line at
  /// the foot of the left page in the closing QR spread. When `null`,
  /// the factory composes the line from the caller's `contextLabelValue`.
  /// Applies only to the closing placement.
  final String? bottomTextOverride;

  @override
  bool operator ==(Object other) =>
      other is AlbumQrSpreadContent &&
      other.qrPayload == qrPayload &&
      other.placement == placement &&
      other.captionOverride == captionOverride &&
      other.bottomTextOverride == bottomTextOverride;

  @override
  int get hashCode => Object.hash(
        qrPayload,
        placement,
        captionOverride,
        bottomTextOverride,
      );
}
