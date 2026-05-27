import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

import '../config/dots_config_exception.dart';

/// SFNT magic bytes for the supported and unsupported font flavors.
///
/// - `0x00010000` — TrueType (`glyf` outlines). Supported.
/// - `'OTTO'` (`0x4F54544F`) — CFF-flavored OpenType (PostScript
///   outlines). NOT supported by the `pdf` package's TtfParser:
///   it parses the SFNT tables but skips the `CFF ` outline table,
///   leaving every glyph with zero advance width.
const int _kSfntTrueTypeMagic = 0x00010000;
const int _kSfntOpenTypeCffMagic = 0x4F54544F; // 'OTTO'

void _assertTrueType(Uint8List bytes, String fieldName) {
  if (bytes.length < 4) {
    throw DotsConfigException(
      'font bytes for "$fieldName" are too short (got ${bytes.length} bytes; '
      'expected a TrueType `.ttf` file)',
      pointer: r'$.fontBundle.' '$fieldName',
    );
  }
  final magic = (bytes[0] << 24) |
      (bytes[1] << 16) |
      (bytes[2] << 8) |
      bytes[3];
  if (magic == _kSfntOpenTypeCffMagic) {
    throw DotsConfigException(
      '"$fieldName" is a CFF-flavored OpenType (.otf) font; the pdf '
      'package does not embed CFF outlines, which renders text with '
      'every letter stacked at the same x position. Convert the file '
      'to TrueType (.ttf) once and bundle the .ttf instead:\n'
      '    pip3 install --user fonttools cu2qu\n'
      '    otf2ttf YourFont.otf   # produces YourFont.ttf\n'
      'Then update DotsFontBundle.fromPackageAssets() (or the asset '
      'paths in your own loader) to point at the .ttf file.',
      pointer: r'$.fontBundle.' '$fieldName',
    );
  }
  if (magic != _kSfntTrueTypeMagic) {
    throw DotsConfigException(
      '"$fieldName" has an unrecognised SFNT header magic '
      '(0x${magic.toRadixString(16).padLeft(8, '0')}); expected a '
      'TrueType `.ttf` font (magic 0x00010000).',
      pointer: r'$.fontBundle.' '$fieldName',
    );
  }
}

/// Logical font role keyed by Dotbook design intent.
///
/// The renderer routes text into one of these roles based on its slot
/// kind (for layout-driven pages) or its `fontFamily` string (for
/// explicit-element pages — see [DotsFontBundle.fontFor]).
enum DotsFontRole {
  /// P22 Mackinac medium. Titles on every layout; spec sizes 11 pt
  /// (body pages), 20 pt (L_hito), 23 pt (per-album-type spreads).
  p22MackinacMedium,

  /// P22 Mackinac book. Body copy on per-album-type spreads, dates,
  /// secondary headings.
  p22MackinacBook,

  /// P22 Mackinac medium italic. Used for emphasized title fragments
  /// (e.g. boda "Antes de empezar **el viaje**").
  p22MackinacMediumItalic,

  /// Inter, regular weight. Body copy on body pages (spec calls for
  /// "Inter Book 9 pt"; this single variable TTF covers it).
  inter,

  /// Inter, italic. Available for callers who need it.
  interItalic,

  /// Inter SemiBold (static 600-weight TTF). Used for the header/footer
  /// trio — page numbers, centre label, and wordmark — at 7 pt / 8.4 pt
  /// leading. Inter v4.1 © Rasmus Andersson — SIL OFL 1.1.
  interSemibold,

  /// Biro Script Plus, regular. Used only for the rotated signature
  /// on the dedication page.
  biroScriptPlus,
}

/// Bundle of font byte data the renderer uses to embed real typography
/// into the produced PDF.
///
/// Each field is the raw `.ttf` or `.otf` byte stream. The bundle is
/// constructed once per app (loading from `rootBundle`) and reused
/// across every generation run; per-run the renderer parses each byte
/// stream into a `pw.Font` exactly once and shares the parsed font
/// across all pages.
///
/// When the generator is constructed without a bundle (the default),
/// text falls back to the pdf package's built-in Helvetica.
@immutable
class DotsFontBundle {
  /// Creates a font bundle from raw byte streams.
  ///
  /// Each byte stream must be a **TrueType** (`.ttf`) font — i.e. an
  /// SFNT container whose header magic is `00 01 00 00`. CFF-flavored
  /// OpenType (`.otf` with magic `OTTO`) is **not supported** by the
  /// underlying `pdf` package: it parses the SFNT tables but skips the
  /// `CFF ` outline table, so every glyph ends up with zero advance
  /// width and text renders with every letter stacked at the same x
  /// position.
  ///
  /// If you have `.otf` files, convert them once with `fontTools`:
  ///
  /// ```sh
  /// pip3 install --user fonttools cu2qu
  /// otf2ttf MyFont.otf   # produces MyFont.ttf alongside the .otf
  /// ```
  ///
  /// The conversion is lossy at the outline level (cubic Bezier →
  /// quadratic Bezier), but visually indistinguishable at print
  /// resolution.
  ///
  /// [assertSupportedFormats] validates every input at construction
  /// time and throws [DotsConfigException] when an unsupported format
  /// is detected. Pass `false` only if you have a reason to believe
  /// the detection is wrong for your inputs.
  factory DotsFontBundle({
    required Uint8List p22MackinacMedium,
    required Uint8List p22MackinacBook,
    required Uint8List p22MackinacMediumItalic,
    required Uint8List inter,
    required Uint8List interItalic,
    required Uint8List interSemibold,
    required Uint8List biroScriptPlus,
    bool assertSupportedFormats = true,
  }) {
    if (assertSupportedFormats) {
      _assertTrueType(p22MackinacMedium, 'p22MackinacMedium');
      _assertTrueType(p22MackinacBook, 'p22MackinacBook');
      _assertTrueType(p22MackinacMediumItalic, 'p22MackinacMediumItalic');
      _assertTrueType(inter, 'inter');
      _assertTrueType(interItalic, 'interItalic');
      _assertTrueType(interSemibold, 'interSemibold');
      _assertTrueType(biroScriptPlus, 'biroScriptPlus');
    }
    return DotsFontBundle._(
      p22MackinacMedium: p22MackinacMedium,
      p22MackinacBook: p22MackinacBook,
      p22MackinacMediumItalic: p22MackinacMediumItalic,
      inter: inter,
      interItalic: interItalic,
      interSemibold: interSemibold,
      biroScriptPlus: biroScriptPlus,
    );
  }

