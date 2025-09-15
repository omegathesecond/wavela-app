import 'package:get/get.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import 'jobs_api_service.dart';

class JobsService extends GetxService {
  late JobsApiService _jobsApi;
  final RxList<JobModel> _jobs = <JobModel>[].obs;
  final RxBool isLoading = true.obs;

  List<JobModel> get jobs => _jobs;
  RxList<JobModel> get jobsObs => _jobs;

  @override
  void onInit() {
    super.onInit();
    _jobsApi = Get.find<JobsApiService>();
    // Load jobs from API
    Future.delayed(Duration.zero, () => loadJobs());
  }

  Future<void> loadJobs() async {
    isLoading.value = true;

    try {
      final jobsList = await _jobsApi.getUserJobs();
      _jobs.clear();
      _jobs.addAll(jobsList);
    } catch (e) {
      // Fallback to mock data if API fails
      await _loadMockJobs();
    }

    isLoading.value = false;
  }

  Future<void> _loadMockJobs() async {
    final mockJobs = [
      // Recent submitted job
      JobModel(
        id: 'JOB001',
        jobId: 'JOB001',
        kycUserId: 'USER001',
        documentType: 'National ID',
        status: JobStatus.inProgress,
        currentStage: JobStage.faceVerification,
        progressPercentage: 60,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 2))),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 1))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: true, notes: 'Analyzing biometric data...'),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          id: 'USER001',
          names: 'John',
          surname: 'Doe',
        ),
      ),

      // Job in background check
      JobModel(
        id: 'JOB002',
        jobId: 'JOB002',
        kycUserId: 'USER002',
        documentType: 'Passport',
        status: JobStatus.inProgress,
        currentStage: JobStage.amlCheck,
        progressPercentage: 80,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 20))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 18))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 12))),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: false, isActive: true, notes: 'Conducting security clearance check'),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          id: 'USER002',
          names: 'Jane',
          surname: 'Smith',
        ),
      ),

      // Completed job
      JobModel(
        id: 'JOB003',
        jobId: 'JOB003',
        kycUserId: 'USER003',
        documentType: 'Driver License',
        status: JobStatus.completed,
        currentStage: JobStage.completed,
        progressPercentage: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 3))),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 3))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 2))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 2))),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.completed, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1)), notes: 'Verification successful'),
        ],
        userModel: UserModel(
          id: 'USER003',
          names: 'Mike',
          surname: 'Johnson',
          verificationStatus: VerificationStatus.verified,
        ),
      ),

      // Job on hold
      JobModel(
        id: 'JOB004',
        jobId: 'JOB004',
        kycUserId: 'USER004',
        documentType: 'National ID',
        status: JobStatus.onHold,
        currentStage: JobStage.ocrProcessing,
        progressPercentage: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 5))),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: false, isActive: false, notes: 'Additional documents required'),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          id: 'USER004',
          names: 'Sarah',
          surname: 'Williams',
        ),
      ),

      // Rejected job
      JobModel(
        id: 'JOB005',
        jobId: 'JOB005',
        kycUserId: 'USER005',
        documentType: 'Passport',
        status: JobStatus.rejected,
        currentStage: JobStage.finalReview,
        progressPercentage: 90,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        rejectionReason: 'Document quality insufficient for verification',
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 7))),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 6))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 5))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 4))),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false, notes: 'Rejected due to document quality'),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          id: 'USER005',
          names: 'Alex',
          surname: 'Brown',
          verificationStatus: VerificationStatus.failed,
        ),
      ),
    ];

    _jobs.clear();
    _jobs.addAll(mockJobs);
  }

  JobModel? getJobById(String id) {
    try {
      return _jobs.firstWhere((job) => job.id == id);
    } catch (e) {
      return null;
    }
  }

  List<JobModel> getJobsByStatus(JobStatus status) {
    return _jobs.where((job) => job.status == status).toList();
  }

  List<JobModel> get pendingJobs => getJobsByStatus(JobStatus.pending);
  List<JobModel> get inProgressJobs => getJobsByStatus(JobStatus.inProgress);
  List<JobModel> get completedJobs => getJobsByStatus(JobStatus.completed);
  List<JobModel> get rejectedJobs => getJobsByStatus(JobStatus.rejected);

  // Get user's full name from job data
  String getUserFullName(JobModel job) {
    if (job.userModel?.names != null && job.userModel?.surname != null) {
      return '${job.userModel!.names} ${job.userModel!.surname}';
    }
    return 'Unknown User';
  }

  // Get formatted job data for the form submission
  Map<String, dynamic> buildJobSubmissionData(UserModel user) {
    return {
      'kycUserId': user.id,
      'documentType': 'National ID',
      'personalData': {
        'names': user.names ?? '',
        'surname': user.surname ?? '',
        'personalIdNumber': user.personalIdNumber ?? '',
        'dateOfBirth': user.dateOfBirth?.toIso8601String(),
        'sex': user.sex ?? '',
        'chiefCode': user.chiefCode ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'email': user.email ?? '',
      },
      'documents': {
        'idFrontImage': user.idFrontImage,
        'idBackImage': user.idBackImage,
        'selfieImage': user.selfieImage,
      },
      // 'fingerprints': user.fingerprints?.map((fp) => fp.toJson()).toList() ?? [],
      'submittedAt': DateTime.now().toIso8601String(),
    };
  }

  // Submit new verification job
  Future<JobModel?> submitVerificationJob(UserModel user) async {
    try {
      final jobData = buildJobSubmissionData(user);
      final newJob = await _jobsApi.createJob(jobData);

      // Add to local list
      _jobs.insert(0, newJob);

      return newJob;
    } catch (e) {
      // Create mock job for fallback
      final mockJob = JobModel(
        id: 'JOB_${DateTime.now().millisecondsSinceEpoch}',
        jobId: 'JOB_${DateTime.now().millisecondsSinceEpoch}',
        kycUserId: user.id ?? 'UNKNOWN',
        documentType: 'National ID',
        status: JobStatus.pending,
        currentStage: JobStage.submitted,
        progressPercentage: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        stageProgress: [
          JobStageProgress(
            stage: JobStage.submitted,
            isCompleted: true,
            isActive: false,
            completedAt: DateTime.now(),
            notes: 'Job submitted successfully',
          ),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: false, isActive: true),
          JobStageProgress(stage: JobStage.ocrProcessing, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.amlCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: user,
      );

      _jobs.insert(0, mockJob);
      return mockJob;
    }
  }

  // Refresh jobs from API
  Future<void> refreshJobs() async {
    await loadJobs();
  }
}