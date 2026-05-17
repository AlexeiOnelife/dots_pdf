/// Logger abstraction used by the library.
///
/// The library never calls `print` directly. Callers wire in their own
/// logger (e.g. a wrapper around `package:logging`); the default
/// implementation discards every message.
abstract class DotsLogger {
  /// Records an informational message.
  void info(String message);

  /// Records a warning. [error] and [stackTrace] are optional.
  void warn(String message, [Object? error, StackTrace? stackTrace]);

  /// Records an error. [error] and [stackTrace] are optional.
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// No-op logger used when the caller does not provide one.
class DotsSilentLogger implements DotsLogger {
  /// Creates a silent logger.
  const DotsSilentLogger();

  @override
  void info(String message) {}

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}
