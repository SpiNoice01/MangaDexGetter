import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';

class DetailController extends GetxController {
  final String mangaId;

  var mangaDetails = Rxn<MangaModel>();
  var authorName = 'Unknown'.obs;
  var chapters = <Map<String, dynamic>>[].obs;
  
  var isLoadingMore = false.obs;
  var isError = false.obs;
  var isChapterError = false.obs;
  
  var lastReadChapterId = RxnString();
  var lastReadChapterTitle = RxnString();
  var farthestReadChapterId = RxnString();
  var farthestReadChapterTitle = RxnString();
  var readChapters = <String>[].obs;
  
  final Map<String, GlobalKey> chapterKeys = {};
  
  int currentPage = 0;
  final int limit = 100;
  var isAscending = true.obs;
  var selectedLanguage = 'en'.obs;

  DetailController({required this.mangaId});

  @override
  void onInit() {
    super.onInit();
    fetchMangaDetails();
    loadReadHistory();
  }

  Future<void> fetchMangaDetails() async {
    isError.value = false;
    try {
      final cachedMangaDetails = await _getMangaDetailsFromCache();
      if (cachedMangaDetails != null) {
        mangaDetails.value = cachedMangaDetails;
      }

      final manga = await MangaRepository.getMangaDetails(mangaId);
      mangaDetails.value = manga;
      await _saveMangaDetailsToCache(manga);

      if (manga.authorId != null) {
        await _fetchAuthorDetails(manga.authorId!);
      }

      fetchChapters(0);
    } catch (e) {
      isError.value = true;
      print("Error fetching manga details: $e");
    }
  }

  Future<void> _fetchAuthorDetails(String authorId) async {
    try {
      final author = await MangaRepository.getAuthorDetails(authorId);
      authorName.value = author['attributes']?['name'] ?? 'Unknown';
    } catch (e) {
      print("Error fetching author details: $e");
    }
  }

  Future<void> fetchChapters(int page) async {
    try {
      if (page == 0) {
        chapters.clear();
      } else {
        isLoadingMore.value = true;
      }

      final newChapters = await MangaRepository.getMangaChapters(
        mangaId,
        limit: limit,
        offset: page * limit,
        isAscending: isAscending.value,
        translatedLanguage: selectedLanguage.value,
      );

      // The feed response already includes the page count per chapter, so there's
      // no need for an extra /chapter/{id} request per item here.
      final chaptersWithDetails = newChapters.map((chapter) {
        return {
          ...chapter,
          'pageCount': chapter['attributes']?['pages'] ?? 'Unknown',
        };
      }).toList();

      if (page == 0) {
        chapters.assignAll(chaptersWithDetails);
      } else {
        chapters.addAll(chaptersWithDetails);
      }
      
      isChapterError.value = false;
    } catch (e) {
      isChapterError.value = true;
      print("Error fetching chapters: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  void toggleSortOrder() {
    isAscending.value = !isAscending.value;
    currentPage = 0;
    chapterKeys.clear();
    fetchChapters(0);
  }

  void changeLanguage(String lang) {
    selectedLanguage.value = lang;
    currentPage = 0;
    chapterKeys.clear();
    fetchChapters(0);
  }

  void jumpToChapter(String chapterId) {
    final key = chapterKeys[chapterId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Align slightly below the top edge
      );
    } else {
      Get.snackbar(
        'Chapter Not Found',
        'The chapter is not currently loaded in the list. Please load more chapters or change the sort order.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF000000).withOpacity(0.7),
        colorText: Colors.white,
      );
    }
  }

  void loadNextPage() {
    currentPage++;
    fetchChapters(currentPage);
  }

  // Favorite logic is now handled by FavoriteButton and FavoriteService

  Future<void> loadReadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastId = prefs.getString('last_read_$mangaId') ?? prefs.getString('bookmark_$mangaId');
    String? farthestId = prefs.getString('farthest_read_$mangaId') ?? prefs.getString('bookmark_$mangaId');
    
    readChapters.assignAll(prefs.getStringList('read_chapters_$mangaId') ?? []);

    if (lastId != null) {
      try {
        final details = await MangaRepository.getChapterDetails(lastId);
        lastReadChapterId.value = lastId;
        lastReadChapterTitle.value = _formatChapterTitle(details);
      } catch (_) {}
    }

    if (farthestId != null && farthestId != lastId) {
      try {
        final details = await MangaRepository.getChapterDetails(farthestId);
        farthestReadChapterId.value = farthestId;
        farthestReadChapterTitle.value = _formatChapterTitle(details);
      } catch (_) {}
    } else if (farthestId != null && farthestId == lastId) {
      farthestReadChapterId.value = lastId;
      farthestReadChapterTitle.value = lastReadChapterTitle.value;
    }
  }

  String _formatChapterTitle(Map<String, dynamic> chapterDetails) {
    final rawTitle = chapterDetails['attributes']['title']?.toString() ?? '';
    final chapterNum = chapterDetails['attributes']['chapter']?.toString() ?? '';
    return rawTitle.isNotEmpty 
        ? rawTitle 
        : (chapterNum.isNotEmpty ? 'Chapter $chapterNum' : 'Oneshot');
  }

  Future<void> refreshData() async {
    currentPage = 0;
    isError.value = false;
    isChapterError.value = false;
    authorName.value = 'Unknown';
    chapterKeys.clear();
    
    await fetchMangaDetails(); // fetchMangaDetails already clears chapters if page == 0
    await loadReadHistory();
  }

  // --- Cache Helpers ---
  Future<void> _saveMangaDetailsToCache(MangaModel manga) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mangaDetails_$mangaId', jsonEncode(manga.toJson()));
  }

  Future<MangaModel?> _getMangaDetailsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mangaDetails_$mangaId');
    if (data != null) {
      return MangaModel.fromJson(jsonDecode(data));
    }
    return null;
  }
}