  const DotsFontBundle._({
    required this.p22MackinacMedium,
    required this.p22MackinacBook,
    required this.p22MackinacMediumItalic,
    required this.inter,
    required this.interItalic,
    required this.interSemibold,
    required this.biroScriptPlus,
  });

  /// P22 Mackinac, medium weight.
  final Uint8List p22MackinacMedium;

  /// P22 Mackinac, book weight.
  final Uint8List p22MackinacBook;

  /// P22 Mackinac, medium italic.
  final Uint8List p22MackinacMediumItalic;

  /// Inter (variable font, upright).
  final Uint8List inter;

  /// Inter (variable font, italic).
  final Uint8List interItalic;

  /// Inter SemiBold (static 600-weight TTF).
  // Inter v4.1 © Rasmus Andersson — SIL OFL 1.1
  final Uint8List interSemibold;

  /// Biro Script Plus, regular.
  final Uint8List biroScriptPlus;

  /// Loads every font in the bundle from this package's bundled
  /// assets via Flutter's `rootBundle`.
  ///
  /// Callers in a Flutter app context use this to avoid hand-rolling
  /// six `rootBundle.load(...)` calls. The asset paths assume the
  /// library's `pubspec.yaml` declares `assets/fonts/` (it does).
  static Future<DotsFontBundle> fromPackageAssets() async {
    Future<Uint8List> load(String path) async {
      final data = await rootBundle.load('packages/dots_pdf/$path');
      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    }

    final results = await Future.wait<Uint8List>(<Future<Uint8List>>[
      load('assets/fonts/p22_mackinac/P22Mackinac-Medium_6.ttf'),
      load('assets/fonts/p22_mackinac/P22Mackinac-Book_13.ttf'),
      load('assets/fonts/p22_mackinac/P22Mackinac-MedItalic_22.ttf'),
      load('assets/fonts/inter/Inter-VariableFont_opsz,wght.ttf'),
      load('assets/fonts/inter/Inter-Italic-VariableFont_opsz,wght.ttf'),
      load('assets/fonts/inter/Inter-SemiBold.ttf'),
      load('assets/fonts/biro_plus/Biro-ScriptPlus-Regular-subset.ttf'),
    ]);

    return DotsFontBundle(
      p22MackinacMedium: results[0],
      p22MackinacBook: results[1],
      p22MackinacMediumItalic: results[2],
      inter: results[3],
      interItalic: results[4],
      interSemibold: results[5],
      biroScriptPlus: results[6],
    );
  }

  /// Returns the byte data for [role].
  Uint8List bytesFor(DotsFontRole role) {
    switch (role) {
      case DotsFontRole.p22MackinacMedium:
        return p22MackinacMedium;
      case DotsFontRole.p22MackinacBook:
        return p22MackinacBook;
      case DotsFontRole.p22MackinacMediumItalic:
        return p22MackinacMediumItalic;
      case DotsFontRole.inter:
        return inter;
      case DotsFontRole.interItalic:
        return interItalic;
      case DotsFontRole.interSemibold:
        return interSemibold;
      case DotsFontRole.biroScriptPlus:
        return biroScriptPlus;
    }
  }

  /// Maps a `DotsTextElement.fontFamily` string to a [DotsFontRole].
  ///
  /// Recognised family strings (case-insensitive):
  ///   - `"P22 Mackinac"`, `"P22 Mackinac Medium"` → medium
  ///   - `"P22 Mackinac Book"` → book
  ///   - `"P22 Mackinac Medium Italic"`, `"P22 Mackinac Italic"` → medium italic
  ///   - `"Inter"`, `"Inter Book"`, `"Inter Light"` → inter
  ///   - `"Inter Italic"` → inter italic
  ///   - `"Inter SemiBold"`, `"Inter Semibold"` → interSemibold
  ///   - `"Biro Script Plus"`, `"Biro"` → biroScriptPlus
  /// Unrecognised strings return `null` and let the caller fall back
  /// to the default font.
  static DotsFontRole? roleFromFamily(String? family) {
    if (family == null) return null;
    final f = family.trim().toLowerCase();
    if (f == 'p22 mackinac' || f == 'p22 mackinac medium') {
      return DotsFontRole.p22MackinacMedium;
    }
    if (f == 'p22 mackinac book') return DotsFontRole.p22MackinacBook;
    if (f == 'p22 mackinac medium italic' || f == 'p22 mackinac italic') {
      return DotsFontRole.p22MackinacMediumItalic;
    }
    if (f.startsWith('inter italic')) return DotsFontRole.interItalic;
    // Check semibold before the generic 'inter' catch-all.
    // Both "Inter SemiBold" and "Inter Semibold" lower-case to 'inter semibold'.
    if (f == 'inter semibold') return DotsFontRole.interSemibold;
    if (f.startsWith('inter')) return DotsFontRole.inter;
    if (f.startsWith('biro')) return DotsFontRole.biroScriptPlus;
    return null;
  }
}
