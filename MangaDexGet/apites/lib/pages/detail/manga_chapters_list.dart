import 'package:flutter/material.dart';
import 'package:apites/pages/read/read_manga.dart';

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
        const Text(
          'Chapters',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
              final chapterTitle = chapter['attributes']['title'] ??
                  'Chapter ${chapter['attributes']['chapter'] ?? ''}';
              final pageCount = chapter['pageCount'] ?? 'Unknown';
              return Card(
                color: const Color(0xFF2C2F33),
                child: ListTile(
                  title: Text(
                    'Chapter ${index + 1}: $chapterTitle',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Pages: $pageCount',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    print(
                        "Navigating to ReadMangaScreen with mangaId: $mangaId, chapterId: ${chapter['id']}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadMangaScreen(
                          mangaId: mangaId,
                          chapterId: chapter['id'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        if (isLoadingMore) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
