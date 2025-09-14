import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Configuration service that loads app settings from JSON file
/// Provides centralized access to all app configuration
class ConfigService extends GetxService {
  static const String _configPath = 'assets/config/app_config.json';
  
  Map<String, dynamic> _config = {};
  bool _isLoaded = false;
  
  // Getters for easy access
  Map<String, dynamic> get config => _config;
  bool get isLoaded => _isLoaded;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await loadConfig();
  }
  
  /// Loads configuration from JSON file
  Future<void> loadConfig() async {
    try {
      debugPrint('[ConfigService] Loading configuration from $_configPath');
      
      final configString = await rootBundle.loadString(_configPath);
      _config = json.decode(configString);
      _isLoaded = true;
      
      debugPrint('[ConfigService] Configuration loaded successfully');
      if (kDebugMode) {
        _printConfig();
      }
    } catch (e) {
      debugPrint('[ConfigService] Failed to load configuration: $e');
      _loadDefaultConfig();
    }
  }
  
  /// Loads default configuration as fallback
  void _loadDefaultConfig() {
    _config = {
      'api': {
        'baseUrl': 'https://yebo-verify-api-659214682765.europe-west1.run.app',
        'apiKey': 'your-api-key-here',
        'timeout': {'connect': 30, 'receive': 30, 'send': 30},
        'retries': 3,
        'enableLogging': true
      },
      'app': {
        'name': 'Yebo Verify',
        'version': '1.0.0',
        'environment': 'development'
      },
      'features': {
        'enableMockData': true,
        'enableDebugMode': true,
        'enableCrashReporting': false,
        'enableAnalytics': false
      }
    };
    _isLoaded = true;
    debugPrint('[ConfigService] Using default configuration');
  }
  
  /// Gets a value from config with optional default
  T get<T>(String path, {T? defaultValue}) {
    final keys = path.split('.');
    dynamic current = _config;
    
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue as T;
      }
    }
    
    return current as T;
  }
  
  /// Checks if a config path exists
  bool has(String path) {
    final keys = path.split('.');
    dynamic current = _config;
    
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return false;
      }
    }
    
    return true;
  }
  
  /// API Configuration getters
  String get baseUrl => get<String>('api.baseUrl', defaultValue: '');
  String get apiKey => get<String>('api.apiKey', defaultValue: '');
  int get connectTimeout => get<int>('api.timeout.connect', defaultValue: 30);
  int get receiveTimeout => get<int>('api.timeout.receive', defaultValue: 30);
  int get sendTimeout => get<int>('api.timeout.send', defaultValue: 30);
  int get maxRetries => get<int>('api.retries', defaultValue: 3);
  bool get enableApiLogging => get<bool>('api.enableLogging', defaultValue: false);
  
  /// App Configuration getters
  String get appName => get<String>('app.name', defaultValue: 'Yebo Verify');
  String get appVersion => get<String>('app.version', defaultValue: '1.0.0');
  String get environment => get<String>('app.environment', defaultValue: 'development');
  
  /// Feature flags
  bool get enableMockData => get<bool>('features.enableMockData', defaultValue: false);
  bool get enableDebugMode => get<bool>('features.enableDebugMode', defaultValue: false);
  bool get enableCrashReporting => get<bool>('features.enableCrashReporting', defaultValue: false);
  bool get enableAnalytics => get<bool>('features.enableAnalytics', defaultValue: false);
  
  /// Upload Configuration
  int get maxFileSize => get<int>('upload.maxFileSize', defaultValue: 10485760); // 10MB
  List<String> get allowedFormats => List<String>.from(get<List>('upload.allowedFormats', defaultValue: ['jpg', 'jpeg', 'png']));
  double get imageQuality => get<double>('upload.imageQuality', defaultValue: 0.85);
  bool get compressionEnabled => get<bool>('upload.compressionEnabled', defaultValue: true);
  
  /// Verification Configuration  
  int get pollInterval => get<int>('verification.pollInterval', defaultValue: 2000);
  int get maxPollTimeout => get<int>('verification.maxPollTimeout', defaultValue: 300000);
  int get minStableFrames => get<int>('verification.minStableFrames', defaultValue: 10);
  
  // Auto-capture settings
  bool get idCardAutoCaptureEnabled => get<bool>('verification.autoCapture.idCard.enabled', defaultValue: true);
  int get idCardCountdown => get<int>('verification.autoCapture.idCard.countdown', defaultValue: 3);
  bool get selfieAutoCaptureEnabled => get<bool>('verification.autoCapture.selfie.enabled', defaultValue: true);
  int get selfieFaceDetectionFrames => get<int>('verification.autoCapture.selfie.faceDetectionFrames', defaultValue: 10);
  
  /// Environment helpers
  bool get isDevelopment => environment == 'development';
  bool get isStaging => environment == 'staging';
  bool get isProduction => environment == 'production';
  
  /// API Key validation
  bool get isApiKeyValid {
    final key = apiKey;
    return key.isNotEmpty && key.length >= 32 && key != 'your-api-key-here';
  }
  
  /// Updates a configuration value at runtime
  void updateConfig(String path, dynamic value) {
    final keys = path.split('.');
    dynamic current = _config;
    
    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(key)) {
          current[key] = <String, dynamic>{};
        }
        current = current[key];
      }
    }
    
    if (current is Map<String, dynamic>) {
      current[keys.last] = value;
    }
    
    debugPrint('[ConfigService] Updated $path = $value');
  }
  
  /// Prints current configuration (debug only)
  void _printConfig() {
    if (!kDebugMode) return;
    
    debugPrint('🔧 App Configuration:');
    debugPrint('   App: $appName v$appVersion ($environment)');
    debugPrint('   API: $baseUrl');
    debugPrint('   API Key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "EMPTY"}');
    debugPrint('   API Key Valid: $isApiKeyValid');
    debugPrint('   Debug Mode: $enableDebugMode');
    debugPrint('   Mock Data: $enableMockData');
    debugPrint('   Timeouts: ${connectTimeout}s/${receiveTimeout}s/${sendTimeout}s');
  }
  
  /// Gets the full configuration as JSON string
  String toJson() {
    return json.encode(_config);
  }
  
  /// Gets configuration summary for debugging
  Map<String, dynamic> getSummary() {
    return {
      'loaded': _isLoaded,
      'environment': environment,
      'apiKeyValid': isApiKeyValid,
      'baseUrl': baseUrl,
      'features': {
        'mockData': enableMockData,
        'debugMode': enableDebugMode,
        'analytics': enableAnalytics,
        'crashReporting': enableCrashReporting,
      },
    };
  }
}