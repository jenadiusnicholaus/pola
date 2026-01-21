import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../calling_booking/models/consultant_models.dart' as calling;
import '../services/consultation_service.dart';

/// Physical Consultation Booking Screen
/// Note: Only Law Firms can be booked for physical consultations
/// Individual advocates, lawyers, and paralegals use the Call system instead
class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final ConsultationService _service = Get.find<ConsultationService>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late final calling.Consultant consultant;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;
  String _paymentMethod = 'mobile_money';
  bool _isSubmitting = false;
  bool _isLawFirm = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments?['consultant'];

    if (arg is calling.Consultant) {
      consultant = arg;
      _isLawFirm = consultant.consultantType.toLowerCase() == 'law_firm';
      
      // Pre-fill location if available
      if (consultant.city != null && consultant.city!.isNotEmpty) {
        _locationController.text = consultant.city!;
      }
    } else {
      // Defensive fallback
      consultant = calling.Consultant(
        id: 0,
        userDetails: calling.UserDetails(
            id: 0, email: '', firstName: '', lastName: '', fullName: 'Unknown'),
        consultantType: '',
        specialization: '',
        yearsOfExperience: 0,
        offersMobileConsultations: true,
        offersPhysicalConsultations: false,
        isAvailable: true,
        totalConsultations: 0,
        totalEarnings: '0',
        averageRating: 0.0,
        totalReviews: 0,
        pricing: calling.ConsultantPricing(
            mobile: calling.PricingDetails(
                price: '0', consultantShare: '0', platformShare: '0')),
      );
      _isLawFirm = false;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  String get _formattedTime {
    if (_selectedTime == null) return '';
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      Get.snackbar('Date Required', 'Please select a date for the consultation');
      return;
    }

    if (_selectedTime == null) {
      Get.snackbar('Time Required', 'Please select a time for the consultation');
      return;
    }

    if (!_isLawFirm) {
      Get.snackbar(
        'Booking Not Available', 
        'Only Law Firms can be booked for physical consultations. Use Call Credits to contact individual professionals.',
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.createBooking(
      consultantProfileId: consultant.id,
      topic: _topicController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledDate: _selectedDate!,
      scheduledTime: _formattedTime,
      location: _locationController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      durationMinutes: _durationMinutes,
      paymentMethod: _paymentMethod,
    );

    setState(() => _isSubmitting = false);

    if (result != null) {
      Get.snackbar(
        'Booking Created', 
        'Your consultation request was submitted. Complete payment on your phone.',
        duration: const Duration(seconds: 4),
      );
      Get.back(result: result);
    } else {
      Get.snackbar(
        'Booking Failed', 
        'Unable to create booking. Please try again later.',
      );
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final price = consultant.pricing.physical?.price ?? '150000';

    // Show warning if not a law firm
    if (!_isLawFirm) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Consultation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Physical Booking Not Available',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Only Law Firms can be booked for physical consultations.\n\n'
                  'To consult with individual advocates, lawyers, or paralegals, '
                  'please use Call Credits for mobile consultations.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Book Physical Consultation')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Law Firm Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        Icons.business,
                        color: colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultant.userDetails.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LAW FIRM',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (consultant.specialization.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              consultant.specialization,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (consultant.city != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  consultant.city!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Topic Field (Required)
              Text('Topic *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Land Ownership Dispute',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic for your consultation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field (Required)
              Text('Description *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your legal matter in detail...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description of your legal matter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Date & Time Selection
              Text('Schedule *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration Selection
              Text('Duration', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                  DropdownMenuItem(value: 120, child: Text('2 hours')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _durationMinutes = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Location Field (Required)
              Text('Meeting Location *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Law Firm Office, Plot 123, Masaki',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the meeting location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Payment Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Details',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone Number for Payment
                    Text('Payment Phone Number *', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+255712345678',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                        helperText: 'M-Pesa, Tigo Pesa, or Airtel Money',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required for payment';
                        }
                        if (!value.startsWith('+255') && !value.startsWith('0')) {
                          return 'Please enter a valid Tanzanian phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    Text('Payment Method', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'mobile_money',
                          child: Text('Mobile Money'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Credit/Debit Card'),
                        ),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Consultation Fee',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'TZS $price',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive a payment prompt on your phone. Complete the payment to confirm your booking.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Book & Pay'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
