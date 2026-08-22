import 'package:flutter/material.dart';
import 'package:apites/controllers/detail_controller.dart';
import 'package:get/get.dart';
import 'package:apites/pages/read/read_manga.dart';
import 'package:apites/widgets/shimmer_loading.dart';

class MangaChaptersList extends StatelessWidget {
  final List<Map<String, dynamic>> chapters;
  final bool isLoadingChapters;
  final bool isChapterError;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final VoidCallback onRetry;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final String mangaId;

  const MangaChaptersList({
    super.key,
    required this.chapters,
    required this.isLoadingChapters,
    required this.isChapterError,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.onRetry,
    required this.onPreviousPage,
    required this.onNextPage,
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
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (isLoadingChapters)
          const ChapterListShimmer()
        else ...[
          if (totalPages > 1) ...[
            _buildPageControls(),
            const SizedBox(height: 8),
          ],
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
                        'Chapter ${currentPage * pageSize + index + 1}: $chapterTitle',
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
          if (totalPages > 1) ...[
            const SizedBox(height: 12),
            _buildPageControls(),
          ],
        ],
      ],
    );
  }

  Widget _buildPageControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: currentPage > 0 ? Colors.white : Colors.white24,
          onPressed: currentPage > 0 ? onPreviousPage : null,
        ),
        Text(
          'Page ${currentPage + 1} of $totalPages',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: currentPage < totalPages - 1 ? Colors.white : Colors.white24,
          onPressed: currentPage < totalPages - 1 ? onNextPage : null,
        ),
      ],
    );
  }
}
