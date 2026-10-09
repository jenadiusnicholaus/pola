import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../utils/navigation_helper.dart';
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
      NavigationHelper.showSafeSnackbar(
        title: tr('Success'),
        message: 'Consultation ${status.toLowerCase()} successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      _loadConsultations();
    } else {
      NavigationHelper.showSafeSnackbar(
        title: tr('Error'),
        message: 'Failed to update consultation status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        title: const Text(
          'My Consultations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.6),
          tabs: _isLawFirm
              ? const [
                  Tab(icon: Icon(Icons.list_alt, size: 20), text: 'All'),
                  Tab(icon: Icon(Icons.phone, size: 20), text: 'Calls'),
                  Tab(
                      icon: Icon(Icons.location_on, size: 20),
                      text: 'Physical'),
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
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount:
                        _consultations!.results.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 76,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                    itemBuilder: (context, index) {
                      if (index == _consultations!.results.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final booking = _consultations!.results[index];
                      return _buildConsultationTile(booking, theme);
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

  /// Compact contacts-style tile: type-icon avatar, client name + status,
  /// one-line meta, swipe actions, and tap-to-view details.
  Widget _buildConsultationTile(ConsultationBooking booking, ThemeData theme) {
    final statusColor = _statusColor(booking);

    final meta = booking.isBooking
        ? '${_formatDate(booking.scheduledDate)} • ${booking.scheduledTime}'
        : '${booking.callType == 'video' ? 'Video' : 'Voice'} call'
            '${booking.durationMinutes != null ? ' • ${booking.durationMinutes} min' : ''}';

    // Swipe actions: pending → accept/reject, confirmed → mark complete.
    Widget? background;
    Widget? secondaryBackground;
    DismissDirection direction = DismissDirection.none;
    if (booking.isPending) {
      direction = DismissDirection.horizontal;
      background = _swipeBackground(
        icon: Icons.check,
        label: tr('Accept'),
        color: Colors.green,
        fromLeft: true,
      );
      secondaryBackground = _swipeBackground(
        icon: Icons.close,
        label: tr('Reject'),
        color: Colors.red,
        fromLeft: false,
      );
    } else if (booking.isConfirmed) {
      direction = DismissDirection.startToEnd;
      background = _swipeBackground(
        icon: Icons.done_all,
        label: tr('Complete'),
        color: Colors.green,
        fromLeft: true,
      );
    }

    return Dismissible(
      key: ValueKey('consultation_${booking.id}'),
      direction: direction,
      background: background,
      secondaryBackground: secondaryBackground,
      confirmDismiss: (dir) async {
        if (booking.isPending) {
          await _updateConsultationStatus(
            consultationId: booking.id,
            status:
                dir == DismissDirection.startToEnd ? 'confirmed' : 'rejected',
          );
        } else if (booking.isConfirmed && dir == DismissDirection.startToEnd) {
          await _updateConsultationStatus(
            consultationId: booking.id,
            status: 'completed',
          );
        }
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _showConsultationDetails(context, booking, theme),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(
            booking.isCall ? Icons.phone : Icons.event,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          booking.clientName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              booking.status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (booking.isPending) ...[
              _actionIcon(
                  theme,
                  Icons.close,
                  Colors.red,
                  () => _updateConsultationStatus(
                      consultationId: booking.id, status: 'rejected')),
              const SizedBox(width: 6),
              _actionIcon(
                  theme,
                  Icons.check,
                  Colors.green,
                  () => _updateConsultationStatus(
                      consultationId: booking.id, status: 'confirmed')),
            ] else if (booking.isConfirmed) ...[
              _actionIcon(
                  theme,
                  Icons.done_all,
                  Colors.green,
                  () => _updateConsultationStatus(
                      consultationId: booking.id, status: 'completed')),
            ] else
              Icon(
                booking.isCompleted ? Icons.done_all : Icons.cancel_outlined,
                size: 18,
                color: statusColor.withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ConsultationBooking booking) {
    if (booking.isPending) return Colors.orange.shade700;
    if (booking.isConfirmed) return Colors.blue.shade700;
    if (booking.isCompleted) return Colors.green.shade700;
    return Colors.red.shade700;
  }

  Widget _swipeBackground({
    required IconData icon,
    required String label,
    required Color color,
    required bool fromLeft,
  }) {
    return Container(
      color: color,
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromLeft) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ] else ...[
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _actionIcon(
      ThemeData theme, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// Bottom sheet with the full consultation details.
  void _showConsultationDetails(
      BuildContext context, ConsultationBooking booking, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                booking.clientName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                booking.clientEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (booking.isBooking) ...[
                _buildDetailRow(theme, Icons.calendar_today,
                    _formatDate(booking.scheduledDate)),
                const SizedBox(height: 8),
                _buildDetailRow(
                    theme, Icons.access_time, booking.scheduledTime),
              ] else ...[
                _buildDetailRow(
                  theme,
                  booking.callType == 'video' ? Icons.videocam : Icons.phone,
                  '${booking.callType == 'video' ? 'Video' : 'Voice'} Call',
                ),
                if (booking.durationMinutes != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      theme, Icons.timer, '${booking.durationMinutes} minutes'),
                ],
              ],
              if (booking.amount != null ||
                  booking.creditsDeducted != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  theme,
                  booking.amount != null
                      ? Icons.payment
                      : Icons.account_balance_wallet,
                  booking.amount != null
                      ? 'TZS ${booking.amount!.toStringAsFixed(0)}'
                      : '${booking.creditsDeducted!.toStringAsFixed(0)} credits',
                ),
              ],
              if (booking.topic != null && booking.topic!.isNotEmpty) ...[
                const SizedBox(height: 16),
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
            ],
          ),
        );
      },
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
