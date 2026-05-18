import 'package:meta/meta.dart';

import 'dots_layout_code.dart';
import 'dots_slot_rect.dart';

/// Authoritative declaration of what content a [DotsLayoutCode] needs.
///
/// The library uses this both to validate template input at parse
/// time and to document for callers what every layout expects.
///
/// - [photoCount] is the exact number of photos the layout's photo
///   slots accept. The parser throws `DotsConfigException` when
///   `DotsLayoutPage.photoAssetPaths.length` differs from this value.
/// - [requiredCaptionKinds] lists the caption slot kinds without
///   which the layout renders visually broken (or, for milestone
///   pages, semantically empty). The parser throws if any required
///   caption is missing or empty in `DotsLayoutPage.captions`.
/// - [optionalCaptionKinds] lists captions the layout supports but
///   does not need; absent entries simply leave the slot blank.
@immutable
class DotsLayoutRequirements {
  /// Creates a requirements descriptor.
  const DotsLayoutRequirements({
    required this.photoCount,
    required this.requiredCaptionKinds,
    required this.optionalCaptionKinds,
  });

  /// Number of photo slots emitted by the solver for this layout.
  ///
  /// Caller must supply exactly this many entries in
  /// `DotsLayoutPage.photoAssetPaths` (order matters — slots are
  /// emitted row-major top-to-bottom, left-to-right).
  final int photoCount;

  /// Caption slot kinds the layout needs to be meaningful.
  ///
  /// The parser raises `DotsConfigException` when any of these is
  /// absent or empty in `DotsLayoutPage.captions`.
  final List<DotsSlotKind> requiredCaptionKinds;

  /// Caption slot kinds the layout supports but does not require.
  ///
  /// Omit them to leave the slot blank.
  final List<DotsSlotKind> optionalCaptionKinds;

  /// Convenience: every caption kind this layout knows about
  /// (required + optional, in that order).
  List<DotsSlotKind> get allCaptionKinds => <DotsSlotKind>[
        ...requiredCaptionKinds,
        ...optionalCaptionKinds,
      ];
}

/// Static descriptor lookup for every [DotsLayoutCode].
extension DotsLayoutCodeRequirements on DotsLayoutCode {
  /// What [DotsLayoutPage.photoAssetPaths] and `.captions` must
  /// contain to satisfy this layout.
  DotsLayoutRequirements get requirements {
    switch (this) {
      case DotsLayoutCode.l1:
      case DotsLayoutCode.l1a:
      case DotsLayoutCode.l1b:
      case DotsLayoutCode.l1c:
      case DotsLayoutCode.l1d:
      case DotsLayoutCode.l1e:
        return const DotsLayoutRequirements(
          photoCount: 1,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l2a:
      case DotsLayoutCode.l2b:
      case DotsLayoutCode.l2c:
        return const DotsLayoutRequirements(
          photoCount: 2,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l3a:
        return const DotsLayoutRequirements(
          photoCount: 3,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l4a:
        return const DotsLayoutRequirements(
          photoCount: 4,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l4b:
        return const DotsLayoutRequirements(
          photoCount: 2,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l6a:
        return const DotsLayoutRequirements(
          photoCount: 3,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.l7:
        // L7 = 2 photos per page, optional date + body. Per spec, "Not
        // every photo needs text to use this spread", so captions are
        // optional. KNOWN LIMITATION: the current solver emits one
        // caption slot per pane (2 panes per page), but
        // `DotsLayoutPage.captions` is keyed only by `DotsSlotKind`,
        // so the same text is reused across both panes. Per-pane
        // captions are a follow-up.
        return const DotsLayoutRequirements(
          photoCount: 2,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[
            DotsSlotKind.captionDate,
            DotsSlotKind.captionBody,
          ],
        );
      case DotsLayoutCode.l8:
        return const DotsLayoutRequirements(
          photoCount: 3,
          requiredCaptionKinds: <DotsSlotKind>[],
          optionalCaptionKinds: <DotsSlotKind>[],
        );
      case DotsLayoutCode.lhito:
        // L_hito is a text-only milestone page. Title and body are
        // structurally required (the page would be empty otherwise).
        // Date and QR are optional — many milestones have neither a
        // precise date nor a link.
        return const DotsLayoutRequirements(
          photoCount: 0,
          requiredCaptionKinds: <DotsSlotKind>[
            DotsSlotKind.captionTitle,
            DotsSlotKind.captionBody,
          ],
          optionalCaptionKinds: <DotsSlotKind>[
            DotsSlotKind.captionDate,
            DotsSlotKind.qrCard,
          ],
        );
    }
  }
}
