import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

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
  const DotsFontBundle({
    required this.p22MackinacMedium,
    required this.p22MackinacBook,
    required this.p22MackinacMediumItalic,
    required this.inter,
    required this.interItalic,
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
      load('assets/fonts/p22_mackinac/P22Mackinac-Medium_6.otf'),
      load('assets/fonts/p22_mackinac/P22Mackinac-Book_13.otf'),
      load('assets/fonts/p22_mackinac/P22Mackinac-MedItalic_22.otf'),
      load('assets/fonts/inter/Inter-VariableFont_opsz,wght.ttf'),
      load('assets/fonts/inter/Inter-Italic-VariableFont_opsz,wght.ttf'),
      load('assets/fonts/biro_plus/Biro-ScriptPlus-Regular-subset.ttf'),
    ]);

    return DotsFontBundle(
      p22MackinacMedium: results[0],
      p22MackinacBook: results[1],
      p22MackinacMediumItalic: results[2],
      inter: results[3],
      interItalic: results[4],
      biroScriptPlus: results[5],
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
  ///   - `"Inter"`, `"Inter Book"`, `"Inter Semibold"`, `"Inter Light"` → inter
  ///   - `"Inter Italic"` → inter italic
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
    if (f.startsWith('inter')) return DotsFontRole.inter;
    if (f.startsWith('biro')) return DotsFontRole.biroScriptPlus;
    return null;
  }
}
