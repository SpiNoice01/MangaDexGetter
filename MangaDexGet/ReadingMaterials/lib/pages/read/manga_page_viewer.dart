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
  final ScrollController verticalScrollController;
  final bool showPageNumber;

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
    required this.verticalScrollController,
    required this.showPageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return isVerticalScrollMode
        ? _buildVerticalScrollView()
        : _buildGalleryView();
  }

  Widget _buildGalleryView() {
    return RefreshIndicator(
      color: const Color(0xFFFF6444),
      onRefresh: onRefresh,
      child: PhotoViewGallery.builder(
        pageController: pageController,
        onPageChanged: onPageChanged,
        itemCount: pages.length + 1,
        loadingBuilder: (context, event) => const Center(
          child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
        ),
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
                        color: Colors.white,
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
      color: const Color(0xFFFF6444),
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: verticalScrollController,
        itemCount: pages.length + 1,
        itemBuilder: (context, index) {
          if (index == pages.length) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'End of Chapter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
          return Stack(
            alignment: Alignment.bottomRight,
            children: [
              CachedNetworkImage(
                imageUrl: pages[index],
                placeholder: (context, url) => const AspectRatio(
                  aspectRatio: 0.7, // Standard manga page ratio so spinners don't squish
                  child: Center(
                    child: SpinKitFadingCircle(
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported),
                fit: BoxFit.contain,
              ),
              if (showPageNumber)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, right: 12.0),
                  child: _StampedPageNumber(label: '${index + 1} / ${pages.length}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

// A page number "stamped" onto the page itself (stroke + fill text, no backdrop)
// so it stays legible over any page content without covering it up.
class _StampedPageNumber extends StatelessWidget {
  final String label;

  const _StampedPageNumber({required this.label});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black.withValues(alpha: 0.75),
          ),
        ),
        Text(
          label,
          style: style.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
