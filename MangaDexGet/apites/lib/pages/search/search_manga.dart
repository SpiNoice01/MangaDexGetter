import 'package:flutter/material.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:apites/pages/search/search_bar.dart' as custom;
import 'package:apites/pages/search/genre_sort.dart';
import 'package:apites/pages/search/manga_gridlist.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  String selectedGenre = 'All';
  String selectedSort = 'Relevance';
  final List<String> genres = [
    'All',
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi'
  ];
  final List<String> sortOptions = ['Relevance', 'Rating', 'Newest'];
  final ScrollController _scrollController = ScrollController();
  int currentPage = 0;
  final int pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      loadMoreManga();
    }
  }

  Future<void> searchManga(String query, String genre, String sort) async {
    setState(() {
      isLoading = true;
      currentPage = 0;
      searchResults.clear();
    });
    try {
      List<Map<String, dynamic>> results;
      if (sort == 'Rating') {
        results = await MangaDexService.getMangaListSortedByRating(
            title: query, limit: pageSize, offset: currentPage * pageSize);
      } else {
        results = await MangaDexService.getMangaList(
            title: query, limit: pageSize, offset: currentPage * pageSize);
      }

      setState(() {
        List<Map<String, dynamic>> filteredResults = results;
        if (genre != 'All') {
          filteredResults = results.where((manga) {
            final mangaGenres = (manga['attributes']['tags'] as List<dynamic>)
                .map((tag) => tag['attributes']['name']['en'] as String)
                .toList();
            return mangaGenres.contains(genre);
          }).toList();
        }

        if (sort == 'Newest') {
          filteredResults.sort((a, b) {
            final dateA = DateTime.tryParse(a['attributes']['createdAt']) ??
                DateTime(1970);
            final dateB = DateTime.tryParse(b['attributes']['createdAt']) ??
                DateTime(1970);
            return dateB.compareTo(dateA);
          });
        }

        searchResults = filteredResults;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error searching manga: $e");
    }
  }

  Future<void> _refreshPage() async {
    await searchManga(_searchController.text, selectedGenre, selectedSort);
  }

  Future<void> loadMoreManga() async {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });
    try {
      List<Map<String, dynamic>> results;
      if (selectedSort == 'Rating') {
        results = await MangaDexService.getMangaListSortedByRating(
            title: _searchController.text,
            limit: pageSize,
            offset: (currentPage + 1) * pageSize);
      } else {
        results = await MangaDexService.getMangaList(
            title: _searchController.text,
            limit: pageSize,
            offset: (currentPage + 1) * pageSize);
      }

      setState(() {
        List<Map<String, dynamic>> filteredResults = results;
        if (selectedGenre != 'All') {
          filteredResults = results.where((manga) {
            final mangaGenres = (manga['attributes']['tags'] as List<dynamic>)
                .map((tag) => tag['attributes']['name']['en'] as String)
                .toList();
            return mangaGenres.contains(selectedGenre);
          }).toList();
        }

        if (selectedSort == 'Newest') {
          filteredResults.sort((a, b) {
            final dateA = DateTime.tryParse(a['attributes']['createdAt']) ??
                DateTime(1970);
            final dateB = DateTime.tryParse(b['attributes']['createdAt']) ??
                DateTime(1970);
            return dateB.compareTo(dateA);
          });
        }

        searchResults.addAll(filteredResults);
        currentPage++;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      print("Error loading more manga: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Manga',
          style: TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Column(
          children: [
            custom.SearchBar(
              searchController: _searchController,
              onSearch: (query) {
                searchManga(query, selectedGenre, selectedSort);
              },
            ),
            GenreSortDropdown(
              selectedGenre: selectedGenre,
              selectedSort: selectedSort,
              genres: genres,
              sortOptions: sortOptions,
              onGenreChanged: (newGenre) {
                setState(() {
                  selectedGenre = newGenre;
                });
              },
              onSortChanged: (newSort) {
                setState(() {
                  selectedSort = newSort;
                });
              },
            ),
            isLoading
                ? const Center(
                    child: SpinKitFadingCircle(
                      color: Colors.white,
                      size: 50.0,
                    ),
                  )
                : MangaGrid(
                    searchResults: searchResults,
                    isLoadingMore: isLoadingMore,
                    scrollController: _scrollController,
                  ),
          ],
        ),
      ),
    );
  }
}
