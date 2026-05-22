import 'dart:math' show pi;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/dots_template.dart';
import '../logging/dots_logger.dart';
import 'crop_marks.dart';
import 'dots_font_bundle.dart';

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

/// Canonical top-left X for the left page-number label, in PDF points.
const double _kHeaderLeftX = 8.0 * _kMmToPt;

/// Y coordinate for all header labels (top of page), in PDF points.
const double _kHeaderY = 8.0 * _kMmToPt;

/// Y coordinate for the footer wordmark (bottom of page, ~8 mm from bottom).
/// Computed at runtime from page height — see [buildAlbumSpreadPage].
const double _kFooterBottomMarginMm = 8.0;

/// Canonical font size for header and footer labels (7pt / 8.4pt leading).
const double _kHeaderFontSize = 7.0;

/// Leading multiplier for header/footer text (8.4 / 7 = 1.2).
const double _kHeaderLineHeight = 1.2;

/// Millimetres → PDF points (1 pt = 1/72 inch; 1 inch = 25.4 mm).
const double _kMmToPt = 2.834645669;

// ---------------------------------------------------------------------------
// Public helper
// ---------------------------------------------------------------------------

/// Builds a single `pw.Page` for [page] — the shared pure rendering path
/// used by both the main-isolate renderer and the isolate-side renderer.
///
/// All external dependencies (font resolution, asset loading, logging, and
/// the photo-failure callback) are injected via closures so this function
/// stays state-free and testable without any renderer instance.
///
/// [fontResolver] returns a parsed `pw.Font` for the given [DotsFontRole],
/// or `null` to fall back to the pdf package's built-in Helvetica.
///
/// [bytesResolver] loads raw asset bytes by path.
///
/// [logger] receives [DotsLogger.warn] calls when a [DotsTextBlockElement]'s
/// content exceeds its declared [DotsTextBlockElement.maxChars] or
/// [DotsTextBlockElement.maxLines] thresholds.
///
/// [onPhotoFailure] is called when a [DotsImageElement] asset cannot be
/// decoded. The slot is silently skipped and rendering continues.
///
/// [drawCropMarks] — when `true`, L-shaped crop marks are appended to the
/// page stack in the 3mm bleed band.
Future<pw.Page> buildAlbumSpreadPage({
  required PdfPageFormat format,
  required DotsAlbumSpreadPage page,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required bool drawCropMarks,
}) async {
  final children = <pw.Widget>[];

  // ── Header ──────────────────────────────────────────────────────────────
  // TODO(inter-semibold): use DotsFontRole.interSemibold when the role is
  // added — D6 follow-up (slice 3+).
  final headerFont = fontResolver(DotsFontRole.inter);
  final headerStyle = pw.TextStyle(
    font: headerFont,
    fontSize: _kHeaderFontSize,
    lineSpacing: _kHeaderFontSize * (_kHeaderLineHeight - 1),
  );

  final leftNum = page.header.leftPageNumber;
  if (leftNum != null && leftNum.isNotEmpty) {
    children.add(pw.Positioned(
      left: _kHeaderLeftX,
      top: _kHeaderY,
      child: pw.Text(leftNum, style: headerStyle),
    ));
  }

  final centerLabel = page.header.centerLabel;
  if (centerLabel != null && centerLabel.isNotEmpty) {
    children.add(pw.Positioned(
      left: 0,
      right: 0,
      top: _kHeaderY,
      child: pw.Text(
        centerLabel,
        style: headerStyle,
        textAlign: pw.TextAlign.center,
      ),
    ));
  }

  final rightNum = page.header.rightPageNumber;
  if (rightNum != null && rightNum.isNotEmpty) {
    children.add(pw.Positioned(
      right: _kHeaderLeftX,
      top: _kHeaderY,
      child: pw.Text(rightNum, style: headerStyle),
    ));
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  final wordmark = page.footer.wordmark;
  if (wordmark.isNotEmpty) {
    final footerY = format.height - _kFooterBottomMarginMm * _kMmToPt;
    children.add(pw.Positioned(
      left: 0,
      right: 0,
      top: footerY,
      child: pw.Text(
        wordmark,
        style: headerStyle,
        textAlign: pw.TextAlign.center,
      ),
    ));
  }

  // ── Elements ─────────────────────────────────────────────────────────────
  for (final element in page.elements) {
    final widget = await _buildElement(
      element: element,
      fontResolver: fontResolver,
      bytesResolver: bytesResolver,
      logger: logger,
      onPhotoFailure: onPhotoFailure,
      pageNumber: page.pageNumber,
    );
    if (widget != null) children.add(widget);
  }

  // ── Crop marks ───────────────────────────────────────────────────────────
  if (drawCropMarks) {
    children.addAll(
      dotsCropMarks(
        pageWidthPt: format.width,
        pageHeightPt: format.height,
        trimMarginPt: 8.503936, // 3 mm in PDF points
      ),
    );
  }

  return pw.Page(
    pageFormat: format,
    build: (context) => pw.Stack(children: children),
  );
}

// ---------------------------------------------------------------------------
// Private element builder
// ---------------------------------------------------------------------------

Future<pw.Widget?> _buildElement({
  required DotsElement element,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required Future<Uint8List> Function(String assetPath) bytesResolver,
  required DotsLogger logger,
  required void Function(String assetPath, Object error) onPhotoFailure,
  required int pageNumber,
}) async {
  switch (element) {
    case DotsTextElement():
      return _buildText(element, fontResolver);

    case DotsImageElement():
      return _buildImage(
        element: element,
        bytesResolver: bytesResolver,
        onPhotoFailure: onPhotoFailure,
      );

    case DotsSpreadImageElement():
      // Spread images are not used on album-spread pages in slice 2.
      // Fall through — skip silently.
      return null;

    case DotsRotatedTextElement():
      return _buildRotatedText(element, fontResolver);

    case DotsTextBlockElement():
      return _buildTextBlock(
        element: element,
        fontResolver: fontResolver,
        logger: logger,
        pageNumber: pageNumber,
      );
  }
}

// ---------------------------------------------------------------------------
// Individual element builders
// ---------------------------------------------------------------------------

pw.Widget _buildText(
  DotsTextElement element,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);
  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Text(
      element.value,
      style: pw.TextStyle(
        fontSize: element.fontSize,
        font: font,
        color: _parseColor(element.colorHex),
      ),
    ),
  );
}

