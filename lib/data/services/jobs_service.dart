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
        userId: 'USER001',
        documentType: 'National ID',
        status: JobStatus.inProgress,
        currentStage: JobStage.fingerprintAnalysis,
        progressPercentage: 60,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 2))),
          JobStageProgress(stage: JobStage.documentReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 1))),
          JobStageProgress(stage: JobStage.fingerprintAnalysis, isCompleted: false, isActive: true, notes: 'Analyzing biometric data...'),
          JobStageProgress(stage: JobStage.backgroundCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          fullName: 'John Doe',
          fingerprints: [
            FingerprintData(finger: 'Right Thumb', quality: 0.92, template: 'template1', capturedAt: DateTime.now()),
            FingerprintData(finger: 'Left Thumb', quality: 0.88, template: 'template2', capturedAt: DateTime.now()),
          ],
        ),
      ),
      
      // Job in background check
      JobModel(
        id: 'JOB002',
        userId: 'USER002',
        documentType: 'Passport',
        status: JobStatus.inProgress,
        currentStage: JobStage.backgroundCheck,
        progressPercentage: 80,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.documentReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 20))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 18))),
          JobStageProgress(stage: JobStage.fingerprintAnalysis, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(hours: 12))),
          JobStageProgress(stage: JobStage.backgroundCheck, isCompleted: false, isActive: true, notes: 'Conducting security clearance check'),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          fullName: 'Jane Smith',
        ),
      ),
      
      // Completed job
      JobModel(
        id: 'JOB003',
        userId: 'USER003',
        documentType: 'Driver License',
        status: JobStatus.completed,
        currentStage: JobStage.completed,
        progressPercentage: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 3))),
          JobStageProgress(stage: JobStage.documentReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 3))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 2))),
          JobStageProgress(stage: JobStage.fingerprintAnalysis, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 2))),
          JobStageProgress(stage: JobStage.backgroundCheck, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1))),
          JobStageProgress(stage: JobStage.completed, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 1)), notes: 'Verification successful'),
        ],
        userModel: UserModel(
          fullName: 'Mike Johnson',
          verificationStatus: VerificationStatus.verified,
        ),
      ),
      
      // Job on hold
      JobModel(
        id: 'JOB004',
        userId: 'USER004',
        documentType: 'National ID',
        status: JobStatus.onHold,
        currentStage: JobStage.documentReview,
        progressPercentage: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 5))),
          JobStageProgress(stage: JobStage.documentReview, isCompleted: false, isActive: false, notes: 'Additional documents required'),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.fingerprintAnalysis, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.backgroundCheck, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: false, isActive: false),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          fullName: 'Sarah Williams',
        ),
      ),
      
      // Rejected job
      JobModel(
        id: 'JOB005',
        userId: 'USER005',
        documentType: 'Passport',
        status: JobStatus.rejected,
        currentStage: JobStage.finalReview,
        progressPercentage: 90,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
        rejectionReason: 'Document authenticity could not be verified',
        stageProgress: [
          JobStageProgress(stage: JobStage.submitted, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 7))),
          JobStageProgress(stage: JobStage.documentReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 6))),
          JobStageProgress(stage: JobStage.faceVerification, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 5))),
          JobStageProgress(stage: JobStage.fingerprintAnalysis, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 4))),
          JobStageProgress(stage: JobStage.backgroundCheck, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 4))),
          JobStageProgress(stage: JobStage.finalReview, isCompleted: true, isActive: false, completedAt: DateTime.now().subtract(const Duration(days: 3)), notes: 'Document verification failed'),
          JobStageProgress(stage: JobStage.completed, isCompleted: false, isActive: false),
        ],
        userModel: UserModel(
          fullName: 'Alex Brown',
          verificationStatus: VerificationStatus.failed,
        ),
      ),
    ];
    
    _jobs.addAll(mockJobs);
  }
  
  JobModel? getJobById(String id) {
    return _jobs.firstWhereOrNull((job) => job.id == id);
  }
  
  List<JobModel> getJobsByStatus(JobStatus status) {
    return _jobs.where((job) => job.status == status).toList();
  }
  
  Future<void> addJob(JobModel job) async {
    // Use microtask to avoid setState during build
    await Future.microtask(() {
      _jobs.add(job);
      _jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
  
  void updateJob(JobModel job) {
    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      _jobs[index] = job;
    }
  }
  
  Future<void> refreshJobs() async {
    await loadJobs();
  }
  
  int get totalJobs => _jobs.length;
  int get pendingJobs => _jobs.where((job) => job.status == JobStatus.pending).length;
  int get inProgressJobs => _jobs.where((job) => job.status == JobStatus.inProgress).length;
  int get completedJobs => _jobs.where((job) => job.status == JobStatus.completed).length;
  
  Future<JobModel> createJobFromVerification({
    required String documentType,
    required UserModel userModel,
  }) async {
    try {
      // Create verification job using new API
      final job = await _jobsApi.createVerificationJob(
        userId: userModel.id ?? 'unknown',
        verificationType: documentType,
        metadata: {
          'fullName': userModel.fullName ?? '',
          'idNumber': userModel.idNumber ?? '',
          'dateOfBirth': userModel.dateOfBirth?.toIso8601String(),
          'gender': userModel.gender,
          'address': userModel.address,
          'phoneNumber': userModel.phoneNumber,
          'email': userModel.email,
          'idIssueDate': userModel.idIssueDate?.toIso8601String(),
          'idExpiryDate': userModel.idExpiryDate?.toIso8601String(),
        },
      );
      
      await addJob(job);
      return job;
    } catch (e) {
      // Fallback: create local job if API fails
      return await _createLocalJob(documentType: documentType, userModel: userModel);
    }
  }
  
  Future<JobModel> _createLocalJob({
    required String documentType,
    required UserModel userModel,
  }) async {
    final jobId = 'JOB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final job = JobModel(
      id: jobId,
      userId: userModel.id ?? 'USER${DateTime.now().millisecondsSinceEpoch}',
      documentType: documentType,
      status: JobStatus.inProgress,
      currentStage: JobStage.submitted,
      progressPercentage: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userModel: userModel,
      stageProgress: [
        JobStageProgress(
          stage: JobStage.submitted, 
          isCompleted: true, 
          isActive: false, 
          completedAt: DateTime.now(),
        ),
        JobStageProgress(
          stage: JobStage.documentReview, 
          isCompleted: false, 
          isActive: true, 
          notes: 'Processing submitted documents...',
        ),
        JobStageProgress(
          stage: JobStage.faceVerification, 
          isCompleted: false, 
          isActive: false,
        ),
        JobStageProgress(
          stage: JobStage.fingerprintAnalysis, 
          isCompleted: false, 
          isActive: false,
        ),
        JobStageProgress(
          stage: JobStage.backgroundCheck, 
          isCompleted: false, 
          isActive: false,
        ),
        JobStageProgress(
          stage: JobStage.finalReview, 
          isCompleted: false, 
          isActive: false,
        ),
        JobStageProgress(
          stage: JobStage.completed, 
          isCompleted: false, 
          isActive: false,
        ),
      ],
    );
    
    await addJob(job);
    return job;
  }
}