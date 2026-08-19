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
        actions: [
          Obx(() => Row(
            children: [
              const Text('NSFW', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.toggleNsfw(!controller.hideNsfw.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: !controller.hideNsfw.value ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white24,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: !controller.hideNsfw.value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !controller.hideNsfw.value ? Colors.redAccent : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(width: 4),
        ],
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (controller.searchMode.value != 'manga') {
                            controller.searchMode.value = 'manga';
                            controller.searchManga(controller.textController.text);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: controller.searchMode.value == 'manga' ? const Color(0xFFFF6444) : const Color(0xFF2C2F33),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Search Manga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2), // Small gap
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (controller.searchMode.value != 'artist') {
                            controller.searchMode.value = 'artist';
                            controller.searchManga(controller.textController.text);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: controller.searchMode.value == 'artist' ? const Color(0xFFFF6444) : const Color(0xFF2C2F33),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Search Artist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                )),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() => custom.SearchBar(
                searchController: controller.textController,
                hintText: controller.searchMode.value == 'manga' ? 'Search manga title...' : 'Search artist/author name...',
                onSearch: (query) {
                  controller.searchQuery.value = query;
                },
              )),
            ),
            Obx(() {
              if (controller.authorSuggestions.isNotEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: controller.authorSuggestions.map((author) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(author['name']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: const Color(0xFF2C2F33),
                              side: const BorderSide(color: Color(0xFFFF6444), width: 1),
                              onPressed: () {
                                controller.selectAuthor(author['name']!);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
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
      floatingActionButton: Obx(() {
        if (controller.showBackToTop.value) {
          return FloatingActionButton(
            backgroundColor: const Color(0xFFFF6444),
            onPressed: controller.scrollToTop,
            child: const Icon(Icons.arrow_upward, color: Colors.white),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
