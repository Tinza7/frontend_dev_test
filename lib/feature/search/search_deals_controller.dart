import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  int _searchGeneration = 0;

  void onQueryChanged(String query) {
    _search(query);
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    if (query.trim().isEmpty) {
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final found = await dealRepo.search(query);
      if (generation != _searchGeneration) return;
      results.assignAll(found);
    } catch (e) {
      LogService.error('search failed', e);
    } finally {
      if (generation == _searchGeneration) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _searchGeneration++;
    super.onClose();
  }
}
