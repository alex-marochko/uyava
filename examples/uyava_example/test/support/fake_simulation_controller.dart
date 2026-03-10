import 'package:uyava_example/src/simulation_controller.dart';

class FakeSimulationController implements SimulationController {
  bool _isRunning = false;
  SimulationTickCallback? _callback;
  int startCount = 0;
  int stopCount = 0;
  Duration? lastInterval;

  @override
  bool get isRunning => _isRunning;

  @override
  void dispose() {
    stop();
  }

  @override
  void setTickCallback(SimulationTickCallback callback) {
    _callback = callback;
  }

  @override
  void start(Duration interval) {
    if (_isRunning) return;
    _isRunning = true;
    lastInterval = interval;
    startCount++;
  }

  @override
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    stopCount++;
  }

  void tick() {
    if (!_isRunning) return;
    _callback?.call();
  }
}
