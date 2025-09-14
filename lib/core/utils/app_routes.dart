import 'package:get/get.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/splash/splash_binding.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/onboarding/onboarding_binding.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/home/home_binding.dart';
import '../../presentation/pages/verification/verification_flow_page.dart';
import '../../presentation/pages/verification/verification_binding.dart';
import '../../presentation/pages/verification/id_capture/id_capture_page.dart';
import '../../presentation/pages/verification/id_capture/id_capture_binding.dart';
import '../../presentation/pages/verification/selfie/selfie_capture_page.dart';
import '../../presentation/pages/verification/selfie/selfie_binding.dart';
import '../../presentation/pages/verification/fingerprint/fingerprint_capture_page.dart';
import '../../presentation/pages/verification/fingerprint/fingerprint_binding.dart';
import '../../presentation/pages/verification/result/result_page.dart';
import '../../presentation/pages/verification/result/result_binding.dart';
import '../../presentation/pages/jobs/jobs_page.dart';
import '../../presentation/pages/jobs/jobs_binding.dart';
import '../../presentation/pages/jobs/job_details_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String verification = '/verification';
  static const String idCapture = '/verification/id-capture';
  static const String selfieCapture = '/verification/selfie';
  static const String fingerprintCapture = '/verification/fingerprint';
  static const String result = '/verification/result';
  static const String jobs = '/jobs';
  static const String jobDetails = '/jobs/details';
  
  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: verification,
      page: () => const VerificationFlowPage(),
      binding: VerificationBinding(),
    ),
    GetPage(
      name: idCapture,
      page: () => const IDCapturePage(),
      binding: IDCaptureBinding(),
    ),
    GetPage(
      name: selfieCapture,
      page: () => const SelfieCapturePage(),
      binding: SelfieBinding(),
    ),
    GetPage(
      name: fingerprintCapture,
      page: () => const FingerprintCapturePage(),
      binding: FingerprintBinding(),
    ),
    GetPage(
      name: result,
      page: () => const ResultPage(),
      binding: ResultBinding(),
    ),
    GetPage(
      name: jobs,
      page: () => const JobsPage(),
      binding: JobsBinding(),
    ),
    GetPage(
      name: jobDetails,
      page: () => const JobDetailsPage(),
      binding: JobsBinding(),
    ),
  ];
}