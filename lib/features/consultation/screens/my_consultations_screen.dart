import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/consultation_service.dart';
import '../../../services/permission_service.dart';

class MyConsultationsScreen extends StatefulWidget {
  const MyConsultationsScreen({super.key});

  @override
  State<MyConsultationsScreen> createState() => _MyConsultationsScreenState();
}

class _MyConsultationsScreenState extends State<MyConsultationsScreen>
    with SingleTickerProviderStateMixin {
  final ConsultationService _consultationService =
      Get.find<ConsultationService>();
  final PermissionService _permissionService = Get.find<PermissionService>();
  
  late bool _isLawFirm;

  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  MyConsultationsResponse? _consultations;
  String? _selectedType; // null = all, 'call', 'physical'
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _isLawFirm = _permissionService.isLawFirm;
    // Physical consultations only for law firms
    final tabCount = _isLawFirm ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_scrollListener);
    _loadConsultations();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _scrollController.removeListener(_scrollListener);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _currentPage = 1;
      _hasMore = true;
      setState(() {
        if (_isLawFirm) {
          // Law firms: All, Calls, Physical
          switch (_tabController.index) {
            case 0:
              _selectedType = null; // All
              break;
            case 1:
              _selectedType = 'call'; // Calls only
              break;
            case 2:
              _selectedType = 'physical'; // Physical bookings only
              break;
          }
        } else {
          // Others: All, Calls (no Physical)
          switch (_tabController.index) {
            case 0:
              _selectedType = null; // All
              break;
            case 1:
              _selectedType = 'call'; // Calls only
              break;
          }
        }
      });
      _loadConsultations();
    }
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    final response = await _consultationService.getMyConsultations(
      type: _selectedType,
      page: _currentPage,
    );

    setState(() {
      _consultations = response;
      _hasMore = response != null && _currentPage < response.totalPages;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _consultations == null) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _consultationService.getMyConsultations(
        type: _selectedType,
        page: _currentPage,
      );

      if (response != null && mounted) {
        setState(() {
          // Merge new consultations with existing ones
          _consultations = MyConsultationsResponse(
            count: response.count,
            page: response.page,
            pageSize: response.pageSize,
            totalPages: response.totalPages,
            summary: response.summary,
            consultations: [
              ..._consultations!.consultations,
              ...response.consultations
            ],
          );
          _hasMore = _currentPage < response.totalPages;
        });
      }
    } catch (e) {
      _currentPage--;
      debugPrint('Error loading more consultations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _updateConsultationStatus({
    required int consultationId,
    required String status,
  }) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('Confirm ${status.toUpperCase()}'),
            content: Text(
                'Are you sure you want to ${status.toLowerCase()} this consultation?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await _consultationService.updateConsultationStatus(
      consultationId: consultationId,
      status: status,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Consultation ${status.toLowerCase()} successfully',
        icon: const Icon(Icons.check_circle, color: Colors.white),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _loadConsultations();
    } else {
      Get.snackbar(
        'Error',
        'Failed to update consultation status',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'My Consultations',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: _isLawFirm
              ? const [
                  Tab(icon: Icon(Icons.list_alt, size: 20), text: 'All'),
                  Tab(icon: Icon(Icons.phone, size: 20), text: 'Calls'),
                  Tab(icon: Icon(Icons.location_on, size: 20), text: 'Physical'),
                ]
              : const [
                  Tab(icon: Icon(Icons.list_alt, size: 20), text: 'All'),
                  Tab(icon: Icon(Icons.phone, size: 20), text: 'Calls'),
                ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations == null || _consultations!.results.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadConsultations,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _consultations!.results.length +
                        (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _consultations!.results.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final booking = _consultations!.results[index];
                      return _buildConsultationCard(booking, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String typeLabel = '';
    if (_selectedType == 'call') {
      typeLabel = 'call ';
    } else if (_selectedType == 'physical') {
      typeLabel = 'physical ';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedType == 'call'
                ? Icons.phone_disabled
                : _selectedType == 'physical'
                    ? Icons.location_off
                    : Icons.event_busy,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${typeLabel}consultations',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedType == 'call'
                ? 'Call consultations from clients will appear here'
                : _selectedType == 'physical'
                    ? 'Physical booking requests will appear here'
                    : 'All consultations from clients will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationBooking booking, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    if (booking.isPending) {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.schedule;
    } else if (booking.isConfirmed) {
      statusColor = Colors.blue.shade700;
      statusIcon = Icons.check_circle;
    } else if (booking.isCompleted) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.done_all;
    } else {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Client name and status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    booking.isCall ? Icons.phone : Icons.event,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.clientEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Details
            if (booking.isBooking) ...[
              _buildDetailRow(
                theme,
                Icons.calendar_today,
                _formatDate(booking.scheduledDate),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                theme,
                Icons.access_time,
                booking.scheduledTime,
              ),
            ] else ...[
              _buildDetailRow(
                theme,
                booking.callType == 'video' ? Icons.videocam : Icons.phone,
                '${booking.callType == 'video' ? 'Video' : 'Voice'} Call',
              ),
              if (booking.durationMinutes != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  theme,
                  Icons.timer,
                  '${booking.durationMinutes} minutes',
                ),
              ],
            ],

            // Amount/Credits
            if (booking.amount != null || booking.creditsDeducted != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                theme,
                booking.amount != null ? Icons.payment : Icons.account_balance_wallet,
                booking.amount != null
                    ? 'TZS ${booking.amount!.toStringAsFixed(0)}'
                    : '${booking.creditsDeducted!.toStringAsFixed(0)} credits',
              ),
            ],

            // Notes/Topic
            if (booking.topic != null && booking.topic!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.topic!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],

            // Actions
            if (booking.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateConsultationStatus(
                        consultationId: booking.id,
                        status: 'rejected',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _updateConsultationStatus(
                        consultationId: booking.id,
                        status: 'confirmed',
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            if (booking.isConfirmed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _updateConsultationStatus(
                    consultationId: booking.id,
                    status: 'completed',
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }


  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
