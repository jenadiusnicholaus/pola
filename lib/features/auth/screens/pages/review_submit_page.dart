import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';

class ReviewSubmitPage extends StatelessWidget {
  const ReviewSubmitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegistrationController>();
    final data = controller.registrationData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with Step Indicator
          _buildEnhancedHeader(context, controller),
          const SizedBox(height: 24),

          // Comprehensive Review Sections
          _buildComprehensiveReview(context, data, controller),

          const SizedBox(height: 32),

          // Final Submit Instructions
          _buildSubmitInstructions(context),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(
      BuildContext context, RegistrationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Review & Submit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step ${controller.currentPage + 1} of ${controller.totalPages} - Registration Summary',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please carefully review all information below before submitting your registration.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComprehensiveReview(
      BuildContext context, dynamic data, RegistrationController controller) {
    return Column(
      children: [
        // Step 1: User Role Selection
        _buildStepSection(
          context,
          1,
          'User Role Selection',
          Icons.person_outline,
          [
            _buildInfoRow('Selected Role', _getRoleDisplay(data.userRole)),
            _buildInfoRow(
                'Role Description', _getRoleDescription(data.userRole)),
          ],
          null,
        ),

        // Step 2: Basic Information Section (for non-law firms)
        if (data.userRole != 'law_firm')
          _buildStepSection(
            context,
            2,
            'Basic Information',
            Icons.badge_outlined,
            [
              _buildInfoRow('Full Name', '${data.firstName} ${data.lastName}'),
              _buildInfoRow('Email Address', data.email),
              _buildInfoRow('Date of Birth',
                  data.dateOfBirth?.toString().split(' ')[0] ?? 'Not provided'),
              _buildInfoRow('Gender', _getGenderDisplay(data.gender)),
            ],
            null,
          ),

        // Basic Information for law firms
        if (data.userRole == 'law_firm')
          _buildStepSection(
            context,
            2,
            'Basic Information',
            Icons.badge_outlined,
            [
              _buildInfoRow('Full Name', '${data.firstName} ${data.lastName}'),
              _buildInfoRow('Email Address', data.email),
              _buildInfoRow('Date of Birth',
                  data.dateOfBirth?.toString().split(' ')[0] ?? 'Not provided'),
              _buildInfoRow('Gender', _getGenderDisplay(data.gender)),
            ],
            null,
          ),

        // Step 3: Contact & Location Information
        _buildStepSection(
          context,
          3,
          'Contact & Location Information',
          Icons.location_on_outlined,
          [
            _buildInfoRow(
                'Phone Number',
                data.phoneNumber.isNotEmpty
                    ? data.phoneNumber
                    : 'Not provided'),
            if (data.region != null)
              _buildInfoRow('Region ID', data.region.toString()),
            if (data.district != null)
              _buildInfoRow('District ID', data.district.toString()),
            if (data.ward?.isNotEmpty == true)
              _buildInfoRow('Ward', data.ward!),
          ],
          null,
        ),

        // Step 4: Professional Information (for professional roles)
        if (_shouldShowProfessionalInfo(data.userRole))
          _buildStepSection(
            context,
            4,
            'Professional Information',
            Icons.work_outline,
            _buildProfessionalInfo(data),
            null,
          ),

        // Step 5: Terms and Conditions Agreement
        _buildStepSection(
          context,
          _shouldShowProfessionalInfo(data.userRole) ? 5 : 4,
          'Terms & Conditions Agreement',
          Icons.assignment_outlined,
          [
            _buildAgreementStatus('Terms and Conditions', data.agreedToTerms),
          ],
          null,
        ),

        const SizedBox(height: 24),

        // Validation Status
        GetBuilder<RegistrationController>(
          builder: (controller) {
            final errors = controller.registrationData.validateForRole();
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errors.isEmpty
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : colorScheme.errorContainer.withOpacity(0.3),
                border: Border.all(
                  color:
                      errors.isEmpty ? colorScheme.primary : colorScheme.error,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        errors.isEmpty ? Icons.check_circle : Icons.error,
                        color: errors.isEmpty
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        errors.isEmpty
                            ? 'Ready to Submit'
                            : 'Please Fix Errors',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: errors.isEmpty
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...errors.map((error) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(color: colorScheme.error)),
                              Expanded(
                                child: Text(
                                  error,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitInstructions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.send_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to Submit?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click the Submit button below to create your account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSection(
    BuildContext context,
    int stepNumber,
    String title,
    IconData icon,
    List<Widget> children,
    Color? accentColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeAccentColor = accentColor ?? colorScheme.primary;
    if (children.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeAccentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: themeAccentColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    icon,
                    color: themeAccentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step $stepNumber',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: themeAccentColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: themeAccentColor,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: themeAccentColor.withOpacity(0.3)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                '$label:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAgreementStatus(String label, bool isAgreed) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAgreed
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.errorContainer.withOpacity(0.3),
          border: Border.all(
            color: isAgreed
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.error.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              isAgreed ? Icons.check_circle : Icons.error,
              color: isAgreed ? colorScheme.primary : colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAgreed
                    ? 'You have agreed to the $label'
                    : 'You must agree to the $label',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isAgreed
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getGenderDisplay(String gender) {
    switch (gender) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return 'Not specified';
    }
  }

  String _getRoleDisplay(dynamic userRole) {
    // Handle both int and String types
    final roleString = userRole.toString().toLowerCase();

    if (userRole is int) {
      switch (userRole) {
        case 1:
          return 'Lawyer';
        case 2:
          return 'Advocate';
        case 3:
          return 'Paralegal';
        case 4:
          return 'Law Student';
        case 5:
          return 'Law Firm';
        default:
          return 'Unknown Role';
      }
    }

    // Handle string values
    switch (roleString) {
      case 'lawyer':
        return 'Lawyer';
      case 'advocate':
        return 'Advocate';
      case 'paralegal':
        return 'Paralegal';
      case 'law_student':
        return 'Law Student';
      case 'law_firm':
        return 'Law Firm';
      case 'citizen':
        return 'Citizen';
      case 'lecturer':
        return 'Lecturer';
      default:
        return 'Unknown Role';
    }
  }

  String _getRoleDescription(dynamic userRole) {
    // Handle both int and String types
    final roleString = userRole.toString().toLowerCase();

    if (userRole is int) {
      switch (userRole) {
        case 1:
          return 'Legal practitioner providing legal services';
        case 2:
          return 'Licensed advocate registered with the Tanganyika Law Society';
        case 3:
          return 'Legal professional supporting lawyers and advocates';
        case 4:
          return 'Student pursuing legal education';
        case 5:
          return 'Law firm organization providing legal services';
        case 6:
          return 'General citizen accessing legal information';
        case 7:
          return 'Legal educator and academic';
        default:
          return 'Role description not available';
      }
    }

    // Handle string values
    switch (roleString) {
      case 'lawyer':
        return 'Legal practitioner providing legal services';
      case 'advocate':
        return 'Licensed advocate registered with the Tanganyika Law Society';
      case 'paralegal':
        return 'Legal professional supporting lawyers and advocates';
      case 'law_student':
        return 'Student pursuing legal education';
      case 'law_firm':
        return 'Law firm organization providing legal services';
      case 'citizen':
        return 'General citizen accessing legal information';
      case 'lecturer':
        return 'Legal educator and academic';
      default:
        return 'Role description not available';
    }
  }

  bool _shouldShowProfessionalInfo(dynamic userRole) {
    // Handle both int and String types
    if (userRole is int) {
      // Show professional info for all roles except citizen (role 6)
      return userRole != 6;
    }

    // Handle string values - show professional info for all roles except citizen
    final roleString = userRole.toString().toLowerCase();
    return roleString != 'citizen';
  }

  List<Widget> _buildProfessionalInfo(data) {
    List<Widget> info = [];

    // Handle both int and String types for userRole
    final roleValue = data.userRole;
    final roleString = roleValue.toString().toLowerCase();

    // Use pattern matching for both numeric and string values
    bool isLawyer = (roleValue == 1) || (roleString == 'lawyer');
    bool isAdvocate = (roleValue == 2) || (roleString == 'advocate');
    bool isParalegal = (roleValue == 3) || (roleString == 'paralegal');
    bool isLawStudent = (roleValue == 4) || (roleString == 'law_student');
    bool isLawFirm = (roleValue == 5) || (roleString == 'law_firm');
    bool isLecturer = (roleValue == 7) || (roleString == 'lecturer');

    if (isLawyer) {
      info.add(_buildInfoRow('Professional Type', 'Lawyer'));
      if (data.placeOfWork != null) {
        info.add(
            _buildInfoRow('Place of Work ID', data.placeOfWork.toString()));
      }
      if (data.yearsOfExperience != null) {
        info.add(_buildInfoRow(
            'Years of Experience', data.yearsOfExperience.toString()));
      }
      if (data.specializations?.isNotEmpty == true) {
        info.add(
            _buildInfoRow('Specializations', data.specializations!.join(', ')));
      }
    } else if (isAdvocate) {
      info.add(_buildInfoRow('Professional Type', 'Advocate'));
      if (data.rollNumber?.isNotEmpty == true) {
        info.add(_buildInfoRow('TLS Roll Number', data.rollNumber!));
      }
      if (data.regionalChapter != null) {
        info.add(_buildInfoRow(
            'Regional Chapter ID', data.regionalChapter.toString()));
      }
      if (data.yearOfAdmissionToBar != null) {
        info.add(_buildInfoRow(
            'Year of Admission', data.yearOfAdmissionToBar.toString()));
      }
      if (data.practiceStatus?.isNotEmpty == true) {
        info.add(_buildInfoRow('Practice Status', data.practiceStatus!));
      }
      if (data.specializations?.isNotEmpty == true) {
        info.add(
            _buildInfoRow('Specializations', data.specializations!.join(', ')));
      }
    } else if (isParalegal) {
      info.add(_buildInfoRow('Professional Type', 'Paralegal'));
      if (data.placeOfWork != null) {
        info.add(
            _buildInfoRow('Place of Work ID', data.placeOfWork.toString()));
      }
      if (data.yearsOfExperience != null) {
        info.add(_buildInfoRow(
            'Years of Experience', data.yearsOfExperience.toString()));
      }
    } else if (isLawStudent) {
      info.add(_buildInfoRow('Professional Type', 'Law Student'));
      if (data.institution?.isNotEmpty == true) {
        info.add(_buildInfoRow('Institution', data.institution!));
      }
      if (data.currentYearOfStudy?.isNotEmpty == true) {
        info.add(_buildInfoRow('Current Year', data.currentYearOfStudy!));
      }
      if (data.expectedGraduationYear?.isNotEmpty == true) {
        info.add(
            _buildInfoRow('Expected Graduation', data.expectedGraduationYear!));
      }
    } else if (isLawFirm) {
      info.add(_buildInfoRow('Organization Type', 'Law Firm'));
      if (data.firmName?.isNotEmpty == true) {
        info.add(_buildInfoRow('Firm Name', data.firmName!));
      }
      if (data.managingPartner != null) {
        info.add(_buildInfoRow(
            'Managing Partner ID', data.managingPartner.toString()));
      }
      if (data.numberOfLawyers != null) {
        info.add(_buildInfoRow(
            'Number of Lawyers', data.numberOfLawyers.toString()));
      }
      if (data.yearEstablished != null) {
        info.add(
            _buildInfoRow('Year Established', data.yearEstablished.toString()));
      }
      if (data.website?.isNotEmpty == true) {
        info.add(_buildInfoRow('Website', data.website!));
      }
    } else if (isLecturer) {
      info.add(_buildInfoRow('Professional Type', 'Lecturer'));
      if (data.institution?.isNotEmpty == true) {
        info.add(_buildInfoRow('Institution', data.institution!));
      }
      if (data.qualification?.isNotEmpty == true) {
        info.add(_buildInfoRow('Qualification', data.qualification!));
      }
      if (data.areaOfLaw?.isNotEmpty == true) {
        info.add(_buildInfoRow('Area of Law', data.areaOfLaw!));
      }
      if (data.employerInstitution?.isNotEmpty == true) {
        info.add(
            _buildInfoRow('Employer Institution', data.employerInstitution!));
      }
    }

    // If no professional information was added, show a placeholder
    if (info.isEmpty) {
      info.add(_buildInfoRow('Professional Type', 'Not specified'));
    }

    return info;
  }
}
