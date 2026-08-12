import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/statutes_controller.dart';
import '../models/statute_models.dart';

class StatutePdfScreen extends StatelessWidget {
  const StatutePdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatutesController>();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final law = args['law'] as StatuteLaw;
    final title = law.localizedTitle(swahili: controller.isSwahili);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open externally',
            onPressed: () async {
              final uri = Uri.tryParse(law.fileUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ).cachedFromUrl(
        law.fileUrl,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: progress > 0 ? progress : null),
              const SizedBox(height: 12),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
        errorWidget: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text('Failed to load PDF\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(law.fileUrl);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Open in browser'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
