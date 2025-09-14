import 'package:get/get.dart';
import 'jobs_controller.dart';
import '../../../data/services/jobs_service.dart';

class JobsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobsService>(() => JobsService());
    Get.lazyPut<JobsController>(() => JobsController());
  }
}