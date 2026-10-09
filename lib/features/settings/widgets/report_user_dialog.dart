import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../models/safety_models.dart';
import '../services/account_safety_service.dart';

/// Shows a dialog to report a user. Returns true if the report was submitted.
Future<bool> showReportUserDialog(
  BuildContext context, {
  required int reportedUserId,
  required String reportedUserName,
}) async {
  ReportType selectedType = ReportType.harassment;
  final descriptionController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(tr('Report {reportedUserName}').replaceAll('{reportedUserName}', '$reportedUserName')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportType>(
                initialValue: selectedType,
                items: ReportType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what happened',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add a description')),
                );
                return;
              }
              try {
                final service = Get.find<AccountSafetyService>();
                await service.reportUser(
                  reportedUserId: reportedUserId,
                  type: selectedType,
                  description: descriptionController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Failed to submit report'))),
                  );
                }
              }
            },
            child: Text(tr('Submit')),
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}

/// Shows a confirmation dialog to block a user. Returns true if blocked.
Future<bool> showBlockUserDialog(
  BuildContext context, {
  required int userId,
  required String userName,
}) async {
  final reasonController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('Block {userName}').replaceAll('{userName}', '$userName')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'You will no longer receive calls, messages, or see content from $userName.'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            try {
              final service = Get.find<AccountSafetyService>();
              await service.blockUser(
                userId: userId,
                reason: reasonController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context, true);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('Failed to block user'))),
                );
              }
            }
          },
          child: Text(tr('Block')),
        ),
      ],
    ),
  );

  return result ?? false;
}

/// Shows a dialog to report content (hub posts, comments, etc.).
/// Returns true if the report was submitted.
Future<bool> showReportContentDialog(
  BuildContext context, {
  required String contentType,
  required String contentId,
  String contentTitle = 'this content',
}) async {
  ReportType selectedType = ReportType.harassment;
  final descriptionController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Report "$contentTitle"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportType>(
                initialValue: selectedType,
                items: ReportType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue with this content',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add a description')),
                );
                return;
              }
              try {
                final service = Get.find<AccountSafetyService>();
                await service.reportContent(
                  type: selectedType,
                  contentType: contentType,
                  contentId: contentId,
                  description: descriptionController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Failed to submit report'))),
                  );
                }
              }
            },
            child: Text(tr('Submit')),
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}
