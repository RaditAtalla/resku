// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'web_mesh_stub.dart';

class WebMeshChannelImpl implements WebMeshChannel {
  html.BroadcastChannel? _channel;

  @override
  void init(Function(Map<String, dynamic>) onMessage) {
    if (kIsWeb) {
      try {
        _channel = html.BroadcastChannel('resku_mesh_sync');
        _channel!.onMessage.listen((event) {
          try {
            final data = event.data;
            if (data is String) {
              onMessage(jsonDecode(data));
            } else if (data is Map) {
              onMessage(Map<String, dynamic>.from(data));
            }
          } catch (e) {
            debugPrint('WebMeshChannel web parse error: $e');
          }
        });
        debugPrint('WebMeshChannel: BroadcastChannel initialized.');
      } catch (e) {
        debugPrint('WebMeshChannel init error: $e');
      }
    }
  }

  @override
  void sendMessage(Map<String, dynamic> message) {
    if (kIsWeb && _channel != null) {
      try {
        _channel!.postMessage(jsonEncode(message));
      } catch (e) {
        debugPrint('WebMeshChannel send error: $e');
      }
    }
  }

  @override
  void dispose() {
    _channel?.close();
    _channel = null;
  }
}

WebMeshChannel getWebMeshChannel() => WebMeshChannelImpl();
