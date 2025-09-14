import 'user_model.dart';

enum JobStage {
  submitted('Submitted', 'Job has been submitted'),
  ocrProcessing('OCR Processing', 'Extracting text from documents'),
  documentReview('Document Review', 'Reviewing submitted documents'),
  faceVerification('Face Verification', 'Verifying selfie photo'),
  fingerprintAnalysis('Fingerprint Analysis', 'Analyzing fingerprint biometrics'),
  backgroundCheck('Background Check', 'Conducting background verification'),
  finalReview('Final Review', 'Manual review and decision'),
  completed('Completed', 'Verification process completed');

  const JobStage(this.title, this.description);
  final String title;
  final String description;
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
    return JobStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => JobStatus.pending,
    );
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
      currentStage: JobStage.values.firstWhere(
        (stage) => stage.name == json['currentStage'],
        orElse: () => JobStage.submitted,
      ),
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
      stage: JobStage.values.firstWhere(
        (stage) => stage.name == json['stage'],
        orElse: () => JobStage.submitted,
      ),
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
    return OCRExtractedData(
      surname: json['surname'],
      names: json['names'],
      personalIdNumber: json['personalIdNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      sex: json['sex'],
      chiefCode: json['chiefCode'],
      confidence: json['confidence'],
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