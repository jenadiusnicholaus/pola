import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../models/safety_models.dart';
import '../services/account_safety_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AccountSafetyService _service = Get.find<AccountSafetyService>();
  final _reasonController = TextEditingController();
  bool _confirmed = false;
  bool _isSubmitting = false;
  List<DeletionRequest> _pendingRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests = await _service.listDeletionRequests();
      setState(() {
        _pendingRequests =
            requests.where((r) => r.status == 'pending').toList();
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _submitDeletion() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm by checking the box')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _service.deleteAccount(
        reason: _reasonController.text.trim(),
      );

      final gracePeriod = result['grace_period_days'] ?? 30;
      final scheduledDate = result['scheduled_deletion_date'] ?? '';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Deletion Scheduled'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Your account has been deactivated. It will be permanently deleted in'),
                SizedBox(height: 8),
                Text(
                  tr('{gracePeriod} days').replaceAll('{gracePeriod}', '$gracePeriod'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (scheduledDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('Scheduled: {date}').replaceAll('{date}',
                          '${DateTime.tryParse(scheduledDate)?.toLocal()}'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                    'You can cancel this request by logging in within the grace period.'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Get.find<AuthService>().logout();
                },
                child: Text(tr('OK')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit deletion request')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelDeletion(DeletionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Deletion'),
        content: Text(
            'Your account will be reactivated and the deletion will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('No')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel Deletion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.cancelDeletion(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Deletion cancelled — account reactivated')),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel deletion')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: _isLoadingRequests
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pendingRequests.isNotEmpty) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Pending Deletion Request',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._pendingRequests.map((req) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      'Type: ${req.deletionType.toUpperCase()}'),
                                  subtitle: Text(
                                    'Scheduled: ${req.scheduledDeletionDate?.toLocal() ?? "N/A"}',
                                  ),
                                  trailing: TextButton(
                                    onPressed: () => _cancelDeletion(req),
                                    child: const Text('Cancel Deletion'),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delete_forever,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Delete Your Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This will deactivate your account immediately. '
                            'Your data will be permanently deleted after a 30-day grace period. '
                            'You can cancel within that period by logging back in.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _reasonController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Reason (optional)',
                              hintText: 'Tell us why you are leaving',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: _confirmed,
                            title: const Text(
                                'I understand this action is irreversible after the grace period'),
                            activeColor: AppColors.primaryAmber,
                            onChanged: (value) =>
                                setState(() => _confirmed = value ?? false),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: _isSubmitting || !_confirmed
                                  ? null
                                  : _submitDeletion,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Delete My Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Get.toNamed('/manage-data'),
                      child: const Text(
                          'Or delete specific data without closing your account'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
