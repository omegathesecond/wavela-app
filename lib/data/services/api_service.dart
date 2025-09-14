import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService extends getx.GetxService {
  late Dio _dio;
  late StorageService _storageService;
  
  static String get baseUrl => ApiConfig.baseUrl;
  static String get apiKey => ApiConfig.apiKey;
  static Duration get connectionTimeout => ApiConfig.connectTimeout;
  static Duration get receiveTimeout => ApiConfig.receiveTimeout;
  
  @override
  void onInit() {
    super.onInit();
    _storageService = getx.Get.find<StorageService>();
    _initializeDio();
  }
  
  void _initializeDio() {
    debugPrint('🔧 [ApiService] Initializing Dio with API key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "EMPTY"}');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': apiKey, // Backend expects uppercase header
        },
      ),
    );
    
    debugPrint('🔧 [ApiService] Base headers: ${_dio.options.headers}');
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always include API key with correct header name
          options.headers['X-API-Key'] = apiKey; // Backend expects uppercase
          
          // Include Bearer token if available (for user-specific operations)
          final token = await _storageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Log the request
          debugPrint('🌐 [ApiService] ${options.method} ${options.baseUrl}${options.path}');
          debugPrint('🔑 [ApiService] Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('📊 [ApiService] Data: ${options.data}');
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [ApiService] Response ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
          debugPrint('📄 [ApiService] Response data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('🚨 [ApiService] Error ${error.response?.statusCode} ${error.requestOptions.method} ${error.requestOptions.path}');
          debugPrint('🚨 [ApiService] Error message: ${error.message}');
          debugPrint('🚨 [ApiService] Error response: ${error.response?.data}');
          debugPrint('🚨 [ApiService] Error headers: ${error.response?.headers}');
          
          if (error.response?.statusCode == 401) {
            debugPrint('🔒 [ApiService] Unauthorized - handling auth error');
            _handleUnauthorized();
          } else if (error.response?.statusCode == 500) {
            debugPrint('💥 [ApiService] 500 SERVER ERROR');
            debugPrint('💥 [ApiService] Server response: ${error.response?.data}');
          }
          
          handler.next(error);
        },
      ),
    );
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
  
  void _handleUnauthorized() async {
    await _storageService.clearAuthData();
    getx.Get.offAllNamed('/splash');
  }
  
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath),
      });
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> uploadMultipleFiles(
    String path,
    List<String> filePaths, {
    Map<String, dynamic>? data,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map((path) => MultipartFile.fromFile(path)),
      );
      
      final formData = FormData.fromMap({
        ...?data,
        'files': files,
      });
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic request method with parser
  Future<T> request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Map<String, dynamic> json)? parser,
  }) async {
    try {
      late Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(path, queryParameters: queryParameters, options: options);
          break;
        case 'POST':
          response = await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
          break;
        case 'PUT':
          response = await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
          break;
        case 'DELETE':
          response = await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method', null);
      }
      
      if (parser != null) {
        return parser(response.data as Map<String, dynamic>);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic list request method
  Future<List<T>> requestList<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    final response = await request<dynamic>(
      method,
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    
    if (response is List) {
      return response.map((item) => parser(item)).toList();
    } else if (response is Map && response.containsKey('data') && response['data'] is List) {
      return (response['data'] as List).map((item) => parser(item)).toList();
    } else {
      throw ApiException('Expected list response but got: ${response.runtimeType}', null);
    }
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection.',
          error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'No internet connection. Please check your network.',
          error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final message = error.response?.data['message'] ?? 
                       'An error occurred. Please try again.';
        return ApiException(message, error.response?.statusCode);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled', null);
      default:
        return ApiException(
          'An unexpected error occurred. Please try again.',
          error.response?.statusCode,
        );
    }
  }
  
  // API Key management methods
  /// Updates the API key for all subsequent requests
  void updateApiKey(String newApiKey) {
    _dio.options.headers['X-API-Key'] = newApiKey;
  }
  
  /// Gets the current API key
  String? getCurrentApiKey() {
    return _dio.options.headers['X-API-Key'];
  }
  
  /// Validates API key by making a health check request
  Future<bool> validateApiKey() async {
    try {
      await get('/health');
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => message;
}