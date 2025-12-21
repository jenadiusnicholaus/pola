import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../calling_booking/models/consultant_models.dart' as calling;
import '../services/consultation_service.dart';

class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final ConsultationService _service = Get.find<ConsultationService>();
  late final calling.Consultant consultant;
  String bookingType = 'mobile';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments?['consultant'];
    final preSelectedType = Get.arguments?['bookingType'] as String?;

    if (arg is calling.Consultant) {
      consultant = arg;
      // Use pre-selected type if provided, otherwise default based on availability
      if (preSelectedType != null &&
          ((preSelectedType == 'mobile' &&
                  consultant.offersMobileConsultations) ||
              (preSelectedType == 'physical' &&
                  consultant.offersPhysicalConsultations))) {
        bookingType = preSelectedType;
      } else {
        bookingType =
            consultant.offersMobileConsultations ? 'mobile' : 'physical';
      }
    } else {
      // Defensive fallback - shouldn't happen
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
      initialTime: TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  DateTime? get _scheduledDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _submitBooking() async {
    if (_scheduledDateTime == null) {
      Get.snackbar(
          'Choose date/time', 'Please select a date and time for the booking');
      return;
    }

    setState(() => _isSubmitting = true);

    final priceStr = bookingType == 'mobile'
        ? (consultant.pricing.mobile?.price ?? '0')
        : (consultant.pricing.physical?.price ?? '0');
    final amount = double.tryParse(priceStr) ?? 0.0;

    final result = await _service.createBooking(
      consultantId: consultant.id,
      bookingType: bookingType,
      scheduledDate: _scheduledDateTime!,
      amount: amount > 0 ? amount : null,
    );

    setState(() => _isSubmitting = false);

    if (result != null) {
      Get.snackbar('Booking created', 'Your booking was created successfully');
      Get.back(result: result);
    } else {
      Get.snackbar(
          'Booking failed', 'Unable to create booking. Try again later');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = bookingType == 'mobile'
        ? (consultant.pricing.mobile?.price ?? '0')
        : (consultant.pricing.physical?.price ?? '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Book Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consultant.userDetails.fullName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(consultant.consultantType.toUpperCase()),
            const SizedBox(height: 16),

            // Only show type selection if both options are available AND no pre-selection
            if (consultant.offersMobileConsultations &&
                consultant.offersPhysicalConsultations &&
                Get.arguments?['bookingType'] == null) ...[
              Text('Select Type', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(children: [
                if (consultant.offersMobileConsultations)
                  ChoiceChip(
                    label: const Text('Mobile'),
                    selected: bookingType == 'mobile',
                    onSelected: (_) => setState(() => bookingType = 'mobile'),
                  ),
                const SizedBox(width: 8),
                if (consultant.offersPhysicalConsultations)
                  ChoiceChip(
                    label: const Text('Physical'),
                    selected: bookingType == 'physical',
                    onSelected: (_) => setState(() => bookingType = 'physical'),
                  ),
              ]),
              const SizedBox(height: 16),
            ],

            Text('Choose Date & Time', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate != null
                    ? _selectedDate!.toLocal().toString().split(' ')[0]
                    : 'Pick date'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(_selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Pick time'),
              ),
            ]),

            const SizedBox(height: 24),
            Text('Price: $price', style: theme.textTheme.titleMedium),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
