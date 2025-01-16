import 'package:flutter/material.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:apites/pages/search/search_manga.dart';
import 'package:apites/pages/favorite/favorite_screen.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:apites/collection/colors.dart';
import 'package:apites/pages/main/carousel_slider_widget.dart';
import 'package:apites/pages/main/favorite_manga_list.dart';
import 'package:apites/pages/main/manga_card.dart';
import 'package:apites/pages/main/popular_carousel.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _pageSize = 10;
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _popularMangaList = [];
  List<Map<String, dynamic>> _favoriteMangaList = [];

  @override
  void initState() {
    super.initState();
    fetchMangaList();
    fetchPopularManga();
    fetchFavoriteManga();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> saveMangaListToCache(
      List<Map<String, dynamic>> mangaList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mangaList', jsonEncode(mangaList));
  }

  Future<List<Map<String, dynamic>>?> getMangaListFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final mangaListString = prefs.getString('mangaList');
    if (mangaListString != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(mangaListString));
    }
    return null;
  }

  Future<void> fetchMangaList() async {
    try {
      final cachedMangaList = await getMangaListFromCache();
      if (cachedMangaList != null) {
        _pagingController.itemList = cachedMangaList;
      }

      final newItems = await MangaDexService.getMangaList(
        title: "",
        limit: _pageSize,
        offset: 0,
      );
      _pagingController.itemList = newItems;
      await saveMangaListToCache(newItems);
    } catch (e) {
      print("Error fetching manga list: $e");
    }
  }

  Future<void> fetchPopularManga() async {
    try {
      final popularManga = await MangaDexService.getPopularManga();
      setState(() {
        _popularMangaList = popularManga;
      });
    } catch (e) {
      print("Error fetching popular manga: $e");
    }
  }

  Future<void> _refreshPage() async {
    _pagingController.refresh();
  }

  Future<void> fetchFavoriteManga() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedMangaIds = prefs.getStringList('likedManga') ?? [];
      List<Map<String, dynamic>> favoriteManga = [];
      for (String id in likedMangaIds) {
        final manga = await MangaDexService.getMangaDetails(id);
        favoriteManga.add(manga);
      }
      setState(() {
        _favoriteMangaList = favoriteManga;
      });
    } catch (e) {
      print("Error fetching favorite manga: $e");
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await MangaDexService.getMangaList(
        title: "",
        limit: _pageSize,
        offset: pageKey,
      );
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> toggleFavorite(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedManga = prefs.getStringList('likedManga') ?? [];
    bool isFavorite;
    if (likedManga.contains(mangaId)) {
      likedManga.remove(mangaId);
      isFavorite = false;
    } else {
      likedManga.add(mangaId);
      isFavorite = true;
    }
    await prefs.setStringList('likedManga', likedManga);
    setState(() {
      fetchFavoriteManga(); // Refresh favorite manga list
    });

    // Show GetX Snackbar at the top
    Get.snackbar(
      margin: const EdgeInsets.all(40),
      isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
      isFavorite
          ? 'Manga has been added to your favorites.'
          : 'Manga has been removed from your favorites.',
      padding: const EdgeInsets.all(30),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<bool> isFavorite(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedManga = prefs.getStringList('likedManga') ?? [];
    return likedManga.contains(mangaId);
  }

  String truncateTitle(String title) {
    const int wordLimit = 1; // Set a default word limit
    List<String> words = title.split(' ');
    if (words.length > wordLimit) {
      return '${words.sublist(0, wordLimit).join(' ')}...';
    }
    return title;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'lib/assets/mangaDex.svg',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'MangaDex',
              style: TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2F33),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.mangaDex),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteScreen(),
                ),
              );
              fetchFavoriteManga(); // Refresh favorite manga list when returning from FavoriteScreen
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward,
                color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: PagedListView<int, Map<String, dynamic>>(
          pagingController: _pagingController,
          scrollController: _scrollController,
          builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
            itemBuilder: (context, manga, index) {
              if (index == 0) {
                return Column(
                  children: [
                    CarouselSliderWidget(
                        mangaList: _pagingController.itemList!),
                    PopularCarousel(popularMangaList: _popularMangaList),
                    if (_favoriteMangaList.isNotEmpty)
                      FavoriteMangaList(
                        favoriteMangaList: _favoriteMangaList,
                        truncateTitle: truncateTitle,
                      ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Just uploaded',
                          style: TextStyle(
                            color: Color.fromARGB(255, 226, 226, 226),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return MangaCard(
                  manga: manga,
                  isFavorite: isFavorite,
                  toggleFavorite: toggleFavorite,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
