import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/job_model.dart';
import '../../../data/services/jobs_service.dart';

class JobsController extends GetxController {
  final JobsService _jobsService = Get.find<JobsService>();
  
  final RxString selectedFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  
  bool get isLoading => _jobsService.isLoading.value;
  RxBool get isLoadingObs => _jobsService.isLoading;
  
  List<JobModel> get allJobs => _jobsService.jobs;
  
  List<JobModel> get filteredJobs {
    var jobs = _jobsService.jobs;
    
    // Apply status filter
    if (selectedFilter.value != 'all') {
      final status = JobStatus.values.firstWhereOrNull(
        (s) => s.name == selectedFilter.value
      );
      if (status != null) {
        jobs = jobs.where((job) => job.status == status).toList();
      }
    }
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      jobs = jobs.where((job) => 
        job.id.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        job.userModel?.fullName?.toLowerCase().contains(searchQuery.value.toLowerCase()) == true ||
        job.documentType.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }
    
    // Sort by created date (newest first)
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return jobs;
  }
  
  int get totalJobs => _jobsService.totalJobs;
  int get pendingJobs => _jobsService.pendingJobs;
  int get inProgressJobs => _jobsService.inProgressJobs;
  int get completedJobs => _jobsService.completedJobs;
  
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
  
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
  
  void refreshJobs() {
    _jobsService.refreshJobs();
  }
  
  void viewJobDetails(JobModel job) {
    Get.toNamed('/jobs/details', arguments: job);
  }
  
  Color getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.onHold:
        return Colors.amber;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.rejected:
        return Colors.red;
      case JobStatus.expired:
        return Colors.grey;
    }
  }
  
  IconData getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Icons.hourglass_empty;
      case JobStatus.inProgress:
        return Icons.sync;
      case JobStatus.onHold:
        return Icons.pause;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.rejected:
        return Icons.cancel;
      case JobStatus.expired:
        return Icons.schedule;
    }
  }
  
  IconData getStageIcon(JobStage stage) {
    switch (stage) {
      case JobStage.submitted:
        return Icons.send;
      case JobStage.documentReview:
        return Icons.description;
      case JobStage.faceVerification:
        return Icons.face;
      case JobStage.fingerprintAnalysis:
        return Icons.fingerprint;
      case JobStage.backgroundCheck:
        return Icons.security;
      case JobStage.finalReview:
        return Icons.rate_review;
      case JobStage.completed:
        return Icons.done_all;
    }
  }
  
  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }
}