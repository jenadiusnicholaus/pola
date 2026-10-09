import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());
    _restoreSavedCredentials();
  }

  Future<void> _restoreSavedCredentials() async {
    final saved = await controller.loadSavedCredentials();
    if (!mounted || saved == null) return;

    if (saved.email.isNotEmpty) {
      _emailController.text = saved.email;
    }
    if (saved.password.isNotEmpty) {
      _passwordController.text = saved.password;
    }
  }

  void _submitLogin() {
    controller.login(
      formKey: _formKey,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: 32),

                  // Welcome message
                  Text(tr('Welcome Back'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Form
                  _buildLoginForm(context),

                  const SizedBox(height: 24),

                  // Login Button
                  _buildLoginButton(context),

                  const SizedBox(height: 24),

                  // Additional Options
                  _buildAdditionalOptions(context),

                  const SizedBox(height: 40),

                  // Register Link
                  _buildRegisterLink(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.primaryAmber.withOpacity(0.15),
                  theme.colorScheme.surface,
                ]
              : [
                  AppColors.primaryAmber.withOpacity(0.95),
                  AppColors.primaryAmber.withOpacity(0.85),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Justice scale icon
              Text(tr('⚖️'),
                style: TextStyle(
                  fontSize: 48,
                  shadows: isDark
                      ? []
                      : [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                ),
              ),
              SizedBox(height: 12),

              // POLA app name
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : AppColors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),

              // Tagline
              Text(tr('The lawyer you carry'),
                style: TextStyle(
                  color: isDark
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : AppColors.black.withOpacity(0.7),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: controller.validateEmail,
            decoration: InputDecoration(
              labelText: tr('Email Address'),
              hintText: 'Enter your email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              filled: false,
            ),
          ),

          SizedBox(height: 16),

          // Password Field
          Obx(() => TextFormField(
                controller: _passwordController,
                obscureText: !controller.isPasswordVisible,
                textInputAction: TextInputAction.done,
                validator: controller.validatePassword,
                onFieldSubmitted: (_) => _submitLogin(),
                decoration: InputDecoration(
                  labelText: tr('Password'),
                  hintText: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: false,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Obx(() => ElevatedButton(
          onPressed: controller.isLoading ? null : _submitLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
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

  Widget _buildAdditionalOptions(BuildContext context) {
    return Column(
      children: [
        // Remember Me and Forgot Password Row
        Row(
          children: [
            // Remember Me Checkbox
            Expanded(
              child: Obx(() => CheckboxListTile(
                    value: controller.rememberMe,
                    onChanged: (value) => controller.toggleRememberMe(value),
                    title: Text(tr('Remember me'),
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
            TextButton(
              onPressed: controller.goToForgotPassword,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(tr('Forgot Password?'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Don\'t have an account?',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.goToRegistration,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
