import 'dart:async';

class LocalLlmService {
  static final LocalLlmService _instance = LocalLlmService._internal();
  factory LocalLlmService() => _instance;
  LocalLlmService._internal();

  bool get isSupported => false;
  bool get isInitialized => false;

  Future<void> initialize(String modelId) async {
    // Stub implementation does nothing
    throw UnsupportedError('Local WebGPU/WASM LLM is only supported on the Web platform.');
  }

  Stream<String> generate(String systemPrompt, String userPrompt) {
    // Return empty stream or throw
    final controller = StreamController<String>();
    controller.addError(UnsupportedError('Local WebGPU/WASM LLM is only supported on the Web platform.'));
    controller.close();
    return controller.stream;
  }
}
