import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/consultation_service.dart';
import '../../../utils/navigation_helper.dart';

class ConsultantApplicationDialog extends StatefulWidget {
  final String consultantType;
  final bool canOfferPhysical;

  const ConsultantApplicationDialog({
    super.key,
    required this.consultantType,
    this.canOfferPhysical = false,
  });

  @override
  State<ConsultantApplicationDialog> createState() => _ConsultantApplicationDialogState();
}

class _ConsultantApplicationDialogState extends State<ConsultantApplicationDialog> {
  final ConsultationService _service = Get.find<ConsultationService>();
  bool _termsAccepted = false;
  bool _offersPhysical = false;
  String _preferredCity = '';
  bool _isLoading = false;

  String get _roleDisplay {
    switch (widget.consultantType.toLowerCase()) {
      case 'advocate': return 'Advocate';
      case 'lawyer': return 'Lawyer';
      case 'paralegal': return 'Paralegal';
      case 'law_firm': return 'Law Firm';
      default: return widget.consultantType;
    }
  }

  Future<void> _submit() async {
    if (!_termsAccepted) {
      NavigationHelper.showSafeSnackbar(
        title: 'Terms Required',
        message: 'Please accept the terms and conditions to continue.',
      );
      return;
    }

    if (_offersPhysical && _preferredCity.trim().isEmpty) {
      NavigationHelper.showSafeSnackbar(
        title: 'City Required',
        message: 'Please enter your preferred city for physical consultations.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _service.submitApplication(
      consultantType: widget.consultantType,
      termsAccepted: _termsAccepted,
      offersPhysicalConsultations: widget.canOfferPhysical ? _offersPhysical : null,
      preferredConsultationCity: (widget.canOfferPhysical && _offersPhysical) ? _preferredCity : null,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      Get.back(result: true);
      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: result.message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      NavigationHelper.showSafeSnackbar(
        title: 'Application Failed',
        message: result.message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text('Apply as $_roleDisplay'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By applying to become a consultant, you will be able to offer legal consultations to Pola users.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            if (widget.canOfferPhysical) ...[
              SwitchListTile(
                title: const Text('Offer Physical Consultations'),
                subtitle: const Text('Allow users to book in-person meetings'),
                value: _offersPhysical,
                onChanged: (val) => setState(() => _offersPhysical = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_offersPhysical) ...[
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Preferred City',
                    hintText: 'e.g., Dar es Salaam',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _preferredCity = val,
                ),
              ],
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                    child: const Text('I agree to the Terms and Conditions for consultants.'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Submit Application'),
        ),
      ],
    );
  }
}
