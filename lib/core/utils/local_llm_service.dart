// Conditional export to support cross-platform builds without compilation issues on native runtimes.
export 'local_llm_service_stub.dart'
    if (dart.library.html) 'local_llm_service_web.dart';
