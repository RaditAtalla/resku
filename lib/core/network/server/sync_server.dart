import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import '../../database/local_db.dart';

// SyncServer hosts a local HTTP sync server when in Rescuer Mobile Collector mode.
// The Rescuer Desktop Dashboard connects to this server over local Wi-Fi to sync database.
class SyncServer {
  static final SyncServer _instance = SyncServer._internal();
  factory SyncServer() => _instance;
  SyncServer._internal();

  HttpServer? _serverInstance;

  bool get isServerRunning => _serverInstance != null;

  Future<void> startServer(int port) async {
    if (isServerRunning) return;
    debugPrint('SyncServer: Starting local API server on port $port...');
    try {
      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware)
          .addHandler(_handleSyncRequest);

      // Listen on all network interfaces (0.0.0.0)
      _serverInstance = await io.serve(handler, '0.0.0.0', port);
      debugPrint('SyncServer: Server active on http://0.0.0.0:$port');
    } catch (e) {
      debugPrint('SyncServer Error: Failed to start server: $e');
      rethrow;
    }
  }

  Future<void> stopServer() async {
    if (_serverInstance == null) return;
    await _serverInstance!.close(force: true);
    _serverInstance = null;
    debugPrint('SyncServer: Server stopped.');
  }

  // CORS Middleware to allow cross-origin requests from the Dashboard (Web/Desktop)
  static Middleware get _corsMiddleware => (Handler innerHandler) {
        return (Request request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
            });
          }
          final response = await innerHandler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
          });
        };
      };

  Future<Response> _handleSyncRequest(Request request) async {
    final path = request.url.path;
    debugPrint('SyncServer: Handled request for path: $path');

    if (path == 'api/sync') {
      try {
        final db = LocalDB();
        final survivors = await db.getAllSurvivors();
        final list = survivors.map((s) => s.toMap()).toList();
        final jsonString = jsonEncode(list);

        return Response.ok(
          jsonString,
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        debugPrint('SyncServer Error in /api/sync handler: $e');
        return Response.internalServerError(body: 'Error retrieving survivors: $e');
      }
    }

    return Response.notFound('Not Found');
  }
}
