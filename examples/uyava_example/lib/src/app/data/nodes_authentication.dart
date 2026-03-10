part of 'package:uyava_example/main.dart';

List<UyavaNode> authenticationNodes() {
  return <UyavaNode>[
    UyavaNode.standard(
      id: 'feat_auth',
      standardType: UyavaStandardType.group,
      label: 'Authentication',
    ),
    UyavaNode.standard(
      id: 'screen_login',
      standardType: UyavaStandardType.screen,
      label: 'Login Screen',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'widget_email_field',
      standardType: UyavaStandardType.widget,
      label: 'Email Field',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'widget_password_field',
      standardType: UyavaStandardType.widget,
      label: 'Password Field',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'widget_login_button',
      standardType: UyavaStandardType.widget,
      label: 'Login Button',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'widget_forgot_password_link',
      standardType: UyavaStandardType.widget,
      label: 'Forgot Password Link',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'widget_signup_link',
      standardType: UyavaStandardType.widget,
      label: 'Sign-up Link',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'screen_register',
      standardType: UyavaStandardType.screen,
      label: 'Registration Screen',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'widget_name_field',
      standardType: UyavaStandardType.widget,
      label: 'Name Field',
      parentId: 'screen_register',
    ),
    UyavaNode.standard(
      id: 'widget_register_button',
      standardType: UyavaStandardType.widget,
      label: 'Register Button',
      parentId: 'screen_register',
    ),
    UyavaNode.standard(
      id: 'screen_forgot_password',
      standardType: UyavaStandardType.screen,
      label: 'Forgot Password Screen',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'widget_reset_password_button',
      standardType: UyavaStandardType.widget,
      label: 'Reset Password Button',
      parentId: 'screen_forgot_password',
    ),
    UyavaNode.standard(
      id: 'widget_social_login_google',
      standardType: UyavaStandardType.widget,
      label: 'Google Login',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'widget_social_login_apple',
      standardType: UyavaStandardType.widget,
      label: 'Apple Login',
      parentId: 'screen_login',
    ),
    UyavaNode.standard(
      id: 'util_form_validator',
      standardType: UyavaStandardType.usecase,
      label: 'Form Validator',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'bloc_auth',
      standardType: UyavaStandardType.bloc,
      label: 'Auth BLoC',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'bloc_registration',
      standardType: UyavaStandardType.bloc,
      label: 'Registration BLoC',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'repo_auth',
      standardType: UyavaStandardType.repository,
      label: 'Auth Repository',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'repo_password_reset',
      standardType: UyavaStandardType.repository,
      label: 'Password Reset Repo',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'service_auth',
      standardType: UyavaStandardType.service,
      label: 'Auth Service',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'service_social_auth',
      standardType: UyavaStandardType.service,
      label: 'Social Auth Service',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'util_token_decoder',
      standardType: UyavaStandardType.usecase,
      label: 'Token Decoder',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'util_deep_link_handler',
      standardType: UyavaStandardType.usecase,
      label: 'Deep Link Handler',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'storage_secure',
      standardType: UyavaStandardType.database,
      label: 'Secure Storage',
      parentId: 'feat_auth',
    ),
    UyavaNode.standard(
      id: 'model_session',
      standardType: UyavaStandardType.model,
      label: 'Session Model',
      parentId: 'feat_auth',
    ),
  ];
}
