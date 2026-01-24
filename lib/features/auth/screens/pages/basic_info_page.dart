import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({super.key});

  @override
  State<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final controller = Get.find<RegistrationController>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _occupationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = controller.registrationData;
    _firstNameController.text = data.firstName;
    _lastNameController.text = data.lastName;
    _emailController.text = data.email;
    _passwordController.text = data.password;
    _confirmPasswordController.text = data.passwordConfirm;
    _occupationController.text = data.occupation ?? '';
    _selectedDate = data.dateOfBirth;
    _selectedGender = data.gender.isEmpty ? null : data.gender;
  }

  bool _validateForm() {
    // All roles need personal details (including law firms)
    if (_firstNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: First name is empty');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: Last name is empty');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      debugPrint('❌ Validation failed: Email is empty');
      return false;
    }
    if (!GetUtils.isEmail(_emailController.text.trim())) {
      debugPrint('❌ Validation failed: Email format invalid');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      debugPrint('❌ Validation failed: Password is empty');
      return false;
    }
    if (_passwordController.text.length < 8) {
      debugPrint('❌ Validation failed: Password too short');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      debugPrint('❌ Validation failed: Passwords do not match');
      return false;
    }
    // All roles need date of birth and gender (including law firms)
    if (_selectedDate == null) {
      debugPrint('❌ Validation failed: Date of birth not selected');
      return false;
    }
    if (_selectedGender == null) {
      debugPrint('❌ Validation failed: Gender not selected');
      return false;
    }
    if (!controller.registrationData.agreedToTerms) {
      debugPrint('❌ Validation failed: Terms not agreed to');
      return false;
    }
    debugPrint('✅ Basic info validation passed');
    return true;
  }

  void _saveData() {
    final data = controller.registrationData;

    // Save personal details for all roles (including law firms)
    data.firstName = _firstNameController.text;
    data.lastName = _lastNameController.text;
    data.dateOfBirth = _selectedDate;
    if (_selectedGender != null) {
      data.gender = _selectedGender!;
    }

    // Save occupation for citizens
    if (data.userRole == 'citizen') {
      data.occupation = _occupationController.text;
    }

    // Email and password are required for all roles
    data.email = _emailController.text;
    data.password = _passwordController.text;
    data.passwordConfirm = _confirmPasswordController.text;
    controller.updateRegistrationData(data);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🏗️ Building BasicInfoPage - Terms agreed: ${controller.registrationData.agreedToTerms}');

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: controller.basicInfoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your personal details to continue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Show selected role (read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.08),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Role',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getRoleDisplay(
                                controller.registrationData.userRole),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Personal Details Section - Required for all roles
              ...[
                // Name Section
                Text(
                  controller.registrationData.userRole == 'citizen'
                      ? 'Maelezo ya Kibinafsi | Personal Details'
                      : 'Personal Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // First Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.registrationData.userRole == 'citizen'
                          ? 'Jina la Kwanza | First Name'
                          : 'First Name',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: controller.registrationData.userRole == 'citizen'
                            ? 'Jina | Name'
                            : 'First name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                      onChanged: (value) => _saveData(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Last Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.registrationData.userRole == 'citizen'
                          ? 'Jina la Mwisho | Last Name'
                          : 'Last Name',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: controller.registrationData.userRole == 'citizen'
                            ? 'Jina | Name'
                            : 'Last name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                      onChanged: (value) => _saveData(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Contact Information Section
              Text(
                controller.registrationData.userRole == 'citizen'
                    ? 'Mawasiliano | Contact Information'
                    : 'Contact Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.registrationData.userRole == 'citizen'
                        ? 'Barua pepe | Email Address'
                        : 'Email Address',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: controller.registrationData.userRole == 'citizen'
                          ? 'Barua pepe | Email'
                          : 'Email address',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onChanged: (value) => _saveData(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date of Birth and Gender - Required for all roles
              ...[
                // Date of Birth
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.registrationData.userRole == 'citizen'
                          ? 'Tarehe ya Kuzaliwa | Date of Birth'
                          : 'Date of Birth',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ??
                              DateTime.now().subtract(
                                  const Duration(days: 6570)), // 18 years ago
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                          _saveData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                          color: colorScheme.surfaceContainer,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                    : (controller.registrationData.userRole == 'citizen'
                                        ? 'Chagua tarehe | Select date'
                                        : 'Select date'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: _selectedDate != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Gender
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.registrationData.userRole == 'citizen'
                          ? 'Jinsia | Gender'
                          : 'Gender',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                        color: colorScheme.surfaceContainer,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'M';
                                });
                                _saveData();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'M'
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    bottomLeft: Radius.circular(7),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.male,
                                      color: _selectedGender == 'M'
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      controller.registrationData.userRole == 'citizen'
                                          ? 'Me | Male'
                                          : 'Male',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _selectedGender == 'M'
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: colorScheme.outline,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'F';
                                });
                                _saveData();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'F'
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(7),
                                    bottomRight: Radius.circular(7),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female,
                                      color: _selectedGender == 'F'
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      controller.registrationData.userRole == 'citizen'
                                          ? 'Ke | Female'
                                          : 'Female',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _selectedGender == 'F'
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Occupation field for citizens only
              if (controller.registrationData.userRole == 'citizen') ...[                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kazi | Occupation',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _occupationController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Kazi yako | Your occupation',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(
                          Icons.work_outline,
                          size: 20,
                        ),
                      ),
                      onChanged: (value) => _saveData(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Security Section
              Text(
                controller.registrationData.userRole == 'citizen'
                    ? 'Usalama | Security'
                    : 'Security',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.registrationData.userRole == 'citizen'
                        ? 'Neno la Siri | Password'
                        : 'Password',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: controller.registrationData.userRole == 'citizen'
                          ? 'Neno la siri | Password'
                          : 'Password',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                    onChanged: (value) => _saveData(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.registrationData.userRole == 'citizen'
                        ? 'Angalau herufi 8 | Minimum 8 characters'
                        : 'Minimum 8 characters',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirm Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.registrationData.userRole == 'citizen'
                        ? 'Thibitisha Neno la Siri | Confirm Password'
                        : 'Confirm Password',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: controller.registrationData.userRole == 'citizen'
                          ? 'Thibitisha | Confirm'
                          : 'Confirm password',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (value) => _saveData(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Add visual separator before terms
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.outline.withOpacity(0.3),
                      colorScheme.outline,
                      colorScheme.outline.withOpacity(0.3)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms and Conditions - IMPORTANT SECTION
              Builder(
                builder: (context) {
                  debugPrint(
                      '📋 Rendering Terms & Conditions checkbox section');
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: controller.registrationData.agreedToTerms
                          ? colorScheme.primaryContainer.withOpacity(0.3)
                          : colorScheme.errorContainer.withOpacity(0.3),
                      border: Border.all(
                        color: controller.registrationData.agreedToTerms
                            ? colorScheme.primary.withOpacity(0.5)
                            : colorScheme.error.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header for terms section
                        Text(
                          '📋 Terms & Conditions Agreement',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: controller.registrationData.agreedToTerms
                                    ? colorScheme.primary
                                    : colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value:
                                    controller.registrationData.agreedToTerms,
                                onChanged: (value) {
                                  final data = controller.registrationData;
                                  data.agreedToTerms = value ?? false;
                                  controller.updateRegistrationData(data);
                                  setState(() {});
                                },
                                activeColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'I agree to the ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                        TextSpan(
                                          text: ' and ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.registrationData.agreedToTerms
                                        ? 'Required to continue with registration'
                                        : '⚠️ You must agree to continue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: controller.registrationData
                                                  .agreedToTerms
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.error,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ], // End of Row children
                        ), // End of Row
                      ], // End of Column children
                    ), // End of Column
                  ); // End of Container
                },
              ), // End of Builder

              // Bottom spacing for better visual balance and scroll visibility
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplay(String roleName) {
    final roles = controller.lookupService.userRoles;
    try {
      final role = roles.firstWhere((role) => role.roleName == roleName);
      return role.getRoleDisplay;
    } catch (e) {
      print('Role not found for name: $roleName');
      return 'Role Not Found';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _occupationController.dispose();
    super.dispose();
  }
}
