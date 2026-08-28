import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

/// Two-way channel: read-side pushes (`message:new`/`typing`/`notification:new`)
/// arrive as bare [events] for callers to react to; write-side actions
/// (send message, typing pulse, mark read) go through [request], which
/// resolves to `null` on any failure (not connected, timeout, error ack) so
/// callers can transparently fall back to REST. Nothing depends on this
/// socket being up — it's a latency/load optimization, never the only path.
final class RealtimeSocketService with WidgetsBindingObserver {
  RealtimeSocketService(this._auth);

  static const _reconnectDelay = Duration(seconds: 5);

  final AuthRepository _auth;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  var _foreground = true;
  var _stopped = true;
  var _reqCounter = 0;

  final _connectedNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get connected => _connectedNotifier;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _controller.stream;

  void start() {
    if (!_stopped) return;
    _stopped = false;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_connect());
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_channel?.sink.close());
    _channel = null;
    _connectedNotifier.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _foreground;
    _foreground = state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached;
    if (_foreground && !wasForeground) {
      unawaited(_connect());
    } else if (!_foreground && wasForeground) {
      // Drop the socket in background — nothing to push to, saves battery.
      unawaited(_sub?.cancel());
      unawaited(_channel?.sink.close());
      _channel = null;
      _connectedNotifier.value = false;
    }
  }

  Future<void> _connect() async {
    if (_stopped || !_foreground || _channel != null) return;
    final userId = _auth.backendUserId?.trim() ?? '';
    if (userId.isEmpty) {
      _scheduleReconnect();
      return;
    }

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      token = null;
    }
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }

    try {
      final channel = WebSocketChannel.connect(Uri.parse(_wsUrl()));
      await channel.ready;
      if (_stopped || !_foreground) {
        unawaited(channel.sink.close());
        return;
      }
      _channel = channel;
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      _sub = channel.stream.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      _scheduleReconnect();
    }
  }

  /// Sends `payload` and waits for the matching `{type:'ack', reqId, ok}`.
  /// Returns the decoded ack map, or `null` if the socket isn't connected,
  /// the request times out, or the send itself throws — callers treat any
  /// of those the same way: fall back to REST.
  Future<Map<String, dynamic>?> request(
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final channel = _channel;
    if (channel == null || !_connectedNotifier.value) return null;

    final reqId = 'req-${DateTime.now().microsecondsSinceEpoch}-${_reqCounter++}';
    final completer = Completer<Map<String, dynamic>?>();
    late final StreamSubscription<Map<String, dynamic>> ackSub;
    ackSub = events.listen((event) {
      if (event['type'] == 'ack' && event['reqId'] == reqId) {
        if (!completer.isCompleted) completer.complete(event);
        unawaited(ackSub.cancel());
      }
    });

    try {
      channel.sink.add(jsonEncode({...payload, 'reqId': reqId}));
    } catch (_) {
      unawaited(ackSub.cancel());
      return null;
    }

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
    } finally {
      unawaited(ackSub.cancel());
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      map = decoded;
    } catch (_) {
      return;
    }
    if (map['type'] == 'auth:ok') {
      _connectedNotifier.value = true;
      return;
    }
    _controller.add(map);
  }

  void _onDisconnected() {
    _channel = null;
    _connectedNotifier.value = false;
    unawaited(_sub?.cancel());
    _sub = null;
    if (!_stopped) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () => unawaited(_connect()));
  }

  String _wsUrl() {
    final base = StringConstants.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws';
  }
}
