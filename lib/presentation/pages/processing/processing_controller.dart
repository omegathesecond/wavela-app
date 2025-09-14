import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

class ProcessingController extends GetxController {
  final RxDouble progress = 0.0.obs;
  final RxString currentProcess = ''.obs;
  final RxBool ocrCompleted = false.obs;
  final RxBool faceMatchCompleted = false.obs;
  final RxBool livenessCompleted = false.obs;
  
  final Dio _dio = Dio();
  final String _geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace with actual API key
  final String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro-vision:generateContent';
  
  late File idFrontImage;
  late File idBackImage;
  late File selfieImage;
  
  Map<String, dynamic> extractedData = {};
  Map<String, dynamic> verificationResults = {};

  @override
  void onInit() {
    super.onInit();
    
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      idFrontImage = arguments['idFront'];
      idBackImage = arguments['idBack'];
      selfieImage = arguments['selfie'];
      
      _startProcessing();
    }
  }

  Future<void> _startProcessing() async {
    try {
      // Step 1: OCR Processing
      await _performOCR();
      
      // Step 2: Face Matching
      await _performFaceMatching();
      
      // Step 3: Liveness Detection
      await _performLivenessDetection();
      
      // Navigate to results
      Get.offNamed('/result', arguments: {
        'extractedData': extractedData,
        'verificationResults': verificationResults,
      });
      
    } catch (e) {
      Get.snackbar('Processing Error', 'Failed to process verification: $e');
      Get.back();
    }
  }

  Future<void> _performOCR() async {
    currentProcess.value = 'ocr';
    progress.value = 0.1;
    
    try {
      // OCR for ID Front
      final frontText = await _extractTextFromImage(idFrontImage, 'Extract all text from this ID document front side. Focus on name, ID number, date of birth, and expiry date.');
      progress.value = 0.2;
      
      // OCR for ID Back
      final backText = await _extractTextFromImage(idBackImage, 'Extract all text from this ID document back side. Focus on address and any additional information.');
      progress.value = 0.3;
      
      extractedData = {
        'frontText': frontText,
        'backText': backText,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      ocrCompleted.value = true;
      progress.value = 0.33;
      
    } catch (e) {
      throw 'OCR processing failed: $e';
    }
  }

  Future<void> _performFaceMatching() async {
    currentProcess.value = 'face';
    
    try {
      final faceMatchResult = await _compareFaces();
      
      verificationResults['faceMatch'] = faceMatchResult;
      faceMatchCompleted.value = true;
      progress.value = 0.66;
      
    } catch (e) {
      throw 'Face matching failed: $e';
    }
  }

  Future<void> _performLivenessDetection() async {
    currentProcess.value = 'liveness';
    
    try {
      // Simple liveness check - in production, use specialized APIs
      final livenessResult = await _checkLiveness();
      
      verificationResults['liveness'] = livenessResult;
      livenessCompleted.value = true;
      progress.value = 1.0;
      
    } catch (e) {
      throw 'Liveness detection failed: $e';
    }
  }

  Future<String> _extractTextFromImage(File imageFile, String prompt) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    
    final response = await _dio.post(
      '$_geminiApiUrl?key=$_geminiApiKey',
      data: {
        'contents': [{
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image
              }
            }
          ]
        }]
      },
    );

    if (response.statusCode == 200) {
      final text = response.data['candidates'][0]['content']['parts'][0]['text'];
      return text ?? '';
    } else {
      throw 'API call failed: ${response.statusCode}';
    }
  }

  Future<Map<String, dynamic>> _compareFaces() async {
    final idImageBytes = await idFrontImage.readAsBytes();
    final selfieBytes = await selfieImage.readAsBytes();
    
    final base64IdImage = base64Encode(idImageBytes);
    final base64Selfie = base64Encode(selfieBytes);
    
    final response = await _dio.post(
      '$_geminiApiUrl?key=$_geminiApiKey',
      data: {
        'contents': [{
          'parts': [
            {'text': 'Compare the faces in these two images. Are they the same person? Provide a confidence score from 0-100 and explain your reasoning.'},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64IdImage
              }
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Selfie
              }
            }
          ]
        }]
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['candidates'][0]['content']['parts'][0]['text'];
      return {
        'match': true, // Parse from result
        'confidence': 85, // Parse from result  
        'details': result,
      };
    } else {
      throw 'Face comparison API call failed';
    }
  }

  Future<Map<String, dynamic>> _checkLiveness() async {
    final selfieBytes = await selfieImage.readAsBytes();
    final base64Selfie = base64Encode(selfieBytes);
    
    final response = await _dio.post(
      '$_geminiApiUrl?key=$_geminiApiKey',
      data: {
        'contents': [{
          'parts': [
            {'text': 'Analyze this selfie image for signs of liveness. Is this a real person or a photo/screen? Look for natural lighting, depth, and realistic features.'},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Selfie
              }
            }
          ]
        }]
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['candidates'][0]['content']['parts'][0]['text'];
      return {
        'isLive': true, // Parse from result
        'confidence': 90, // Parse from result
        'details': result,
      };
    } else {
      throw 'Liveness check API call failed';
    }
  }
}