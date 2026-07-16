// App constants and BLE configuration settings for the Resku Mesh Network.
class AppConstants {
  static const String appName = 'Resku';
  
  // BLE Configuration
  static const String bleServiceUuid = '0d322bb2-e7f0-4e31-8f5c-ef66236b281f';
  static const String locationSyncCharUuid = 'a445e90d-2b4a-4e2b-bbd4-1a3b1a6c4293';
  static const String announcementsCharUuid = 'c12e8b23-1d4a-4b9b-9cde-9a573b9e4bc1';
  
  // Local HTTP Sync Server
  static const int defaultSyncPort = 8080;
  
  // AI Settings
  static const String fallbackGeminiModel = 'gemini-1.5-flash';
}
