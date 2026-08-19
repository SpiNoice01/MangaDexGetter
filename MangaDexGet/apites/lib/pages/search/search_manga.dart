import 'package:flutter/material.dart';
import 'package:apites/collection/colors.dart';
import 'package:get/get.dart';
import 'package:apites/controllers/search_controller.dart';
import 'package:apites/pages/search/search_bar.dart' as custom;
import 'package:apites/pages/search/genre_sort.dart';
import 'package:apites/pages/search/manga_gridlist.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
        child: Column(
          children: [
            custom.SearchBar(
              searchController: controller.textController,
              onSearch: (query) {
                controller.searchManga(query);
              },
            ),
            Obx(() => GenreSortDropdown(
              selectedGenre: controller.selectedGenre.value,
              selectedSort: controller.selectedSort.value,
              genres: controller.genres,
              sortOptions: controller.sortOptions,
              onGenreChanged: (newGenre) {
                controller.updateGenre(newGenre);
              },
              onSortChanged: (newSort) {
                controller.updateSort(newSort);
              },
            )),
            Obx(() {
              if (controller.isLoading.value) {
                return const Expanded(
                  child: Center(
                    child: SpinKitFadingCircle(color: Colors.white,
                      size: 30.0,
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
