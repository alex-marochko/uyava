/// A set of predefined, recommended types for Uyava nodes.
///
/// Using these standard types allows the Uyava DevTools extension to apply
/// consistent styling and semantic analysis.
enum UyavaStandardType {
  // UI Layer
  widget,
  screen,

  // State Management
  bloc,
  provider,
  riverpod,
  state,

  // Business Logic
  service,
  repository,
  usecase,
  manager,

  // Data Layer
  database,
  api,
  source,
  model,

  // Messaging
  stream,
  queue,
  event,

  // Generic & Structural
  group,
  sensor,
  ai,
}
