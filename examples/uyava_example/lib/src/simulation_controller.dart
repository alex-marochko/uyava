import 'dart:async';

typedef SimulationTickCallback = void Function();

/// Abstraction for timers driving the simulation so tests can provide fakes.
abstract class SimulationTimer {
  bool get isActive;
  void cancel();
}

typedef SimulationTimerFactory =
    SimulationTimer Function(Duration interval, SimulationTickCallback onTick);

/// Shared contract for controlling the start/stop simulation cycle.
abstract class SimulationController {
  bool get isRunning;

  void setTickCallback(SimulationTickCallback callback);

  void start(Duration interval);

  void stop();

  void dispose();
}

class EventSimulationController implements SimulationController {
  EventSimulationController({SimulationTimerFactory? timerFactory})
    : _timerFactory = timerFactory ?? _defaultSimulationTimerFactory;

  final SimulationTimerFactory _timerFactory;
  SimulationTimer? _timer;
  SimulationTickCallback? _tickCallback;

  @override
  bool get isRunning => _timer?.isActive ?? false;

  @override
  void setTickCallback(SimulationTickCallback callback) {
    _tickCallback = callback;
  }

  @override
  void start(Duration interval) {
    if (isRunning) return;
    final SimulationTickCallback? tick = _tickCallback;
    if (tick == null) {
      throw StateError(
        'Simulation tick callback is not configured. '
        'Call setTickCallback before starting the controller.',
      );
    }
    _timer = _timerFactory(interval, tick);
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
  }
}

SimulationTimer _defaultSimulationTimerFactory(
  Duration interval,
  SimulationTickCallback onTick,
) {
  return _RealSimulationTimer(Timer.periodic(interval, (_) => onTick()));
}

class _RealSimulationTimer implements SimulationTimer {
  _RealSimulationTimer(this._timer);

  final Timer _timer;

  @override
  void cancel() {
    _timer.cancel();
  }

  @override
  bool get isActive => _timer.isActive;
}
