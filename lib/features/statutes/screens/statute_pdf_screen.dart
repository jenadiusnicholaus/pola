import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/statutes_controller.dart';
import '../models/statute_models.dart';

/// Full-screen statute reader.
///
/// Professional reading experience: page-snap scrolling, page indicator,
/// prev/next controls, and a night-mode toggle.
class StatutePdfScreen extends StatefulWidget {
  const StatutePdfScreen({super.key});

  @override
  State<StatutePdfScreen> createState() => _StatutePdfScreenState();
}

class _StatutePdfScreenState extends State<StatutePdfScreen> {
  late final StatuteLaw _law;
  late final String _title;

  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _nightMode = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<StatutesController>();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _law = args['law'] as StatuteLaw;
    _title = _law.localizedTitle(swahili: controller.isSwahili);
  }

  Future<void> _goToPage(int page) async {
    if (_pdfController == null) return;
    final target = page.clamp(0, _totalPages - 1);
    await _pdfController!.setPage(target);
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(_law.fileUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
                _nightMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            tooltip: _nightMode ? 'Day mode' : 'Night mode',
            onPressed: () => setState(() => _nightMode = !_nightMode),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open externally',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        nightMode: _nightMode,
        fitPolicy: FitPolicy.WIDTH,
        fitEachPage: true,
        onViewCreated: (PDFViewController controller) {
          _pdfController = controller;
        },
        onRender: (pages) {
          if (mounted) {
            setState(() {
              _totalPages = pages ?? 0;
              _ready = true;
            });
          }
        },
        onPageChanged: (page, total) {
          if (mounted) {
            setState(() {
              _currentPage = page ?? 0;
              if (total != null) _totalPages = total;
            });
          }
        },
      ).cachedFromUrl(
        _law.fileUrl,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress / 100 : null,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading document… ${progress.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        errorWidget: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  'Could not load document',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open in browser'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ready && _totalPages > 0
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous page',
                      onPressed: _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next page',
                      onPressed: _currentPage < _totalPages - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
