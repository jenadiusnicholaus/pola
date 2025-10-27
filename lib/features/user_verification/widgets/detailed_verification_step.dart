import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';

class DetailedVerificationStep extends StatelessWidget {
  final String stepId;
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final List<VerificationDocument> documents;
  final List<RequiredDocument> requiredDocuments;
  final Map<String, String> userInfo;
  final List<String> missingInfo;

  const DetailedVerificationStep({
    super.key,
    required this.stepId,
    required this.title,
    required this.description,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.documents,
    required this.requiredDocuments,
    required this.userInfo,
    required this.missingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrent ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getStepBackgroundColor(theme),
          border: Border.all(
            color: _getStepBorderColor(theme),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Theme(
          data: theme.copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: theme.expansionTileTheme.copyWith(
              iconColor: _getStepIconColor(theme),
              collapsedIconColor: _getStepIconColor(theme),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: isCurrent || !isCompleted,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStepIconBackgroundColor(theme),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _getStepIconColor(theme),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStepTitleColor(theme),
                    ),
                  ),
                ),
                _buildStepStatus(theme),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getStepDescriptionColor(theme),
                  ),
                ),
                if (isCurrent && missingInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${missingInfo.length} item(s) required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),

                    // Step content based on type
                    if (stepId == 'documents') ...[
                      _buildDocumentsContent(context, theme),
                    ] else if (stepId == 'contact' || stepId == 'personal') ...[
                      _buildInformationContent(context, theme),
                    ] else ...[
                      _buildGenericContent(context, theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepStatus(ThemeData theme) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green[700]!,
            ),
            const SizedBox(width: 4),
            Text(
              'Complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[700]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radio_button_checked,
              size: 16,
              color: Colors.amber[700]!,
            ),
            const SizedBox(width: 4),
            Text(
              'Current',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber[700]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radio_button_unchecked,
              size: 16,
              color: Colors.red[700]!,
            ),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentsContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uploaded Documents
        if (documents.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Uploaded Documents',
            Icons.upload_file,
            '${documents.length} uploaded',
          ),
          const SizedBox(height: 12),
          ...documents
              .map((doc) => _buildDocumentItem(context, theme, doc, true)),
          const SizedBox(height: 16),
        ],

