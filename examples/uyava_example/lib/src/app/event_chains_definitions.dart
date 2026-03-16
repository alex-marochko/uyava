part of 'package:uyava_example/main.dart';

const String _loginChainId = 'login_flow';
const List<String> _loginChainTags = <String>['auth', 'flow-login'];
const List<UyavaEventChainStep>
_loginChainDefinitionSteps = <UyavaEventChainStep>[
  UyavaEventChainStep(stepId: 'tap_button', nodeId: 'widget_login_button'),
  UyavaEventChainStep(stepId: 'validate_form', nodeId: 'util_form_validator'),
  UyavaEventChainStep(
    stepId: 'dispatch_auth',
    nodeId: 'bloc_auth',
    edgeId: 'e1',
  ),
  UyavaEventChainStep(
    stepId: 'persist_session',
    nodeId: 'repo_auth',
    edgeId: 'e2',
  ),
  UyavaEventChainStep(stepId: 'complete', nodeId: 'service_auth', edgeId: 'e3'),
];

const List<_ChainStepTemplate> _loginChainSimulationSteps =
    <_ChainStepTemplate>[
      _ChainStepTemplate(
        stepId: 'tap_button',
        nodeId: 'widget_login_button',
        message: 'Login button tapped',
        severity: UyavaSeverity.info,
      ),
      _ChainStepTemplate(
        stepId: 'validate_form',
        nodeId: 'util_form_validator',
        message: 'Validating credentials',
        severity: UyavaSeverity.debug,
      ),
      _ChainStepTemplate(
        stepId: 'dispatch_auth',
        nodeId: 'bloc_auth',
        edgeId: 'e1',
        message: 'Dispatching auth event',
        severity: UyavaSeverity.info,
      ),
      _ChainStepTemplate(
        stepId: 'persist_session',
        nodeId: 'repo_auth',
        edgeId: 'e2',
        message: 'Persisting auth session',
        severity: UyavaSeverity.info,
      ),
      _ChainStepTemplate(
        stepId: 'complete',
        nodeId: 'service_auth',
        edgeId: 'e3',
        message: 'User session active',
        severity: UyavaSeverity.info,
      ),
    ];

const List<_ChainStepTemplate> _loginChainFailureSteps = <_ChainStepTemplate>[
  _ChainStepTemplate(
    stepId: 'tap_button',
    nodeId: 'widget_login_button',
    message: 'Login button tapped',
    severity: UyavaSeverity.info,
  ),
  _ChainStepTemplate(
    stepId: 'complete',
    nodeId: 'service_auth',
    edgeId: 'e3',
    message: 'Auth failure',
    severity: UyavaSeverity.error,
  ),
];

const String _checkoutChainId = 'checkout_flow';
const List<String> _checkoutChainTags = <String>['order', 'flow-checkout'];
const List<UyavaEventChainStep> _checkoutChainDefinitionSteps =
    <UyavaEventChainStep>[
      UyavaEventChainStep(
        stepId: 'add_item',
        nodeId: 'widget_add_to_cart_button',
        edgeId: 'e61',
      ),
      UyavaEventChainStep(
        stepId: 'review_cart',
        nodeId: 'screen_cart',
        edgeId: 'e16',
      ),
      UyavaEventChainStep(
        stepId: 'select_payment',
        nodeId: 'screen_checkout_payment',
        edgeId: 'e127',
      ),
      UyavaEventChainStep(
        stepId: 'place_order',
        nodeId: 'widget_place_order_button',
        edgeId: 'e75',
      ),
      UyavaEventChainStep(
        stepId: 'persist_order',
        nodeId: 'repo_order',
        edgeId: 'e76',
      ),
      UyavaEventChainStep(
        stepId: 'charge_payment',
        nodeId: 'service_payment',
        edgeId: 'e21',
      ),
    ];

const List<_ChainStepTemplate> _checkoutChainSimulationSteps =
    <_ChainStepTemplate>[
      _ChainStepTemplate(
        stepId: 'add_item',
        nodeId: 'widget_add_to_cart_button',
        edgeId: 'e61',
        message: 'Item added to cart',
      ),
      _ChainStepTemplate(
        stepId: 'review_cart',
        nodeId: 'screen_cart',
        edgeId: 'e16',
        message: 'Reviewing order in cart',
      ),
      _ChainStepTemplate(
        stepId: 'select_payment',
        nodeId: 'screen_checkout_payment',
        edgeId: 'e127',
        message: 'Selecting payment method',
      ),
      _ChainStepTemplate(
        stepId: 'place_order',
        nodeId: 'widget_place_order_button',
        edgeId: 'e75',
        message: 'Placing order',
      ),
      _ChainStepTemplate(
        stepId: 'persist_order',
        nodeId: 'repo_order',
        edgeId: 'e76',
        message: 'Saving order record',
      ),
      _ChainStepTemplate(
        stepId: 'charge_payment',
        nodeId: 'service_payment',
        edgeId: 'e21',
        message: 'Charging customer card',
      ),
    ];

