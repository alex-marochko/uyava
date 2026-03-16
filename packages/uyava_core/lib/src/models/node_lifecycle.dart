import 'package:uyava_protocol/uyava_protocol.dart';

/// Backwards-compatible alias for the shared lifecycle enum exposed
/// through `uyava_protocol`. Core code can keep referring to
/// [NodeLifecycle] while interoperating with SDK payloads.
typedef NodeLifecycle = UyavaLifecycleState;
