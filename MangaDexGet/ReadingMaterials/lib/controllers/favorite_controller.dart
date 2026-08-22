import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';

class FavoriteController extends GetxController {
  var favoriteMangaIds = <String>[].obs;
  var favoriteMangaDetails = <MangaModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites({bool isRefresh = false}) async {
    if (!isRefresh) isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(AppConstants.likedMangaKey) ?? [];
      favoriteMangaIds.assignAll(ids);
      await fetchFavoriteMangaDetails(ids);
    } catch (e) {
      print("Error loading favorites: $e");
    } finally {
      if (!isRefresh) isLoading.value = false;
    }
  }

  Future<void> fetchFavoriteMangaDetails(List<String> ids) async {
    if (ids.isEmpty) {
      favoriteMangaDetails.clear();
      return;
    }
    
    try {
      // Chunking if ids > 100 (MangaDex limit is 100)
      List<MangaModel> allManga = [];
      for (var i = 0; i < ids.length; i += 100) {
        var end = (i + 100 < ids.length) ? i + 100 : ids.length;
        var chunk = ids.sublist(i, end);
        var fetched = await MangaRepository.getMangaListByIds(chunk);
        allManga.addAll(fetched);
      }
      
      // Restore the order as MangaDex might not return them in the requested order
      List<MangaModel> orderedManga = [];
      for (String id in ids) {
        final manga = allManga.firstWhereOrNull((m) => m.id == id);
        if (manga != null) {
          orderedManga.add(manga);
        }
      }
      
      favoriteMangaDetails.assignAll(orderedManga);
    } catch (e) {
      print("Error fetching batch details for favorites: $e");
    }
  }

  Future<void> saveFavoritesOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.likedMangaKey, favoriteMangaIds);
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = favoriteMangaDetails.removeAt(oldIndex);
    favoriteMangaDetails.insert(newIndex, item);

    final id = favoriteMangaIds.removeAt(oldIndex);
    favoriteMangaIds.insert(newIndex, id);

    saveFavoritesOrder();
  }
}
