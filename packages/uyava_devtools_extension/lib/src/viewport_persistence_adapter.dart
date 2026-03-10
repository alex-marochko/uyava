import 'package:uyava_ui/uyava_ui.dart';

import 'viewport_persistence_adapter_stub.dart'
    if (dart.library.html) 'viewport_persistence_adapter_web.dart';

ViewportPersistenceAdapter createViewportPersistenceAdapter() =>
    createViewportPersistenceAdapterImpl();
