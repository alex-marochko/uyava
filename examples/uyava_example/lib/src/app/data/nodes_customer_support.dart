part of 'package:uyava_example/main.dart';

List<UyavaNode> customerSupportNodes() {
  return <UyavaNode>[
    UyavaNode.standard(
      id: 'feat_support',
      standardType: UyavaStandardType.group,
      label: 'Customer Support',
    ),
    UyavaNode.standard(
      id: 'screen_support_center',
      standardType: UyavaStandardType.screen,
      label: 'Support Center',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'widget_faq_list',
      standardType: UyavaStandardType.widget,
      label: 'FAQ List',
      parentId: 'screen_support_center',
    ),
    UyavaNode.standard(
      id: 'widget_faq_item',
      standardType: UyavaStandardType.widget,
      label: 'FAQ Item',
      parentId: 'widget_faq_list',
    ),
    UyavaNode.standard(
      id: 'widget_start_chat_button',
      standardType: UyavaStandardType.widget,
      label: 'Start Chat Button',
      parentId: 'screen_support_center',
    ),
    UyavaNode.standard(
      id: 'screen_support_chat',
      standardType: UyavaStandardType.screen,
      label: 'Support Chat Screen',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'widget_chat_bubble',
      standardType: UyavaStandardType.widget,
      label: 'Chat Bubble',
      parentId: 'screen_support_chat',
    ),
    UyavaNode.standard(
      id: 'widget_message_input_field',
      standardType: UyavaStandardType.widget,
      label: 'Message Input',
      parentId: 'screen_support_chat',
    ),
    UyavaNode.standard(
      id: 'widget_send_message_button',
      standardType: UyavaStandardType.widget,
      label: 'Send Button',
      parentId: 'screen_support_chat',
    ),
    UyavaNode.standard(
      id: 'widget_typing_indicator',
      standardType: UyavaStandardType.widget,
      label: 'Typing Indicator',
      parentId: 'screen_support_chat',
    ),
    UyavaNode.standard(
      id: 'widget_attachment_button',
      standardType: UyavaStandardType.widget,
      label: 'Attachment Button',
      parentId: 'screen_support_chat',
    ),
    UyavaNode.standard(
      id: 'bloc_support_chat',
      standardType: UyavaStandardType.bloc,
      label: 'Support Chat BLoC',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'repo_chat_history',
      standardType: UyavaStandardType.repository,
      label: 'Chat History Repo',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'service_chat_websocket',
      standardType: UyavaStandardType.event,
      label: 'Chat WebSocket',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'util_text_sanitizer',
      standardType: UyavaStandardType.usecase,
      label: 'Text Sanitizer',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'model_chat_message',
      standardType: UyavaStandardType.model,
      label: 'Chat Message Model',
      parentId: 'feat_support',
    ),
    UyavaNode.standard(
      id: 'model_faq_item',
      standardType: UyavaStandardType.model,
      label: 'FAQ Item Model',
      parentId: 'feat_support',
    ),
  ];
}
