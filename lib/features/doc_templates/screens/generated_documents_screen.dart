import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../controllers/generated_documents_controller.dart';
import '../models/generated_document_model.dart';
import '../../../config/dio_config.dart';

class GeneratedDocumentsScreen extends StatelessWidget {
  const GeneratedDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GeneratedDocumentsController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.documents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty && controller.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading documents',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.error.value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No documents yet',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate your first document from templates',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.documents.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.documents.length) {
                // Load more indicator
                controller.loadMore();
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final document = controller.documents[index];
              return _DocumentCard(document: document);
            },
          ),
        );
      }),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final GeneratedDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.documentTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.language == 'sw'
                            ? document.templateNameSw
                            : document.templateName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: document.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  document.getFormattedDate(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.language, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  document.language.toUpperCase(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                if (document.downloadCount > 0) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.download, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${document.downloadCount}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (document.status == 'completed') ...[
              const SizedBox(height: 16),
              if (document.isFree)
                _DownloadButton(document: document)
              else
                _PayButton(document: document),
            ],
            if (document.status == 'failed' &&
                document.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.errorMessage!,
                        style:
                            TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final GeneratedDocument document;

  const _DownloadButton({required this.document});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _isDownloading = false;
  double _progress = 0;

  Future<String> _getDownloadPath() async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Try to use external storage Downloads folder for Android
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to app's external storage
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // Use documents directory for iOS
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version - Android 10+ has scoped storage
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      // For Android 13+, we need different permissions
      if (await Permission.manageExternalStorage.isGranted) return true;
      
      // Request permission
      final result = await Permission.storage.request();
      if (result.isGranted) return true;
      
      // Try manage external storage for Android 11+
      final manageResult = await Permission.manageExternalStorage.request();
      return manageResult.isGranted;
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (widget.document.downloadUrl == null) {
      _showError(context, 'Download URL not available');
      return;
    }

    // Request permission first
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showError(context, 'Storage permission is required to download files');
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final dio = DioConfig.instance;
      final downloadPath = await _getDownloadPath();
      
      // Create filename from document title or use a default
      final fileName = '${widget.document.documentTitle.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final filePath = '$downloadPath/$fileName';
      
      debugPrint('📥 Downloading to: $filePath');
      debugPrint('📥 From URL: ${widget.document.downloadUrl}');

      await dio.download(
        widget.document.downloadUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _progress = 0;
      });

      if (!context.mounted) return;

      // Show success and offer to open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () async {
              final result = await OpenFilex.open(filePath);
              if (result.type != ResultType.done) {
                debugPrint('❌ Could not open file: ${result.message}');
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } on DioException catch (e) {
      setState(() {
        _isDownloading = false;
        _progress = 0;
      });
      debugPrint('❌ Dio error downloading: ${e.message}');
      _showError(context, 'Download failed: ${e.message}');
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _progress = 0;
      });
      debugPrint('❌ Error downloading: $e');
      _showError(context, 'Download failed: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _isDownloading
          ? Column(
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: () => _downloadDocument(context),
              icon: const Icon(Icons.download),
              label: const Text('Download FREE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
    );
  }
}

class _PayButton extends StatelessWidget {
  final GeneratedDocument document;

  const _PayButton({required this.document});

  void _initiatePayment(BuildContext context) {
    // TODO: Implement payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment flow for TZS ${document.paymentAmount}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _initiatePayment(context),
        icon: const Icon(Icons.payment),
        label: Text('Pay TZS ${document.paymentAmount} to Download'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
