part of 'package:uyava_example/main.dart';

mixin _EventChainsTabMixin on _ExampleAppStateBase, _EventChainsLogicMixin {
  Widget _buildEventChainsTab() {
    final bool loginReady = _loginChainDefined;
    final bool checkoutReady = _checkoutChainDefined;
    final bool profileReady = _profileChainDefined;

    List<Widget> buildStepList(List<_ChainStepTemplate> steps) {
      return steps
          .map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${step.stepId} → '
                '${_nodeLabels[step.nodeId] ?? step.nodeId}',
              ),
            ),
          )
          .toList(growable: false);
    }

    final List<Widget> loginStepWidgets = buildStepList(
      _loginChainSimulationSteps,
    );
    final List<Widget> checkoutStepWidgets = buildStepList(
      _checkoutChainSimulationSteps,
    );
    final List<Widget> profileStepWidgets = buildStepList(
      _profileChainSimulationSteps,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login Flow Chain',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define and simulate the expected authentication flow. Additional '
            'checkout and profile chains are registered automatically on app '
            'startup for quick filtering experiments. Open the Event Chains '
            'panel in DevTools or the desktop host to observe real-time '
            'progress and diagnostics.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                key: const ValueKey('define-login-chain-button'),
                onPressed: _defineLoginChain,
                icon: const Icon(Icons.rule),
                label: Text(
                  loginReady
                      ? 'Redefine Login Flow Chain'
                      : 'Define Login Flow Chain',
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('simulate-login-success-button'),
                onPressed: loginReady
                    ? () => _simulateLoginChainSuccess()
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Simulate successful attempt'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('simulate-login-failure-button'),
                onPressed: loginReady
                    ? () => _simulateLoginChainFailure()
                    : null,
                icon: const Icon(Icons.error_outline),
                label: const Text('Simulate out-of-order attempt'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('simulate-login-status-failure-button'),
                onPressed: loginReady
                    ? () => _simulateLoginChainStatusFailure()
                    : null,
                icon: const Icon(Icons.cancel),
                label: const Text('Simulate status-based failure'),
              ),
            ],
          ),
          if (_lastLoginAttemptId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last attempt: $_lastLoginAttemptId',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Login flow steps',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...loginStepWidgets,
          const SizedBox(height: 32),
          const Text(
            'Checkout Flow',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: checkoutReady
                    ? () => _simulateCheckoutChainSuccess()
                    : null,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Simulate successful checkout'),
              ),
              OutlinedButton.icon(
                onPressed: checkoutReady
                    ? () => _simulateCheckoutChainFailure()
                    : null,
                icon: const Icon(Icons.do_not_disturb_alt),
                label: const Text('Simulate checkout failure'),
              ),
            ],
          ),
          if (_lastCheckoutAttemptId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last checkout attempt: $_lastCheckoutAttemptId',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          ...checkoutStepWidgets,
          const SizedBox(height: 32),
          const Text(
            'Profile Update Flow',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: profileReady
                    ? () => _simulateProfileChainSuccess()
                    : null,
                icon: const Icon(Icons.person_pin_circle),
                label: const Text('Simulate successful update'),
              ),
              OutlinedButton.icon(
                onPressed: profileReady
                    ? () => _simulateProfileChainFailure()
                    : null,
                icon: const Icon(Icons.report_problem),
                label: const Text('Simulate update failure'),
              ),
            ],
          ),
          if (_lastProfileAttemptId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last profile attempt: $_lastProfileAttemptId',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          ...profileStepWidgets,
          const SizedBox(height: 24),
          const Text(
            'Tip: toggle the related feature groups in the Features tab to see '
            'how filters influence the chain visibility.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
