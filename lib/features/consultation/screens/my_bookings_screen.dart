import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/consultation_service.dart';

/// Screen for clients to view their consultation bookings and call history
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final ConsultationService _service = Get.find<ConsultationService>();

  late TabController _mainTabController;
  
  // Bookings state
  bool _isLoadingBookings = true;
  MyBookingsResponse? _bookings;
  String _selectedBookingStatus = 'all';
  
  // Calls state
  bool _isLoadingCalls = true;
  CallHistoryResponse? _callHistory;
  CallCreditsResponse? _callCredits;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(_onMainTabChanged);
    _loadBookings();
    _loadCallData();
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_onMainTabChanged);
    _mainTabController.dispose();
    super.dispose();
  }

  void _onMainTabChanged() {
    if (!_mainTabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoadingBookings = true);

    final status = _selectedBookingStatus == 'all' ? null : _selectedBookingStatus;
    final response = await _service.getMyBookings(status: status);

    setState(() {
      _bookings = response;
      _isLoadingBookings = false;
    });
  }

  Future<void> _loadCallData() async {
    setState(() => _isLoadingCalls = true);

    final historyFuture = _service.getMyCallHistory();
    final creditsFuture = _service.getMyCallCredits();

    final results = await Future.wait([historyFuture, creditsFuture]);

    setState(() {
      _callHistory = results[0] as CallHistoryResponse?;
      _callCredits = results[1] as CallCreditsResponse?;
      _isLoadingCalls = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today, size: 20),
              text: 'Bookings',
            ),
            Tab(
              icon: Icon(Icons.phone, size: 20),
              text: 'Call History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildBookingsTab(theme),
          _buildCallHistoryTab(theme),
        ],
      ),
    );
  }

  // ============ BOOKINGS TAB ============
  Widget _buildBookingsTab(ThemeData theme) {
    return Column(
      children: [
        // Status filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmed', 'confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        
        // Bookings list
        Expanded(
          child: _isLoadingBookings
              ? const Center(child: CircularProgressIndicator())
              : _bookings == null || _bookings!.results.isEmpty
                  ? _buildEmptyBookingsState()
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings!.results.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(theme, _bookings!.results[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedBookingStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedBookingStatus = status);
        _loadBookings();
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedBookingStatus == 'all'
                ? 'You haven\'t made any consultation bookings yet'
                : 'No ${_selectedBookingStatus} bookings',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/nearby-lawyers'),
            icon: const Icon(Icons.search),
            label: const Text('Find a Lawyer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(ThemeData theme, ClientBooking booking) {
    final statusColor = _getStatusColor(booking.status);
    final amount = (double.tryParse(booking.totalAmount) ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Consultant name + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        booking.consultantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.capitalizeFirst ?? booking.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    booking.scheduledDate != null
                        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(booking.scheduledDate!)
                        : 'Date not set',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Duration & Location
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.scheduledDurationMinutes} minutes',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (booking.meetingLocation != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.meetingLocation!,
                        style: TextStyle(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Divider
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'TZS ${NumberFormat('#,###').format(amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ CALL HISTORY TAB ============
  Widget _buildCallHistoryTab(ThemeData theme) {
    if (_isLoadingCalls) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadCallData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credits card
            if (_callCredits != null) _buildCreditsCard(theme),
            
            // Call history
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Calls',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_callHistory != null)
                    Text(
                      '${_callHistory!.totalMinutesUsed} min used',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            
            if (_callHistory == null || _callHistory!.calls.isEmpty)
              _buildEmptyCallsState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _callHistory!.calls.length,
                itemBuilder: (context, index) {
                  return _buildCallCard(theme, _callHistory!.calls[index]);
                },
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Call Credits',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
                onPressed: () => Get.toNamed('/buy-credits'),
                tooltip: 'Buy More Credits',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_callCredits!.totalMinutes}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'minutes',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (_callCredits!.activeCredits.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black26),
            const SizedBox(height: 8),
            ...(_callCredits!.activeCredits.take(2).map((credit) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      credit.bundleName,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      '${credit.remainingMinutes} min${credit.expiresAt != null ? ' • Exp: ${DateFormat('d MMM').format(credit.expiresAt!)}' : ''}',
                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ],
                ),
              );
            })),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCallsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.phone_missed, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No call history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your call history will appear here',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/consultants'),
              icon: const Icon(Icons.phone),
              label: const Text('Call a Lawyer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallCard(ThemeData theme, ClientCallRecord call) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Call icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green, size: 22),
            ),
            const SizedBox(width: 12),
            
            // Call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.consultantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    call.startTime != null
                        ? DateFormat('d MMM yyyy • h:mm a').format(call.startTime!)
                        : call.date,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${call.durationMinutes} min',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
                if (call.callQualityRating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < call.callQualityRating! ? Icons.star : Icons.star_border,
                        size: 12,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ HELPERS ============
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(ClientBooking booking) {
    final theme = Theme.of(context);
    final amount = (double.tryParse(booking.totalAmount) ?? 0).toInt();
    final statusColor = _getStatusColor(booking.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Booking Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.capitalizeFirst ?? booking.status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Consultant info
            _buildDetailRow(Icons.person, 'Consultant', booking.consultantName),
            if (booking.reference != null)
              _buildDetailRow(Icons.receipt_outlined, 'Reference', booking.reference!),
            
            const Divider(height: 24),

            // Booking details
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              booking.scheduledDate != null
                  ? DateFormat('EEEE, d MMMM yyyy').format(booking.scheduledDate!)
                  : 'Not set',
            ),
            _buildDetailRow(
              Icons.access_time,
              'Time',
              booking.scheduledDate != null
                  ? DateFormat('h:mm a').format(booking.scheduledDate!)
                  : 'Not set',
            ),
            _buildDetailRow(
              Icons.timer_outlined,
              'Duration',
              '${booking.scheduledDurationMinutes} minutes',
            ),
            if (booking.meetingLocation != null)
              _buildDetailRow(
                Icons.location_on_outlined,
                'Location',
                booking.meetingLocation!,
              ),

            const Divider(height: 24),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'TZS ${NumberFormat('#,###').format(amount)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),

            // Notes
            if (booking.clientNotes != null && booking.clientNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.clientNotes!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons based on status
            if (booking.status == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to call or contact
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact Consultant'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
