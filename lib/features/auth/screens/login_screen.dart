import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the login controller
    final controller = Get.put(LoginController());

    return Scaffold(
      body: Column(
        children: [
          // App Logo Header
          _buildHeader(context),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  const SizedBox(height: 48),

                  // Login Form
                  _buildLoginForm(context, controller),

                  const SizedBox(height: 24),

                  // Login Button
                  _buildLoginButton(context, controller),

                  const SizedBox(height: 24),

                  // Additional Options
                  _buildAdditionalOptions(context, controller),

                  const SizedBox(height: 40),

                  // Register Link
                  _buildRegisterLink(context, controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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

              const SizedBox(height: 16),

              // Welcome message
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Sign in to your Pola Legal account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.black.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: controller.validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),

          const SizedBox(height: 16),

          // Password Field
          Obx(() => TextFormField(
                controller: controller.passwordController,
                obscureText: !controller.isPasswordVisible,
                textInputAction: TextInputAction.done,
                validator: controller.validatePassword,
                onFieldSubmitted: (_) => controller.login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginController controller) {
    return Obx(() => ElevatedButton(
          onPressed: controller.isLoading ? null : controller.login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: controller.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ));
  }

  Widget _buildAdditionalOptions(
      BuildContext context, LoginController controller) {
    return Column(
      children: [
        // Remember Me and Forgot Password Row
        Row(
          children: [
            // Remember Me Checkbox
            Expanded(
              child: Obx(() => CheckboxListTile(
                    value: controller.rememberMe,
                    onChanged: (_) => controller.toggleRememberMe(),
                    title: Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Theme.of(context).colorScheme.primary,
                  )),
            ),

            // Forgot Password Link
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAmberLight.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: TextButton(
                onPressed: controller.goToForgotPassword,
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness ==
                          Brightness.dark
                      ? AppColors.primaryAmberLight.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primaryAmberLight
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context, LoginController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryAmberLight.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Don\'t have an account?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.goToRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.buttonBlue
                    : Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              child: const Text(
                'Create New Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
