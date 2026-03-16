part of 'package:uyava_example/main.dart';

Map<String, List<UyavaNode>> generateFeatureNodes() {
  final Map<String, List<UyavaNode>> features = <String, List<UyavaNode>>{
    'Authentication': authenticationNodes(),
    'Restaurant Feed': restaurantFeedNodes(),
    'Order & Checkout': orderAndCheckoutNodes(),
    'Profile & Settings': profileAndSettingsNodes(),
    'Real-time Tracking': realTimeTrackingNodes(),
    'Customer Support': customerSupportNodes(),
  };
  return _decorateFeatureNodesWithTags(features);
}
