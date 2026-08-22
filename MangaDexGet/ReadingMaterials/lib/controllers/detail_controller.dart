import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';
import 'package:apites/services/history_service.dart';

class DetailController extends GetxController {
  final String mangaId;

  var mangaDetails = Rxn<MangaModel>();
  var authorName = 'Unknown'.obs;
  var chapters = <Map<String, dynamic>>[].obs;

  var isLoadingChapters = false.obs;
  var isError = false.obs;
  var isChapterError = false.obs;

  var lastReadChapterId = RxnString();
  var lastReadChapterTitle = RxnString();
  var farthestReadChapterId = RxnString();
  var farthestReadChapterTitle = RxnString();
  var readChapters = <String>[].obs;

  final Map<String, GlobalKey> chapterKeys = {};

  var currentPage = 0.obs; // 0-indexed
  var totalChapterCount = 0.obs;
  final int limit = 25;
  var isAscending = true.obs;
  var selectedLanguage = 'en'.obs;

  int get totalPages => totalChapterCount.value <= 0 ? 1 : (totalChapterCount.value / limit).ceil();

  DetailController({required this.mangaId});

  @override
  void onInit() {
    super.onInit();
    fetchMangaDetails();
    loadReadHistory();
    Get.find<HistoryService>().recordView(mangaId);
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

  // Chapters are paginated 25 at a time (page is 0-indexed); each call
  // replaces the currently displayed page rather than appending to it.
  Future<void> fetchChapters(int page) async {
    isLoadingChapters.value = true;
    chapterKeys.clear();
    try {
      final result = await MangaRepository.getMangaChapters(
        mangaId,
        limit: limit,
        offset: page * limit,
        isAscending: isAscending.value,
        translatedLanguage: selectedLanguage.value,
      );

      // The feed response already includes the page count per chapter, so there's
      // no need for an extra /chapter/{id} request per item here.
      final chaptersWithDetails = result.items.map((chapter) {
        return {
          ...chapter,
          'pageCount': chapter['attributes']?['pages'] ?? 'Unknown',
        };
      }).toList();

      chapters.assignAll(chaptersWithDetails);
      totalChapterCount.value = result.total;
      currentPage.value = page;

      isChapterError.value = false;
    } catch (e) {
      isChapterError.value = true;
      print("Error fetching chapters: $e");
    } finally {
      isLoadingChapters.value = false;
    }
  }

  void toggleSortOrder() {
    isAscending.value = !isAscending.value;
    fetchChapters(0);
  }

  void changeLanguage(String lang) {
    selectedLanguage.value = lang;
    fetchChapters(0);
  }

  void nextPage() {
    if (currentPage.value + 1 < totalPages) fetchChapters(currentPage.value + 1);
  }

  void previousPage() {
    if (currentPage.value > 0) fetchChapters(currentPage.value - 1);
  }

  void goToPage(int page) {
    if (page < 0 || page >= totalPages || page == currentPage.value) return;
    fetchChapters(page);
  }

  // Jumps to a chapter that may be on a different page than the one
  // currently displayed: resolve its position in the full ordered chapter
  // list, switch to the page it falls on, then scroll it into view.
  Future<void> jumpToChapter(String chapterId) async {
    final existingKey = chapterKeys[chapterId];
    if (existingKey != null && existingKey.currentContext != null) {
      _scrollToKey(existingKey);
      return;
    }

    final index = await _resolveChapterIndex(chapterId);
    if (index == null) {
      Get.snackbar(
        'Chapter Not Found',
        'Could not locate that chapter with the current language filter.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF000000).withValues(alpha: 0.7),
        colorText: Colors.white,
      );
      return;
    }

    final page = index ~/ limit;
    await fetchChapters(page);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = chapterKeys[chapterId];
      if (key != null && key.currentContext != null) {
        _scrollToKey(key);
      }
    });
  }

  void _scrollToKey(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.1, // Align slightly below the top edge
    );
  }

  // Finds [chapterId]'s position in the full ordered chapter list by
  // paging through the feed in large batches. A rare, one-off lookup
  // (only run when jumping to a chapter outside the current page).
  Future<int?> _resolveChapterIndex(String chapterId) async {
    const batchSize = 500;
    int offset = 0;
    while (true) {
      final result = await MangaRepository.getMangaChapters(
        mangaId,
        limit: batchSize,
        offset: offset,
        isAscending: isAscending.value,
        translatedLanguage: selectedLanguage.value,
      );
      final localIndex = result.items.indexWhere((c) => c['id'] == chapterId);
      if (localIndex != -1) return offset + localIndex;

      offset += result.items.length;
      if (result.items.isEmpty || offset >= result.total) return null;
    }
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
    isError.value = false;
    isChapterError.value = false;
    authorName.value = 'Unknown';
    chapterKeys.clear();

    await fetchMangaDetails(); // fetchMangaDetails triggers fetchChapters(0)
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
