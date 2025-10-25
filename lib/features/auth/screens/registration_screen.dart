import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/registration_controller.dart';
import '../services/lookup_service.dart';
import 'pages/role_selection_page.dart';
import 'pages/basic_info_page.dart';
import 'pages/contact_info_page.dart';
import 'pages/identity_info_page.dart';
import 'pages/professional_info_page.dart';
import 'pages/review_submit_page.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services and controller
    Get.put(LookupService());
    final controller = Get.put(RegistrationController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.getPageTitle())),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (controller.isFirstPage) {
              Get.back();
            } else {
              controller.previousPage();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Obx(() => LinearProgressIndicator(
                value: controller.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              )),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator with page numbers
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Step ${controller.currentPage + 1} of ${controller.totalPages}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                )),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (index) {
                // Update current page when user swipes (will be implemented)
              },
              children: [
                const RoleSelectionPage(),
                const BasicInfoPage(),
                const ContactInfoPage(),
                const IdentityInfoPage(),
                const ProfessionalInfoPage(),
                if (controller.totalPages > 5) const ReviewSubmitPage(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Previous button
                Obx(() => controller.isFirstPage
                    ? const SizedBox(width: 100)
                    : SizedBox(
                        width: 100,
                        child: OutlinedButton(
                          onPressed: controller.previousPage,
                          child: const Text('Previous'),
                        ),
                      )),

                const Spacer(),

                // Next/Submit button
                Obx(() => SizedBox(
                      width: 120,
                      child: controller.isLastPage
                          ? ElevatedButton(
                              onPressed: controller.isSubmitting
                                  ? null
                                  : controller.submitRegistration,
                              child: controller.isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Submit'),
                            )
                          : ElevatedButton(
                              onPressed: controller.nextPage,
                              child: const Text('Next'),
                            ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
