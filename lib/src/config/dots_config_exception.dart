/// Thrown when a JSON template fails validation during parsing.
///
/// Carries a human-readable [message] plus an optional [pointer] that
/// locates the offending field inside the source JSON tree (e.g.
/// `pages[3].elements[1].fontSize`).
class DotsConfigException implements Exception {
  /// Creates a config exception with a [message] and optional JSON [pointer].
  const DotsConfigException(this.message, {this.pointer});

  /// Human-readable description of the validation failure.
  final String message;

  /// Optional dotted path to the offending field, for diagnostics.
  final String? pointer;

  @override
  String toString() => pointer == null
      ? 'DotsConfigException: $message'
      : 'DotsConfigException at $pointer: $message';
}
