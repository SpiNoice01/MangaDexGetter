import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/collection/colors.dart';
import 'package:apites/controllers/detail_controller.dart';
import 'package:apites/pages/read/read_manga.dart';
import 'package:apites/pages/detail/manga_details_header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:apites/widgets/shimmer_loading.dart';
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
                return const MangaDetailShimmer();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MangaDetailsHeader(
                    mangaDetails: controller.mangaDetails.value!,
                    authorName: controller.authorName.value,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final lastId = controller.lastReadChapterId.value;
                    final farthestId = controller.farthestReadChapterId.value;

                    Widget buildButton(String label, String? chapterId, Color color, {bool isJump = false}) {
                      return ElevatedButton(
                        onPressed: () async {
                          if (isJump && chapterId != null) {
                            controller.jumpToChapter(chapterId);
                          } else {
                            await Get.to(() => ReadMangaScreen(
                              mangaId: mangaId,
                              chapterId: chapterId,
                            ));
                            controller.loadReadHistory();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(label, textAlign: TextAlign.center),
                      );
                    }

                    if (lastId == null) {
                      return SizedBox(
                        width: double.infinity,
                        child: buildButton('Start Reading', null, AppColors.mangaDex),
                      );
                    }

                    if (lastId == farthestId) {
                      return SizedBox(
                        width: double.infinity,
                        child: buildButton('Jump to Continue Reading\n${controller.lastReadChapterTitle.value}', lastId, AppColors.mangaDex, isJump: true),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: buildButton('Jump to Last Read\n${controller.lastReadChapterTitle.value}', lastId, const Color(0xFF6C757D), isJump: true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildButton('Jump to Farthest\n${controller.farthestReadChapterTitle.value}', farthestId, AppColors.mangaDex, isJump: true),
                        ),
                      ],
                    );
                  }),
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
