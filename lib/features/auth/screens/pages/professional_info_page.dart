import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';
import '../../models/lookup_models.dart';

class ProfessionalInfoPage extends StatefulWidget {
  const ProfessionalInfoPage({super.key});

  @override
  State<ProfessionalInfoPage> createState() => _ProfessionalInfoPageState();
}

class _ProfessionalInfoPageState extends State<ProfessionalInfoPage> {
  final controller = Get.find<RegistrationController>();

  // Controllers for text fields
  final _rollNumberController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _institutionController = TextEditingController();
  final _currentYearController = TextEditingController();
  final _graduationYearController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _employerController = TextEditingController();
  final _areaOfLawController = TextEditingController();

  // Dropdowns
  int? _selectedChapter;
  int? _selectedWorkplace;
  int? _selectedYearOfAdmission;
  int? _selectedYearsOfExperience;
  int? _selectedNumberOfLawyers;
  int? _selectedYearEstablished;
  int? _selectedManagingPartner;
  String? _selectedPracticeStatus;
  List<int> _selectedSpecializations = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadLookupData();
  }

  void _loadExistingData() {
    final data = controller.registrationData;
    _rollNumberController.text = data.rollNumber ?? '';
    _firmNameController.text = data.firmName ?? '';
    _selectedManagingPartner = data.managingPartner;
    _websiteController.text = data.website ?? '';
    _institutionController.text = data.institution ?? '';
    _currentYearController.text = data.currentYearOfStudy ?? '';
    _graduationYearController.text = data.expectedGraduationYear ?? '';
    _qualificationController.text = data.qualification ?? '';
    _employerController.text = data.employerInstitution ?? '';
    _areaOfLawController.text = data.areaOfLaw ?? '';

    _selectedChapter = data.regionalChapter;
    _selectedWorkplace = data.placeOfWork;
    _selectedYearOfAdmission = data.yearOfAdmissionToBar;
    _selectedYearsOfExperience = data.yearsOfExperience;
    _selectedNumberOfLawyers = data.numberOfLawyers;
    _selectedYearEstablished = data.yearEstablished;
    _selectedPracticeStatus = data.practiceStatus;
    _selectedSpecializations = data.specializations ?? [];
  }

  void _loadLookupData() async {
    try {
      await controller.lookupService.fetchSpecializations();
      await controller.lookupService.fetchWorkplaces();
      await controller.lookupService.fetchChapters();
      // Load advocates for law firm managing partner selection
      if (controller.registrationData.userRole == 5) {
        await controller.lookupService.fetchAdvocates();
      }
    } catch (e) {
      print('Error loading lookup data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dropdown options. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadLookupData,
            ),
          ),
        );
      }
    }
  }

  void _saveData() {
    final data = controller.registrationData;
    data.rollNumber =
        _rollNumberController.text.isEmpty ? null : _rollNumberController.text;
    data.firmName =
        _firmNameController.text.isEmpty ? null : _firmNameController.text;
    data.managingPartner = _selectedManagingPartner;
    data.website =
        _websiteController.text.isEmpty ? null : _websiteController.text;
    data.institution = _institutionController.text.isEmpty
        ? null
        : _institutionController.text;
    data.currentYearOfStudy = _currentYearController.text.isEmpty
        ? null
        : _currentYearController.text;
    data.expectedGraduationYear = _graduationYearController.text.isEmpty
        ? null
        : _graduationYearController.text;
    data.qualification = _qualificationController.text.isEmpty
        ? null
        : _qualificationController.text;
    data.employerInstitution =
        _employerController.text.isEmpty ? null : _employerController.text;
    data.areaOfLaw =
        _areaOfLawController.text.isEmpty ? null : _areaOfLawController.text;

    data.regionalChapter = _selectedChapter;
    data.placeOfWork = _selectedWorkplace;
    data.yearOfAdmissionToBar = _selectedYearOfAdmission;
    data.yearsOfExperience = _selectedYearsOfExperience;
    data.numberOfLawyers = _selectedNumberOfLawyers;
    data.yearEstablished = _selectedYearEstablished;
    data.practiceStatus = _selectedPracticeStatus;
    data.specializations =
        _selectedSpecializations.isNotEmpty ? _selectedSpecializations : null;

    controller.updateRegistrationData(data);
  }

  @override
  Widget build(BuildContext context) {
    final userRole = controller.registrationData.userRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: controller.professionalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getPageTitle(userRole),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Build different forms based on user role
            if (userRole == 2) ..._buildAdvocateFields(),
            if (userRole == 1 || userRole == 3)
              ..._buildLawyerParalegalFields(),
            if (userRole == 5) ..._buildLawFirmFields(),
            if (userRole == 4) ..._buildLawStudentFields(),
            if (userRole == 7) ..._buildLecturerFields(),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(int userRole) {
    switch (userRole) {
      case 1:
        return 'Lawyer Information';
      case 2:
        return 'Advocate Information';
      case 3:
        return 'Paralegal Information';
      case 4:
        return 'Law Student Information';
      case 5:
        return 'Law Firm Information';
      case 7:
        return 'Lecturer Information';
      default:
        return 'Professional Information';
    }
  }

  List<Widget> _buildAdvocateFields() {
    return [
      // TLS Roll Number
      TextFormField(
        controller: _rollNumberController,
        decoration: const InputDecoration(
          labelText: 'TLS Roll Number *',
          border: OutlineInputBorder(),
          helperText: 'e.g., TLS/2015/123456',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'TLS Roll Number is required for advocates';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      // Regional Chapter
      Obx(() {
        final chapters = controller.lookupService.chapters;
        final isLoadingChapters = controller.lookupService.isLoadingChapters;

        return DropdownButtonFormField<int>(
          value: _selectedChapter,
          decoration: InputDecoration(
            labelText: 'Regional Chapter *',
            border: const OutlineInputBorder(),
            helperText: isLoadingChapters
                ? 'Loading chapters...'
                : chapters.isEmpty
                    ? 'No chapters available'
                    : 'Select your TLS regional chapter',
            suffixIcon: isLoadingChapters
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (value) =>
              value == null ? 'Regional chapter is required' : null,
          items: chapters.isEmpty
              ? []
              : chapters.map((Chapter chapter) {
                  return DropdownMenuItem<int>(
                    value: chapter.id,
                    child: Text(
                      chapter.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: isLoadingChapters
              ? null
              : (value) {
                  setState(() {
                    _selectedChapter = value;
                  });
                  _saveData();
                },
        );
      }),
      const SizedBox(height: 16),

      // Year of Admission to Bar
      DropdownButtonFormField<int>(
        value: _selectedYearOfAdmission,
        decoration: const InputDecoration(
          labelText: 'Year of Admission to Bar *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Year of admission is required' : null,
        items: List.generate(50, (index) => DateTime.now().year - index)
            .map((year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedYearOfAdmission = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      // Practice Status
      DropdownButtonFormField<String>(
        value: _selectedPracticeStatus,
        decoration: const InputDecoration(
          labelText: 'Practice Status *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Practice status is required' : null,
        items: const [
          DropdownMenuItem(value: 'practising', child: Text('Practising')),
          DropdownMenuItem(
              value: 'non_practising', child: Text('Non-Practising')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedPracticeStatus = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      ..._buildCommonProfessionalFields(),
    ];
  }

  List<Widget> _buildLawyerParalegalFields() {
    return [
      // Place of Work
      Obx(() {
        final workplaces = controller.lookupService.workplaces;
        final isLoadingWorkplaces =
            controller.lookupService.isLoadingWorkplaces;

        return DropdownButtonFormField<int>(
          value: _selectedWorkplace,
          decoration: InputDecoration(
            labelText: 'Place of Work *',
            border: const OutlineInputBorder(),
            helperText: isLoadingWorkplaces
                ? 'Loading workplaces...'
                : workplaces.isEmpty
                    ? 'No workplaces available'
                    : 'Select your place of work',
            suffixIcon: isLoadingWorkplaces
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (value) =>
              value == null ? 'Place of work is required' : null,
          items: workplaces.isEmpty
              ? []
              : workplaces.map((Workplace workplace) {
                  return DropdownMenuItem<int>(
                    value: workplace.id,
                    child: Text(
                      workplace.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: isLoadingWorkplaces
              ? null
              : (value) {
                  setState(() {
                    _selectedWorkplace = value;
                  });
                  _saveData();
                },
        );
      }),
      const SizedBox(height: 16),

      // Years of Experience
      DropdownButtonFormField<int>(
        value: _selectedYearsOfExperience,
        decoration: const InputDecoration(
          labelText: 'Years of Experience *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Years of experience is required' : null,
        items: List.generate(41, (index) => index)
            .map((years) => DropdownMenuItem<int>(
                  value: years,
                  child: Text(years == 0
                      ? 'Less than 1 year'
                      : '$years ${years == 1 ? 'year' : 'years'}'),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedYearsOfExperience = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      ..._buildCommonProfessionalFields(),
    ];
  }

  List<Widget> _buildLawFirmFields() {
    return [
      // Firm Name
      TextFormField(
        controller: _firmNameController,
        decoration: const InputDecoration(
          labelText: 'Firm Name *',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Firm name is required';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      // Managing Partner - Dropdown from Advocates API
      Obx(() {
        final advocates = controller.lookupService.advocates;
        final isLoadingAdvocates = controller.lookupService.isLoadingAdvocates;

        return DropdownButtonFormField<int>(
          value: _selectedManagingPartner,
          decoration: InputDecoration(
            labelText: 'Managing Partner *',
            border: const OutlineInputBorder(),
            helperText: isLoadingAdvocates
                ? 'Loading advocates...'
                : advocates.isEmpty
                    ? 'No advocates available'
                    : 'Select the managing partner advocate',
            suffixIcon: isLoadingAdvocates
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (value) =>
              value == null ? 'Managing partner is required' : null,
          items: advocates.isEmpty
              ? []
              : advocates.map((Advocate advocate) {
                  return DropdownMenuItem<int>(
                    value: advocate.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          advocate.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Roll No: ${advocate.rollNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          onChanged: isLoadingAdvocates
              ? null
              : (value) {
                  setState(() {
                    _selectedManagingPartner = value;
                  });
                  _saveData();
                },
        );
      }),
      const SizedBox(height: 16),

      // Number of Lawyers
      DropdownButtonFormField<int>(
        value: _selectedNumberOfLawyers,
        decoration: const InputDecoration(
          labelText: 'Number of Lawyers *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Number of lawyers is required' : null,
        items: [
          ...List.generate(20, (index) => index + 1)
              .map((num) => DropdownMenuItem<int>(
                    value: num,
                    child: Text(num.toString()),
                  )),
          const DropdownMenuItem<int>(value: 50, child: Text('20+')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedNumberOfLawyers = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      // Year Established
      DropdownButtonFormField<int>(
        value: _selectedYearEstablished,
        decoration: const InputDecoration(
          labelText: 'Year Established *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Year established is required' : null,
        items: List.generate(75, (index) => DateTime.now().year - index)
            .map((year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedYearEstablished = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      // Practice Status
      DropdownButtonFormField<String>(
        value: _selectedPracticeStatus,
        decoration: const InputDecoration(
          labelText: 'Practice Status *',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null ? 'Practice status is required' : null,
        items: const [
          DropdownMenuItem(value: 'practising', child: Text('Practising')),
          DropdownMenuItem(
              value: 'non_practising', child: Text('Non-Practising')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedPracticeStatus = value;
          });
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      // Website
      TextFormField(
        controller: _websiteController,
        decoration: const InputDecoration(
          labelText: 'Website (Optional)',
          border: OutlineInputBorder(),
          helperText: 'e.g., https://www.yourfirm.com',
        ),
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      ..._buildCommonProfessionalFields(),
    ];
  }

  List<Widget> _buildLawStudentFields() {
    return [
      // Institution
      TextFormField(
        controller: _institutionController,
        decoration: const InputDecoration(
          labelText: 'Institution *',
          border: OutlineInputBorder(),
          helperText: 'Name of your law school/university',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Institution is required';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      // Current Year of Study
      DropdownButtonFormField<String>(
        value: _currentYearController.text.isEmpty
            ? null
            : _currentYearController.text,
        decoration: const InputDecoration(
          labelText: 'Current Year of Study *',
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? 'Current year is required' : null,
        items: const [
          DropdownMenuItem(value: '1', child: Text('Year 1')),
          DropdownMenuItem(value: '2', child: Text('Year 2')),
          DropdownMenuItem(value: '3', child: Text('Year 3')),
          DropdownMenuItem(value: '4', child: Text('Year 4')),
          DropdownMenuItem(value: '5', child: Text('Year 5')),
          DropdownMenuItem(value: 'Graduate', child: Text('Graduate Student')),
        ],
        onChanged: (value) {
          _currentYearController.text = value ?? '';
          _saveData();
        },
      ),
      const SizedBox(height: 16),

      // Expected Graduation Year
      DropdownButtonFormField<String>(
        value: _graduationYearController.text.isEmpty
            ? null
            : _graduationYearController.text,
        decoration: const InputDecoration(
          labelText: 'Expected Graduation Year *',
          border: OutlineInputBorder(),
        ),
        items: List.generate(10, (index) => DateTime.now().year + index)
            .map((year) => DropdownMenuItem<String>(
                  value: year.toString(),
                  child: Text(year.toString()),
                ))
            .toList(),
        onChanged: (value) {
          _graduationYearController.text = value ?? '';
          _saveData();
        },
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildLecturerFields() {
    return [
      // Employer Institution
      TextFormField(
        controller: _employerController,
        decoration: const InputDecoration(
          labelText: 'Institution *',
          border: OutlineInputBorder(),
          helperText: 'Name of your employing institution',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Institution is required';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      // Qualification
      TextFormField(
        controller: _qualificationController,
        decoration: const InputDecoration(
          labelText: 'Qualification *',
          border: OutlineInputBorder(),
          helperText: 'e.g., PhD in Law, LLM, etc.',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Qualification is required';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),

      // Area of Law
      TextFormField(
        controller: _areaOfLawController,
        decoration: const InputDecoration(
          labelText: 'Area of Law *',
          border: OutlineInputBorder(),
          helperText: 'Your area of specialization',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Area of law is required';
          }
          return null;
        },
        onChanged: (value) => _saveData(),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildCommonProfessionalFields() {
    return [
      // Specializations
      Text(
        'Specializations (Optional)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Obx(() {
        final specializations = controller.lookupService.specializations;
        final isLoadingSpecs =
            controller.lookupService.isLoadingSpecializations;

        if (isLoadingSpecs) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (specializations.isEmpty) {
          return const Text('No specializations available');
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specializations.map((specialization) {
            final isSelected =
                _selectedSpecializations.contains(specialization.id);
            return FilterChip(
              label: Text(specialization.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecializations.add(specialization.id);
                  } else {
                    _selectedSpecializations.remove(specialization.id);
                  }
                });
                _saveData();
              },
            );
          }).toList(),
        );
      }),
    ];
  }

  @override
  void dispose() {
    _rollNumberController.dispose();
    _firmNameController.dispose();
    _websiteController.dispose();
    _institutionController.dispose();
    _currentYearController.dispose();
    _graduationYearController.dispose();
    _qualificationController.dispose();
    _employerController.dispose();
    _areaOfLawController.dispose();
    super.dispose();
  }
}
