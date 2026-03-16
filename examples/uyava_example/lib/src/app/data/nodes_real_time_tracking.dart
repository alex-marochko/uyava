part of 'package:uyava_example/main.dart';

List<UyavaNode> realTimeTrackingNodes() {
  return <UyavaNode>[
    UyavaNode.standard(
      id: 'feat_tracking',
      standardType: UyavaStandardType.group,
      label: 'Real-time Tracking',
    ),
    UyavaNode.standard(
      id: 'screen_tracking',
      standardType: UyavaStandardType.screen,
      label: 'Order Tracking Screen',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_map_view',
      standardType: UyavaStandardType.widget,
      label: 'Map View',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_courier_details_card',
      standardType: UyavaStandardType.widget,
      label: 'Courier Details',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_order_status_stepper',
      standardType: UyavaStandardType.widget,
      label: 'Order Status Stepper',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_estimated_delivery_time',
      standardType: UyavaStandardType.widget,
      label: 'ETA Display',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_call_courier_button',
      standardType: UyavaStandardType.widget,
      label: 'Call Courier Button',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_report_issue_button',
      standardType: UyavaStandardType.widget,
      label: 'Report Issue Button',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'widget_rate_delivery_button',
      standardType: UyavaStandardType.widget,
      label: 'Rate Delivery Button',
      parentId: 'screen_tracking',
    ),
    UyavaNode.standard(
      id: 'cubit_order',
      standardType: UyavaStandardType.bloc,
      label: 'Order Status Cubit',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'cubit_tracking_details',
      standardType: UyavaStandardType.bloc,
      label: 'Tracking Details Cubit',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'service_socket',
      standardType: UyavaStandardType.event,
      label: 'Order WebSocket',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'service_location',
      standardType: UyavaStandardType.service,
      label: 'Location Service',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'service_map_provider',
      standardType: UyavaStandardType.service,
      label: 'Map Provider SDK',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'repo_tracking',
      standardType: UyavaStandardType.repository,
      label: 'Tracking Repository',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'util_polyline_decoder',
      standardType: UyavaStandardType.usecase,
      label: 'Polyline Decoder',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'util_eta_calculator',
      standardType: UyavaStandardType.usecase,
      label: 'ETA Calculator',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'model_courier',
      standardType: UyavaStandardType.model,
      label: 'Courier Model',
      parentId: 'feat_tracking',
    ),
    UyavaNode.standard(
      id: 'model_route',
      standardType: UyavaStandardType.model,
      label: 'Route Model',
      parentId: 'feat_tracking',
    ),
  ];
}
