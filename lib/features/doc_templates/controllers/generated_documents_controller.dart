import 'package:get/get.dart';
import '../models/generated_document_model.dart';
import '../services/template_service.dart';

class GeneratedDocumentsController extends GetxController {
  final TemplateService _service = TemplateService();

  var documents = <GeneratedDocument>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  var totalCount = 0.obs;
  var currentPage = 1.obs;
  var hasMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
  }

  Future<void> fetchDocuments({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        documents.clear();
      }

      isLoading.value = true;
      error.value = '';

      final response =
          await _service.getGeneratedDocuments(page: currentPage.value);

      final newDocuments = response['documents'] as List<GeneratedDocument>;

      if (refresh) {
        documents.value = newDocuments;
      } else {
        documents.addAll(newDocuments);
      }

      totalCount.value = response['count'] as int;
      hasMore.value = response['next'] != null;
    } catch (e) {
      error.value = e.toString();
      print('Error fetching documents: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;

    currentPage.value++;
    await fetchDocuments();
  }

  Future<void> refresh() async {
    await fetchDocuments(refresh: true);
  }
}
