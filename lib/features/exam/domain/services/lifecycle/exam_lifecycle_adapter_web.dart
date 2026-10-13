import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'browser_lifecycle_signal.dart';

/// Flutter Web implementation of [BrowserLifecycleAdapter] attaching native DOM listeners.
class BrowserLifecycleAdapter {
  final _signalController = StreamController<BrowserLifecycleSignal>.broadcast();
  bool _isActive = false;

  web.EventListener? _visibilityListener;
  web.EventListener? _blurListener;
  web.EventListener? _focusListener;

  Stream<BrowserLifecycleSignal> get signalStream => _signalController.stream;
  bool get isActive => _isActive;

  void start() {
    if (_isActive) return;
    _isActive = true;

    // Primary interruption signal: document.visibilitychange
    _visibilityListener = ((web.Event event) {
      if (!_isActive || _signalController.isClosed) return;
      if (web.document.visibilityState == 'hidden') {
        _signalController.add(BrowserLifecycleSignal.documentHidden);
      } else {
        _signalController.add(BrowserLifecycleSignal.documentVisible);
      }
    }).toJS;
    web.document.addEventListener('visibilitychange', _visibilityListener);

    // Supporting interruption signal: window.blur
    _blurListener = ((web.Event event) {
      if (!_isActive || _signalController.isClosed) return;
      _signalController.add(BrowserLifecycleSignal.windowBlur);
    }).toJS;
    web.window.addEventListener('blur', _blurListener);

    // Supporting resumption signal: window.focus
    _focusListener = ((web.Event event) {
      if (!_isActive || _signalController.isClosed) return;
      _signalController.add(BrowserLifecycleSignal.windowFocus);
    }).toJS;
    web.window.addEventListener('focus', _focusListener);
  }

  void stop() {
    if (!_isActive) return;
    _isActive = false;

    if (_visibilityListener != null) {
      web.document.removeEventListener('visibilitychange', _visibilityListener);
      _visibilityListener = null;
    }
    if (_blurListener != null) {
      web.window.removeEventListener('blur', _blurListener);
      _blurListener = null;
    }
    if (_focusListener != null) {
      web.window.removeEventListener('focus', _focusListener);
      _focusListener = null;
    }
  }

  /// Allows simulated events in testing environments.
  void emitSignal(BrowserLifecycleSignal signal) {
    if (_isActive && !_signalController.isClosed) {
      _signalController.add(signal);
    }
  }

  void dispose() {
    stop();
    _signalController.close();
  }
}
