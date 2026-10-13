import 'dart:async';
import 'browser_lifecycle_signal.dart';

/// Platform-agnostic stub implementation of [BrowserLifecycleAdapter] for tests and non-web platforms.
class BrowserLifecycleAdapter {
  final _signalController = StreamController<BrowserLifecycleSignal>.broadcast();
  bool _isActive = false;

  Stream<BrowserLifecycleSignal> get signalStream => _signalController.stream;
  bool get isActive => _isActive;

  void start() {
    _isActive = true;
  }

  void stop() {
    _isActive = false;
  }

  /// Enables unit and widget tests to inject deterministic browser lifecycle events.
  void emitSignal(BrowserLifecycleSignal signal) {
    if (_isActive && !_signalController.isClosed) {
      _signalController.add(signal);
    }
  }

  void dispose() {
    _isActive = false;
    _signalController.close();
  }
}
