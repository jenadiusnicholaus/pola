import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/statute_models.dart';
import '../services/statutes_service.dart';

class StatutesController extends GetxController {
  final StatutesService _service = StatutesService();

  final categories = <StatuteCategory>[].obs;
  final laws = <StatuteLaw>[].obs;

  final isLoadingCategories = false.obs;
  final isLoadingLaws = false.obs;
  final isLoadingMoreLaws = false.obs;
  final categoriesError = ''.obs;
  final lawsError = ''.obs;

  final categoryPage = 1.obs;
  final lawPage = 1.obs;
  final hasMoreLaws = false.obs;
  final lawsCount = 0.obs;

  int? selectedCategoryId;
  String selectedCategoryName = '';

  bool get isSwahili {
    final code = Get.locale?.languageCode.toLowerCase() ?? 'en';
    return code.startsWith('sw');
  }

  Future<void> loadCategories({bool refresh = true}) async {
    if (refresh) {
      categoryPage.value = 1;
      categories.value = [];
    }
    isLoadingCategories.value = true;
    categoriesError.value = '';
    try {
      final result = await _service.fetchCategories(page: categoryPage.value);
      categories.value = result.items;
    } catch (e) {
      categoriesError.value = e.toString();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> openCategory(StatuteCategory category) async {
    selectedCategoryId = category.id;
    selectedCategoryName = category.localizedName(swahili: isSwahili);
    lawPage.value = 1;
    laws.value = [];
    await loadLaws(refresh: true);
    Get.toNamed('/statutes/laws', arguments: {
      'categoryId': category.id,
      'categoryName': selectedCategoryName,
    });
  }

  Future<void> loadLaws({bool refresh = false, bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMoreLaws.value || isLoadingMoreLaws.value) return;
      isLoadingMoreLaws.value = true;
      lawPage.value += 1;
    } else {
      if (refresh) {
        lawPage.value = 1;
        laws.value = [];
      }
      isLoadingLaws.value = true;
      lawsError.value = '';
    }

    try {
      final result = await _service.fetchLaws(
        page: lawPage.value,
        categoryId: selectedCategoryId,
      );
      if (loadMore) {
        laws.addAll(result.items);
      } else {
        laws.value = result.items;
      }
      hasMoreLaws.value = result.hasMore;
      lawsCount.value = result.count;
    } catch (e) {
      if (loadMore) {
        lawPage.value = (lawPage.value - 1).clamp(1, 9999);
      }
      lawsError.value = e.toString();
    } finally {
      isLoadingLaws.value = false;
      isLoadingMoreLaws.value = false;
    }
  }

  void openPdf(StatuteLaw law) {
    if (law.fileUrl.isEmpty) {
      Get.snackbar(
        'Error',
        'No PDF available for this law',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    Get.toNamed('/statutes/pdf', arguments: {'law': law});
  }
}
