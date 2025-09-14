import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OCRService extends GetxService {
  late TextRecognizer _textRecognizer;
  
  final RxBool isProcessing = false.obs;
  final RxString processingStatus = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _textRecognizer = TextRecognizer();
  }
  
  @override
  void onClose() {
    _textRecognizer.close();
    super.onClose();
  }
  
  Future<Map<String, String>> extractIDCardData(String imagePath) async {
    if (isProcessing.value) return {};
    
    try {
      isProcessing.value = true;
      processingStatus.value = 'Processing image...';
      
      final inputImage = InputImage.fromFile(File(imagePath));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      processingStatus.value = 'Extracting information...';
      
      Map<String, String> extractedData = {};
      String fullText = recognizedText.text;
      
      extractedData['fullName'] = _extractName(fullText);
      extractedData['idNumber'] = _extractIDNumber(fullText);
      extractedData['dateOfBirth'] = _extractDateOfBirth(fullText);
      extractedData['gender'] = _extractGender(fullText);
      extractedData['address'] = _extractAddress(fullText);
      extractedData['issueDate'] = _extractIssueDate(fullText);
      extractedData['expiryDate'] = _extractExpiryDate(fullText);
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          _processLine(line.text, extractedData);
        }
      }
      
      processingStatus.value = 'Extraction complete';
      return extractedData;
      
    } catch (e) {
      processingStatus.value = 'Error: ${e.toString()}';
      return {};
    } finally {
      isProcessing.value = false;
    }
  }
  
  void _processLine(String text, Map<String, String> data) {
    text = text.trim();
    
    if (_isIDNumber(text) && data['idNumber']?.isEmpty != false) {
      data['idNumber'] = text;
    }
    
    if (_isDate(text)) {
      if (data['dateOfBirth']?.isEmpty != false && _isBirthDate(text)) {
        data['dateOfBirth'] = text;
      } else if (data['issueDate']?.isEmpty != false) {
        data['issueDate'] = text;
      } else if (data['expiryDate']?.isEmpty != false) {
        data['expiryDate'] = text;
      }
    }
    
    if (_isName(text) && data['fullName']?.isEmpty != false) {
      data['fullName'] = text;
    }
  }
  
  String _extractName(String text) {
    final namePatterns = [
      RegExp(r'Name[s]?\s*[:.]?\s*([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', 
             caseSensitive: false),
      RegExp(r'Full\s+Name\s*[:.]?\s*([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', 
             caseSensitive: false),
      RegExp(r'([A-Z][a-z]+\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s*(?:ID|DOB|Date)', 
             caseSensitive: false),
    ];
    
    for (var pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    final lines = text.split('\n');
    for (var line in lines) {
      if (_isName(line)) {
        return line.trim();
      }
    }
    
    return '';
  }
  
  String _extractIDNumber(String text) {
    final idPatterns = [
      RegExp(r'ID\s*(?:Number|No\.?|#)?\s*[:.]?\s*([0-9]{8,13})', caseSensitive: false),
      RegExp(r'National\s*ID\s*[:.]?\s*([0-9]{8,13})', caseSensitive: false),
      RegExp(r'([0-9]{8,13})\s*(?:ID|National)', caseSensitive: false),
      RegExp(r'\b([0-9]{13})\b'),
    ];
    
    for (var pattern in idPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  String _extractDateOfBirth(String text) {
    final dobPatterns = [
      RegExp(r'(?:Date\s*of\s*Birth|DOB|Birth\s*Date)\s*[:.]?\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})', 
             caseSensitive: false),
      RegExp(r'Born\s*[:.]?\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})', 
             caseSensitive: false),
    ];
    
    for (var pattern in dobPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  String _extractGender(String text) {
    final genderPatterns = [
      RegExp(r'(?:Gender|Sex)\s*[:.]?\s*(M|F|Male|Female)', caseSensitive: false),
      RegExp(r'\b(M|F|Male|Female)\b\s*(?:Gender|Sex)?', caseSensitive: false),
    ];
    
    for (var pattern in genderPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String gender = match.group(1)?.trim().toUpperCase() ?? '';
        if (gender == 'M' || gender == 'MALE') return 'Male';
        if (gender == 'F' || gender == 'FEMALE') return 'Female';
      }
    }
    
    return '';
  }
  
  String _extractAddress(String text) {
    final addressPatterns = [
      RegExp(r'Address\s*[:.]?\s*(.+?)(?:ID|Date|Gender|$)', 
             caseSensitive: false, multiLine: true),
      RegExp(r'Residence\s*[:.]?\s*(.+?)(?:ID|Date|Gender|$)', 
             caseSensitive: false, multiLine: true),
    ];
    
    for (var pattern in addressPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  String _extractIssueDate(String text) {
    final issueDatePatterns = [
      RegExp(r'(?:Issue\s*Date|Date\s*of\s*Issue|Issued)\s*[:.]?\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})', 
             caseSensitive: false),
    ];
    
    for (var pattern in issueDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  String _extractExpiryDate(String text) {
    final expiryDatePatterns = [
      RegExp(r'(?:Expiry\s*Date|Date\s*of\s*Expiry|Expires?|Valid\s*Until)\s*[:.]?\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})', 
             caseSensitive: false),
    ];
    
    for (var pattern in expiryDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }
  
  bool _isIDNumber(String text) {
    return RegExp(r'^[0-9]{8,13}$').hasMatch(text.trim());
  }
  
  bool _isDate(String text) {
    return RegExp(r'[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}').hasMatch(text);
  }
  
  bool _isBirthDate(String text) {
    if (!_isDate(text)) return false;
    
    try {
      final parts = text.split(RegExp(r'[/-]'));
      if (parts.length != 3) return false;
      
      int year = int.parse(parts[2]);
      if (year < 100) {
        year += (year > 50) ? 1900 : 2000;
      }
      
      final age = DateTime.now().year - year;
      return age >= 16 && age <= 120;
    } catch (e) {
      return false;
    }
  }
  
  bool _isName(String text) {
    text = text.trim();
    
    if (text.length < 3 || text.length > 50) return false;
    
    if (RegExp(r'[0-9]').hasMatch(text)) return false;
    
    if (RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+$').hasMatch(text)) {
      return true;
    }
    
    return false;
  }
  
  double calculateConfidence(Map<String, String> data) {
    int filledFields = 0;
    int totalFields = 7;
    
    if (data['fullName']?.isNotEmpty == true) filledFields++;
    if (data['idNumber']?.isNotEmpty == true) filledFields++;
    if (data['dateOfBirth']?.isNotEmpty == true) filledFields++;
    if (data['gender']?.isNotEmpty == true) filledFields++;
    if (data['address']?.isNotEmpty == true) filledFields++;
    if (data['issueDate']?.isNotEmpty == true) filledFields++;
    if (data['expiryDate']?.isNotEmpty == true) filledFields++;
    
    return (filledFields / totalFields) * 100;
  }
}