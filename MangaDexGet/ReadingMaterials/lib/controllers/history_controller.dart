import 'package:get/get.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';
import 'package:apites/services/history_service.dart';

class HistoryController extends GetxController {
  final HistoryService historyService = Get.find<HistoryService>();

  var historyMangaDetails = <MangaModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory({bool isRefresh = false}) async {
    if (!isRefresh) isLoading.value = true;
    try {
      final ids = historyService.historyIds.toList();
      if (ids.isEmpty) {
        historyMangaDetails.clear();
        return;
      }

      // Chunking if ids > 100 (MangaDex limit is 100)
      List<MangaModel> allManga = [];
      for (var i = 0; i < ids.length; i += 100) {
        var end = (i + 100 < ids.length) ? i + 100 : ids.length;
        var fetched = await MangaRepository.getMangaListByIds(ids.sublist(i, end));
        allManga.addAll(fetched);
      }

      // Preserve most-recently-viewed-first order
      List<MangaModel> orderedManga = [];
      for (String id in ids) {
        final manga = allManga.firstWhereOrNull((m) => m.id == id);
        if (manga != null) orderedManga.add(manga);
      }

      historyMangaDetails.assignAll(orderedManga);
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      if (!isRefresh) isLoading.value = false;
    }
  }

  Future<void> removeFromHistory(String mangaId) async {
    historyMangaDetails.removeWhere((m) => m.id == mangaId);
    await historyService.removeFromHistory(mangaId);
  }

  Future<void> clearHistory() async {
    historyMangaDetails.clear();
    await historyService.clearHistory();
  }

  Future<void> setTrackingEnabled(bool value) async {
    await historyService.setTrackingEnabled(value);
  }
}
