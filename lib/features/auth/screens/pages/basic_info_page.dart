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
    _selectedDate = data.dateOfBirth;
    _selectedGender = data.gender.isEmpty ? null : data.gender;
  }

  bool _validateForm() {
    // Law firms (role 5) don't need personal details
    final isLawFirm = controller.registrationData.userRole == 5;

    if (!isLawFirm) {
      if (_firstNameController.text.trim().isEmpty) {
        debugPrint('❌ Validation failed: First name is empty');
        return false;
      }
      if (_lastNameController.text.trim().isEmpty) {
        debugPrint('❌ Validation failed: Last name is empty');
        return false;
      }
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
    if (!isLawFirm) {
      if (_selectedDate == null) {
        debugPrint('❌ Validation failed: Date of birth not selected');
        return false;
      }
      if (_selectedGender == null) {
        debugPrint('❌ Validation failed: Gender not selected');
        return false;
      }
    }
    if (!controller.registrationData.agreedToTerms) {
      debugPrint('❌ Validation failed: Terms not agreed to');
      return false;
    }
    debugPrint('✅ Basic info validation passed');
    return true;
  }

  void _handleNext() {
    if (_validateForm()) {
      final data = controller.registrationData;
      final isLawFirm = controller.registrationData.userRole == 5;

      // Only set personal details for non-law firms
      if (!isLawFirm) {
        data.firstName = _firstNameController.text.trim();
        data.lastName = _lastNameController.text.trim();
        data.dateOfBirth = _selectedDate;
        if (_selectedGender != null) {
          data.gender = _selectedGender!;
        }
      }

      // Email and password are required for all roles
      data.email = _emailController.text.trim();
      data.password = _passwordController.text;
      data.passwordConfirm = _confirmPasswordController.text;

      controller.updateRegistrationData(data);
      controller.nextPage();
    }
  }

  void _saveData() {
    final data = controller.registrationData;
    final isLawFirm = controller.registrationData.userRole == 5;

    // Only save personal details for non-law firms
    if (!isLawFirm) {
      data.firstName = _firstNameController.text;
      data.lastName = _lastNameController.text;
      data.dateOfBirth = _selectedDate;
      if (_selectedGender != null) {
        data.gender = _selectedGender!;
      }
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFCFCFD),
            const Color(0xFFF8FAFC),
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your personal details to continue',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 32),

              // Show selected role (read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.08),
                      const Color(0xFF1D4ED8).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: const Color(0xFF1D4ED8),
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
                              color: const Color(0xFF6B7280),
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
                              color: const Color(0xFF1D4ED8),
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

              // Personal Details Section - Only for non-law firms
              if (controller.registrationData.userRole != 5) ...[
                // Name Section
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // First Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your first name',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: const Color(0xFF3B82F6), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFEF4444)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
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
                      'Last Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your last name',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: const Color(0xFF3B82F6), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFEF4444)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
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
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),

              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: const Color(0xFF3B82F6), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFEF4444)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
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

              // Date of Birth and Gender - Only for non-law firms
              if (controller.registrationData.userRole != 5) ...[
                // Date of Birth
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
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
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFFAFAFA),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                    : 'Select your date of birth',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: _selectedDate != null
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF9CA3AF),
                                  letterSpacing: -0.1,
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
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFFAFAFA),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'M'
                                      ? const Color(0xFF3B82F6)
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
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Male',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedGender == 'M'
                                            ? Colors.white
                                            : const Color(0xFF374151),
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
                            color: const Color(0xFFD1D5DB),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'F'
                                      ? const Color(0xFF3B82F6)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female,
                                      color: _selectedGender == 'F'
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Female',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedGender == 'F'
                                            ? Colors.white
                                            : const Color(0xFF374151),
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
                            color: const Color(0xFFD1D5DB),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'O';
                                });
                                _saveData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'O'
                                      ? const Color(0xFF3B82F6)
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
                                      Icons.person_outline,
                                      color: _selectedGender == 'O'
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Other',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedGender == 'O'
                                            ? Colors.white
                                            : const Color(0xFF374151),
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

              // Security Section
              Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Create a strong password',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: const Color(0xFF3B82F6), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFEF4444)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
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
                    'Minimum 8 characters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirm Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: const Color(0xFF3B82F6), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFFEF4444)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
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
                      Colors.grey.shade200,
                      Colors.grey.shade400,
                      Colors.grey.shade200
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
                          ? Colors.blue.shade50
                          : Colors.red.shade100,
                      border: Border.all(
                        color: controller.registrationData.agreedToTerms
                            ? Colors.blue.shade300
                            : Colors.red.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: controller.registrationData.agreedToTerms
                                ? Colors.blue.shade800
                                : Colors.red.shade800,
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
                                activeColor: const Color(0xFF3B82F6),
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF374151),
                                            height: 1.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3B82F6),
                                            height: 1.4,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' and ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF374151),
                                            height: 1.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3B82F6),
                                            height: 1.4,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: controller
                                              .registrationData.agreedToTerms
                                          ? const Color(0xFF6B7280)
                                          : Colors.red.shade700,
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

  String _getRoleDisplay(int roleId) {
    final roles = controller.lookupService.userRoles;
    try {
      final role = roles.firstWhere((role) => role.id == roleId);
      return role.getRoleDisplay;
    } catch (e) {
      print('Role not found for ID: $roleId');
      return 'Role Not Found';
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFFEF4444), width: 2),
      ),
      errorStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFEF4444),
        height: 1.3,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
