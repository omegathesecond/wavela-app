import 'package:get/get.dart';
import 'id_capture_controller.dart';

class IDCaptureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => IDCaptureController());
  }
}