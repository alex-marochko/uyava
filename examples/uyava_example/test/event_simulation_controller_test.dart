import 'package:flutter_test/flutter_test.dart';
import 'package:uyava_example/src/simulation_controller.dart';

void main() {
  group('EventSimulationController', () {
    test('throws when start is called without a callback', () {
      final controller = EventSimulationController(
        timerFactory: _FakeTimerFactory().build,
      );
      expect(
        () => controller.start(const Duration(milliseconds: 10)),
        throwsA(isA<StateError>()),
      );
    });

    test('starts timer and triggers tick callback', () {
      final factory = _FakeTimerFactory();
      int tickCount = 0;
      final controller = EventSimulationController(timerFactory: factory.build);
      controller.setTickCallback(() {
        tickCount++;
      });

      controller.start(const Duration(milliseconds: 250));

      expect(controller.isRunning, isTrue);
      expect(
        factory.createdTimers.single.interval,
        const Duration(milliseconds: 250),
      );

      factory.createdTimers.single.fire();
      expect(tickCount, 1);
    });

    test('stop cancels timer and clears running flag', () {
      final factory = _FakeTimerFactory();
      final controller = EventSimulationController(timerFactory: factory.build);
      controller.setTickCallback(() {});
      controller.start(const Duration(milliseconds: 300));
      expect(controller.isRunning, isTrue);

      controller.stop();

      expect(controller.isRunning, isFalse);
      expect(factory.createdTimers.single.isActive, isFalse);
    });
  });
}

class _FakeTimerFactory {
  final List<_FakeSimulationTimer> createdTimers = <_FakeSimulationTimer>[];

  SimulationTimer build(Duration interval, SimulationTickCallback onTick) {
    final timer = _FakeSimulationTimer(interval, onTick);
    createdTimers.add(timer);
    return timer;
  }
}

class _FakeSimulationTimer implements SimulationTimer {
  _FakeSimulationTimer(this.interval, this._onTick);

  final Duration interval;
  final SimulationTickCallback _onTick;
  bool _isActive = true;

  void fire() {
    if (_isActive) {
      _onTick();
    }
  }

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;
}
