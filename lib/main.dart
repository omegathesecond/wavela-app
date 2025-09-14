import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'data/services/api_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/advanced_liveness_service.dart';
import 'data/services/config_service.dart';

Future<void> initServices() async {
  // Initialize services in the correct order
  debugPrint('[Main] Initializing services...');
  
  // Initialize storage service first
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);
  debugPrint('[Main] Storage service initialized and registered');
  
  // Initialize config service before API service (API service depends on it)
  final configService = ConfigService();
  await configService.onInit();
  Get.put(configService, permanent: true);
  debugPrint('[Main] Config service initialized and registered');
  
  // Initialize API service
  Get.put(ApiService(), permanent: true);
  debugPrint('[Main] API service initialized and registered');
  
  // Initialize advanced liveness service
  Get.put(AdvancedLivenessService(), permanent: true);
  debugPrint('[Main] Advanced liveness service initialized and registered');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    await initServices();
    runApp(const WavelaApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $error'),
        ),
      ),
    );
  }
}

class WavelaApp extends StatelessWidget {
  const WavelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[WavelaApp] Building app with initial route: ${AppRoutes.splash}');
    return GetMaterialApp(
      title: 'Wavela',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      routingCallback: (routing) {
        debugPrint('[WavelaApp] Routing to: ${routing?.current}');
      },
    );
  }
}
