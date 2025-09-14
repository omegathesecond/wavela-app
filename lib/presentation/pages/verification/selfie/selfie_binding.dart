import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'selfie_controller.dart';

class SelfieBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('[SelfieBinding] dependencies() called');
    Get.lazyPut(() => SelfieController());
    debugPrint('[SelfieBinding] SelfieController registered as lazy');
  }
}