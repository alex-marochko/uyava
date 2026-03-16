part of '../console_logger.dart';

/// Abstraction for console sinks used by the logger worker.
abstract class ConsoleSink {
  void write(String line);
  Future<void> flush();
}

/// Wraps a standard [IOSink] for compatibility with [ConsoleSink].
class IoConsoleSink implements ConsoleSink {
  IoConsoleSink(this.inner);

  final IOSink inner;

  @override
  void write(String line) => inner.writeln(line);

  @override
  Future<void> flush() => inner.flush();
}
