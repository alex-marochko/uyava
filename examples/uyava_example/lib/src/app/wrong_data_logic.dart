part of 'package:uyava_example/main.dart';

mixin _WrongDataLogicMixin on _ExampleAppStateBase, _FeaturesGraphMixin {
  Future<void> _changeMinLogLevel(UyavaSeverity? level) async {
    if (level == null || _isUpdatingMinLevel || level == _minLogLevel) {
      return;
    }

    final UyavaSeverity previous = _minLogLevel;
    setState(() {
      _isUpdatingMinLevel = true;
      _minLogLevel = level;
    });

    final bool success = await updateFileLoggingMinLevel(level);
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (!success) {
      setState(() {
        _isUpdatingMinLevel = false;
        _minLogLevel = previous;
      });
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update the minimum logging level. Check the console.',
          ),
        ),
      );
      _bindDiscardStats();
      _bindArchiveEvents();
      return;
    }

    final UyavaFileTransport? refreshed = currentFileTransport();
    setState(() {
      _isUpdatingMinLevel = false;
      if (refreshed != null) {
        _minLogLevel = refreshed.config.minLevel;
      }
    });
    _bindDiscardStats();
    _bindArchiveEvents();

    messenger?.showSnackBar(
      SnackBar(
        content: Text('Saved minimum level: ${_severityLabel(_minLogLevel)}'),
      ),
    );
  }

  void _bindDiscardStats({bool initial = false}) {
    _discardStatsSubscription?.cancel();
    _discardStatsSubscription = null;

    final UyavaDiscardStats? snapshot = Uyava.latestDiscardStats;
    if (initial) {
      _discardStats = snapshot;
    } else if (mounted) {
      setState(() {
        _discardStats = snapshot;
      });
    } else {
      _discardStats = snapshot;
    }

    final Stream<UyavaDiscardStats>? stream = Uyava.discardStatsStream;
    if (stream == null) {
      return;
    }

    _discardStatsSubscription = stream.listen((UyavaDiscardStats stats) {
      if (!mounted) return;
      setState(() {
        _discardStats = stats;
      });
    });
  }

  void _bindArchiveEvents({bool initial = false}) {
    _archiveEventSubscription?.cancel();
    _archiveEventSubscription = null;

    final Stream<UyavaLogArchiveEvent>? stream = archiveEvents();
    if (stream == null) {
      if (mounted) {
        setState(() {
          _archiveStreamAvailable = false;
          _recentArchiveEvents.clear();
        });
      } else {
        _archiveStreamAvailable = false;
        _recentArchiveEvents.clear();
      }
      return;
    }

    if (mounted) {
      setState(() {
        _archiveStreamAvailable = true;
        if (initial) {
          _recentArchiveEvents.clear();
        }
      });
    } else {
      _archiveStreamAvailable = true;
      if (initial) {
        _recentArchiveEvents.clear();
      }
    }

    _archiveEventSubscription = stream.listen((UyavaLogArchiveEvent event) {
      if (!mounted) return;
      setState(() {
        _recentArchiveEvents.insert(0, event);
        const int maxEntries = 8;
        if (_recentArchiveEvents.length > maxEntries) {
          _recentArchiveEvents.removeRange(
            maxEntries,
            _recentArchiveEvents.length,
          );
        }
      });
    });
  }

  void _resetDiagnostics() {
    _diagnosticScenarioCounter = 0;
    _updateGraph();
    Uyava.clearDiagnostics();
  }

  Future<void> _cloneActiveArchive(BuildContext messengerContext) async {
    if (_isCloningLog) return;

    final ScaffoldMessengerState? scaffoldMessenger = ScaffoldMessenger.maybeOf(
      messengerContext,
    );
    if (scaffoldMessenger == null) {
      debugPrint(
        'Uyava Example: ScaffoldMessenger not found for clone button.',
      );
      return;
    }
    if (currentFileTransport() == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('File transport is not active, nothing to clone.'),
        ),
      );
      return;
    }

    setState(() {
      _isCloningLog = true;
    });

    try {
      final UyavaLogArchive? archive = await cloneActiveLogArchive();
      if (!mounted) return;

      if (archive == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to clone the active archive. Check the console.',
            ),
          ),
        );
        return;
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Clone ${archive.fileName} is ready (${formatArchiveSize(archive.sizeBytes)}).\n'
            'Path: ${archive.path}',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Uyava Example: failed to clone log archive: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isCloningLog = false;
        });
      } else {
        _isCloningLog = false;
      }
    }
  }

  Future<void> _sendLogArchive(BuildContext messengerContext) async {
    if (_isSendingLog) return;

    final ScaffoldMessengerState? scaffoldMessenger = ScaffoldMessenger.maybeOf(
      messengerContext,
    );
    if (scaffoldMessenger == null) {
      debugPrint(
        'Uyava Example: ScaffoldMessenger not found for export button.',
      );
      return;
    }
    if (currentFileTransport() == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('File transport is not active, nothing to export.'),
        ),
      );
      return;
    }

    final RenderBox? originBox =
        messengerContext.findRenderObject() as RenderBox?;
    final Rect? origin = originBox != null
        ? originBox.localToGlobal(Offset.zero) & originBox.size
        : null;

    setState(() {
      _isSendingLog = true;
    });

    try {
      final UyavaLogArchive? archive = await exportCurrentLogArchive();
      if (!mounted) return;

      if (archive == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to collect the log archive. Check the console.',
            ),
          ),
        );
        return;
      }

      final XFile attachment = XFile(
        archive.path,
        name: archive.fileName,
        mimeType: 'application/octet-stream',
      );

      final DateTime completedAt = archive.completedAt.toLocal();
      final String subject =
          'Uyava panic-tail ${completedAt.toIso8601String()}';
      final StringBuffer body = StringBuffer()
        ..writeln('Uyava panic-tail archive: ${archive.fileName}')
        ..writeln('Exported at: $completedAt')
        ..writeln('Size: ${archive.sizeBytes} bytes')
        ..writeln('Source: ${archive.sourcePath ?? archive.path}');

      await Share.shareXFiles(
        <XFile>[attachment],
        subject: subject,
        text: body.toString(),
        sharePositionOrigin: origin,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Archive ${archive.fileName} is ready (${archive.sizeBytes} bytes).\n'
            'Path: ${archive.path}',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Uyava Example: failed to send log archive: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to send log: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLog = false;
        });
      }
    }
  }

  void _emitSelfLoopEdge() {
    final int suffix = _diagnosticScenarioCounter++;
    final String nodeId = 'diag-self-loop-$suffix';
    final String edgeId = 'diag-self-loop-edge-$suffix';
    Uyava.loadGraph(
      nodes: [UyavaNode(id: nodeId, label: 'Self-loop demo #$suffix')],
      edges: [UyavaEdge(id: edgeId, from: nodeId, to: nodeId)],
    );
  }

  void _emitDuplicateNodeIds() {
    final int suffix = _diagnosticScenarioCounter++;
    final String nodeId = 'diag-duplicate-$suffix';
    Uyava.loadGraph(
      nodes: [
        UyavaNode(
          id: nodeId,
          label: 'Duplicate node base #$suffix',
          tags: const ['alpha'],
        ),
        UyavaNode(
          id: nodeId,
          label: 'Duplicate node override #$suffix',
          tags: const ['alpha', 'beta'],
        ),
      ],
    );
  }

  void _emitDanglingEdge() {
    final int suffix = _diagnosticScenarioCounter++;
    final String sourceOnly = 'diag-dangling-source-$suffix';
    final String supportNode = 'diag-dangling-support-$suffix';

    Uyava.addEdge(
      UyavaEdge(
        id: 'diag-dangling-edge-source-$suffix',
        from: sourceOnly, // missing in the graph
        to: supportNode,
      ),
    );

    Uyava.addNode(
      UyavaNode(id: supportNode, label: 'Dangling source support #$suffix'),
    );

    Uyava.addEdge(
      UyavaEdge(
        id: 'diag-dangling-edge-target-$suffix',
        from: supportNode,
        to: 'diag-dangling-missing-target-$suffix',
      ),
    );
  }

  void _emitDuplicateEdgeIds() {
    final int suffix = _diagnosticScenarioCounter++;
    final String from = 'diag-edge-src-$suffix';
    final String to = 'diag-edge-dst-$suffix';
    final String edgeId = 'diag-duplicate-edge-$suffix';

    Uyava.loadGraph(
      nodes: [
        UyavaNode(id: from, label: 'Edge source #$suffix'),
        UyavaNode(id: to, label: 'Edge target #$suffix'),
      ],
      edges: [
        UyavaEdge(id: edgeId, from: from, to: to),
        UyavaEdge(id: edgeId, from: from, to: to),
      ],
    );
  }

  void _triggerFlutterFrameworkError() {
    final StateError error = StateError(
      'Example Flutter error for Uyava panic-tail test',
    );
    final StackTrace stackTrace = StackTrace.current;

    debugPrint(
      'Uyava Example: reporting synthetic Flutter error for panic-tail test.',
    );

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'uyava_example panic-tail demo',
        context: ErrorDescription('Triggered via the Wrong data tab'),
        informationCollector: () sync* {
          yield ErrorDescription('trigger: wrong_data_tab');
          yield ErrorDescription('type: flutter');
        },
      ),
    );
  }

  void _triggerAsyncZoneError() {
    Future<void>.microtask(() {
      throw StateError('Example async zone error for Uyava panic-tail test');
    });
  }

  Future<void> _spawnIsolateCrash() async {
    final int id = _errorHookCounter++;
    final SendPort? port = UyavaBootstrap.isolateErrorPort;
    if (port == null) {
      _showSnack('Enable isolate errors first to capture worker crashes.');
      return;
    }

    final ReceivePort exitPort = ReceivePort();
    await Isolate.spawn<SendPort?>(
      (SendPort? errorPort) {
        Future<void>.microtask(() {
          throw StateError(
            'Example isolate panic #$id for Uyava panic-tail test',
          );
        });
      },
      port,
      onError: port,
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
    );
    await exitPort.first;
    exitPort.close();
    _showSnack('Spawned isolate crashed; check journal for isolate errors.');
  }

  void _throwAsyncOutsideGuard() {
    final int id = _errorHookCounter++;
    Zone.root.run(() {
      Future<void>.microtask(() {
        throw StateError('Async error outside UyavaBootstrap.runZoned #$id');
      });
    });
  }

  void _overrideOnErrorAndPresent() {
    final int id = _errorHookCounter++;
    if (UyavaBootstrap.isolateErrorPort == null) {
      _showSnack(
        'Global error handlers не підключені (нема file logging?) — guard може не спрацювати.',
      );
    }
    UyavaBootstrap.ensurePresentErrorHook();
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails _) {
      // Intentionally swallow to exercise presentError fallback.
    };
    FlutterError.presentError(
      FlutterErrorDetails(
        exception: StateError('presentError-only failure #$id'),
        stack: StackTrace.current,
        library: 'uyava_example wrong_data',
        context: ErrorDescription('Triggered via Error hooks card'),
      ),
    );
    FlutterError.onError = previous;
  }

  void _emitNonFatalFlutterError() {
    final int id = _errorHookCounter++;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: Exception(
          'Non-fatal Flutter error (emitNonFatal toggle) #$id',
        ),
        stack: StackTrace.current,
        library: 'uyava_example wrong_data',
        context: ErrorDescription('Non-fatal scenario via Error hooks card'),
      ),
    );
  }

  Future<void> _applyErrorOptions({
    bool? enableIsolateErrors,
    bool? captureCurrentIsolateErrors,
    bool? emitNonFatalDiagnostics,
  }) async {
    if (_errorOptionsUpdating) {
      return;
    }
    final int id = _errorHookCounter++;
    final UyavaGlobalErrorOptions next = _globalErrorOptions.copyWith(
      enableIsolateErrors: enableIsolateErrors,
      captureCurrentIsolateErrors: captureCurrentIsolateErrors,
      emitNonFatalDiagnostics: emitNonFatalDiagnostics,
    );
    setState(() {
      _errorOptionsUpdating = true;
      _globalErrorOptions = next;
      _isolateErrorsEnabled = next.enableIsolateErrors;
      _captureCurrentIsolateErrors = next.captureCurrentIsolateErrors;
      _emitNonFatalDiagnostics = next.emitNonFatalDiagnostics;
    });
    try {
      await updateGlobalErrorOptions(next);
    } finally {
      if (mounted) {
        setState(() {
          _errorOptionsUpdating = false;
        });
      } else {
        _errorOptionsUpdating = false;
      }
    }
    _showSnack(
      'Updated error hooks (rev $id): isolate=${next.enableIsolateErrors}, '
      'captureCurrent=${next.captureCurrentIsolateErrors}, '
      'diagnostics=${next.emitNonFatalDiagnostics}',
    );
  }

  void _attachPanicDiagnosticObserver() {
    // ignore: invalid_use_of_visible_for_testing_member
    _previousPostEventObserver = Uyava.postEventObserver;
    void panicObserver(String type, Map<String, dynamic> payload) {
      _previousPostEventObserver?.call(type, payload);
      if (type == UyavaEventTypes.graphDiagnostics &&
          payload['code'] == 'logging.panic_tail_captured') {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(payload);
        if (mounted) {
          setState(() {
            _lastPanicDiagnostic = copy;
          });
        } else {
          _lastPanicDiagnostic = copy;
        }
      }
    }

    _panicPostEventObserver = panicObserver;
    // ignore: invalid_use_of_visible_for_testing_member
    Uyava.postEventObserver = panicObserver;
  }

  void _crashWithFlutterFrameworkError() {
    updateGlobalErrorOptions(
      const UyavaGlobalErrorOptions(
        delegateOriginalHandlers: true,
        propagateToZone: true,
      ),
    ).then((_) {
      debugPrint('Uyava Example: entering crash mode via Flutter error.');
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: StateError('Crash Flutter error for Uyava panic-tail demo'),
        stack: StackTrace.current,
        library: 'uyava_example crash demo',
        context: ErrorDescription('Crash mode via Wrong data tab'),
      );
      FlutterError.reportError(details);
    });
  }

  void _crashWithAsyncZoneError() {
    updateGlobalErrorOptions(
      const UyavaGlobalErrorOptions(
        delegateOriginalHandlers: true,
        propagateToZone: true,
      ),
    ).then((_) {
      debugPrint('Uyava Example: entering crash mode via async zone error.');
      Future<void>.microtask(() {
        throw StateError('Crash async zone error for Uyava panic-tail demo');
      });
    });
  }
}
