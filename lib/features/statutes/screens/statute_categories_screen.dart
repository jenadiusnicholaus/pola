import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/statutes_controller.dart';

class StatuteCategoriesScreen extends StatelessWidget {
  const StatuteCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatutesController());
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.categories.length == 0 &&
          !controller.isLoadingCategories.value) {
        controller.loadCategories();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isSwahili
            ? 'Sheria za Nchi ya Tanzania'
            : 'Tanzania Statutes & Laws'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Obx(() {
        if (controller.isLoadingCategories.value &&
            controller.categories.length == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categoriesError.value.isNotEmpty &&
            controller.categories.length == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red),
                SizedBox(height: 12),
                Text(controller.categoriesError.value,
                    textAlign: TextAlign.center),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadCategories,
                  child: Text(tr('Retry')),
                ),
              ],
            ),
          );
        }
        if (controller.categories.length == 0) {
          return Center(
            child: Text(
              controller.isSwahili
                  ? 'Hakuna kategoria bado'
                  : 'No categories yet',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadCategories(refresh: true),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 76,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.gavel,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: Text(
                  cat.localizedName(swahili: controller.isSwahili),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  cat
                          .localizedDescription(swahili: controller.isSwahili)
                          .isEmpty
                      ? (controller.isSwahili
                          ? '${cat.statutesCount} sheria'
                          : '${cat.statutesCount} laws')
                      : cat.localizedDescription(swahili: controller.isSwahili),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                onTap: () => controller.openCategory(cat),
              );
            },
          ),
        );
      }),
    );
  }
}
