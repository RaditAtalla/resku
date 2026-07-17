class WebMeshChannel {
  void init(Function(Map<String, dynamic>) onMessage) {}
  void sendMessage(Map<String, dynamic> message) {}
  void dispose() {}
}

WebMeshChannel getWebMeshChannel() => WebMeshChannel();
