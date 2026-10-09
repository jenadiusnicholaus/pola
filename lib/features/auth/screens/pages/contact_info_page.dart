import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';
import '../../models/lookup_models.dart';
import '../../../../shared/widgets/intl_phone_input.dart';

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
  final _occupationController = TextEditingController();

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
    _occupationController.text = data.occupation ?? '';
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
              label: tr('Retry'),
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
    data.occupation = _occupationController.text;
    data.region = _selectedRegion;
    data.district = _selectedDistrict;
    controller.updateRegistrationData(data);
  }

  String _initialNational() {
    var digits =
        controller.registrationData.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final isCitizen = controller.registrationData.userRole == 'citizen';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: controller.contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCitizen
                  ? 'Mawasiliano | Contact Information'
                  : 'Contact Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Phone Number (international, defaults to Tanzania)
            IntlPhoneInput(
              initialValue: _initialNational(),
              labelText:
                  isCitizen ? 'Nambari ya Simu | Phone Number' : 'Phone Number',
              helperText: isCitizen
                  ? 'Nambari yako | Your number'
                  : 'Enter your mobile number',
              invalidNumberMessage: isCitizen
                  ? 'Nambari si sahihi'
                  : 'Please enter a valid phone number',
              validator: (phone) {
                if (phone == null || phone.number.trim().isEmpty) {
                  return isCitizen
                      ? 'Nambari ya simu inahitajika'
                      : 'Phone number is required';
                }
                return null;
              },
              onChanged: (complete) {
                _phoneController.text = complete;
                _saveData();
              },
            ),
            const SizedBox(height: 16),

            // Region
            Text(
              isCitizen ? 'Mahali | Location' : 'Location Information',
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
                  labelText: isCitizen ? 'Mkoa | Region' : 'Region',
                  border: const OutlineInputBorder(),
                  helperText: isLoadingRegions
                      ? (isCitizen ? 'Inapakia...' : 'Loading regions...')
                      : regions.isEmpty
                          ? (isCitizen
                              ? 'Hakuna mikoa'
                              : 'No regions available')
                          : (isCitizen
                              ? 'Chagua mkoa | Select region'
                              : 'Select your region'),
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
                  labelText: isCitizen ? 'Wilaya | District' : 'District',
                  border: const OutlineInputBorder(),
                  helperText: _selectedRegion == null
                      ? (isCitizen
                          ? 'Chagua mkoa kwanza'
                          : 'Please select a region first')
                      : isLoadingDistricts
                          ? (isCitizen ? 'Inapakia...' : 'Loading districts...')
                          : _filteredDistricts.isEmpty
                              ? (isCitizen
                                  ? 'Hakuna wilaya'
                                  : 'No districts available')
                              : (isCitizen
                                  ? 'Chagua wilaya | Select district'
                                  : 'Select your district'),
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
            SizedBox(height: 16),

            // Ward
            TextFormField(
              controller: _wardController,
              decoration: InputDecoration(
                labelText: isCitizen
                    ? 'Kata (Hiari) | Ward (Optional)'
                    : 'Ward (Optional)',
                border: OutlineInputBorder(),
                helperText: isCitizen
                    ? 'Jina la kata/mtaa | Ward/street name'
                    : 'Enter your ward/street name',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) => _saveData(),
            ),
            SizedBox(height: 16),

            // Office Address (for professionals only - not for citizens or students)
            if (controller.registrationData.userRole != 'citizen' &&
                controller.registrationData.userRole != 'law_student')
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('Office Address'),
                  border: OutlineInputBorder(),
                  helperText: 'Enter your office or workplace address',
                ),
                onChanged: (value) => _saveData(),
              ),

            // Occupation field (for citizens only)
            if (controller.registrationData.userRole == 'citizen') ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _occupationController,
                decoration: InputDecoration(
                  labelText: 'Kazi | Occupation',
                  border: OutlineInputBorder(),
                  helperText: tr('Kazi yako | Your job'),
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                onChanged: (value) => _saveData(),
              ),
            ],
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
    _occupationController.dispose();
    super.dispose();
  }
}
