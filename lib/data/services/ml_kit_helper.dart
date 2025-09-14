import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MLKitHelper {
  /// Converts a CameraImage to InputImage for ML Kit processing (Android optimized)
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      debugPrint('[MLKitHelper] Processing image - Format: ${image.format.group}, Raw: ${image.format.raw}, Planes: ${image.planes.length}');
      
      // Android-only app - get rotation from camera sensor
      final InputImageRotation? rotation = 
          _rotationIntToImageRotation(camera.sensorOrientation);
      
      if (rotation == null) {
        debugPrint('[MLKitHelper] Unable to determine rotation for sensor: ${camera.sensorOrientation}');
        return null;
      }

      // Try to convert based on format group and raw value
      InputImageFormat? inputFormat;
      Uint8List? bytes;
      
      // Handle different Android camera formats
      if (image.format.group == ImageFormatGroup.nv21) {
        inputFormat = InputImageFormat.nv21;
        bytes = _processNV21(image);
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        // Convert YUV420 to NV21 since ML Kit prefers NV21 on Android
        inputFormat = InputImageFormat.nv21;
        bytes = _convertYUV420ToNV21(image);
      } else {
        // Fallback: try to force as NV21
        debugPrint('[MLKitHelper] Unknown format ${image.format.group}, attempting NV21 conversion');
        inputFormat = InputImageFormat.nv21;
        bytes = _processAsNV21Fallback(image);
      }

      if (bytes == null) {
        debugPrint('[MLKitHelper] Failed to process image bytes');
        return null;
      }

      final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      debugPrint('[MLKitHelper] Successfully created InputImage with format: $inputFormat');
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('[MLKitHelper] Error converting camera image: $e');
      return null;
    }
  }

  static Uint8List? _processNV21(CameraImage image) {
    try {
      final allBytes = <int>[];
      for (final Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      return Uint8List.fromList(allBytes);
    } catch (e) {
      debugPrint('[MLKitHelper] Error processing NV21: $e');
      return null;
    }
  }

  static Uint8List? _convertYUV420ToNV21(CameraImage image) {
    try {
      debugPrint('[MLKitHelper] Converting YUV420 to NV21');
      
      // YUV420 has 3 planes: Y, U, V
      final yPlane = image.planes[0];  // Y (luminance)
      final uPlane = image.planes[1];  // U (chroma)
      final vPlane = image.planes[2];  // V (chroma)
      
      final ySize = yPlane.bytes.length;
      
      debugPrint('[MLKitHelper] YUV420 planes - Y: $ySize bytes, U: ${uPlane.bytes.length}, V: ${vPlane.bytes.length}');
      
      // NV21 format: Y plane + interleaved VU plane
      final nv21Bytes = <int>[];
      
      // Copy Y plane as-is
      nv21Bytes.addAll(yPlane.bytes);
      
      // Interleave V and U bytes for NV21 (VUVUVU...)
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;
      final minLength = uBytes.length < vBytes.length ? uBytes.length : vBytes.length;
      
      for (int i = 0; i < minLength; i++) {
        nv21Bytes.add(vBytes[i]); // V first
        nv21Bytes.add(uBytes[i]); // U second
      }
      
      debugPrint('[MLKitHelper] Converted to NV21: ${nv21Bytes.length} bytes');
      return Uint8List.fromList(nv21Bytes);
    } catch (e) {
      debugPrint('[MLKitHelper] Error converting YUV420 to NV21: $e');
      return null;
    }
  }

  static Uint8List? _processAsNV21Fallback(CameraImage image) {
    try {
      // Simple fallback: concatenate all plane bytes
      final allBytes = <int>[];
      for (final Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      return Uint8List.fromList(allBytes);
    } catch (e) {
      debugPrint('[MLKitHelper] Error in NV21 fallback: $e');
      return null;
    }
  }


  /// Converts rotation int to InputImageRotation
  static InputImageRotation? _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }

  /// Checks if text contains common ID card keywords
  static bool containsIDCardKeywords(String text) {
    final keywords = [
      // English keywords
      'ID', 'IDENTITY', 'NAME', 'DATE', 'BIRTH', 'NUMBER', 
      'CARD', 'REPUBLIC', 'CITIZEN', 'NATIONAL', 'SURNAME',
      'GIVEN', 'SEX', 'GENDER', 'EXPIRES', 'ISSUED', 'VALID',
      'SIGNATURE', 'ADDRESS', 'DOCUMENT', 'LICENSE', 'PASSPORT',
      
      // Common abbreviations
      'DOB', 'D.O.B', 'ID#', 'NO.', 'EXP', 'ISS',
    ];
    
    final upperText = text.toUpperCase();
    int keywordCount = 0;
    
    for (final keyword in keywords) {
      if (upperText.contains(keyword)) {
        keywordCount++;
      }
    }
    
    // Need at least 2 keywords to consider it an ID card
    return keywordCount >= 2;
  }
}