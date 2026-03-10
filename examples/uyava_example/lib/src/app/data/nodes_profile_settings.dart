part of 'package:uyava_example/main.dart';

List<UyavaNode> profileAndSettingsNodes() {
  return <UyavaNode>[
    UyavaNode.standard(
      id: 'feat_profile',
      standardType: UyavaStandardType.group,
      label: 'Profile & Settings',
    ),
    UyavaNode.standard(
      id: 'screen_profile',
      standardType: UyavaStandardType.screen,
      label: 'Profile Screen',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'widget_avatar',
      standardType: UyavaStandardType.widget,
      label: 'User Avatar',
      parentId: 'screen_profile',
    ),
    UyavaNode.standard(
      id: 'widget_order_history',
      standardType: UyavaStandardType.widget,
      label: 'Order History List',
      parentId: 'screen_profile',
    ),
    UyavaNode.standard(
      id: 'widget_order_history_details_view',
      standardType: UyavaStandardType.widget,
      label: 'Order History Details',
      parentId: 'widget_order_history',
    ),
    UyavaNode.standard(
      id: 'widget_theme_switch',
      standardType: UyavaStandardType.widget,
      label: 'Theme Switch',
      parentId: 'screen_profile',
    ),
    UyavaNode.standard(
      id: 'widget_logout_button',
      standardType: UyavaStandardType.widget,
      label: 'Logout Button',
      parentId: 'screen_profile',
    ),
    UyavaNode.standard(
      id: 'widget_help_center_link',
      standardType: UyavaStandardType.widget,
      label: 'Help Center Link',
      parentId: 'screen_profile',
    ),
    UyavaNode.standard(
      id: 'screen_settings',
      standardType: UyavaStandardType.screen,
      label: 'Settings Screen',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'screen_manage_addresses',
      standardType: UyavaStandardType.screen,
      label: 'Manage Addresses',
      parentId: 'screen_settings',
    ),
    UyavaNode.standard(
      id: 'widget_editable_address_card',
      standardType: UyavaStandardType.widget,
      label: 'Editable Address Card',
      parentId: 'screen_manage_addresses',
    ),
    UyavaNode.standard(
      id: 'screen_manage_payment_methods',
      standardType: UyavaStandardType.screen,
      label: 'Manage Payment Methods',
      parentId: 'screen_settings',
    ),
    UyavaNode.standard(
      id: 'widget_editable_payment_card',
      standardType: UyavaStandardType.widget,
      label: 'Editable Payment Card',
      parentId: 'screen_manage_payment_methods',
    ),
    UyavaNode.standard(
      id: 'screen_notification_settings',
      standardType: UyavaStandardType.screen,
      label: 'Notification Settings',
      parentId: 'screen_settings',
    ),
    UyavaNode.standard(
      id: 'widget_notification_toggle',
      standardType: UyavaStandardType.widget,
      label: 'Notification Toggle',
      parentId: 'screen_notification_settings',
    ),
    UyavaNode.standard(
      id: 'bloc_profile',
      standardType: UyavaStandardType.bloc,
      label: 'Profile BLoC',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'bloc_settings',
      standardType: UyavaStandardType.bloc,
      label: 'Settings BLoC',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'repo_user',
      standardType: UyavaStandardType.repository,
      label: 'User Repository',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'repo_settings',
      standardType: UyavaStandardType.repository,
      label: 'Settings Repository',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'service_theme',
      standardType: UyavaStandardType.service,
      label: 'Theme Service',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'service_notifications',
      standardType: UyavaStandardType.service,
      label: 'Push Notifications',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'service_user_preferences',
      standardType: UyavaStandardType.service,
      label: 'User Preferences',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'util_local_storage',
      standardType: UyavaStandardType.usecase,
      label: 'Local Storage Util',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'model_user',
      standardType: UyavaStandardType.model,
      label: 'User Model',
      parentId: 'feat_profile',
    ),
    UyavaNode.standard(
      id: 'model_user_settings',
      standardType: UyavaStandardType.model,
      label: 'User Settings Model',
      parentId: 'feat_profile',
    ),
  ];
}
