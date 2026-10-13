/// Signals emitted by the browser environment regarding visibility and focus.
enum BrowserLifecycleSignal {
  /// Document visibility changed to hidden (primary interruption signal)
  documentHidden,

  /// Document visibility changed to visible
  documentVisible,

  /// Window lost focus (supporting signal)
  windowBlur,

  /// Window regained focus
  windowFocus,
}
