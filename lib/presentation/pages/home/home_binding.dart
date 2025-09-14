import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('[HomeBinding] dependencies() called');
    Get.lazyPut(() => HomeController());
    debugPrint('[HomeBinding] HomeController registered as lazy');
  }
}