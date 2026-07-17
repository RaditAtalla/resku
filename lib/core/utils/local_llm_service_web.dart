// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

class LocalLlmService {
  static final LocalLlmService _instance = LocalLlmService._internal();
  factory LocalLlmService() => _instance;
  LocalLlmService._internal();

  html.Worker? _worker;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  StreamController<String>? _generationController;

  bool get isSupported => true;
  bool get isInitialized => _isInitialized;

  Future<void> initialize(String modelId) async {
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      html.window.console.log('Spawning off-thread MLC/WebLLM Web Worker...');
      _worker?.terminate();
      _worker = html.Worker('llama_worker.js');
      
      _worker!.onMessage.listen((html.MessageEvent event) {
        final Map<dynamic, dynamic> data = event.data as Map<dynamic, dynamic>;
        final status = data['status'] as String?;
        
        if (status == 'ready') {
          _isInitialized = true;
          _initCompleter?.complete();
          _initCompleter = null;
        } else if (status == 'token') {
          final token = data['token'] as String;
          _generationController?.add(token);
        } else if (status == 'complete') {
          _generationController?.close();
          _generationController = null;
        } else if (status == 'error') {
          final err = data['error'] as String? ?? 'Unknown worker error';
          if (_initCompleter != null && !_initCompleter!.isCompleted) {
            _initCompleter!.completeError(err);
            _initCompleter = null;
          } else {
            _generationController?.addError(err);
            _generationController?.close();
            _generationController = null;
          }
        }
      }, onError: (err) {
        if (_initCompleter != null && !_initCompleter!.isCompleted) {
          _initCompleter!.completeError(err);
          _initCompleter = null;
        } else {
          _generationController?.addError(err);
          _generationController?.close();
          _generationController = null;
        }
      });

      _worker!.postMessage({
        'action': 'initialize',
        'payload': {'modelId': modelId}
      });

      await _initCompleter!.future;
    } catch (e) {
      _initCompleter?.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  Stream<String> generate(String systemPrompt, String userPrompt) {
    if (!_isInitialized || _worker == null) {
      final controller = StreamController<String>();
      controller.addError(StateError('LocalLlmService is not initialized. Call initialize() first.'));
      controller.close();
      return controller.stream;
    }

    _generationController?.close();

    final controller = StreamController<String>();
    _generationController = controller;

    _worker!.postMessage({
      'action': 'infer',
      'payload': {
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt
      }
    });

    return controller.stream;
  }
}
