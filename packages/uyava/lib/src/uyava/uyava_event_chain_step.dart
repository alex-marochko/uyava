part of 'package:uyava/uyava.dart';

/// Describes a single step within an event chain definition.
class UyavaEventChainStep {
  const UyavaEventChainStep({
    required this.stepId,
    required this.nodeId,
    this.edgeId,
    this.expectedSeverity,
  });

  final String stepId;
  final String nodeId;
  final String? edgeId;
  final UyavaSeverity? expectedSeverity;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stepId': stepId,
      'nodeId': nodeId,
      if (edgeId != null) 'edgeId': edgeId,
      if (expectedSeverity != null) 'expectedSeverity': expectedSeverity!.name,
    };
  }
}
