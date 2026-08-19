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
  
  var bookmarkedChapterId = RxnString();
  var bookmarkedChapterTitle = RxnString();
  
  int currentPage = 0;
  final int limit = 10;

  DetailController({required this.mangaId});

  @override
  void onInit() {
    super.onInit();
    fetchMangaDetails();
    getBookmark();
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

  void loadNextPage() {
    currentPage++;
    fetchChapters(currentPage);
  }

  // Favorite logic is now handled by FavoriteButton and FavoriteService

  Future<void> getBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final chapterId = prefs.getString('bookmark_$mangaId');
    if (chapterId != null) {
      try {
        final chapterDetails = await MangaDexService.getChapterDetails(chapterId);
        bookmarkedChapterId.value = chapterId;
        final rawTitle = chapterDetails['attributes']['title']?.toString() ?? '';
        final chapterNum = chapterDetails['attributes']['chapter']?.toString() ?? '';
        bookmarkedChapterTitle.value = rawTitle.isNotEmpty 
            ? rawTitle 
            : (chapterNum.isNotEmpty ? 'Chapter $chapterNum' : 'Oneshot');
      } catch (e) {
        // ignore error
      }
    }
  }

  Future<void> refreshData() async {
    currentPage = 0;
    isError.value = false;
    isChapterError.value = false;
    // Do NOT set mangaDetails to null here, or else the Pull-to-Refresh indicator will be destroyed
    // and replaced by the full-screen SpinKit loading circle!
    // mangaDetails.value = null;
    authorName.value = 'Unknown';
    // Don't clear chapters here either to keep the UI smooth while fetching
    // chapters.clear(); 
    
    await fetchMangaDetails(); // fetchMangaDetails already clears chapters if page == 0
    await getBookmark();
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
