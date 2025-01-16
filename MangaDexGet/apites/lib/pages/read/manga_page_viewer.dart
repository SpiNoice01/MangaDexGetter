import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/collection/colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MangaPageViewer extends StatelessWidget {
  final List<String> pages;
  final int currentPage;
  final PageController pageController;
  final Function(int) onPageChanged;
  final String? nextChapterId;
  final VoidCallback readNextChapter;
  final bool isVerticalScrollMode;
  final Future<void> Function() onRefresh;

  const MangaPageViewer({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.nextChapterId,
    required this.readNextChapter,
    required this.isVerticalScrollMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return isVerticalScrollMode
        ? _buildVerticalScrollView()
        : _buildGalleryView();
  }

  Widget _buildGalleryView() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: PhotoViewGallery.builder(
        pageController: pageController,
        onPageChanged: onPageChanged,
        itemCount: pages.length + 1,
        builder: (context, index) {
          if (index == pages.length) {
            return PhotoViewGalleryPageOptions.customChild(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'End of Chapter',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mangaDex,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (nextChapterId != null)
                      ElevatedButton(
                        onPressed: readNextChapter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mangaDex,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Read Next Chapter'),
                      ),
                  ],
                ),
              ),
            );
          }
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(pages[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: pages[index]),
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported);
            },
            filterQuality: FilterQuality.high,
          );
        },
      ),
    );
  }

  Widget _buildVerticalScrollView() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: pages.length + 1,
        itemBuilder: (context, index) {
          if (index == pages.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'End of Chapter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mangaDex,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (nextChapterId != null)
                    ElevatedButton(
                      onPressed: readNextChapter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mangaDex,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Read Next Chapter'),
                    ),
                ],
              ),
            );
          }
          return CachedNetworkImage(
            imageUrl: pages[index],
            placeholder: (context, url) => const Center(
              child: SpinKitFadingCircle(
                color: Colors.white,
                size: 50.0,
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.image_not_supported),
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
