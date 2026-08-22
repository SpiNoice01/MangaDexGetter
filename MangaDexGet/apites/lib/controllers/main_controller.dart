import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:apites/services/favorite_service.dart';

class MainController extends GetxController {
  final int pageSize = 10;
  final PagingController<int, MangaModel> pagingController = PagingController(firstPageKey: 0);
  
  var popularMangaList = <MangaModel>[].obs;
  var favoriteMangaList = <MangaModel>[].obs;
  final FavoriteService favService = Get.find<FavoriteService>();

  @override
  void onInit() {
    super.onInit();
    fetchPopularManga();
    fetchFavoriteManga();
    pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    
    // Auto sync when favorites change globally
    ever(favService.favoriteIds, (_) {
      fetchFavoriteManga();
    });
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  // Handle Pagination Data
  Future<void> _fetchPage(int pageKey) async {
    try {
      if (pageKey == 0) {
        // Load from cache initially for smooth UX
        final cachedData = await _getMangaListFromCache();
        if (cachedData != null && cachedData.isNotEmpty) {
           // We don't append it to pagination directly to avoid duplicates when API returns, 
           // but we can set it to the list temporarily.
           pagingController.itemList = cachedData;
        }
      }

      final newItems = await MangaRepository.getMangaList(
        title: "",
        limit: pageSize,
        offset: pageKey,
      );

      if (pageKey == 0) {
        await _saveMangaListToCache(newItems);
        // Replace cache completely instead of appending
        final nextPageKey = newItems.length < pageSize ? null : pageKey + newItems.length;
        pagingController.value = PagingState(
          nextPageKey: nextPageKey,
          itemList: newItems,
        );
        return;
      }

      final isLastPage = newItems.length < pageSize;
      if (isLastPage) {
        pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      pagingController.error = error;
    }
  }

  Future<void> refreshPage() async {
    fetchPopularManga();
    fetchFavoriteManga();
    pagingController.refresh();
  }

  Future<void> fetchPopularManga() async {
    try {
      final popular = await MangaRepository.getPopularManga();
      popularMangaList.assignAll(popular);
    } catch (e) {
      print("Error fetching popular manga: $e");
    }
  }

  Future<void> fetchFavoriteManga() async {
    try {
      final likedMangaIds = favService.favoriteIds.toList();
      
      if (likedMangaIds.isEmpty) {
        favoriteMangaList.clear();
        return;
      }

      // Batch fetch up to 100 (for main screen preview, maybe we just fetch the first 20)
      final idsToFetch = likedMangaIds.take(20).toList();
      final fetched = await MangaRepository.getMangaListByIds(idsToFetch);
      
      // Preserve order
      List<MangaModel> orderedManga = [];
      for (String id in idsToFetch) {
        final manga = fetched.firstWhereOrNull((m) => m.id == id);
        if (manga != null) orderedManga.add(manga);
      }
      
      favoriteMangaList.assignAll(orderedManga);
    } catch (e) {
      print("Error fetching favorite manga: $e");
    }
  }

  // Removed old toggleFavorite and isFavorite as they are now in FavoriteService

  // --- Cache Helpers ---
  Future<void> _saveMangaListToCache(List<MangaModel> mangaList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = mangaList.map((m) => m.toJson()).toList();
    await prefs.setString(AppConstants.cachedMangaListKey, jsonEncode(jsonList));
  }

  Future<List<MangaModel>?> _getMangaListFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final mangaListString = prefs.getString(AppConstants.cachedMangaListKey);
    if (mangaListString != null) {
      final List<dynamic> jsonList = jsonDecode(mangaListString);
      return jsonList.map((json) => MangaModel.fromJson(json)).toList();
    }
    return null;
  }
}
