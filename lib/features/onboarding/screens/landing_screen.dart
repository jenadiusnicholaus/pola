import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_const_list_obj.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Section (Flexible height with amber background)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryAmber,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Justice scale icon on top
                    const Text(
                      '⚖️',
                      style: TextStyle(
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // POLA app name in middle
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Horizontal line spacer
                    Container(
                      width: 60,
                      height: 1.5,
                      color: AppColors.black,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    const SizedBox(height: 4),

                    // Tagline at bottom
                    const Text(
                      'The lawyer you carry',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.3,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Section (Professional layout with precise centering)
          Expanded(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top section with welcome text
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Welcome to Portable Lawyer App',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Center section - Features list (precisely fitted)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: AppConstListObj.appConstListBjs.length,
                          itemBuilder: (context, index) {
                            final feature =
                                AppConstListObj.appConstListBjs[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]?.withOpacity(0.2)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      AppColors.primaryAmber.withOpacity(0.15),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon with consistent spacing
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    child: Text(
                                      feature['icon'] as String,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Feature text
                                  Expanded(
                                    child: Text(
                                      feature['title'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2,
                                        letterSpacing: 0.1,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.87)
                                            : Colors.grey[800],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottom section with CTA and buttons (constrained)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "All in one Place!" text
                      Text(
                        'All in One Place!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAmber,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                  height: 1.1,
                                ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Sign Up Button (Amber) - compact but readable
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to registration screen
                            Get.toNamed('/registration');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonAmber,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            '${AppStrings.signUpBtnText.toUpperCase()} | ${AppStrings.signUpBtnTextSw.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // "Already have an account" text - compact
                      const Text(
                        'Already have an account | Una akaunt tayari?',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      // Sign In Button (Amber) - compact but readable
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to login screen
                            Get.toNamed('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAmber,
                            foregroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            '${AppStrings.signInBtnText.toUpperCase()} | ${AppStrings.signInBtnTextSw.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Temporary Skip Button (for development)
                      SizedBox(
                        height: 24,
                        child: TextButton(
                          onPressed: () {
                            Get.offAllNamed('/home');
                          },
                          child: const Text(
                            'Skip to Home (Development Only)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 8,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
