import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';

class MangaSearchController extends GetxController {
  var searchResults = <MangaModel>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var showBackToTop = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  var searchQuery = ''.obs;
  var authorSuggestions = <Map<String, String>>[].obs;
  var searchMode = 'manga'.obs; // 'manga' or 'artist'
  var hideNsfw = false.obs;
  
  var selectedGenreId = ''.obs; // The UUID of the selected tag
  var selectedGenreName = 'All'.obs; // The UI display name
  
  var selectedSortId = 'relevance'.obs; // The sort order key for API
  var selectedSortName = 'Relevance'.obs; // The UI display name
  
  int currentPage = 0;
  final int pageSize = 20;

  var tagList = <Map<String, String>>[{'id': '', 'name': 'All'}].obs;
  
  final List<Map<String, String>> sortOptions = [
    {'id': 'relevance', 'name': 'Relevance'},
    {'id': 'latestUploadedChapter', 'name': 'Latest Uploaded'},
    {'id': 'followedCount', 'name': 'Most Followed'},
    {'id': 'rating', 'name': 'Highest Rating'},
    {'id': 'createdAt', 'name': 'Newest Added'},
  ];


  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    _fetchTags();
    
    // Load initial data
    searchManga('');
    
    // Debounce typing to avoid API spam
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        if (searchMode.value == 'artist') {
          fetchAuthorSuggestions(query);
        } else {
          authorSuggestions.clear();
        }
        searchManga(query);
      } else {
        authorSuggestions.clear();
        searchManga('');
      }
    }, time: const Duration(milliseconds: 600));
  }

  Future<void> fetchAuthorSuggestions(String query) async {
    final authors = await MangaRepository.searchAuthors(query);
    authorSuggestions.assignAll(authors);
  }

  Future<void> _fetchTags() async {
    try {
      final tags = await MangaRepository.getMangaTags();
      // Insert 'All' at the beginning
      tagList.assignAll([{'id': '', 'name': 'All'}, ...tags]);
    } catch (e) {
      print("Error fetching tags: $e");
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= 500) {
      if (!showBackToTop.value) showBackToTop.value = true;
    } else {
      if (showBackToTop.value) showBackToTop.value = false;
    }

    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMoreManga();
    }
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void updateGenre(String genreId, String genreName) {
    selectedGenreId.value = genreId;
    selectedGenreName.value = genreName;
    // Auto trigger search when genre changes
    searchManga(textController.text);
  }

  void updateSort(String sortId, String sortName) {
    selectedSortId.value = sortId;
    selectedSortName.value = sortName;
    searchManga(textController.text);
  }

  void toggleNsfw(bool value) {
    hideNsfw.value = value;
    searchManga(textController.text);
  }

  void selectAuthor(String authorName) {
    textController.text = authorName;
    searchQuery.value = authorName; // triggers debounce but it's fine, or we can just search directly
    authorSuggestions.clear();
    searchManga(authorName);
  }

  Future<void> searchManga(String query) async {
    isLoading.value = true;
    currentPage = 0;
    searchResults.clear();

    try {
      final results = await MangaRepository.getMangaList(
        title: searchMode.value == 'manga' ? query : '',
        authorName: searchMode.value == 'artist' ? query : '',
        limit: pageSize,
        offset: currentPage * pageSize,
        sortOrder: selectedSortId.value,
        includedTagId: selectedGenreId.value,
        hideNsfw: hideNsfw.value,
      );

      _filterAndAssignResults(results, isLoadMore: false);
    } catch (e) {
      print("Error searching manga: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreManga() async {
    if (isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;

    try {
      final results = await MangaRepository.getMangaList(
        title: searchMode.value == 'manga' ? textController.text : '',
        authorName: searchMode.value == 'artist' ? textController.text : '',
        limit: pageSize,
        offset: (currentPage + 1) * pageSize,
        sortOrder: selectedSortId.value,
        includedTagId: selectedGenreId.value,
        hideNsfw: hideNsfw.value,
      );

      _filterAndAssignResults(results, isLoadMore: true);
      currentPage++;
    } catch (e) {
      print("Error loading more manga: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _filterAndAssignResults(List<MangaModel> results, {required bool isLoadMore}) {
    if (isLoadMore) {
      searchResults.addAll(results);
    } else {
      searchResults.assignAll(results);
    }
  }
}