const List<_ChainStepTemplate> _checkoutChainFailureSteps =
    <_ChainStepTemplate>[
      _ChainStepTemplate(
        stepId: 'add_item',
        nodeId: 'widget_add_to_cart_button',
        edgeId: 'e61',
        message: 'Item added to cart',
      ),
      _ChainStepTemplate(
        stepId: 'charge_payment',
        nodeId: 'service_payment',
        edgeId: 'e21',
        message: 'Payment rejected',
        severity: UyavaSeverity.error,
      ),
    ];

const String _profileChainId = 'profile_update_flow';
const List<String> _profileChainTags = <String>[
  'profile',
  'settings',
  'flow-profile',
];
const List<UyavaEventChainStep> _profileChainDefinitionSteps =
    <UyavaEventChainStep>[
      UyavaEventChainStep(
        stepId: 'open_profile',
        nodeId: 'screen_profile',
        edgeId: 'e25',
      ),
      UyavaEventChainStep(
        stepId: 'apply_changes',
        nodeId: 'bloc_profile',
        edgeId: 'e26',
      ),
      UyavaEventChainStep(
        stepId: 'persist_user',
        nodeId: 'repo_user',
        edgeId: 'e27',
      ),
      UyavaEventChainStep(
        stepId: 'update_preferences',
        nodeId: 'service_user_preferences',
        edgeId: 'e80',
      ),
      UyavaEventChainStep(
        stepId: 'broadcast_settings',
        nodeId: 'bloc_settings',
        edgeId: 'e78',
      ),
    ];

const List<_ChainStepTemplate> _profileChainSimulationSteps =
    <_ChainStepTemplate>[
      _ChainStepTemplate(
        stepId: 'open_profile',
        nodeId: 'screen_profile',
        edgeId: 'e25',
        message: 'Profile opened',
      ),
      _ChainStepTemplate(
        stepId: 'apply_changes',
        nodeId: 'bloc_profile',
        edgeId: 'e26',
        message: 'Applying profile changes',
      ),
      _ChainStepTemplate(
        stepId: 'persist_user',
        nodeId: 'repo_user',
        edgeId: 'e27',
        message: 'Persisting user data',
      ),
      _ChainStepTemplate(
        stepId: 'update_preferences',
        nodeId: 'service_user_preferences',
        edgeId: 'e80',
        message: 'Updating user preferences',
      ),
      _ChainStepTemplate(
        stepId: 'broadcast_settings',
        nodeId: 'bloc_settings',
        edgeId: 'e78',
        message: 'Broadcasting new settings',
      ),
    ];

const List<_ChainStepTemplate> _profileChainFailureSteps = <_ChainStepTemplate>[
  _ChainStepTemplate(
    stepId: 'apply_changes',
    nodeId: 'bloc_profile',
    edgeId: 'e26',
    message: 'Attempting to update profile',
  ),
  _ChainStepTemplate(
    stepId: 'update_preferences',
    nodeId: 'service_user_preferences',
    edgeId: 'e80',
    message: 'Preference update failed',
    severity: UyavaSeverity.warn,
  ),
];

const List<_PredefinedChain> _additionalChainDefinitions = <_PredefinedChain>[
  _PredefinedChain(
    id: _checkoutChainId,
    tags: _checkoutChainTags,
    label: 'Checkout Flow',
    description: 'Covers cart review, checkout, and payment confirmation.',
    steps: _checkoutChainDefinitionSteps,
    successSimulation: _checkoutChainSimulationSteps,
    failureSimulation: _checkoutChainFailureSteps,
  ),
  _PredefinedChain(
    id: _profileChainId,
    tags: _profileChainTags,
    label: 'Profile Update Flow',
    description:
        'Documents how profile edits propagate through storage and settings.',
    steps: _profileChainDefinitionSteps,
    successSimulation: _profileChainSimulationSteps,
    failureSimulation: _profileChainFailureSteps,
  ),
];
