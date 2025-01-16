import 'package:apites/collection/colors.dart';
import 'package:flutter/material.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:apites/pages/read/read_manga.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:apites/pages/detail/manga_details_header.dart';
import 'package:apites/pages/detail/manga_chapters_list.dart';
import 'package:get/get.dart'; // Tambahkan ini

class DetailScreen extends StatefulWidget {
  final String mangaId;

  const DetailScreen({super.key, required this.mangaId});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? mangaDetails;
  Map<String, dynamic>? authorDetails;
  List<Map<String, dynamic>> chapters = [];
  bool isLoadingMore = false;
  bool isError = false;
  bool isChapterError = false;
  bool isLiked = false;
  String? bookmarkedChapterId;
  String? bookmarkedChapterTitle;
  int currentPage = 0;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMangaDetails();
    _scrollController.addListener(_scrollListener);
    checkIfLiked();
    getBookmark();
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
    bool isFavorite;
    if (isLiked) {
      likedManga.remove(widget.mangaId);
      isFavorite = false;
    } else {
      likedManga.add(widget.mangaId);
      isFavorite = true;
    }
    await prefs.setStringList('likedManga', likedManga);
    setState(() {
      isLiked = !isLiked;
    });

    // Show GetX Snackbar at the top
    Get.snackbar(
      margin: const EdgeInsets.all(40),
      isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
      isFavorite
          ? 'Manga has been added to your favorites.'
          : 'Manga has been removed from your favorites.',
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.all(30),
      backgroundColor: Colors.black.withOpacity(0.7),
      duration: const Duration(milliseconds: 800),
      colorText: Colors.white,
    );
  }

  Future<void> saveMangaDetailsToCache(
      Map<String, dynamic> mangaDetails) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'mangaDetails_${widget.mangaId}', jsonEncode(mangaDetails));
  }

  Future<Map<String, dynamic>?> getMangaDetailsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final mangaDetailsString =
        prefs.getString('mangaDetails_${widget.mangaId}');
    if (mangaDetailsString != null) {
      return jsonDecode(mangaDetailsString);
    }
    return null;
  }

  Future<void> fetchMangaDetails() async {
    try {
      final cachedMangaDetails = await getMangaDetailsFromCache();
      if (cachedMangaDetails != null) {
        setState(() {
          mangaDetails = cachedMangaDetails;
        });
      }

      final manga = await MangaDexService.getMangaDetails(widget.mangaId);
      setState(() {
        mangaDetails = manga;
        isError = false;
      });
      await saveMangaDetailsToCache(manga);
      fetchAuthorDetails(manga['relationships']);
      fetchChapters(0);
    } catch (e) {
      setState(() {
        isError = true;
      });
      print("Error fetching manga details: $e");
    }
  }

  Future<void> fetchAuthorDetails(List<dynamic> relationships) async {
    try {
      final authorRelationship = relationships
          .firstWhere((rel) => rel['type'] == 'author', orElse: () => null);
      if (authorRelationship != null) {
        final authorId = authorRelationship['id'];
        final author = await MangaDexService.getAuthorDetails(authorId);
        setState(() {
          authorDetails = author;
        });
      }
    } catch (e) {
      print("Error fetching author details: $e");
    }
  }

  Future<void> fetchChapters(int page) async {
    try {
      if (page == 0) {
        setState(() {
          chapters = [];
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final newChapters = await MangaDexService.getMangaChapters(
        widget.mangaId,
        limit: limit,
        offset: page * limit,
      );
      final chaptersWithDetails =
          await Future.wait(newChapters.map((chapter) async {
        final chapterDetails =
            await MangaDexService.getChapterDetails(chapter['id']);
        return {
          ...chapter,
          'pageCount': chapterDetails['attributes']['pages'] ?? 'Unknown',
        };
      }));

      setState(() {
        if (page == 0) {
          chapters = chaptersWithDetails;
        } else {
          chapters.addAll(chaptersWithDetails);
        }
        isLoadingMore = false;
        isChapterError = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
        isChapterError = true;
      });
      print("Error fetching chapters: $e");
    }
  }

  Future<void> getBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final chapterId = prefs.getString('bookmark_${widget.mangaId}');
    if (chapterId != null) {
      final chapterDetails = await MangaDexService.getChapterDetails(chapterId);
      setState(() {
        bookmarkedChapterId = chapterId;
        bookmarkedChapterTitle = chapterDetails['attributes']['title'] ??
            'Chapter ${chapterDetails['attributes']['chapter']}';
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        currentPage++;
      });
      fetchChapters(currentPage);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      currentPage = 0;
      isError = false;
      isChapterError = false;
      mangaDetails = null;
      authorDetails = null;
      chapters = [];
    });
    await fetchMangaDetails();
    await getBookmark();
    await checkIfLiked();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manga Details',
          style: TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: _refresh,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isError)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading manga details',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (mangaDetails == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  MangaDetailsHeader(
                    mangaDetails: mangaDetails!,
                    authorDetails: authorDetails,
                    isLiked: isLiked,
                    toggleLike: toggleLike,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadMangaScreen(
                            mangaId: widget.mangaId,
                            chapterId: bookmarkedChapterId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mangaDex,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(bookmarkedChapterId != null
                        ? 'Continue Reading, \n$bookmarkedChapterTitle'
                        : 'Start Reading'),
                  ),
                  const SizedBox(height: 16),
                  MangaChaptersList(
                    chapters: chapters,
                    isLoadingMore: isLoadingMore,
                    isChapterError: isChapterError,
                    currentPage: currentPage,
                    fetchChapters: fetchChapters,
                    mangaId: widget.mangaId,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