        // Required Documents
        if (requiredDocuments.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Required Documents',
            Icons.description,
            '${requiredDocuments.length} required',
          ),
          const SizedBox(height: 12),
          ...requiredDocuments.map((reqDoc) {
            final isUploaded = documents.any((doc) =>
                doc.documentType.toLowerCase() ==
                reqDoc.documentType.toLowerCase());
            return _buildRequiredDocumentItem(
                context, theme, reqDoc, isUploaded);
          }),
        ],
      ],
    );
  }

  Widget _buildInformationContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available Information
        if (userInfo.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Provided Information',
            Icons.check_circle_outline,
            '${userInfo.length} fields',
          ),
          const SizedBox(height: 12),
          ...userInfo.entries.map((entry) =>
              _buildInfoItem(context, theme, entry.key, entry.value, true)),
          const SizedBox(height: 16),
        ],

        // Missing Information
        if (missingInfo.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Missing Information',
            Icons.warning_outlined,
            '${missingInfo.length} fields required',
            isWarning: true,
          ),
          const SizedBox(height: 12),
          ...missingInfo.map((info) =>
              _buildInfoItem(context, theme, info, 'Required', false)),
        ],
      ],
    );
  }

  Widget _buildGenericContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompleted) ...[
          _buildInfoCard(
            context,
            theme,
            'This step has been completed successfully.',
            Icons.check_circle,
            Colors.green[700]!,
          ),
        ] else if (isCurrent) ...[
          _buildInfoCard(
            context,
            theme,
            'This is your current step. Complete all requirements to proceed.',
            Icons.info,
            Colors.amber[700]!,
          ),
        ] else ...[
          _buildInfoCard(
            context,
            theme,
            'Complete previous steps to unlock this step.',
            Icons.lock_outline,
            theme.colorScheme.error,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle, {
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final color =
        isWarning ? theme.colorScheme.error : _getStepIconColor(theme);

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isWarning
                      ? theme.colorScheme.error.withOpacity(0.7)
                      : _getStepIconColor(theme).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(BuildContext context, ThemeData theme,
      VerificationDocument doc, bool isUploaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getDocumentStatusColor(doc.status, context).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getDocumentStatusColor(doc.status, context)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(doc.status),
                  size: 20,
                  color: _getDocumentStatusColor(doc.status, context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.documentTypeDisplay,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDocumentStatusColor(doc.status, context)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc.statusDisplay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getDocumentStatusColor(doc.status, context),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDocumentActionButton(context, doc),
            ],
          ),

          // Additional information
          if (doc.createdAt.isNotEmpty || doc.verificationDate != null) ...[
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor.withOpacity(0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (doc.createdAt.isNotEmpty) ...[
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Uploaded: ${_formatDate(doc.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
                if (doc.verificationDate != null) ...[
                  if (doc.createdAt.isNotEmpty) const SizedBox(width: 16),
                  Icon(
                    Icons.verified_user,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified: ${_formatDate(doc.verificationDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Rejection reason
          if (doc.status == 'rejected' &&
              doc.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 16,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc.rejectionReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Verification notes
          if (doc.status == 'verified' &&
              doc.verificationNotes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Notes:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc.verificationNotes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentActionButton(
      BuildContext context, VerificationDocument doc) {
    switch (doc.status) {
      case 'verified':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.verified,
            color: Colors.green[700],
            size: 24,
          ),
        );
      case 'rejected':
        return ElevatedButton.icon(
          onPressed: () => _showReuploadDialog(context, doc),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Re-upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Reviewing',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      default:
        return IconButton(
          onPressed: () => _showDocumentPreview(context, doc),
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'View Document',
        );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showDocumentPreview(BuildContext context, VerificationDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.documentTypeDisplay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc.isImage) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: doc.fileUrl.isNotEmpty
                    ? Image.network(
                        doc.fileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.error, size: 50)),
                      )
                    : const Center(child: Icon(Icons.image, size: 50)),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      doc.isPdf ? Icons.picture_as_pdf : Icons.description,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doc.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (doc.fileUrl.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement document download/open
                Navigator.pop(context);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequiredDocumentItem(BuildContext context, ThemeData theme,
      RequiredDocument reqDoc, bool isUploaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUploaded
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUploaded
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              size: 16,
              color: isUploaded ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reqDoc.documentTypeDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  reqDoc.description ?? 'Document required for verification',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!isUploaded) ...[
            ElevatedButton.icon(
              onPressed: () => _showUploadDialog(context, reqDoc),
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Uploaded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, ThemeData theme, String label,
      String value, bool isProvided) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isProvided
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isProvided
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isProvided ? Icons.check : Icons.warning_outlined,
              size: 16,
              color: isProvided ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isProvided) ...[
                  Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isProvided) ...[
            ElevatedButton(
              onPressed: () => _showEditInfoDialog(context, label),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Edit'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme, String message,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepBorderColor(ThemeData theme) {
    if (isCompleted) return Colors.green.withOpacity(0.5);
    if (isCurrent) return Colors.amber.withOpacity(0.5);
    return Colors.red.withOpacity(0.3);
  }

  Color _getStepIconBackgroundColor(ThemeData theme) {
    if (isCompleted) return Colors.green.withOpacity(0.1);
    if (isCurrent) return Colors.amber.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }

  Color _getStepIconColor(ThemeData theme) {
    if (isCompleted) return Colors.green[700]!;
    if (isCurrent) return Colors.amber[700]!;
    return Colors.red[700]!;
  }

  Color _getStepTitleColor(ThemeData theme) {
    if (isCompleted) return Colors.green[700]!;
    if (isCurrent) return Colors.amber[700]!;
    return theme.colorScheme.onSurface;
  }

  Color _getStepBackgroundColor(ThemeData theme) {
    if (isCompleted) return Colors.green.withOpacity(0.02);
    if (isCurrent) return Colors.amber.withOpacity(0.02);
    return theme.colorScheme.surface;
  }

  Color _getStepDescriptionColor(ThemeData theme) {
    if (isCompleted) return Colors.green[600]!.withOpacity(0.8);
    if (isCurrent) return Colors.amber[600]!.withOpacity(0.8);
    return theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);
  }

  Color _getDocumentStatusColor(String status, [BuildContext? context]) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green[700]!;
      case 'rejected':
        return Colors.red[700]!;
      case 'pending':
        return Colors.amber[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getDocumentIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.description;
    }
  }

  void _showUploadDialog(BuildContext context, RequiredDocument reqDoc) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.upload_file,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Upload ${reqDoc.documentTypeDisplay}'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reqDoc.description ??
                          'Document required for verification',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadGuidelines(theme),
            const SizedBox(height: 16),
            if (reqDoc.required) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'This document is required for verification',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showUploadOptions(context, reqDoc);
            },
            icon: const Icon(Icons.upload),
            label: const Text('Choose File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context, RequiredDocument reqDoc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload ${reqDoc.documentTypeDisplay}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to upload your document',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildUploadOptionCard(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Take a photo',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromCamera(context, reqDoc);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUploadOptionCard(
                    context,
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    subtitle: 'Choose from photos',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromGallery(context, reqDoc);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildUploadOptionCard(
                context,
                icon: Icons.folder_outlined,
                title: 'Browse Files',
                subtitle: 'Choose PDF or image file (with gallery fallback)',
                onTap: () {
                  Navigator.pop(context);
                  _uploadFromFiles(context, reqDoc);
                },
                isWide: true,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isWide ? 16 : 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  void _uploadFromCamera(BuildContext context, RequiredDocument reqDoc) {
    Get.find<VerificationController>(tag: 'verification_screen')
        .uploadDocumentFromCamera(reqDoc.documentType);
  }

  void _uploadFromGallery(BuildContext context, RequiredDocument reqDoc) {
    Get.find<VerificationController>(tag: 'verification_screen')
        .uploadDocumentFromGallery(reqDoc.documentType);
  }

  void _uploadFromFiles(BuildContext context, RequiredDocument reqDoc) {
    Get.find<VerificationController>(tag: 'verification_screen')
        .uploadDocumentFromFiles(reqDoc.documentType);
  }

  void _showEditInfoDialog(BuildContext context, String field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content:
            const Text('Navigate to your profile to edit this information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/profile');
            },
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  void _showReuploadDialog(BuildContext context, VerificationDocument doc) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.refresh,
              color: Colors.red[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Re-upload Document'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 16,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Rejected:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        if (doc.rejectionReason?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            doc.rejectionReason!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please upload a new ${doc.documentTypeDisplay.toLowerCase()} that meets the requirements:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildUploadGuidelines(theme, isReupload: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showReuploadOptions(context, doc);
            },
            icon: const Icon(Icons.upload),
            label: const Text('Upload New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReuploadOptions(BuildContext context, VerificationDocument doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: Colors.red[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Re-upload ${doc.documentTypeDisplay}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildUploadOptionCard(
              context,
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Use camera to capture document',
              onTap: () {
                Navigator.pop(context);
                Get.find<VerificationController>(tag: 'verification_screen')
                    .uploadDocumentFromCamera(doc.documentType);
              },
              isWide: true,
            ),
            const SizedBox(height: 12),
            _buildUploadOptionCard(
              context,
              icon: Icons.photo_library,
              title: 'Photo Gallery',
              subtitle: 'Choose from your photos',
              onTap: () {
                Navigator.pop(context);
                Get.find<VerificationController>(tag: 'verification_screen')
                    .uploadDocumentFromGallery(doc.documentType);
              },
              isWide: true,
            ),
            const SizedBox(height: 12),
            _buildUploadOptionCard(
              context,
              icon: Icons.folder,
              title: 'Browse Files',
              subtitle: 'Choose PDF or image file (with gallery fallback)',
              onTap: () {
                Navigator.pop(context);
                Get.find<VerificationController>(tag: 'verification_screen')
                    .uploadDocumentFromFiles(doc.documentType);
              },
              isWide: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadGuidelines(ThemeData theme, {bool isReupload = false}) {
    final guidelines = [
      'Clear, high-quality image or PDF',
      'All text must be readable',
      'Document should be recent and valid',
      'File size under 10MB',
      'Supported formats: JPG, PNG, PDF',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isReupload ? Colors.orange : Colors.blue).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isReupload ? Colors.orange : Colors.blue).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: (isReupload ? Colors.orange : Colors.blue)[700],
              ),
              const SizedBox(width: 6),
              Text(
                'Upload Guidelines:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (isReupload ? Colors.orange : Colors.blue)[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...guidelines.map((guideline) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isReupload ? Colors.orange : Colors.blue)[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guideline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              (isReupload ? Colors.orange : Colors.blue)[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
