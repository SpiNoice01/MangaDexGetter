import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/repositories/manga_repository.dart';

class MangaSearchController extends GetxController {
  var searchResults = <MangaModel>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  var selectedGenre = 'All'.obs;
  var selectedSort = 'Relevance'.obs;
  
  int currentPage = 0;
  final int pageSize = 20;

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

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMoreManga();
    }
  }

  void updateGenre(String genre) {
    selectedGenre.value = genre;
  }

  void updateSort(String sort) {
    selectedSort.value = sort;
  }

  Future<void> searchManga(String query) async {
    isLoading.value = true;
    currentPage = 0;
    searchResults.clear();

    try {
      List<MangaModel> results;
      
      String? sortOrder;
      if (selectedSort.value == 'Rating') {
        sortOrder = 'rating';
      } else if (selectedSort.value == 'Newest') {
        sortOrder = 'createdAt';
      }

      results = await MangaRepository.getMangaList(
        title: query,
        limit: pageSize,
        offset: currentPage * pageSize,
        sortOrder: sortOrder,
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
      List<MangaModel> results;
      
      String? sortOrder;
      if (selectedSort.value == 'Rating') {
        sortOrder = 'rating';
      } else if (selectedSort.value == 'Newest') {
        sortOrder = 'createdAt';
      }

      results = await MangaRepository.getMangaList(
        title: textController.text,
        limit: pageSize,
        offset: (currentPage + 1) * pageSize,
        sortOrder: sortOrder,
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
    List<MangaModel> filteredResults = results;

    // Filter by genre
    if (selectedGenre.value != 'All') {
      filteredResults = results.where((manga) {
        return manga.genres.contains(selectedGenre.value);
      }).toList();
    }

    if (isLoadMore) {
      searchResults.addAll(filteredResults);
    } else {
      searchResults.assignAll(filteredResults);
    }
  }
}
