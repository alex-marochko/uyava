import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';

import 'src/devtools_extension_stub.dart'
    if (dart.library.js_interop) 'package:devtools_extensions/devtools_extensions.dart';

typedef ExtensionEventHandler = void Function(Event event);
typedef InitialGraphFetcher = Future<void> Function();

class DevToolsVmEventBridge {
  DevToolsVmEventBridge({
    required this.onExtensionEvent,
    required this.onFetchInitialGraph,
  });

  final ExtensionEventHandler onExtensionEvent;
  final InitialGraphFetcher onFetchInitialGraph;

  StreamSubscription<Event>? _eventSubscription;
  VoidCallback? _connectedListener;

  void ensureSubscribed() {
    if (_eventSubscription != null) {
      return;
    }
    if (serviceManager.connectedState.value.connected) {
      _fetchAndSubscribe();
    } else {
      _connectedListener ??= () {
        if (!serviceManager.connectedState.value.connected) {
          return;
        }
        _fetchAndSubscribe();
        if (_connectedListener != null) {
          serviceManager.connectedState.removeListener(_connectedListener!);
          _connectedListener = null;
        }
      };
      serviceManager.connectedState.addListener(_connectedListener!);
    }
  }

  void _fetchAndSubscribe() {
    onFetchInitialGraph();
    _eventSubscription = serviceManager.service!.onExtensionEvent.listen(
      onExtensionEvent,
      onError: (error) => developer.log(
        '[Uyava DevTools] Error listening to extension events: $error',
        name: 'Uyava DevTools',
        level: 1000,
      ),
    );
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    if (_connectedListener != null) {
      serviceManager.connectedState.removeListener(_connectedListener!);
      _connectedListener = null;
    }
  }
}
