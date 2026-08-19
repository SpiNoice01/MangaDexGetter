import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/controllers/search_controller.dart';
import 'package:apites/pages/search/search_bar.dart' as custom;
import 'package:apites/pages/search/genre_sort.dart';
import 'package:apites/pages/search/manga_gridlist.dart';
import 'package:apites/widgets/shimmer_loading.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MangaSearchController controller = Get.put(MangaSearchController());

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
            Get.back();
          },
        ),
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        color: const Color(0xFFFF6444),
        onRefresh: () => controller.searchManga(controller.textController.text),
        child: CustomScrollView(
          controller: controller.scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: custom.SearchBar(
                searchController: controller.textController,
                onSearch: (query) {
                  controller.searchQuery.value = query;
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() => GenreSortDropdown(
                selectedGenreId: controller.selectedGenreId.value,
                selectedSortId: controller.selectedSortId.value,
                genres: controller.tagList.toList(),
                sortOptions: controller.sortOptions,
                onGenreChanged: (newGenreId, newGenreName) {
                  controller.updateGenre(newGenreId, newGenreName);
                },
                onSortChanged: (newSortId, newSortName) {
                  controller.updateSort(newSortId, newSortName);
                },
              )),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: MangaGridShimmer(),
                );
              }
              if (!controller.isLoading.value && controller.searchResults.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'No manga found',
                          style: TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return MangaGrid(
                searchResults: controller.searchResults.toList(),
                isLoadingMore: controller.isLoadingMore.value,
                scrollController: controller.scrollController,
              );
            }),
          ],
        ),
      ),
    );
  }
}
