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

  Widget _buildEnhancedHeader(BuildContext context, RegistrationController controller) {
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
                      color: Colors.grey[600],
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
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please carefully review all information below before submitting your registration.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
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

  Widget _buildComprehensiveReview(BuildContext context, dynamic data, RegistrationController controller) {
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
            _buildInfoRow('Role Description', _getRoleDescription(data.userRole)),
          ],
          Colors.purple,
        ),

        // Step 2: Basic Information Section
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
            _buildInfoRow('Phone Number', data.phoneNumber.isNotEmpty ? data.phoneNumber : 'Not provided'),
          ],
          Colors.blue,
        ),

        // Step 3: Contact & Location Information
        _buildStepSection(
          context,
          3,
          'Contact & Location Information',
          Icons.location_on_outlined,
          [
            if (data.region != null)
              _buildInfoRow('Region ID', data.region.toString()),
            if (data.district != null)
              _buildInfoRow('District ID', data.district.toString()),
            if (data.ward?.isNotEmpty == true)
              _buildInfoRow('Ward', data.ward!),
            if (data.officeAddress?.isNotEmpty == true)
              _buildInfoRow('Address', data.officeAddress!),
          ],
          Colors.green,
        ),

        // Step 4: Identity Information (if provided)
        if (data.idNumber?.isNotEmpty == true)
          _buildStepSection(
            context,
            4,
            'Identity Information',
            Icons.credit_card_outlined,
            [
              _buildInfoRow('ID Number', data.idNumber!),
            ],
            Colors.orange,
          ),

        // Step 5: Professional Information (if applicable)
        if (data.userRole != 6) // Not citizen
          _buildStepSection(
            context,
            data.userRole == 6 ? 4 : 5,
            'Professional Information',
            Icons.work_outline,
            _buildProfessionalInfo(data),
            Colors.teal,
          ),

        // Step 6: Terms and Conditions Agreement
        _buildStepSection(
          context,
          controller.totalPages - 1,
          'Terms & Conditions Agreement',
          Icons.assignment_outlined,
          [
            _buildAgreementStatus('Terms and Conditions', data.agreedToTerms),
          ],
          data.agreedToTerms ? Colors.green : Colors.red,
        ),

        const SizedBox(height: 24),

        // Validation Status
        GetBuilder<RegistrationController>(
          builder: (controller) {
            final errors = controller.registrationData.validateForRole();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errors.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(
                  color: errors.isEmpty ? Colors.green : Colors.red,
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
                        color: errors.isEmpty ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        errors.isEmpty
                            ? 'Ready to Submit'
                            : 'Please Fix Errors',
                        style: TextStyle(
                          color: errors.isEmpty ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                              Text('• ', style: TextStyle(color: Colors.red)),
                              Expanded(
                                child: Text(
                                  error,
                                  style: TextStyle(color: Colors.red[700]),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.send_outlined,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to Submit?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click the Submit button below to create your account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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
    Color accentColor,
  ) {
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
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: accentColor.withOpacity(0.3)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementStatus(String label, bool isAgreed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAgreed ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isAgreed ? Colors.green.shade300 : Colors.red.shade300,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isAgreed ? Icons.check_circle : Icons.error,
            color: isAgreed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAgreed
                  ? 'You have agreed to the $label'
                  : 'You must agree to the $label',
              style: TextStyle(
                color: isAgreed ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfessionalInfo(data) {
    List<Widget> info = [];

    // Common fields
    if (data.placeOfWork != null) {
      info.add(_buildInfoRow('Place of Work ID', data.placeOfWork.toString()));
    }
    if (data.yearsOfExperience != null) {
      info.add(_buildInfoRow(
          'Years of Experience', data.yearsOfExperience.toString()));
    }

    // Advocate specific
    if (data.userRole == 2) {
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
    }

    // Law Firm specific
    if (data.userRole == 5) {
      if (data.firmName?.isNotEmpty == true) {
        info.add(_buildInfoRow('Firm Name', data.firmName!));
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
    }

    // Academic fields
    if (data.userRole == 4 || data.userRole == 7) {
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
      if (data.qualification?.isNotEmpty == true) {
        info.add(_buildInfoRow('Qualification', data.qualification!));
      }
      if (data.areaOfLaw?.isNotEmpty == true) {
        info.add(_buildInfoRow('Area of Law', data.areaOfLaw!));
      }
    }

    // Specializations
    if (data.specializations?.isNotEmpty == true) {
      info.add(
          _buildInfoRow('Specializations', data.specializations!.join(', ')));
    }

    return info;
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

  String _getRoleDisplay(int roleId) {
    switch (roleId) {
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
      case 6:
        return 'Citizen';
      case 7:
        return 'Lecturer';
      default:
        return 'Unknown';
    }
  }

  String _getRoleDescription(int roleId) {
    switch (roleId) {
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
}