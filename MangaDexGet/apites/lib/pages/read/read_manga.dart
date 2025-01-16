import 'package:flutter/material.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/pages/read/manga_page_viewer.dart';
import 'package:apites/pages/read/manga_navigation_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ReadMangaScreen extends StatefulWidget {
  final String mangaId;
  final String? chapterId;

  const ReadMangaScreen({super.key, required this.mangaId, this.chapterId});

  @override
  _ReadMangaScreenState createState() => _ReadMangaScreenState();
}

class _ReadMangaScreenState extends State<ReadMangaScreen> {
  List<String> pages = [];
  bool isLoading = true;
  int currentPage = 0;
  bool isLiked = false;
  bool isVerticalScrollMode = false;
  String chapterTitle = '';
  String chapterNumber = '';
  Color backgroundColor = const Color(0xFF2C2F33); // Discord black background
  Color appBarColor = const Color(0xFF2C2F33); // Default to white background
  Color textColor =
      const Color.fromARGB(255, 203, 203, 203); // Default to white text
  Color iconColor =
      const Color.fromARGB(255, 185, 184, 184); // Default to white icons
  String? nextChapterId;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPage);
    fetchMangaPages();
    checkIfLiked();
  }

  Future<void> checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final likedManga = prefs.getStringList('likedManga') ?? [];
    setState(() {
      isLiked = likedManga.contains(widget.mangaId);
    });
  }

  Future<void> toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final likedManga = prefs.getStringList('likedManga') ?? [];
    if (isLiked) {
      likedManga.remove(widget.mangaId);
    } else {
      likedManga.add(widget.mangaId);
    }
    await prefs.setStringList('likedManga', likedManga);
    setState(() {
      isLiked = !isLiked;
    });
  }

  Future<void> saveBookmark(String mangaId, String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmark_$mangaId', chapterId);
  }

  Future<void> fetchMangaPages() async {
    try {
      final chapterId = widget.chapterId ??
          (await MangaDexService.getMangaChapters(widget.mangaId,
                  limit: 1, offset: 0))
              .first['id'];
      final chapterDetails = await MangaDexService.getChapterDetails(chapterId);
      final pages = await MangaDexService.getChapterPages(chapterId);
      final nextChapter =
          await MangaDexService.getNextChapter(widget.mangaId, chapterId);
      setState(() {
        this.pages = pages;
        chapterTitle = chapterDetails['attributes']['title'] ??
            'Chapter ${chapterDetails['attributes']['chapter']}';
        chapterNumber = chapterDetails['attributes']['chapter'] ?? '';
        nextChapterId = nextChapter?['id'];
        isLoading = false;
      });
      await saveBookmark(widget.mangaId, chapterId);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching manga pages: $e");
    }
  }

  Future<void> _refresh() async {
    setState(() {
      isLoading = true;
    });
    await fetchMangaPages();
  }

  void _nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      backgroundColor = color;
      appBarColor = color.withOpacity(0.8);
      if (color == const Color.fromARGB(255, 217, 217, 217) ||
          color == const Color.fromARGB(255, 195, 169, 128)) {
        textColor = const Color.fromARGB(255, 36, 36, 36);
        iconColor = const Color.fromARGB(255, 36, 36, 36);
      } else {
        textColor = const Color.fromARGB(255, 124, 124, 124);
        iconColor = const Color.fromARGB(255, 124, 124, 124);
      }
    });
  }

  void _readNextChapter() {
    if (nextChapterId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReadMangaScreen(
            mangaId: widget.mangaId,
            chapterId: nextChapterId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$chapterTitle (Chapter $chapterNumber)',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                color: iconColor),
            onPressed: toggleLike,
          ),
          PopupMenuButton<Color>(
            onSelected: _changeBackgroundColor,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Color.fromARGB(255, 217, 217, 217),
                child: Text('White'),
              ),
              const PopupMenuItem(
                value: Colors.black,
                child: Text('Dark'),
              ),
              const PopupMenuItem(
                value: Color.fromARGB(255, 195, 169, 128),
                child: Text('Warm'),
              ),
            ],
            icon: Icon(Icons.color_lens, color: iconColor),
          ),
          IconButton(
            icon: Icon(
              isVerticalScrollMode ? Icons.view_carousel : Icons.view_stream,
              color: iconColor,
            ),
            onPressed: () {
              setState(() {
                isVerticalScrollMode = !isVerticalScrollMode;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.white,
                size: 50.0,
              ),
            )
          : pages.isEmpty
              ? const Center(child: Text('No pages available'))
              : Container(
                  color: backgroundColor,
                  child: Column(
                    children: [
                      Expanded(
                        child: MangaPageViewer(
                          pages: pages,
                          currentPage: currentPage,
                          pageController: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          nextChapterId: nextChapterId,
                          readNextChapter: _readNextChapter,
                          isVerticalScrollMode: isVerticalScrollMode,
                          onRefresh: _refresh,
                        ),
                      ),
                      if (!isVerticalScrollMode)
                        MangaNavigationBar(
                          currentPage: currentPage,
                          totalPages: pages.length,
                          previousPage: _previousPage,
                          nextPage: _nextPage,
                          iconColor: iconColor,
                          textColor: textColor,
                        ),
                    ],
                  ),
                ),
    );
  }
}
