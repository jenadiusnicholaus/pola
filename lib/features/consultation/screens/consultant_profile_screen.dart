import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/consultation_service.dart';

class ConsultantProfileScreen extends StatefulWidget {
  const ConsultantProfileScreen({super.key});

  @override
  State<ConsultantProfileScreen> createState() =>
      _ConsultantProfileScreenState();
}

class _ConsultantProfileScreenState extends State<ConsultantProfileScreen> {
  final ConsultationService _consultationService =
      Get.find<ConsultationService>();

  ConsultationEligibility? _eligibility;
  ConsultantProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _eligibility = await _consultationService.checkEligibility();

    if (_eligibility?.isConsultant == true) {
      _profile = await _consultationService.getMyProfile();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildContent(theme),
              ),
            ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_eligibility == null) {
      return _buildErrorState(theme);
    }

    // Check status and show appropriate screen
    if (_eligibility!.isConsultant && _profile != null) {
      return _buildApprovedConsultantView(theme);
    } else if (_eligibility!.status == 'pending') {
      return _buildPendingApplicationView(theme);
    } else if (_eligibility!.status == 'rejected') {
      return _buildRejectedApplicationView(theme);
    } else if (_eligibility!.canApply) {
      return _buildApplyView(theme);
    } else {
      return _buildNotEligibleView(theme);
    }
  }

  Widget _buildApprovedConsultantView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Consultant',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can now receive consultation requests',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Availability Toggle
        Card(
          child: SwitchListTile(
            title: const Text('Available for Consultations'),
            subtitle: Text(
              _profile!.isAvailable
                  ? 'You are currently accepting requests'
                  : 'You are not accepting new requests',
            ),
            value: _profile!.isAvailable,
            onChanged: _toggleAvailability,
            secondary: Icon(
              _profile!.isAvailable ? Icons.check_circle : Icons.cancel,
              color: _profile!.isAvailable ? Colors.green : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Statistics
        Text(
          'Performance Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total',
                _profile!.totalConsultations.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'This Month',
                _profile!.consultationsThisMonth.toString(),
                Icons.calendar_month,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Rating',
                _profile!.averageRating?.toStringAsFixed(1) ?? 'N/A',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Completion',
                '${_profile!.completionRate.toStringAsFixed(0)}%',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Reviews',
                _profile!.totalReviews.toString(),
                Icons.rate_review,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'This Month',
                'TZS ${_profile!.earningsThisMonth.toStringAsFixed(0)}',
                Icons.payments,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Profile Details
        Text(
          'Profile Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  'Consultant Type',
                  _profile!.consultantType.toUpperCase(),
                  Icons.badge,
                ),
                if (_profile!.specialization != null) ...[
                  const Divider(),
                  _buildDetailRow(
                    'Specialization',
                    _profile!.specialization!,
                    Icons.star,
                  ),
                ],
                if (_profile!.yearsOfExperience != null) ...[
                  const Divider(),
                  _buildDetailRow(
                    'Experience',
                    '${_profile!.yearsOfExperience} years',
                    Icons.work,
                  ),
                ],
                const Divider(),
                _buildDetailRow(
                  'Mobile Consultations',
                  _profile!.offersMobileConsultations ? 'Yes' : 'No',
                  Icons.phone_android,
                ),
                const Divider(),
                _buildDetailRow(
                  'Physical Consultations',
                  _profile!.offersPhysicalConsultations ? 'Yes' : 'No',
                  Icons.location_on,
                ),
                if (_profile!.city != null && _profile!.city!.isNotEmpty) ...[
                  const Divider(),
                  _buildDetailRow(
                    'City',
                    _profile!.city!,
                    Icons.location_city,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _viewReviews,
            icon: const Icon(Icons.star_outline),
            label: Text('View Reviews (${_profile!.totalReviews})'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApplicationView(ThemeData theme) {
    final application = _eligibility!.application;

    return Column(
      children: [
        Icon(
          Icons.schedule,
          size: 80,
          color: Colors.orange.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Application Under Review',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your consultant application is currently being reviewed by our admin team.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Application Details:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (application != null) ...[
                  _buildDetailRow(
                    'Type',
                    application['consultant_type_display'] ??
                        application['consultant_type'] ??
                        'N/A',
                    Icons.badge,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Status',
                    application['status_display'] ??
                        application['status'] ??
                        'Pending',
                    Icons.info,
                  ),
                  if (application['created_at'] != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      'Submitted',
                      _formatDate(application['created_at']),
                      Icons.calendar_today,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'What Happens Next?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Admin reviews your application and documents'),
              _buildInfoRow('You will be notified via email once reviewed'),
              _buildInfoRow(
                  'If approved, you can start accepting consultations'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedApplicationView(ThemeData theme) {
    final application = _eligibility!.application;
    final adminNotes = application?['admin_notes'];

    return Column(
      children: [
        Icon(
          Icons.cancel,
          size: 80,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Application Not Approved',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unfortunately, your consultant application was not approved.',
                  style: theme.textTheme.bodyLarge,
                ),
                if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Admin Notes:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(adminNotes.toString()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Contact support or reapply
              Get.snackbar(
                'Contact Support',
                'Please contact support for more information',
                icon: const Icon(Icons.support_agent, color: Colors.white),
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyView(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.psychology,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Become a Consultant',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your legal expertise and earn by helping others with their legal queries.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Benefits:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Earn money by providing consultations'),
                _buildInfoRow('Flexible schedule - work when you want'),
                _buildInfoRow('Help people with legal guidance'),
                _buildInfoRow('Build your professional reputation'),
                const SizedBox(height: 16),
                Text(
                  'Requirements:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Valid professional credentials'),
                _buildInfoRow('ID/Passport documentation'),
                _buildInfoRow('Admin approval required'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showApplicationDialog,
            icon: const Icon(Icons.send),
            label: const Text('Apply Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotEligibleView(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.info_outline,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Not Eligible',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _eligibility?.message ??
                  'You are not eligible to apply as a consultant at this time. '
                      'Only verified advocates, lawyers, paralegals, and law firms can apply.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Error Loading Data',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final success = await _consultationService.updateProfile({
      'is_available': value,
    });

    if (success) {
      // Reload the profile to get updated data
      await _loadData();

      Get.snackbar(
        'Success',
        value
            ? 'You are now available for consultations'
            : 'You are no longer accepting new consultations',
        icon: Icon(
          value ? Icons.check_circle : Icons.cancel,
          color: Colors.white,
        ),
        backgroundColor: value ? Colors.green : Colors.orange,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update availability',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _viewReviews() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final reviewsData = await _consultationService.getMyReviews();
    Get.back(); // Close loading

    if (reviewsData == null || reviewsData.reviews.isEmpty) {
      Get.snackbar(
        'No Reviews',
        'You don\'t have any reviews yet',
        icon: const Icon(Icons.info_outline, color: Colors.white),
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    // Show reviews in a bottom sheet or new screen
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'My Reviews (${reviewsData.count})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviewsData.reviews.length,
                itemBuilder: (context, index) {
                  final review = reviewsData.reviews[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  review.client?['name']?[0] ?? 'C',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.client?['name'] ?? 'Client',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(
                                          review.createdAt.toIso8601String()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    review.rating.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (review.reviewText != null) ...[
                            const SizedBox(height: 12),
                            Text(review.reviewText!),
                          ],
                          if (review.consultantResponse != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Response:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(review.consultantResponse!),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _respondToReview(review),
                              icon: const Icon(Icons.reply, size: 16),
                              label: const Text('Respond'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _respondToReview(ConsultantReview review) {
    final controller = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please write a response',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back(); // Close dialog
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              final success = await _consultationService.respondToReview(
                review.id,
                controller.text.trim(),
              );

              Get.back(); // Close loading

              if (success) {
                Get.snackbar(
                  'Success',
                  'Response submitted successfully',
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                Get.back(); // Close reviews sheet
                _viewReviews(); // Reload reviews
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to submit response',
                  icon: const Icon(Icons.error, color: Colors.white),
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showApplicationDialog() {
    bool offersPhysical = false;
    bool termsAccepted = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Apply as Consultant'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your professional information and documents are already verified. Just select your consultation preferences:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Offer Physical Consultations'),
                    subtitle: const Text(
                      'In-person consultations at your office',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: offersPhysical,
                    onChanged: (value) {
                      setState(() => offersPhysical = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('Accept Terms & Conditions'),
                    subtitle: const Text(
                      'I agree to the consultant terms',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: termsAccepted,
                    onChanged: (value) {
                      setState(() => termsAccepted = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Note:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Mobile/video consultations are included by default\n'
                          '• Physical consultations require law firm association\n'
                          '• Admin approval required before receiving bookings',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: termsAccepted
                    ? () async {
                        Get.back(); // Close dialog

                        Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                          barrierDismissible: false,
                        );

                        final result =
                            await _consultationService.submitApplication(
                          offersPhysicalConsultations: offersPhysical,
                          termsAccepted: true,
                        );

                        Get.back(); // Close loading

                        if (result.success) {
                          Get.dialog(
                            AlertDialog(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 48),
                              title: const Text('Application Submitted!'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(result.message),
                                  if (result.nextSteps != null &&
                                      result.nextSteps!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Next Steps:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...result.nextSteps!
                                        .map((step) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text('• '),
                                                  Expanded(child: Text(step)),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Get.back(); // Close success dialog
                                    _loadData(); // Reload data
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Get.snackbar(
                            'Application Failed',
                            result.message,
                            icon: const Icon(Icons.error, color: Colors.white),
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 5),
                          );
                        }
                      }
                    : null,
                child: const Text('Submit Application'),
              ),
            ],
          );
        },
      ),
    );
  }
}
