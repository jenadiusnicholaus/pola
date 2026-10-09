import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../models/safety_models.dart';
import '../services/account_safety_service.dart';

class ManageDataScreen extends StatefulWidget {
  const ManageDataScreen({super.key});

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final AccountSafetyService _service = Get.find<AccountSafetyService>();
  final Set<DataCategory> _selected = {};
  bool _isDeleting = false;

  static const _categories = [
    DataCategory.location,
    DataCategory.deviceInfo,
    DataCategory.callHistory,
    DataCategory.messages,
    DataCategory.documents,
    DataCategory.payment,
    DataCategory.profile,
  ];

  Future<void> _confirmAndDelete() async {
    if (_selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Delete Selected Data')),
        content: Text(
          'This will permanently delete: ${_selected.map((c) => c.label).join(', ')}. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final result = await _service.deleteData(_selected.toList());
      final deleted =
          (result['deleted'] as Map?)?.values.join('\n') ?? 'Data deleted.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(deleted)),
        );
        setState(() {
          _selected.clear();
          _isDeleting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Failed to delete data'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select the categories of data you want to permanently delete. '
            'Your account will remain active.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: _categories
                  .map(
                    (category) => CheckboxListTile(
                      value: _selected.contains(category),
                      title: Text(category.label),
                      activeColor: AppColors.primaryAmber,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(category);
                          } else {
                            _selected.remove(category);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed:
                  _isDeleting || _selected.isEmpty ? null : _confirmAndDelete,
              child: _isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(tr('Delete Selected Data')),
            ),
          ),
        ],
      ),
    );
  }
}
