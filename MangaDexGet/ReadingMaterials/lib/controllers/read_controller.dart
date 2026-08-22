import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/chapter_model.dart';
import 'package:apites/repositories/manga_repository.dart';
import 'package:flutter/services.dart';

class ReadController extends GetxController {
  final String mangaId;
  String? chapterId;
  final String? translatedLanguage;

  ReadController({required this.mangaId, this.chapterId, this.translatedLanguage});

  var pages = <String>[].obs;
  var isLoading = true.obs;
  var currentPage = 0.obs;
  
  var isVerticalScrollMode = false.obs;

  // Vertical scroll progress tracking
  late ScrollController verticalScrollController;
  var scrollProgress = 0.0.obs; // 0.0 - 1.0 through the chapter
  var isScrollBarVisible = false.obs;
  var showVerticalOverlay = true.obs; // persisted user preference
  var showVerticalPageNumber = true.obs; // persisted user preference
  Timer? _hideScrollBarTimer;

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
    verticalScrollController = ScrollController()..addListener(_onVerticalScroll);
    _hideSystemUI();
    fetchMangaPages();
    _loadVerticalOverlayPreference();
  }

  Future<void> _loadVerticalOverlayPreference() async {
    final prefs = await SharedPreferences.getInstance();
    showVerticalOverlay.value = prefs.getBool(AppConstants.showVerticalReadOverlayKey) ?? true;
    showVerticalPageNumber.value = prefs.getBool(AppConstants.showVerticalPageNumberKey) ?? true;
  }

  Future<void> setVerticalOverlayVisible(bool value) async {
    showVerticalOverlay.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.showVerticalReadOverlayKey, value);
  }

  Future<void> setVerticalPageNumberVisible(bool value) async {
    showVerticalPageNumber.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.showVerticalPageNumberKey, value);
  }

  @override
  void onClose() {
    pageController.dispose();
    verticalScrollController.dispose();
    _hideScrollBarTimer?.cancel();
    _showSystemUI();
    super.onClose();
  }

  void _onVerticalScroll() {
    if (!verticalScrollController.hasClients) return;
    final position = verticalScrollController.position;
    final maxScroll = position.maxScrollExtent;
    final progress = maxScroll > 0 ? (position.pixels / maxScroll).clamp(0.0, 1.0) : 0.0;
    scrollProgress.value = progress;

    if (pages.isNotEmpty) {
      final estimatedPage = (progress * pages.length).floor().clamp(0, pages.length - 1);
      currentPage.value = estimatedPage;
    }

    _revealScrollBar();
  }

  void _revealScrollBar() {
    isScrollBarVisible.value = true;
    _hideScrollBarTimer?.cancel();
    _hideScrollBarTimer = Timer(const Duration(milliseconds: 1200), () {
      isScrollBarVisible.value = false;
    });
  }

  // Jump to an approximate scroll position for [index] (page heights vary,
  // so this mirrors the same proportional estimate used for scrollProgress).
  void jumpToPage(int index) {
    if (!verticalScrollController.hasClients || pages.isEmpty) return;
    final maxScroll = verticalScrollController.position.maxScrollExtent;
    final target = (maxScroll * (index / pages.length)).clamp(0.0, maxScroll);
    verticalScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _revealScrollBar();
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
        final chapters = (await MangaRepository.getMangaChapters(mangaId, limit: 1, offset: 0, translatedLanguage: translatedLanguage ?? 'en')).items;
        if (chapters.isNotEmpty) {
          chapterId = chapters.first['id'];
        }
      }

      if (chapterId != null) {
        final chapterData = await MangaRepository.getChapterDetails(chapterId!);
        final chapterModel = ChapterModel.fromJson(chapterData);

        final fetchedPages = await MangaRepository.getChapterPages(chapterId!);
        final nextChapter = await MangaRepository.getNextChapter(mangaId, chapterId!, translatedLanguage: translatedLanguage ?? 'en');

        pages.assignAll(fetchedPages);
        
        // Pre-cache first 3 pages
        if (Get.context != null) {
          for (int i = 0; i < (pages.length > 3 ? 3 : pages.length); i++) {
            precacheImage(NetworkImage(pages[i]), Get.context!);
          }
        }
        chapterTitle.value = chapterModel.title;
        chapterNumber.value = chapterModel.chapter;
        nextChapterId.value = nextChapter?['id'];
        
        await saveBookmark(mangaId, chapterId!, chapterModel.chapter);
        
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
      await MangaRepository.getChapterPages(nextId);
    } catch (e) {
      // Ignore errors for preloading
    }
  }

  Future<void> refreshPages() async {
    await fetchMangaPages();
  }

  void onPageChanged(int index) {
    // index == pages.length is the "End of Chapter" pseudo-page; keep the
    // counter pinned at the last real page instead of counting it.
    if (index < pages.length) {
      currentPage.value = index;
    }

    // Auto-hide System UI when scrolling
    _hideSystemUI();
    
    // Precache the next 2 pages to make reading perfectly smooth
    if (Get.context != null) {
      if (index + 1 < pages.length) precacheImage(NetworkImage(pages[index + 1]), Get.context!);
      if (index + 2 < pages.length) precacheImage(NetworkImage(pages[index + 2]), Get.context!);
    }
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

  void showSettingsBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2F33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reading Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Theme', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _themeButton('Dark', const Color(0xFF2C2F33)),
                _themeButton('Light', const Color.fromARGB(255, 217, 217, 217)),
                _themeButton('Sepia', const Color.fromARGB(255, 195, 169, 128)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Scroll Mode', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Obx(() => Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isVerticalScrollMode.value ? const Color(0xFFFF6444) : const Color(0xFF3F4349),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      isVerticalScrollMode.value = false;
                      Get.back();
                    },
                    child: const Text('Horizontal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerticalScrollMode.value ? const Color(0xFFFF6444) : const Color(0xFF3F4349),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      isVerticalScrollMode.value = true;
                      Get.back();
                    },
                    child: const Text('Vertical'),
                  ),
                ),
              ],
            )),
            Obx(() {
              if (!isVerticalScrollMode.value) return const SizedBox(height: 8);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text('Progress Overlay', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: const Color(0xFFFF6444),
                    title: const Text('Show progress bar', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'The clickable segment bar on the left edge',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: showVerticalOverlay.value,
                    onChanged: setVerticalOverlayVisible,
                  )),
                  Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: const Color(0xFFFF6444),
                    title: const Text('Show page number', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'The page count stamped at the bottom of each page',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: showVerticalPageNumber.value,
                    onChanged: setVerticalPageNumberVisible,
                  )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _themeButton(String label, Color color) {
    return GestureDetector(
      onTap: () {
        changeTheme(color);
        Get.back();
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
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

  Future<void> saveBookmark(String mangaId, String currentChapterId, String currentChapterNum) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Legacy support fallback update
    await prefs.setString('bookmark_$mangaId', currentChapterId);

    // Save last read
    await prefs.setString('last_read_$mangaId', currentChapterId);
    
    // Save farthest read
    final storedFarthestNumStr = prefs.getString('farthest_read_num_$mangaId');
    double storedFarthestNum = -1.0;
    if (storedFarthestNumStr != null) {
      storedFarthestNum = double.tryParse(storedFarthestNumStr) ?? -1.0;
    }
    
    double currentNum = double.tryParse(currentChapterNum) ?? -1.0;
    if (currentNum >= storedFarthestNum) {
      await prefs.setString('farthest_read_$mangaId', currentChapterId);
      await prefs.setString('farthest_read_num_$mangaId', currentChapterNum);
    }
    
    // Save history array for checkmarks
    List<String> readChapters = prefs.getStringList('read_chapters_$mangaId') ?? [];
    if (!readChapters.contains(currentChapterId)) {
      readChapters.add(currentChapterId);
      await prefs.setStringList('read_chapters_$mangaId', readChapters);
    }
  }
}
