part of 'package:uyava_example/main.dart';

mixin _EventChainsLogicMixin on _ExampleAppStateBase {
  void _defineLoginChain({bool silently = false}) {
    try {
      Uyava.defineEventChain(
        id: _loginChainId,
        tags: _loginChainTags,
        label: 'Login Flow',
        description: 'Happy-path steps when a user signs in.',
        steps: _loginChainDefinitionSteps,
      );
      void updateState() {
        _loginChainDefined = true;
        _loginChainAttemptCounter = 0;
        _lastLoginAttemptId = null;
      }

      if (silently) {
        updateState();
      } else if (mounted) {
        setState(updateState);
        _showSnack('Defined login flow chain');
      } else {
        updateState();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to define chain: $error\n$stackTrace');
      if (!silently) {
        _showSnack('Failed to define login flow chain: $error');
      }
    }
  }

  void _defineDefaultEventChains({bool silent = false}) {
    _defineLoginChain(silently: silent);
    for (final _PredefinedChain chain in _additionalChainDefinitions) {
      try {
        Uyava.defineEventChain(
          id: chain.id,
          tags: chain.tags,
          label: chain.label,
          description: chain.description,
          steps: chain.steps,
        );
        void markChainReady() {
          if (chain.id == _checkoutChainId) {
            _checkoutChainDefined = true;
            _checkoutChainAttemptCounter = 0;
            _lastCheckoutAttemptId = null;
          } else if (chain.id == _profileChainId) {
            _profileChainDefined = true;
            _profileChainAttemptCounter = 0;
            _lastProfileAttemptId = null;
          }
        }

        if (silent || !mounted) {
          markChainReady();
        } else {
          setState(markChainReady);
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to define chain ${chain.id}: $error\n$stackTrace');
        if (!silent) {
          _showSnack('Failed to define ${chain.label}: $error');
        }
      }
    }
  }

  Future<void> _simulateLoginChainSuccess() async {
    if (!_ensureLoginChainReady()) return;
    final String attemptId = _nextLoginAttemptId();
    await _runChainSimulation(
      chainId: _loginChainId,
      steps: _loginChainSimulationSteps,
      attemptId: attemptId,
    );
    setState(() => _lastLoginAttemptId = attemptId);
    _showSnack('Simulated successful login chain attempt ($attemptId)');
  }

  Future<void> _simulateLoginChainFailure() async {
    if (!_ensureLoginChainReady()) return;
    final String attemptId = _nextLoginAttemptId();
    await _runChainSimulation(
      chainId: _loginChainId,
      steps: _loginChainFailureSteps,
      attemptId: attemptId,
      markLastAsFailure: true,
    );
    setState(() => _lastLoginAttemptId = attemptId);
    _showSnack('Simulated out-of-order login chain attempt ($attemptId)');
  }

  Future<void> _simulateLoginChainStatusFailure() async {
    if (!_ensureLoginChainReady()) return;
    final String attemptId = _nextLoginAttemptId();
    await _runChainSimulation(
      chainId: _loginChainId,
      steps: _loginChainSimulationSteps,
      attemptId: attemptId,
      markLastAsFailure: true,
    );
    setState(() => _lastLoginAttemptId = attemptId);
    _showSnack('Simulated status-based login failure ($attemptId)');
  }

  bool _ensureLoginChainReady() {
    if (_loginChainDefined) {
      return true;
    }
    _showSnack('Define the login flow chain first');
    return false;
  }

  String _nextLoginAttemptId() {
    _loginChainAttemptCounter += 1;
    return 'loginAttempt_${_loginChainAttemptCounter.toString().padLeft(2, '0')}';
  }

  bool _ensureCheckoutChainReady() {
    if (_checkoutChainDefined) {
      return true;
    }
    _showSnack('Define the checkout flow chain first');
    return false;
  }

  bool _ensureProfileChainReady() {
    if (_profileChainDefined) {
      return true;
    }
    _showSnack('Define the profile update chain first');
    return false;
  }

  String _nextCheckoutAttemptId() {
    _checkoutChainAttemptCounter += 1;
    return 'checkoutAttempt_${_checkoutChainAttemptCounter.toString().padLeft(2, '0')}';
  }

  String _nextProfileAttemptId() {
    _profileChainAttemptCounter += 1;
    return 'profileAttempt_${_profileChainAttemptCounter.toString().padLeft(2, '0')}';
  }

  Future<void> _simulateCheckoutChainSuccess() async {
    if (!_ensureCheckoutChainReady()) return;
    final String attemptId = _nextCheckoutAttemptId();
    await _runChainSimulation(
      chainId: _checkoutChainId,
      steps: _checkoutChainSimulationSteps,
      attemptId: attemptId,
    );
    setState(() => _lastCheckoutAttemptId = attemptId);
    _showSnack('Simulated successful checkout attempt ($attemptId)');
  }

  Future<void> _simulateCheckoutChainFailure() async {
    if (!_ensureCheckoutChainReady()) return;
    final String attemptId = _nextCheckoutAttemptId();
    await _runChainSimulation(
      chainId: _checkoutChainId,
      steps: _checkoutChainFailureSteps,
      attemptId: attemptId,
      markLastAsFailure: true,
    );
    setState(() => _lastCheckoutAttemptId = attemptId);
    _showSnack('Simulated failed checkout attempt ($attemptId)');
  }

  Future<void> _simulateProfileChainSuccess() async {
    if (!_ensureProfileChainReady()) return;
    final String attemptId = _nextProfileAttemptId();
    await _runChainSimulation(
      chainId: _profileChainId,
      steps: _profileChainSimulationSteps,
      attemptId: attemptId,
    );
    setState(() => _lastProfileAttemptId = attemptId);
    _showSnack('Simulated successful profile update ($attemptId)');
  }

  Future<void> _simulateProfileChainFailure() async {
    if (!_ensureProfileChainReady()) return;
    final String attemptId = _nextProfileAttemptId();
    await _runChainSimulation(
      chainId: _profileChainId,
      steps: _profileChainFailureSteps,
      attemptId: attemptId,
      markLastAsFailure: true,
    );
    setState(() => _lastProfileAttemptId = attemptId);
    _showSnack('Simulated failed profile update ($attemptId)');
  }

  Future<void> _runChainSimulation({
    required String chainId,
    required List<_ChainStepTemplate> steps,
    required String attemptId,
    bool markLastAsFailure = false,
  }) async {
    if (steps.isEmpty) {
      _showSnack('No steps configured for $chainId');
      return;
    }
    for (var index = 0; index < steps.length; index++) {
      final _ChainStepTemplate step = steps[index];
      final bool isLast = index == steps.length - 1;
      _emitChainStep(
        chainId: chainId,
        step: step,
        attemptId: attemptId,
        markFailure: markLastAsFailure && isLast,
      );
      if (!isLast) {
        await Future<void>.delayed(_chainStepDelay);
      }
    }
  }

  void _emitChainStep({
    required String chainId,
    required _ChainStepTemplate step,
    required String attemptId,
    bool markFailure = false,
  }) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'chain': <String, dynamic>{
        'id': chainId,
        'step': step.stepId,
        'attempt': attemptId,
      },
    };
    if (step.message != null) {
      payload['message'] = step.message;
    }
    if (step.edgeId != null) {
      payload['edgeId'] = step.edgeId;
    }
    if (markFailure) {
      payload['status'] = 'failed';
    }

    final String eventMessage =
        step.message ??
        (markFailure
            ? 'Chain $chainId failed at ${step.stepId}'
            : 'Chain $chainId progressed to ${step.stepId}');

    Uyava.emitNodeEvent(
      nodeId: step.nodeId,
      message: eventMessage,
      severity: step.severity,
      payload: payload,
    );
  }
}
