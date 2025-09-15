import 'package:flutter/foundation.dart';
import 'user_model.dart';

enum JobStage {
  submitted('Application Submitted', 'Job has been submitted'),
  faceVerification('Face Verification', 'Verifying selfie against ID photo'),
  ocrProcessing('Document Processing', 'Extracting text from documents'),
  amlCheck('Security Check', 'Anti-money laundering verification'),
  finalReview('Final Review', 'Manual review and decision'),
  completed('Verification Complete', 'Verification process completed');

  const JobStage(this.title, this.description);
  final String title;
  final String description;

  static JobStage _parseJobStage(String? stageString) {
    if (stageString == null) return JobStage.submitted;

    switch (stageString) {
      case 'submitted':
        return JobStage.submitted;
      case 'face_verification':
        return JobStage.faceVerification;
      case 'ocr_processing':
        return JobStage.ocrProcessing;
      case 'aml_check':
        return JobStage.amlCheck;
      case 'final_review':
        return JobStage.finalReview;
      case 'completed':
        return JobStage.completed;
      default:
        return JobStage.submitted;
    }
  }
}

enum JobStatus {
  pending('Pending', 'Waiting to be processed'),
  inProgress('In Progress', 'Currently being processed'),
  onHold('On Hold', 'Temporarily paused'),
  completed('Completed', 'Successfully completed'),
  rejected('Rejected', 'Verification failed'),
  expired('Expired', 'Job has expired');

  const JobStatus(this.title, this.description);
  final String title;
  final String description;

  static JobStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return JobStatus.pending;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'on_hold':
        return JobStatus.onHold;
      case 'completed':
        return JobStatus.completed;
      case 'rejected':
        return JobStatus.rejected;
      case 'expired':
        return JobStatus.expired;
      default:
        return JobStatus.pending;
    }
  }
}

class JobModel {
  final String id;
  final String jobId;
  final String kycUserId;
  final String documentType;
  final JobStatus status;
  final JobStage currentStage;
  final List<JobStageProgress> stageProgress;
  final OCRExtractedData? ocrExtractedData;
  final UserModel? userModel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? rejectionReason;
  final int progressPercentage;

  JobModel({
    required this.id,
    required this.jobId,
    required this.kycUserId,
    required this.documentType,
    required this.status,
    required this.currentStage,
    required this.stageProgress,
    this.ocrExtractedData,
    this.userModel,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.rejectionReason,
    required this.progressPercentage,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? json['_id'],
      jobId: json['jobId'],
      kycUserId: json['kycUserId'],
      documentType: json['documentType'],
      status: JobStatus.fromString(json['status']),
      currentStage: JobStage._parseJobStage(json['currentStage']),
      stageProgress: (json['stageProgress'] as List<dynamic>?)
          ?.map((e) => JobStageProgress.fromJson(e))
          .toList() ?? [],
      ocrExtractedData: json['ocrExtractedData'] != null
          ? OCRExtractedData.fromJson(json['ocrExtractedData'])
          : null,
      userModel: json['userModel'] != null
          ? UserModel.fromJson(json['userModel'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      progressPercentage: json['progressPercentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'kycUserId': kycUserId,
      'documentType': documentType,
      'status': status.name,
      'currentStage': currentStage.name,
      'stageProgress': stageProgress.map((e) => e.toJson()).toList(),
      'ocrExtractedData': ocrExtractedData?.toJson(),
      'userModel': userModel?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'progressPercentage': progressPercentage,
    };
  }

  JobModel copyWith({
    String? id,
    String? jobId,
    String? kycUserId,
    String? documentType,
    JobStatus? status,
    JobStage? currentStage,
    List<JobStageProgress>? stageProgress,
    OCRExtractedData? ocrExtractedData,
    UserModel? userModel,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? rejectionReason,
    int? progressPercentage,
  }) {
    return JobModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      kycUserId: kycUserId ?? this.kycUserId,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      stageProgress: stageProgress ?? this.stageProgress,
      ocrExtractedData: ocrExtractedData ?? this.ocrExtractedData,
      userModel: userModel ?? this.userModel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

class JobStageProgress {
  final JobStage stage;
  final bool isCompleted;
  final bool isActive;
  final DateTime? completedAt;
  final String? notes;

  JobStageProgress({
    required this.stage,
    required this.isCompleted,
    required this.isActive,
    this.completedAt,
    this.notes,
  });

  factory JobStageProgress.fromJson(Map<String, dynamic> json) {
    return JobStageProgress(
      stage: JobStage._parseJobStage(json['stage']),
      isCompleted: json['isCompleted'] ?? false,
      isActive: json['isActive'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage.name,
      'isCompleted': isCompleted,
      'isActive': isActive,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

class OCRExtractedData {
  final String? surname;
  final String? names;
  final String? personalIdNumber;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? chiefCode;
  final int? confidence;

  OCRExtractedData({
    this.surname,
    this.names,
    this.personalIdNumber,
    this.dateOfBirth,
    this.sex,
    this.chiefCode,
    this.confidence,
  });

  factory OCRExtractedData.fromJson(Map<String, dynamic> json) {
    // Handle direct simple format
    if (json.containsKey('surname') && json['surname'] is String) {
      return OCRExtractedData(
        surname: json['surname'],
        names: json['names'],
        personalIdNumber: json['personalIdNumber'],
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : null,
        sex: json['sex'],
        chiefCode: json['chiefCode'],
        confidence: json['confidence']?.toDouble(),
      );
    }

    // Handle complex API response format
    String? extractedSurname;
    String? extractedNames;
    String? extractedIdNumber;
    String? extractedSex;
    String? extractedChiefCode;
    double? extractedConfidence;

    // Try to extract from API response structure
    try {
      extractedSurname = json['surname'];
      extractedConfidence = json['confidence']?.toDouble();

      // If surname is direct, use it
      if (extractedSurname != null) {
        return OCRExtractedData(
          surname: extractedSurname,
          names: json['names'],
          personalIdNumber: json['personalIdNumber'],
          dateOfBirth: json['dateOfBirth'] != null
              ? DateTime.tryParse(json['dateOfBirth'])
              : null,
          sex: json['sex'],
          chiefCode: json['chiefCode'],
          confidence: extractedConfidence?.round(),
        );
      }

      // Fallback: try to parse from extractedText array if available
      final extractedText = json['extractedText'];
      if (extractedText is List) {
        for (String text in extractedText.cast<String>()) {
          if (text.startsWith('LAST_NAME:')) {
            extractedSurname = text.split(':').last.trim();
          }
          // Add more parsing logic as needed
        }
      }
    } catch (e) {
      // If parsing fails, return with available data
      debugPrint('[OCRExtractedData] Parsing error: $e');
    }

    return OCRExtractedData(
      surname: extractedSurname,
      names: extractedNames,
      personalIdNumber: extractedIdNumber,
      dateOfBirth: null,
      sex: extractedSex,
      chiefCode: extractedChiefCode,
      confidence: extractedConfidence?.round(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surname': surname,
      'names': names,
      'personalIdNumber': personalIdNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'chiefCode': chiefCode,
      'confidence': confidence,
    };
  }
}