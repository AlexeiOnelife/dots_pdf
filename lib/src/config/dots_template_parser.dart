import 'dart:convert';

import '../render/layout/dots_layout_code.dart';
import '../render/layout/dots_layout_requirements.dart';
import '../render/layout/dots_layout_solver.dart';
import '../render/layout/dots_page_geometry.dart';
import '../render/layout/dots_slot_rect.dart';
import 'dots_config_exception.dart';
import 'dots_pliego.dart';
import 'dots_template.dart';

/// JSON key in a caption map → solver-side slot kind.
const Map<String, DotsSlotKind> _captionJsonKeyToKind = <String, DotsSlotKind>{
  'title': DotsSlotKind.captionTitle,
  'date': DotsSlotKind.captionDate,
  'body': DotsSlotKind.captionBody,
  'qr': DotsSlotKind.qrCard,
};

/// Reverse of [_captionJsonKeyToKind] — slot kind → JSON key — used by
/// validation error messages so users can copy/paste the right key.
const Map<DotsSlotKind, String> _captionKindToJsonKey = <DotsSlotKind, String>{
  DotsSlotKind.captionTitle: 'title',
  DotsSlotKind.captionDate: 'date',
  DotsSlotKind.captionBody: 'body',
  DotsSlotKind.qrCard: 'qr',
};

/// Parses a JSON template string or pre-decoded map into a typed
/// [DotsTemplate] tree.
///
/// The parser is intentionally strict: any missing required field or
/// type mismatch raises a [DotsConfigException] that pinpoints the
/// offending JSON path. The raw `Map<String, dynamic>` is dropped as
/// soon as parsing completes — the rest of the pipeline operates on
/// the compact typed tree only.
class DotsTemplateParser {
  /// Creates a parser. The class is stateless; one instance can parse
  /// any number of templates.
  const DotsTemplateParser();

