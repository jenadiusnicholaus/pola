import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../models/safety_models.dart';
import '../services/account_safety_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final AccountSafetyService _service = Get.find<AccountSafetyService>();
  List<UserReport> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reports = await _service.listMyReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Reports'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reports.isEmpty
                  ? const Center(child: Text('You have not submitted any reports'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(report.reportType
                                .replaceAll('_', ' ')
                                .toUpperCase()),
                            subtitle: Text(report.description),
                            trailing: Chip(
                              label: Text(
                                report.status.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                              backgroundColor: _statusColor(report.status),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
