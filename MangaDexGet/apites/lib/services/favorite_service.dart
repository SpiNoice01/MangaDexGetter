import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';

class FavoriteService extends GetxService {
  var favoriteIds = <String>{}.obs;

  Future<FavoriteService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final likedMangaIds = prefs.getStringList(AppConstants.likedMangaKey) ?? [];
    favoriteIds.assignAll(likedMangaIds);
    return this;
  }

  bool isFavorite(String mangaId) {
    return favoriteIds.contains(mangaId);
  }

  Future<bool> toggleFavorite(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedManga = prefs.getStringList(AppConstants.likedMangaKey) ?? [];
    bool isFav;
    
    if (likedManga.contains(mangaId)) {
      likedManga.remove(mangaId);
      favoriteIds.remove(mangaId);
      isFav = false;
    } else {
      likedManga.add(mangaId);
      favoriteIds.add(mangaId);
      isFav = true;
    }
    
    await prefs.setStringList(AppConstants.likedMangaKey, likedManga);
    return isFav;
  }
}
