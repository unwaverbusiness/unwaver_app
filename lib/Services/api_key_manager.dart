import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyManager {
  static String get geminiKey {
    // 1. WEB
    if (kIsWeb) {
      return _getKey('GEMINI_API_WEB');
    } 
    // 2. ANDROID
    else if (Platform.isAndroid) {
      return _getKey('GEMINI_API_ANDROID');
    } 
    // 3. IOS
    else if (Platform.isIOS) {
      return _getKey('GEMINI_API_IOS');
    }
    
    // 4. FALLBACK (For testing on Windows/Mac desktop)
    // If we are on a platform that isn't mobile/web, use the Main key
    return _getKey('GEMINI_API_MAIN');
  }

  static String _getKey(String keyName) {
    final key = dotenv.env[keyName];
    
    // VALIDATION
    if (key == null || key.isEmpty) {
      // If the specific key is missing, but we are in Debug mode, 
      // try to use the MAIN key as a backup.
      if (kDebugMode && keyName != 'GEMINI_API_MAIN') {
        final mainKey = dotenv.env['GEMINI_API_MAIN'];
        if (mainKey != null && mainKey.isNotEmpty) {
          print("⚠️ WARNING: Using Unrestricted MAIN key for $keyName");
          return mainKey;
        }
      }
      
      throw Exception('API Key $keyName not found in .env');
    }
    return key;
  }
}