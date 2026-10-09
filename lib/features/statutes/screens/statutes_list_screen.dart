import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/statutes_controller.dart';

class StatutesListScreen extends StatelessWidget {
  const StatutesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatutesController>();
    final args = Get.arguments;
    if (args is Map) {
      controller.selectedCategoryId = args['categoryId'] as int?;
      controller.selectedCategoryName = (args['categoryName'] ?? '').toString();
    }
    final theme = Theme.of(context);
    final scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadLaws(loadMore: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.laws.length == 0 && !controller.isLoadingLaws.value) {
        controller.loadLaws(refresh: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.selectedCategoryName.isEmpty
            ? (controller.isSwahili ? 'Sheria' : 'Laws')
            : controller.selectedCategoryName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Obx(() {
        if (controller.isLoadingLaws.value && controller.laws.length == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.lawsError.value.isNotEmpty &&
            controller.laws.length == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red),
                SizedBox(height: 12),
                Text(controller.lawsError.value, textAlign: TextAlign.center),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadLaws(refresh: true),
                  child: Text(tr('Retry')),
                ),
              ],
            ),
          );
        }
        if (controller.laws.length == 0) {
          return Center(
            child: Text(
              controller.isSwahili
                  ? 'Hakuna sheria katika kategoria hii'
                  : 'No laws in this category',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadLaws(refresh: true),
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount:
                controller.laws.length + (controller.hasMoreLaws.value ? 1 : 0),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 76,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              if (index >= controller.laws.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final law = controller.laws[index];
              final desc =
                  law.localizedDescription(swahili: controller.isSwahili);
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.picture_as_pdf,
                      color: Colors.red, size: 20),
                ),
                title: Text(
                  law.localizedTitle(swahili: controller.isSwahili),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  desc.isEmpty
                      ? 'PDF • ${law.fileSizeMb} MB'
                      : '$desc • ${law.fileSizeMb} MB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                onTap: () => controller.openPdf(law),
              );
            },
          ),
        );
      }),
    );
  }
}
