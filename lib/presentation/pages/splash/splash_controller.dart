import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/services/storage_service.dart';

class SplashController extends GetxController {
  late final StorageService _storageService;
  
  SplashController() {
    debugPrint('[SplashController] Constructor called');
  }
  
  @override
  void onInit() {
    debugPrint('[SplashController] onInit called');
    super.onInit();
    
    try {
      _storageService = Get.find<StorageService>();
      debugPrint('[SplashController] StorageService found successfully');
    } catch (e) {
      debugPrint('[SplashController] ERROR: Could not find StorageService: $e');
    }
    
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      debugPrint('[SplashController] Initializing app...');
      
      // Check if storage service is available
      if (!Get.isRegistered<StorageService>()) {
        debugPrint('[SplashController] ERROR: StorageService not registered!');
        Get.offNamed('/onboarding');
        return;
      }
      
      debugPrint('[SplashController] Storage service found, proceeding...');
      
      // Give some time for splash screen animation
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('[SplashController] Checking if it is the first launch...');
      // Check if it's first launch
      final isFirstLaunch = await _storageService.isFirstLaunch();
      debugPrint('[SplashController] Is first launch: $isFirstLaunch');
      
      // Always show onboarding - user can skip if they want
      debugPrint('[SplashController] Navigating to onboarding (isFirstLaunch: $isFirstLaunch)...');
      
      // Mark first launch as complete if it's the first time
      if (isFirstLaunch) {
        await _storageService.setFirstLaunch(false);
        debugPrint('[SplashController] First launch marked as complete.');
      }
      
      // Always navigate to onboarding
      debugPrint('[SplashController] About to navigate to /onboarding');
      Get.offNamed('/onboarding');
      debugPrint('[SplashController] Navigation to /onboarding called');
    } catch (e) {
      debugPrint('[SplashController] Splash initialization error: $e');
      debugPrint('[SplashController] Stack trace: ${StackTrace.current}');
      // Fallback to onboarding if error
      debugPrint('[SplashController] Falling back to /onboarding');
      Get.offNamed('/onboarding');
    }
  }
}