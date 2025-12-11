import 'package:get/get.dart';
import '../models/template_model.dart';
import '../services/template_service.dart';

class TemplateController extends GetxController {
  final TemplateService _service = TemplateService();

  var templates = <DocumentTemplate>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  var totalCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await _service.getTemplates();
      templates.value = response['templates'] as List<DocumentTemplate>;
      totalCount.value = response['count'] as int;
    } catch (e) {
      error.value = e.toString();
      print('Error fetching templates: $e');
    } finally {
      isLoading.value = false;
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