  /// Decodes [source] as UTF-8 JSON and parses the resulting tree.
  DotsTemplate parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw DotsConfigException('invalid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const DotsConfigException(
        'template root must be a JSON object',
        pointer: r'$',
      );
    }
    return parseMap(decoded);
  }

  /// Parses an already-decoded JSON map.
  DotsTemplate parseMap(Map<String, dynamic> json) {
    final documentId = _requireString(json, 'documentId', r'$');
    final pageSize = _parsePageSize(
      _requireMap(json, 'pageSize', r'$'),
      r'$.pageSize',
    );

    final hasPages = json.containsKey('pages');
    final hasPliegos = json.containsKey('pliegos');
    if (hasPages && hasPliegos) {
      throw const DotsConfigException(
        'template must declare "pages" OR "pliegos", not both',
        pointer: r'$',
      );
    }
    if (!hasPages && !hasPliegos) {
      throw const DotsConfigException(
        'template must declare "pages" or "pliegos"',
        pointer: r'$',
      );
    }

    if (hasPliegos) {
      final pliegosRaw = _requireList(json, 'pliegos', r'$');
      final pliegos = <DotsPliego>[];
      for (var i = 0; i < pliegosRaw.length; i++) {
        final entry = pliegosRaw[i];
        if (entry is! Map<String, dynamic>) {
          throw DotsConfigException(
            'pliego entry must be an object',
            pointer: r'$.pliegos[' '$i' ']',
          );
        }
        pliegos.add(_parsePliego(entry, r'$.pliegos[' '$i' ']'));
      }
      return DotsTemplate(
        documentId: documentId,
        pageSize: pageSize,
        pliegos: List<DotsPliego>.unmodifiable(pliegos),
      );
    }

    final pagesRaw = _requireList(json, 'pages', r'$');
    final pages = <DotsPage>[];
    for (var i = 0; i < pagesRaw.length; i++) {
      final entry = pagesRaw[i];
      if (entry is! Map<String, dynamic>) {
        throw DotsConfigException(
          'page entry must be an object',
          pointer: r'$.pages[' '$i' ']',
        );
      }
      pages.add(_parsePage(entry, r'$.pages[' '$i' ']'));
    }
    return DotsTemplate(
      documentId: documentId,
      pageSize: pageSize,
      pages: List<DotsPage>.unmodifiable(pages),
    );
  }

  /// Parses one pliego object. JSON shape:
  ///
  /// ```json
  /// { "pliegoNumber": 1, "type": "layout",
  ///   "left":  { /* page shape */ },
  ///   "right": { /* page shape */ } }
  /// ```
  ///
  /// or
  ///
  /// ```json
  /// { "pliegoNumber": 2, "type": "spreadImage",
  ///   "assetPath": "https://…",
  ///   "spreadWidth": 1184, "height": 689,
  ///   "x": 0, "y": 0,
  ///   "bleedTop": true, "bleedBottom": true, "bleedOuter": true }
  /// ```
  ///
  /// `pageNumber` on the inner pages of a layout pliego is ignored —
  /// the renderer assigns the final page numbers from the pliego's
  /// position in the template.
  DotsPliego _parsePliego(Map<String, dynamic> json, String at) {
    final pliegoNumber = _requireInt(json, 'pliegoNumber', at);
    final type = _requireString(json, 'type', at);
    switch (type) {
      case 'layout':
        final leftJson = _requireMap(json, 'left', at);
        final rightJson = _requireMap(json, 'right', at);
        // Inner pages may omit pageNumber — supply a placeholder; the
        // pliego flattener overrides it from the parent position.
        final leftWithPageNum = <String, dynamic>{
          'pageNumber': 0,
          ...leftJson,
        };
        final rightWithPageNum = <String, dynamic>{
          'pageNumber': 0,
          ...rightJson,
        };
        return DotsLayoutPliego(
          pliegoNumber: pliegoNumber,
          left: _parsePage(leftWithPageNum, '$at.left'),
          right: _parsePage(rightWithPageNum, '$at.right'),
        );
      case 'spreadImage':
        final spreadWidth = _requireDouble(json, 'spreadWidth', at);
        if (spreadWidth <= 0) {
          throw DotsConfigException(
            'field "spreadWidth" must be positive (got $spreadWidth)',
            pointer: '$at.spreadWidth',
          );
        }
        final height = _requireDouble(json, 'height', at);
        if (height <= 0) {
          throw DotsConfigException(
            'field "height" must be positive (got $height)',
            pointer: '$at.height',
          );
        }
        return DotsSpreadImagePliego(
          pliegoNumber: pliegoNumber,
          assetPath: _requireString(json, 'assetPath', at),
          spreadWidth: spreadWidth,
          height: height,
          x: _optionalDouble(json, 'x') ?? 0,
          y: _optionalDouble(json, 'y') ?? 0,
          bleedTop: _optionalBool(json, 'bleedTop') ?? false,
          bleedBottom: _optionalBool(json, 'bleedBottom') ?? false,
          bleedOuter: _optionalBool(json, 'bleedOuter') ?? false,
        );
      default:
        throw DotsConfigException(
          'unknown pliego type "$type" (expected "layout" or "spreadImage")',
          pointer: '$at.type',
        );
    }
  }

  double? _optionalDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is num ? value.toDouble() : null;
  }

  DotsPageSize _parsePageSize(Map<String, dynamic> json, String at) {
    return DotsPageSize(
      width: _requireDouble(json, 'width', at),
      height: _requireDouble(json, 'height', at),
    );
  }

  DotsPage _parsePage(Map<String, dynamic> json, String at) {
    final pageNumber = _requireInt(json, 'pageNumber', at);
    final hasLayout = json.containsKey('layout');
    final hasElements = json.containsKey('elements');
    if (hasLayout && hasElements) {
      throw DotsConfigException(
        'page must declare either "layout" or "elements", not both',
        pointer: at,
      );
    }
    if (hasLayout) {
      return _parseLayoutPage(json, at, pageNumber: pageNumber);
    }
    return _parseElementsPage(json, at, pageNumber: pageNumber);
  }

  DotsElementsPage _parseElementsPage(
    Map<String, dynamic> json,
    String at, {
    required int pageNumber,
  }) {
    final elementsRaw = _requireList(json, 'elements', at);
    final elements = <DotsElement>[];
    for (var i = 0; i < elementsRaw.length; i++) {
      final entry = elementsRaw[i];
      if (entry is! Map<String, dynamic>) {
        throw DotsConfigException(
          'element entry must be an object',
          pointer: '$at.elements[$i]',
        );
      }
      elements.add(_parseElement(entry, '$at.elements[$i]'));
    }
    return DotsElementsPage(
      pageNumber: pageNumber,
      elements: List<DotsElement>.unmodifiable(elements),
    );
  }

  DotsLayoutPage _parseLayoutPage(
    Map<String, dynamic> json,
    String at, {
    required int pageNumber,
  }) {
    final layoutString = _requireString(json, 'layout', at);
    final layoutCode = _decodeLayoutCode(layoutString, '$at.layout');

    // Resolve photos.
    final photoPaths = <String>[];
    final photosRaw = json['photos'];
    if (photosRaw != null) {
      if (photosRaw is! List) {
        throw DotsConfigException(
          'field "photos" must be an array of strings',
          pointer: '$at.photos',
        );
      }
      for (var i = 0; i < photosRaw.length; i++) {
        final entry = photosRaw[i];
        if (entry is! String || entry.isEmpty) {
          throw DotsConfigException(
            'photos[$i] must be a non-empty string',
            pointer: '$at.photos[$i]',
          );
        }
        photoPaths.add(entry);
      }
    }

    // Resolve captions.
    final captions = <DotsSlotKind, String>{};
    final captionsRaw = json['captions'];
    if (captionsRaw != null) {
      if (captionsRaw is! Map<String, dynamic>) {
        throw DotsConfigException(
          'field "captions" must be a JSON object',
          pointer: '$at.captions',
        );
      }
      for (final entry in captionsRaw.entries) {
        final kind = _captionJsonKeyToKind[entry.key];
        if (kind == null) {
          throw DotsConfigException(
            'unknown caption key "${entry.key}" '
            '(expected one of: title, date, body, qr)',
            pointer: '$at.captions.${entry.key}',
          );
        }
        final value = entry.value;
        if (value is! String) {
          throw DotsConfigException(
            'caption "${entry.key}" must be a string',
            pointer: '$at.captions.${entry.key}',
          );
        }
        captions[kind] = value;
      }
    }

    // Validate against solver output.
    _validateLayoutPageAgainstSolver(
      layoutCode: layoutCode,
      photoPaths: photoPaths,
      captions: captions,
      at: at,
    );

    return DotsLayoutPage(
      pageNumber: pageNumber,
      layoutCode: layoutCode,
      photoAssetPaths: List<String>.unmodifiable(photoPaths),
      captions: Map<DotsSlotKind, String>.unmodifiable(captions),
    );
  }

  DotsLayoutCode _decodeLayoutCode(String raw, String at) {
    for (final code in DotsLayoutCode.values) {
      if (code.name == raw) return code;
    }
    throw DotsConfigException(
      'unknown layout code "$raw"',
      pointer: at,
    );
  }

  void _validateLayoutPageAgainstSolver({
    required DotsLayoutCode layoutCode,
    required List<String> photoPaths,
    required Map<DotsSlotKind, String> captions,
    required String at,
  }) {
    // TODO(dots-pdf): make geometry pluggable per-template. The
    // dotbook-default is the only geometry the solver supports today,
    // so it is safe to assume it here for validation purposes.
    const DotsLayoutSolver solver = DotsLayoutSolver();
    final geometry = DotsPageGeometry.dotbookDefault();
    final List<DotsSlotRect> slots;
    try {
      slots = solver.solve(layoutCode, geometry);
    } on StateError catch (e) {
      throw DotsConfigException(
        'layout "${layoutCode.name}" does not fit the configured '
        'page geometry: ${e.message}',
        pointer: '$at.layout',
      );
    }

    final photoSlots =
        slots.where((s) => s.kind == DotsSlotKind.photo).toList();
    if (photoSlots.length != photoPaths.length) {
      throw DotsConfigException(
        'layout "${layoutCode.name}" expects ${photoSlots.length} photo(s) '
        'but ${photoPaths.length} were supplied',
        pointer: '$at.photos',
      );
    }

    final captionSlotKinds = <DotsSlotKind>{
      for (final s in slots)
        if (s.kind != DotsSlotKind.photo) s.kind,
    };
    for (final providedKind in captions.keys) {
      if (!captionSlotKinds.contains(providedKind)) {
        throw DotsConfigException(
          'layout "${layoutCode.name}" has no slot for caption kind '
          '"${providedKind.name}"',
          pointer: '$at.captions',
        );
      }
    }

    // Enforce required captions per the layout's static descriptor.
    // (See `lib/src/render/layout/dots_layout_requirements.dart` for
    // the full table of who needs what.)
    final requirements = layoutCode.requirements;
    for (final requiredKind in requirements.requiredCaptionKinds) {
      final value = captions[requiredKind];
      if (value == null || value.isEmpty) {
        throw DotsConfigException(
          'layout "${layoutCode.name}" requires caption kind '
          '"${requiredKind.name}" — supply a non-empty string under '
          'captions.${_captionKindToJsonKey[requiredKind]}',
          pointer: '$at.captions',
        );
      }
    }
  }

  DotsElement _parseElement(Map<String, dynamic> json, String at) {
    final type = _requireString(json, 'type', at);
    switch (type) {
      case 'text':
        return DotsTextElement(
          x: _requireDouble(json, 'x', at),
          y: _requireDouble(json, 'y', at),
          value: _requireString(json, 'value', at),
          fontSize: _requireDouble(json, 'fontSize', at),
          fontFamily: _optionalString(json, 'fontFamily'),
          colorHex: _optionalString(json, 'color'),
        );
      case 'image':
        return DotsImageElement(
          x: _requireDouble(json, 'x', at),
          y: _requireDouble(json, 'y', at),
          assetPath: _requireString(json, 'assetPath', at),
          width: _requireDouble(json, 'width', at),
          height: _requireDouble(json, 'height', at),
          bleedTop: _optionalBool(json, 'bleedTop') ?? false,
          bleedBottom: _optionalBool(json, 'bleedBottom') ?? false,
          bleedLeft: _optionalBool(json, 'bleedLeft') ?? false,
          bleedRight: _optionalBool(json, 'bleedRight') ?? false,
        );
      case 'spreadImage':
        final spreadWidth = _requireDouble(json, 'spreadWidth', at);
        if (spreadWidth <= 0) {
          throw DotsConfigException(
            'field "spreadWidth" must be positive (got $spreadWidth)',
            pointer: '$at.spreadWidth',
          );
        }
        final height = _requireDouble(json, 'height', at);
        if (height <= 0) {
          throw DotsConfigException(
            'field "height" must be positive (got $height)',
            pointer: '$at.height',
          );
        }
        final halfRaw = _requireString(json, 'half', at);
        final DotsSpreadHalf half;
        switch (halfRaw) {
          case 'left':
            half = DotsSpreadHalf.left;
          case 'right':
            half = DotsSpreadHalf.right;
          default:
            throw DotsConfigException(
              'field "half" must be "left" or "right" (got "$halfRaw")',
              pointer: '$at.half',
            );
        }
        return DotsSpreadImageElement(
          x: _requireDouble(json, 'x', at),
          y: _requireDouble(json, 'y', at),
          assetPath: _requireString(json, 'assetPath', at),
          spreadWidth: spreadWidth,
          height: height,
          half: half,
          bleedTop: _optionalBool(json, 'bleedTop') ?? false,
          bleedBottom: _optionalBool(json, 'bleedBottom') ?? false,
          bleedOuter: _optionalBool(json, 'bleedOuter') ?? false,
        );
      default:
        throw DotsConfigException(
          'unknown element type: "$type"',
          pointer: '$at.type',
        );
    }
  }

  String _requireString(Map<String, dynamic> json, String key, String at) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw DotsConfigException(
      'missing or empty string field "$key"',
      pointer: '$at.$key',
    );
  }

  String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String ? value : null;
  }

  bool? _optionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is bool ? value : null;
  }

  int _requireInt(Map<String, dynamic> json, String key, String at) {
    final value = json[key];
    if (value is int) return value;
    throw DotsConfigException(
      'missing or non-integer field "$key"',
      pointer: '$at.$key',
    );
  }

  double _requireDouble(Map<String, dynamic> json, String key, String at) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw DotsConfigException(
      'missing or non-numeric field "$key"',
      pointer: '$at.$key',
    );
  }

  Map<String, dynamic> _requireMap(
    Map<String, dynamic> json,
    String key,
    String at,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    throw DotsConfigException(
      'missing or non-object field "$key"',
      pointer: '$at.$key',
    );
  }

  List<dynamic> _requireList(
    Map<String, dynamic> json,
    String key,
    String at,
  ) {
    final value = json[key];
    if (value is List) return value;
    throw DotsConfigException(
      'missing or non-array field "$key"',
      pointer: '$at.$key',
    );
  }
}
