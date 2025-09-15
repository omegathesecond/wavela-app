import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../config/api_config.dart';

/// Service for handling file uploads to R2 storage for verification
class FileUploadApiService extends getx.GetxService {
  static const String baseUrl = 'https://yebo-verify-api-659214682765.europe-west1.run.app';

  /// Uploads a document to R2 storage for verification
  Future<R2UploadResponse> uploadDocumentToR2({
    required String jobId,
    required String documentType, // 'selfie', 'id_front', 'id_back'
    required String filePath,
    Function(int, int)? onProgress,
  }) async {
    try {
      debugPrint('📤 [FileUploadApiService] Starting upload for $documentType');
      debugPrint('📤 [FileUploadApiService] JobId: $jobId');
      debugPrint('📤 [FileUploadApiService] FilePath: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ [FileUploadApiService] File not found: $filePath');
        throw Exception('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      final fileName = path.basename(filePath);
      final fileSize = bytes.length;
      
      debugPrint('📄 [FileUploadApiService] File: $fileName ($fileSize bytes)');

      final formData = FormData.fromMap({
        'jobId': jobId,
        'documentType': documentType,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final dio = Dio();
      final url = '$baseUrl/verification-media/upload';
      
      debugPrint('🌐 [FileUploadApiService] POST $url');
      debugPrint('🔑 [FileUploadApiService] API Key: ${ApiConfig.apiKey.substring(0, 8)}...');
      debugPrint('📊 [FileUploadApiService] Form data: jobId=$jobId, documentType=$documentType, fileName=$fileName');
      
      final response = await dio.post(
        url,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            'X-API-Key': ApiConfig.apiKey,
          },
        ),
      );

      debugPrint('✅ [FileUploadApiService] Response status: ${response.statusCode}');
      debugPrint('📋 [FileUploadApiService] Response headers: ${response.headers}');
      debugPrint('📄 [FileUploadApiService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        debugPrint('🎯 [FileUploadApiService] Upload successful for $documentType: $responseData');
        return R2UploadResponse.fromJson(responseData);
      } else {
        debugPrint('❌ [FileUploadApiService] Upload failed with status ${response.statusCode}');
        debugPrint('❌ [FileUploadApiService] Error response: ${response.data}');
        throw Exception('Failed to upload $documentType: ${response.data}');
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('🚨 [FileUploadApiService] DioException occurred:');
        debugPrint('🚨 [FileUploadApiService] Type: ${e.type}');
        debugPrint('🚨 [FileUploadApiService] Message: ${e.message}');
        debugPrint('🚨 [FileUploadApiService] Response status: ${e.response?.statusCode}');
        debugPrint('🚨 [FileUploadApiService] Response data: ${e.response?.data}');
        debugPrint('🚨 [FileUploadApiService] Response headers: ${e.response?.headers}');
        
        if (e.response?.statusCode == 500) {
          debugPrint('💥 [FileUploadApiService] 500 SERVER ERROR for $documentType upload');
          debugPrint('💥 [FileUploadApiService] Server response: ${e.response?.data}');
        }
      } else {
        debugPrint('❌ [FileUploadApiService] General error: $e');
      }
      rethrow;
    }
  }

  /// Uploads multiple documents to R2 for verification
  Future<Map<String, R2UploadResponse>> uploadVerificationDocuments({
    required String jobId,
    String? idFrontPath,
    String? idBackPath,
    String? selfiePath,
    Function(String, double)? onProgress,
  }) async {
    final results = <String, R2UploadResponse>{};
    int totalFiles = 0;
    int uploadedFiles = 0;

    // Count total files
    if (idFrontPath != null) totalFiles++;
    if (idBackPath != null) totalFiles++;
    if (selfiePath != null) totalFiles++;

    if (totalFiles == 0) {
      throw Exception('No files to upload');
    }

    // Upload ID front
    if (idFrontPath != null) {
      onProgress?.call('Uploading ID front...', uploadedFiles / totalFiles);
      results['id_front'] = await uploadDocumentToR2(
        jobId: jobId,
        documentType: 'id_front',
        filePath: idFrontPath,
      );
      uploadedFiles++;
      onProgress?.call('ID front uploaded', uploadedFiles / totalFiles);
    }

    // Upload ID back
    if (idBackPath != null) {
      onProgress?.call('Uploading ID back...', uploadedFiles / totalFiles);
      results['id_back'] = await uploadDocumentToR2(
        jobId: jobId,
        documentType: 'id_back',
        filePath: idBackPath,
      );
      uploadedFiles++;
      onProgress?.call('ID back uploaded', uploadedFiles / totalFiles);
    }

    // Upload selfie
    if (selfiePath != null) {
      onProgress?.call('Uploading selfie...', uploadedFiles / totalFiles);
      results['selfie'] = await uploadDocumentToR2(
        jobId: jobId,
        documentType: 'selfie',
        filePath: selfiePath,
      );
      uploadedFiles++;
      onProgress?.call('Selfie uploaded', uploadedFiles / totalFiles);
    }

    return results;
  }
}

/// Response from R2 upload
class R2UploadResponse {
  final String url;  // Public URL for the document
  final String key;  // R2 key for reference

  R2UploadResponse({
    required this.url,
    required this.key,
  });

  factory R2UploadResponse.fromJson(Map<String, dynamic> json) {
    return R2UploadResponse(
      url: json['url'] ?? '',
      key: json['key'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'key': key,
    };
  }
}