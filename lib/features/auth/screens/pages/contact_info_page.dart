import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';
import '../../models/lookup_models.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final controller = Get.find<RegistrationController>();

  final _phoneController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();

  int? _selectedRegion;
  int? _selectedDistrict;
  List<District> _filteredDistricts = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadRegions();
  }

  void _loadExistingData() {
    final data = controller.registrationData;
    _phoneController.text = data.phoneNumber;
    _wardController.text = data.ward ?? '';
    _addressController.text = data.officeAddress ?? '';
    _selectedRegion = data.region;
    _selectedDistrict = data.district;
    if (_selectedRegion != null) {
      _loadDistrictsForRegion(_selectedRegion!);
    }
  }

  void _loadRegions() async {
    await controller.lookupService.fetchRegions();
  }

  void _loadDistrictsForRegion(int regionId) async {
    try {
      final districts =
          await controller.lookupService.fetchDistricts(regionId: regionId);
      setState(() {
        _filteredDistricts = districts;
      });
    } catch (e) {
      print('Error loading districts for region $regionId: $e');
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load districts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadDistrictsForRegion(regionId),
            ),
          ),
        );
      }
      setState(() {
        _filteredDistricts = [];
      });
    }
  }

  void _saveData() {
    final data = controller.registrationData;
    data.phoneNumber = _phoneController.text;
    data.ward = _wardController.text;
    data.officeAddress = _addressController.text;
    data.region = _selectedRegion;
    data.district = _selectedDistrict;
    controller.updateRegistrationData(data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: controller.contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixText: '+255',
                helperText: 'Enter your mobile number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length < 9) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              onChanged: (value) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Region
            Text(
              'Location Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Obx(() {
              final regions = controller.lookupService.regions;
              final isLoadingRegions =
                  controller.lookupService.isLoadingRegions;

              return DropdownButtonFormField<int>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Region',
                  border: const OutlineInputBorder(),
                  helperText: isLoadingRegions
                      ? 'Loading regions...'
                      : regions.isEmpty
                          ? 'No regions available'
                          : 'Select your region',
                  suffixIcon: isLoadingRegions
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
                items: regions.map((Region region) {
                  return DropdownMenuItem<int>(
                    value: region.id,
                    child: Text(
                      region.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: isLoadingRegions
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRegion = value;
                          _selectedDistrict = null;
                          _filteredDistricts = [];
                        });
                        if (value != null) {
                          _loadDistrictsForRegion(value);
                        }
                        _saveData();
                      },
              );
            }),
            const SizedBox(height: 16),

            // District
            Obx(() {
              final isLoadingDistricts =
                  controller.lookupService.isLoadingDistricts;

              return DropdownButtonFormField<int>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: 'District',
                  border: const OutlineInputBorder(),
                  helperText: _selectedRegion == null
                      ? 'Please select a region first'
                      : isLoadingDistricts
                          ? 'Loading districts...'
                          : _filteredDistricts.isEmpty
                              ? 'No districts available'
                              : 'Select your district',
                  suffixIcon: isLoadingDistricts
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
                items: _filteredDistricts.map((District district) {
                  return DropdownMenuItem<int>(
                    value: district.id,
                    child: Text(
                      district.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (_selectedRegion == null || isLoadingDistricts)
                    ? null
                    : (value) {
                        setState(() {
                          _selectedDistrict = value;
                        });
                        _saveData();
                      },
              );
            }),
            const SizedBox(height: 16),

            // Ward
            TextFormField(
              controller: _wardController,
              decoration: const InputDecoration(
                labelText: 'Ward (Optional)',
                border: OutlineInputBorder(),
                helperText: 'Enter your ward/street name',
              ),
              onChanged: (value) => _saveData(),
            ),
            const SizedBox(height: 16),

            // Office Address (for professionals only - not for citizens or students)
            if (controller.registrationData.userRole != 'citizen' &&
                controller.registrationData.userRole != 'law_student')
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Office Address',
                  border: OutlineInputBorder(),
                  helperText: 'Enter your office or workplace address',
                ),
                onChanged: (value) => _saveData(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
