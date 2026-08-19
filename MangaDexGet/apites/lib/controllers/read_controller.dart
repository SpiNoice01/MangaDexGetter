import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/chapter_model.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:flutter/services.dart';

class ReadController extends GetxController {
  final String mangaId;
  String? chapterId;

  ReadController({required this.mangaId, this.chapterId});

  var pages = <String>[].obs;
  var isLoading = true.obs;
  var currentPage = 0.obs;
  
  var isVerticalScrollMode = false.obs;
  
  var chapterTitle = ''.obs;
  var chapterNumber = ''.obs;
  var nextChapterId = RxnString();
  
  // Theming
  var backgroundColor = const Color(0xFF2C2F33).obs;
  var appBarColor = const Color(0xFF2C2F33).obs;
  var textColor = const Color.fromARGB(255, 203, 203, 203).obs;
  var iconColor = const Color.fromARGB(255, 185, 184, 184).obs;

  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentPage.value);
    _hideSystemUI();
    fetchMangaPages();
  }

  @override
  void onClose() {
    pageController.dispose();
    _showSystemUI();
    super.onClose();
  }
  
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> fetchMangaPages() async {
    isLoading.value = true;
    try {
      if (chapterId == null) {
        final chapters = await MangaDexService.getMangaChapters(mangaId, limit: 1, offset: 0);
        if (chapters.isNotEmpty) {
          chapterId = chapters.first['id'];
        }
      }

      if (chapterId != null) {
        final chapterData = await MangaDexService.getChapterDetails(chapterId!);
        final chapterModel = ChapterModel.fromJson(chapterData);
        
        final fetchedPages = await MangaDexService.getChapterPages(chapterId!);
        final nextChapter = await MangaDexService.getNextChapter(mangaId, chapterId!);

        pages.assignAll(fetchedPages);
        chapterTitle.value = chapterModel.title;
        chapterNumber.value = chapterModel.chapter;
        nextChapterId.value = nextChapter?['id'];
        
        await saveBookmark(mangaId, chapterId!);
        
        // Background task to preload next chapter if it exists
        if (nextChapterId.value != null) {
          _preloadNextChapter(nextChapterId.value!);
        }
      }
    } catch (e) {
      print("Error fetching manga pages: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _preloadNextChapter(String nextId) async {
    try {
      // Just fetch the links so they are cached in the HTTP client level
      // Actual image pre-caching can be done via precacheImage in the UI layer if needed
      await MangaDexService.getChapterPages(nextId);
    } catch (e) {
      // Ignore errors for preloading
    }
  }

  Future<void> refreshPages() async {
    await fetchMangaPages();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    
    // Auto-hide System UI when scrolling
    _hideSystemUI();
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void toggleScrollMode() {
    isVerticalScrollMode.value = !isVerticalScrollMode.value;
  }

  void changeTheme(Color color) {
    backgroundColor.value = color;
    appBarColor.value = color.withValues(alpha: 0.8);
    
    if (color == const Color.fromARGB(255, 217, 217, 217) ||
        color == const Color.fromARGB(255, 195, 169, 128)) {
      textColor.value = const Color.fromARGB(255, 36, 36, 36);
      iconColor.value = const Color.fromARGB(255, 36, 36, 36);
    } else {
      // Default Dark Theme colors
      textColor.value = const Color.fromARGB(255, 203, 203, 203);
      iconColor.value = const Color.fromARGB(255, 185, 184, 184);
    }
  }

  void readNextChapter() {
    if (nextChapterId.value != null) {
      // Reset state for new chapter
      chapterId = nextChapterId.value;
      currentPage.value = 0;
      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }
      fetchMangaPages();
    }
  }

  // Favorite logic is now handled by FavoriteButton and FavoriteService

  Future<void> saveBookmark(String mangaId, String currentChapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmark_$mangaId', currentChapterId);
  }
}
