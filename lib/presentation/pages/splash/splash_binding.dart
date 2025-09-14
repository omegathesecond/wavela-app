import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('[SplashBinding] dependencies() called');
    Get.lazyPut(() => SplashController());
    debugPrint('[SplashBinding] SplashController registered as lazy');
  }
}