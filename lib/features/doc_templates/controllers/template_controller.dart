import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/template_model.dart';
import '../services/template_service.dart';

class TemplateController extends GetxController {
  final TemplateService _service = TemplateService();

  var templates = <DocumentTemplate>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  var totalCount = 0.obs;

  // Pagination
  final ScrollController scrollController = ScrollController();
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int currentPage = 1;
  final int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    fetchTemplates();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        loadMore();
      }
    }
  }

  Future<void> fetchTemplates() async {
    try {
      isLoading.value = true;
      error.value = '';
      currentPage = 1;
      hasMore.value = true;

      final response =
          await _service.getTemplates(page: currentPage, pageSize: pageSize);
      templates.value = response['templates'] as List<DocumentTemplate>;
      totalCount.value = response['count'] as int;
      hasMore.value = response['next'] != null;
    } catch (e) {
      error.value = e.toString();
      print('Error fetching templates: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage++;

      final response =
          await _service.getTemplates(page: currentPage, pageSize: pageSize);
      final newTemplates = response['templates'] as List<DocumentTemplate>;
      templates.addAll(newTemplates);
      hasMore.value = response['next'] != null;
    } catch (e) {
      debugPrint('Error loading more templates: $e');
      currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<Map<String, dynamic>?> getTemplateFields({
    required int templateId,
    String language = 'en',
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _service.getTemplateDetail(
        templateId: templateId,
        language: language,
      );
      return result;
    } catch (e) {
      error.value = e.toString();
      print('Error fetching template fields: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> generateDocument({
    required int templateId,
    required Map<String, dynamic> formData,
    String language = 'en',
    String? documentTitle,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _service.generatePDF(
        templateId: templateId,
        formData: formData,
        language: language,
        documentTitle: documentTitle,
      );
      return result;
    } catch (e) {
      error.value = e.toString();
      print('Error generating document: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  List<DocumentTemplate> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
}