Future<pw.Widget?> _buildImage({
  required DotsImageElement element,
  required Future<Uint8List> Function(String) bytesResolver,
  required void Function(String, Object) onPhotoFailure,
}) async {
  final pw.MemoryImage image;
  try {
    final bytes = await bytesResolver(element.assetPath);
    image = pw.MemoryImage(bytes);
  } catch (error) {
    onPhotoFailure(element.assetPath, error);
    return null;
  }

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Image(
        image,
        width: element.width,
        height: element.height,
        fit: pw.BoxFit.cover,
      ),
    ),
  );
}

/// Renders a [DotsRotatedTextElement] by wrapping a [pw.Text] in
/// [pw.Transform.rotate].
///
/// The un-rotated bounding box (x, y) is used for positioning via
/// [pw.Positioned]. The rotation is applied around the child's geometric
/// centre (`alignment: pw.Alignment.center`). At 2°, the visual excursion
/// beyond the un-rotated bbox is ≈0.4 mm — negligible at print resolution.
pw.Widget _buildRotatedText(
  DotsRotatedTextElement element,
  pw.Font? Function(DotsFontRole) fontResolver,
) {
  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);
  final angleRadians = element.angleDegrees * pi / 180.0;

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.Transform.rotate(
      angle: angleRadians,
      child: pw.Text(
        element.value,
        style: pw.TextStyle(
          fontSize: element.fontSize,
          font: font,
          color: _parseColor(element.colorHex),
        ),
      ),
    ),
  );
}

/// Renders a [DotsTextBlockElement] inside a [pw.SizedBox] for width
/// constraining and word-wrapping.
///
/// Emits a [DotsLogger.warn] message (but continues rendering) when:
///   - [DotsTextBlockElement.maxChars] is set and
///     `value.length > maxChars`, or
///   - [DotsTextBlockElement.maxLines] is set and
///     `value.split('\n').length > maxLines`.
pw.Widget _buildTextBlock({
  required DotsTextBlockElement element,
  required pw.Font? Function(DotsFontRole) fontResolver,
  required DotsLogger logger,
  required int pageNumber,
}) {
  // Overflow guards — warn but always render.
  final maxChars = element.maxChars;
  if (maxChars != null && element.value.length > maxChars) {
    logger.warn(
      'DotsTextBlockElement on page $pageNumber: '
      'body length ${element.value.length} exceeds maxChars $maxChars',
    );
  }
  final maxLines = element.maxLines;
  if (maxLines != null && element.value.split('\n').length > maxLines) {
    logger.warn(
      'DotsTextBlockElement on page $pageNumber: '
      'line count ${element.value.split('\n').length} exceeds maxLines $maxLines',
    );
  }

  final role = DotsFontBundle.roleFromFamily(element.fontFamily);
  final font = role == null ? null : fontResolver(role);

  final textAlign = switch (element.textAlign) {
    DotsTextAlign.left => pw.TextAlign.left,
    DotsTextAlign.center => pw.TextAlign.center,
    DotsTextAlign.right => pw.TextAlign.right,
  };

  return pw.Positioned(
    left: element.x,
    top: element.y,
    child: pw.SizedBox(
      width: element.width,
      child: pw.Text(
        element.value,
        style: pw.TextStyle(
          fontSize: element.fontSize,
          font: font,
          color: _parseColor(element.colorHex),
          lineSpacing: element.fontSize * (element.lineHeight - 1),
        ),
        textAlign: textAlign,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PdfColor? _parseColor(String? hex) {
  if (hex == null) return null;
  final trimmed = hex.startsWith('#') ? hex.substring(1) : hex;
  if (trimmed.length != 6) return null;
  final value = int.tryParse(trimmed, radix: 16);
  if (value == null) return null;
  return PdfColor(
    ((value >> 16) & 0xff) / 255.0,
    ((value >> 8) & 0xff) / 255.0,
    (value & 0xff) / 255.0,
  );
}
