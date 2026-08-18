import 'package:flutter/material.dart';
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
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(controller.lawsError.value, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadLaws(refresh: true),
                  child: const Text('Retry'),
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
            padding: const EdgeInsets.all(16),
            itemCount:
                controller.laws.length + (controller.hasMoreLaws.value ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= controller.laws.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final law = controller.laws[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: Text(
                    law.localizedTitle(swahili: controller.isSwahili),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    law
                            .localizedDescription(swahili: controller.isSwahili)
                            .isEmpty
                        ? '${law.fileSizeMb} MB'
                        : law.localizedDescription(
                            swahili: controller.isSwahili),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    'READ MORE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () => controller.openPdf(law),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
