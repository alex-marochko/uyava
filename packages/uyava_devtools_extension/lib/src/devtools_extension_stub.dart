import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart';

class DevToolsExtension extends StatelessWidget {
  const DevToolsExtension({
    super.key,
    required this.child,
    this.eventHandlers = const {},
    @Deprecated(
      'Set the requiresConnection field in the extension\'s config.yaml file instead.',
    )
    this.requiresRunningApplication = true,
  });

  final Widget child;
  final Map<dynamic, dynamic> eventHandlers;
  final bool requiresRunningApplication;

  @override
  Widget build(BuildContext context) => child;
}

ServiceManager get serviceManager {
  final existing = globals[ServiceManager] as ServiceManager<VmService>?;
  if (existing != null) {
    return existing;
  }
  final manager = ServiceManager<VmService>();
  setGlobal(ServiceManager, manager);
  return manager;
}
