import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/collection/colors.dart';
import 'package:apites/controllers/detail_controller.dart';
import 'package:apites/pages/read/read_manga.dart';
import 'package:apites/pages/detail/manga_details_header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:apites/pages/detail/manga_chapters_list.dart';

class DetailScreen extends StatelessWidget {
  final String mangaId;

  const DetailScreen({super.key, required this.mangaId});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final DetailController controller = Get.put(DetailController(mangaId: mangaId), tag: mangaId);
    final ScrollController scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        controller.loadNextPage();
      }
    });

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
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        color: const Color(0xFFFF6444),
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (controller.isError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Error loading manga details',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.mangaDetails.value == null) {
                return const Center(
                  child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MangaDetailsHeader(
                    mangaDetails: controller.mangaDetails.value!,
                    authorName: controller.authorName.value,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Get.to(() => ReadMangaScreen(
                        mangaId: mangaId,
                        chapterId: controller.bookmarkedChapterId.value,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mangaDex,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(controller.bookmarkedChapterId.value != null
                        ? 'Continue Reading, \n${controller.bookmarkedChapterTitle.value}'
                        : 'Start Reading'),
                  ),
                  const SizedBox(height: 16),
                  MangaChaptersList(
                    chapters: controller.chapters.toList(),
                    isLoadingMore: controller.isLoadingMore.value,
                    isChapterError: controller.isChapterError.value,
                    currentPage: controller.currentPage,
                    fetchChapters: controller.fetchChapters,
                    mangaId: mangaId,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
