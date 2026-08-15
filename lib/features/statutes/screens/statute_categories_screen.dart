import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/statutes_controller.dart';

class StatuteCategoriesScreen extends StatelessWidget {
  const StatuteCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatutesController());
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.categories.isEmpty && !controller.isLoadingCategories.value) {
        controller.loadCategories();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isSwahili
            ? 'Sheria za Nchi ya Tanzania'
            : 'Tanzania Statutes & Laws'),
      ),
      body: Obx(() {
        if (controller.isLoadingCategories.value && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categoriesError.value.isNotEmpty &&
            controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(controller.categoriesError.value,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadCategories,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (controller.categories.isEmpty) {
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
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.gavel, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    cat.localizedName(swahili: controller.isSwahili),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    cat.localizedDescription(swahili: controller.isSwahili)
                            .isEmpty
                        ? (controller.isSwahili
                            ? '${cat.statutesCount} sheria'
                            : '${cat.statutesCount} laws')
                        : cat.localizedDescription(
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
                  onTap: () => controller.openCategory(cat),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
