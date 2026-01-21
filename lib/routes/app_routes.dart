import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../features/onboarding/screens/landing_screen.dart';
import '../features/auth/screens/registration_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/navigation/screens/main_navigation_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/hubs_and_services/legal_education/screens/legal_education_screen.dart';
import '../features/hubs_and_services/legal_education/screens/topic_materials_screen.dart';
import '../features/hubs_and_services/legal_education/screens/material_viewer_screen.dart';
import '../features/hubs_and_services/hub_content/screens/hub_content_screen.dart';
import '../features/bookmarks/screens/bookmark_screen.dart';
import '../features/help/screens/help_support_screen.dart';
import '../features/common/screens/coming_soon_screen.dart';
import '../features/questions/screens/my_questions_screen.dart';
import '../features/questions/screens/ask_question_screen.dart';
import '../features/questions/screens/question_detail_screen.dart';
import '../features/calling_booking/screens/consultants_screen.dart';
import '../features/calling_booking/screens/consultant_detail_screen.dart';
import '../features/calling_booking/screens/call_screen.dart';
import '../features/calling_booking/screens/credit_payment_screen.dart';
import '../features/calling_booking/screens/buy_credits_screen.dart';
import '../features/doc_templates/screens/templates_list_screen.dart';
import '../features/doc_templates/screens/generated_documents_screen.dart';
import '../features/nearbylawyers/screens/nearby_lawyers_screen.dart';
import '../features/nearbylawyers/screens/lawyers_map_screen.dart';
import '../features/auth/screens/change_role_screen.dart';
import '../features/consultation/screens/my_consultations_screen.dart';
import '../features/consultation/screens/book_consultation_screen.dart';
import '../features/subscription/screens/subscription_plans_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String legalEducation = '/legal-education';
  static const String topicMaterials = '/topic-materials';
  static const String materialViewer = '/material-viewer';
  static const String advocatesHub = '/advocates-hub';
  static const String studentsHub = '/students-hub';
  static const String forumHub = '/forum-hub';
  static const String bookmarks = '/bookmarks';
  static const String helpSupport = '/help-support';
  static const String comingSoon = '/coming-soon';
  static const String myQuestions = '/my-questions';
  static const String askQuestion = '/ask-question';
  static const String questionDetail = '/question-detail';
  static const String consultants = '/consultants';
  static const String consultantDetail = '/consultant-detail';
  static const String call = '/call';
  static const String payment = '/payment';
  static const String buyCredits = '/buy-credits';
  static const String templates = '/templates';
  static const String myDocuments = '/my-documents';
  static const String nearbyLawyers = '/nearby-lawyers';
  static const String lawyersMap = '/lawyers-map';
  static const String changeRole = '/change-role';
  static const String myConsultations = '/my-consultations';
  static const String bookConsultation = '/book-consultation';
  static const String subscriptionPlans = '/subscription-plans';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const AuthCheckScreen(),
    ),
    GetPage(
      name: landing,
      page: () => const LandingScreen(),
    ),
    GetPage(
      name: registration,
      page: () => const RegistrationScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: home,
      page: () => const MainNavigationScreen(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: legalEducation,
      page: () => const LegalEducationScreen(),
    ),
    GetPage(
      name: topicMaterials,
      page: () => const TopicMaterialsScreen(),
    ),
    GetPage(
      name: materialViewer,
      page: () => const MaterialViewerScreen(),
    ),
    GetPage(
      name: advocatesHub,
      page: () => const HubContentScreen(),
    ),
    GetPage(
      name: studentsHub,
      page: () => const HubContentScreen(),
    ),
    GetPage(
      name: forumHub,
      page: () => const HubContentScreen(),
    ),
    GetPage(
      name: bookmarks,
      page: () => const BookmarkScreen(),
    ),
    GetPage(
      name: helpSupport,
      page: () => const HelpSupportScreen(),
    ),
    GetPage(
      name: comingSoon,
      page: () => const ComingSoonScreen(),
    ),
    GetPage(
      name: myQuestions,
      page: () => const MyQuestionsScreen(),
    ),
    GetPage(
      name: askQuestion,
      page: () => AskQuestionScreen(
        materialId: Get.arguments?['materialId'],
        materialTitle: Get.arguments?['materialTitle'],
      ),
    ),
    GetPage(
      name: questionDetail,
      page: () => QuestionDetailScreen(
        questionId: Get.arguments['questionId'] ?? 0,
      ),
    ),
    GetPage(
      name: consultants,
      page: () => const ConsultantsScreen(),
    ),
    GetPage(
      name: consultantDetail,
      page: () => const ConsultantDetailScreen(),
    ),
    GetPage(
      name: call,
      page: () => CallScreen(
        consultant: Get.arguments?['consultant'],
        callId: Get.arguments?['callId'],
        channelName: Get.arguments?['channelName'],
        isIncoming: Get.arguments?['isIncoming'] ?? false,
        callerName: Get.arguments?['callerName'],
        callerPhoto: Get.arguments?['callerPhoto'],
      ),
    ),
    GetPage(
      name: payment,
      page: () => const CreditPaymentScreen(),
    ),
    GetPage(
      name: buyCredits,
      page: () => const BuyCreditsScreen(),
    ),
    GetPage(
      name: templates,
      page: () => const TemplatesListScreen(),
    ),
    GetPage(
      name: myDocuments,
      page: () => const GeneratedDocumentsScreen(),
    ),
    GetPage(
      name: nearbyLawyers,
      page: () => const NearbyLawyersScreen(),
    ),
    GetPage(
      name: lawyersMap,
      page: () => const LawyersMapScreen(),
    ),
    GetPage(
      name: changeRole,
      page: () => const ChangeRoleScreen(),
    ),
    GetPage(
      name: myConsultations,
      page: () => const MyConsultationsScreen(),
    ),
    GetPage(
      name: bookConsultation,
      page: () => const BookConsultationScreen(),
    ),
    GetPage(
      name: subscriptionPlans,
      page: () => const SubscriptionPlansScreen(),
    ),
  ];

  // Route not found handler
  static GetPage unknownRoute = GetPage(
    name: '/not-found',
    page: () => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
