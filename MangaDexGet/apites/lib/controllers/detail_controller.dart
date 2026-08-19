import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';
import 'package:apites/services/mangadex_services.dart';

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

      // Need to fetch author using old service temporarily because relationships logic is slightly complex
      // In a real scenario we would add it to Repository as well
      final rawMangaData = await MangaDexService.getMangaDetails(mangaId);
      if (rawMangaData['relationships'] != null) {
        await _fetchAuthorDetails(rawMangaData['relationships']);
      }
      
      fetchChapters(0);
    } catch (e) {
      isError.value = true;
      print("Error fetching manga details: $e");
    }
  }

  Future<void> _fetchAuthorDetails(List<dynamic> relationships) async {
    try {
      final authorRelationship = relationships.firstWhere(
          (rel) => rel['type'] == 'author',
          orElse: () => null);
      if (authorRelationship != null) {
        final authorId = authorRelationship['id'];
        final author = await MangaDexService.getAuthorDetails(authorId);
        authorName.value = author['attributes']?['name'] ?? 'Unknown';
      }
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

      final newChapters = await MangaDexService.getMangaChapters(
        mangaId,
        limit: limit,
        offset: page * limit,
        isAscending: isAscending.value,
        translatedLanguage: selectedLanguage.value,
      );
      
      final chaptersWithDetails = await Future.wait(newChapters.map((chapter) async {
        final chapterDetails = await MangaDexService.getChapterDetails(chapter['id']);
        return {
          ...chapter,
          'pageCount': chapterDetails['attributes']['pages'] ?? 'Unknown',
        };
      }));

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
        final details = await MangaDexService.getChapterDetails(lastId);
        lastReadChapterId.value = lastId;
        lastReadChapterTitle.value = _formatChapterTitle(details);
      } catch (_) {}
    }
    
    if (farthestId != null && farthestId != lastId) {
      try {
        final details = await MangaDexService.getChapterDetails(farthestId);
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
