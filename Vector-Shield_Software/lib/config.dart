import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Blynk API credentials
  static String get blynkTemplateId => dotenv.env['BLYNK_TEMPLATE_ID'] ?? '';
  static String get blynkTemplateName => dotenv.env['BLYNK_TEMPLATE_NAME'] ?? '';
  static String get blynkAuthToken => dotenv.env['BLYNK_AUTH_TOKEN'] ?? '';
  static String get blynkBaseUrl => dotenv.env['BLYNK_BASE_URL'] ?? 'https://blynk.cloud/external/api';
  
  // Firebase configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  // Method to check if running in production
  static bool get isProduction {
    // This is a simple check - you might want to use a more sophisticated approach
    return dotenv.env['ENVIRONMENT'] == 'production';
  }
}

