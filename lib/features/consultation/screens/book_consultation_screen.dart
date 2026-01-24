import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../calling_booking/models/consultant_models.dart' as calling;
import '../services/consultation_service.dart';

/// Physical Consultation Booking Screen
/// Flow: Create Booking → Initiate Payment → Wait for Confirmation
/// Note: Only Law Firms can be booked for physical consultations
class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final ConsultationService _service = Get.find<ConsultationService>();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final calling.Consultant consultant;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;
  bool _isLawFirm = false;

  // Booking flow state
  _BookingStep _currentStep = _BookingStep.details;
  bool _isLoading = false;
  String? _errorMessage;
  PhysicalBookingResponse? _bookingResponse;
  
  // Payment provider selection
  String _selectedProvider = 'Mpesa';

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments?['consultant'];

    if (arg is calling.Consultant) {
      consultant = arg;
      _isLawFirm = consultant.consultantType.toLowerCase() == 'law_firm';

      // Debug logging
      debugPrint('📋 Book Consultation Screen:');
      debugPrint('   Consultant ID: ${consultant.id}');
      debugPrint('   User ID: ${consultant.userDetails.id}');
      debugPrint('   Name: ${consultant.userDetails.fullName}');
      debugPrint('   Offers Physical: ${consultant.offersPhysicalConsultations}');
      debugPrint('   Type: ${consultant.consultantType}');

      // Pre-fill location
      if (consultant.city != null && consultant.city!.isNotEmpty) {
        _locationController.text = consultant.city!;
      }
    } else {
      consultant = _createFallbackConsultant();
      _isLawFirm = false;
    }
  }

  calling.Consultant _createFallbackConsultant() {
    return calling.Consultant(
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
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

  DateTime _getScheduledDateTime() {
    final date = _selectedDate ?? DateTime.now().add(const Duration(days: 1));
    final time = _selectedTime ?? const TimeOfDay(hour: 10, minute: 0);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '255${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('255')) {
      cleaned = '255$cleaned';
    }
    return cleaned;
  }

  /// Step 1: Create the booking
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _errorMessage = 'Please select date and time');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: TEMPORARY WORKAROUND - Backend nearby lawyers API returns wrong IDs
      // Remove this hardcoded ID once backend fixes the data
      final validConsultantId = 3; // Using a known valid profile ID for testing
      debugPrint('⚠️ TEMP: Using hardcoded consultant_id: $validConsultantId instead of ${consultant.id}');
      
      final response = await _service.createPhysicalBooking(
        consultantId: validConsultantId, // TEMP: was consultant.id
        scheduledDate: _getScheduledDateTime(),
        durationMinutes: _durationMinutes,
        meetingLocation: _locationController.text.trim(),
        clientNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (response != null && response.success) {
        setState(() {
          _bookingResponse = response;
          _currentStep = _BookingStep.payment;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Failed to create booking';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Step 2: Initiate payment
  Future<void> _initiatePayment() async {
    if (_bookingResponse == null) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentResult = await _service.initiateBookingPayment(
        bookingId: _bookingResponse!.booking!.id,
        phoneNumber: _formatPhoneNumber(phone),
        provider: _selectedProvider,
      );

      if (paymentResult != null && paymentResult['success'] == true) {
        setState(() {
          _currentStep = _BookingStep.processing;
          _isLoading = false;
        });

        // Start polling for confirmation
        _pollForConfirmation();
      } else {
        setState(() {
          _errorMessage = paymentResult?['error'] ?? 'Payment initiation failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment error: $e';
        _isLoading = false;
      });
    }
  }

  /// Poll for payment confirmation
  Future<void> _pollForConfirmation() async {
    if (_bookingResponse == null) return;

    for (int i = 0; i < 60; i++) {
      // Poll for 5 minutes (60 x 5s)
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      try {
        final status =
            await _service.checkBookingStatus(_bookingResponse!.booking!.id);

        if (status == 'confirmed') {
          setState(() => _currentStep = _BookingStep.success);
          return;
        } else if (status == 'cancelled' || status == 'failed') {
          setState(() {
            _errorMessage = 'Payment was not completed';
            _currentStep = _BookingStep.payment;
          });
          return;
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    }

    // Timeout
    if (mounted) {
      setState(() {
        _errorMessage = 'Payment timeout. Check My Bookings for status.';
        _currentStep = _BookingStep.payment;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if law firm
    if (!_isLawFirm) {
      return _buildNotAvailableScreen(theme);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildCurrentStep(theme),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case _BookingStep.details:
        return 'Book Consultation';
      case _BookingStep.payment:
        return 'Confirm & Pay';
      case _BookingStep.processing:
        return 'Processing Payment';
      case _BookingStep.success:
        return 'Booking Confirmed';
    }
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case _BookingStep.details:
        return _buildDetailsStep(theme);
      case _BookingStep.payment:
        return _buildPaymentStep(theme);
      case _BookingStep.processing:
        return _buildProcessingStep(theme);
      case _BookingStep.success:
        return _buildSuccessStep(theme);
    }
  }

  /// Step 1: Booking details form
  Widget _buildDetailsStep(ThemeData theme) {
    final price = consultant.pricing.physical?.price ?? '150000';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Law Firm Header Card
          _buildLawFirmCard(theme),
          const SizedBox(height: 24),

          // Schedule Section
          _buildSectionLabel('Schedule'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDateSelector(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeSelector(theme)),
            ],
          ),
          const SizedBox(height: 20),

          // Duration
          _buildSectionLabel('Duration'),
          const SizedBox(height: 12),
          _buildDurationSelector(theme),
          const SizedBox(height: 20),

          // Location
          _buildSectionLabel('Meeting Location'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hint: 'Enter meeting address',
            icon: Icons.location_on_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Location required' : null,
          ),
          const SizedBox(height: 20),

          // Notes (optional)
          _buildSectionLabel('Notes', isOptional: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _notesController,
            hint: 'Briefly describe your legal matter...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) _buildErrorMessage(theme),

          // Price Summary
          _buildPriceSummary(theme, price),
          const SizedBox(height: 16),

          // Continue Button
          _buildPrimaryButton(
            label: 'Continue',
            onPressed: _isLoading ? null : _createBooking,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Step 2: Payment form
  Widget _buildPaymentStep(ThemeData theme) {
    final amountStr = _bookingResponse?.paymentInfo?['amount']?.toString() ??
        _bookingResponse?.booking?.totalAmount ??
        '0';
    // Parse as double first (handles "30000.00"), then convert to int
    final amount = (double.tryParse(amountStr) ?? 0).toInt();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Booking Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Law Firm', consultant.userDetails.fullName),
              _buildDetailRow(
                'Date',
                _selectedDate != null
                    ? DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!)
                    : '-',
              ),
              _buildDetailRow(
                'Time',
                _selectedTime?.format(context) ?? '-',
              ),
              _buildDetailRow('Duration', '$_durationMinutes minutes'),
              _buildDetailRow('Location', _locationController.text),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'TZS ${NumberFormat('#,###').format(amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method - Provider Selection
        _buildSectionLabel('Select Payment Provider'),
        const SizedBox(height: 12),
        _buildProviderSelector(theme),
        const SizedBox(height: 20),

        // Phone Number
        _buildSectionLabel('Phone Number'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _phoneController,
          hint: '0712 345 678',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        Text(
          'You will receive a payment prompt on this number',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Error message
        if (_errorMessage != null) _buildErrorMessage(theme),

        // Pay Button
        _buildPrimaryButton(
          label: 'Pay TZS ${NumberFormat('#,###').format(amount)}',
          onPressed: _isLoading ? null : _initiatePayment,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),

        // Back button
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = _BookingStep.details),
            child: Text(
              'Back to details',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 3: Processing payment
  Widget _buildProcessingStep(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Waiting for Payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check your phone and enter your\nMobile Money PIN to confirm payment',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android, color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _phoneController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 4: Success
  Widget _buildSuccessStep(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your consultation has been scheduled with',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              consultant.userDetails.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null && _selectedTime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'at ${_selectedTime!.format(context)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(
                label: 'Done',
                onPressed: () => Get.back(result: true),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.toNamed('/my-bookings'),
              child: Text(
                'View My Bookings',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAvailableScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Book Consultation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Not Available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Physical consultations are only available for Law Firms.\n\nUse Call Credits to speak with individual lawyers.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPrimaryButton(
                label: 'Go Back',
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Helper Widgets ============

  Widget _buildLawFirmCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business, color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultant.userDetails.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Law Firm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, {bool isOptional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        if (isOptional)
          Text(
            ' (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? theme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: hasDate ? theme.primaryColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Text(
              hasDate ? DateFormat('d MMM').format(_selectedDate!) : 'Select date',
              style: TextStyle(
                fontSize: 14,
                color: hasDate ? Colors.black87 : Colors.grey.shade500,
                fontWeight: hasDate ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(ThemeData theme) {
    final hasTime = _selectedTime != null;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasTime ? theme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: hasTime ? theme.primaryColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Text(
              hasTime ? _selectedTime!.format(context) : 'Select time',
              style: TextStyle(
                fontSize: 14,
                color: hasTime ? Colors.black87 : Colors.grey.shade500,
                fontWeight: hasTime ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    // Duration options: 15min, 30min, 45min, 1hr, 1.5hr, 2hr, 2.5hr, 3hr
    final durations = [15, 30, 45, 60, 90, 120, 150, 180];
    
    String formatDuration(int mins) {
      if (mins < 60) return '$mins min';
      final hours = mins ~/ 60;
      final remaining = mins % 60;
      if (remaining == 0) return '$hours hr';
      return '$hours.${remaining == 30 ? '5' : remaining} hr';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: durations.map((mins) {
          final isSelected = _durationMinutes == mins;
          final label = formatDuration(mins);

          return Padding(
            padding: EdgeInsets.only(right: mins != durations.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _durationMinutes = mins),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProviderSelector(ThemeData theme) {
    final providers = [
      {'id': 'Mpesa', 'name': 'M-Pesa'},
      {'id': 'Tigo', 'name': 'Tigo Pesa'},
      {'id': 'Airtel', 'name': 'Airtel Money'},
      {'id': 'Halopesa', 'name': 'Halotel'},
      {'id': 'Azampesa', 'name': 'Azam Pesa'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvider,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          items: providers.map((provider) {
            return DropdownMenuItem<String>(
              value: provider['id'] as String,
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(provider['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedProvider = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: Colors.grey.shade500)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildPriceSummary(ThemeData theme, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Consultation Fee',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'TZS ${NumberFormat('#,###').format(int.tryParse(price) ?? 0)}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BookingStep { details, payment, processing, success }
