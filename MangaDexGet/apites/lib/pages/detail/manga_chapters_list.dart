import 'package:flutter/material.dart';
import 'package:apites/controllers/detail_controller.dart';
import 'package:get/get.dart';
import 'package:apites/pages/read/read_manga.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MangaChaptersList extends StatelessWidget {
  final List<Map<String, dynamic>> chapters;
  final bool isLoadingMore;
  final bool isChapterError;
  final int currentPage;
  final Future<void> Function(int) fetchChapters;
  final String mangaId;

  const MangaChaptersList({
    super.key,
    required this.chapters,
    required this.isLoadingMore,
    required this.isChapterError,
    required this.currentPage,
    required this.fetchChapters,
    required this.mangaId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chapters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() {
              final controller = Get.find<DetailController>(tag: mangaId);
              return Row(
                children: [
                  Text(
                    controller.isAscending.value ? 'Oldest' : 'Newest',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  IconButton(
                    icon: Icon(
                      controller.isAscending.value ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: controller.toggleSortOrder,
                    tooltip: 'Sort Chapters',
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        if (isChapterError)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error loading chapters',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => fetchChapters(currentPage),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final rawTitle = chapter['attributes']['title']?.toString() ?? '';
              final chapterNum =
                  chapter['attributes']['chapter']?.toString() ?? '';
              final chapterTitle = rawTitle.isNotEmpty
                  ? rawTitle
                  : (chapterNum.isNotEmpty ? 'Chapter $chapterNum' : 'Oneshot');
              final pageCount = chapter['pageCount'] ?? 'Unknown';

                return Obx(() {
                  final controller = Get.find<DetailController>(tag: mangaId);
                  final isRead = controller.readChapters.contains(chapter['id']);
                  final isLastRead = controller.lastReadChapterId.value == chapter['id'];
                  final isFarthest = controller.farthestReadChapterId.value == chapter['id'];

                  IconData trailingIcon;
                  Color iconColor;

                  if (isFarthest && isLastRead) {
                    trailingIcon = Icons.bookmark;
                    iconColor = const Color(0xFFFF6444); // MangaDex Orange
                  } else if (isFarthest) {
                    trailingIcon = Icons.star;
                    iconColor = Colors.yellow;
                  } else if (isLastRead) {
                    trailingIcon = Icons.bookmark_outline;
                    iconColor = const Color(0xFFFF6444);
                  } else if (isRead) {
                    trailingIcon = Icons.check_circle;
                    iconColor = Colors.green;
                  } else {
                    trailingIcon = Icons.circle_outlined;
                    iconColor = Colors.white24;
                  }

                  // Create or get a GlobalKey for this chapter to allow jumping
                  final key = controller.chapterKeys.putIfAbsent(chapter['id'], () => GlobalKey());

                  return Card(
                    key: key,
                    color: const Color(0xFF2C2F33),
                    child: ListTile(
                      leading: Icon(trailingIcon, color: iconColor),
                      title: Text(
                        'Chapter ${index + 1}: $chapterTitle',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Pages: $pageCount',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        await Get.to(() => ReadMangaScreen(
                              mangaId: mangaId,
                              chapterId: chapter['id'],
                            ));
                        controller.loadReadHistory();
                      },
                    ),
                  );
                });
            },
          ),
        if (isLoadingMore)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
            ),
          ),
      ],
    );
  }
}
