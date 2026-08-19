import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/controllers/read_controller.dart';
import 'package:apites/pages/read/manga_page_viewer.dart';
import 'package:apites/pages/read/manga_navigation_bar.dart';
import 'package:apites/widgets/favorite_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ReadMangaScreen extends StatelessWidget {
  final String mangaId;
  final String? chapterId;

  const ReadMangaScreen({super.key, required this.mangaId, this.chapterId});

  @override
  Widget build(BuildContext context) {
    // Unique tag in case we open multiple instances (rare but good practice)
    final ReadController controller = Get.put(
      ReadController(mangaId: mangaId, chapterId: chapterId),
      tag: '$mangaId-$chapterId',
    );

    return Obx(() {
      final appBarColor = controller.appBarColor.value;
      final backgroundColor = controller.backgroundColor.value;
      final textColor = controller.textColor.value;
      final iconColor = controller.iconColor.value;
      final chapterTitle = controller.chapterTitle.value;
      final chapterNumber = controller.chapterNumber.value;
      final isVerticalScrollMode = controller.isVerticalScrollMode.value;
      final isLoading = controller.isLoading.value;
      final pages = controller.pages;

      return Scaffold(
        extendBodyBehindAppBar: true, // Better reading experience
        appBar: AppBar(
          title: Text(
            chapterTitle + (chapterNumber.isNotEmpty ? ' (Ch. $chapterNumber)' : ''),
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () {
              // Delete the controller from memory when leaving
              Get.delete<ReadController>(tag: '$mangaId-$chapterId');
              Navigator.of(context).pop();
            },
          ),
          actions: [
            FavoriteButton(
              mangaId: mangaId,
              defaultColor: iconColor,
              isBeatingAnimation: true,
            ),
            PopupMenuButton<Color>(
              onSelected: controller.changeTheme,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: Color.fromARGB(255, 217, 217, 217),
                  child: Text('White Theme'),
                ),
                const PopupMenuItem(
                  value: Color(0xFF2C2F33),
                  child: Text('Dark Theme'),
                ),
                const PopupMenuItem(
                  value: Color.fromARGB(255, 195, 169, 128),
                  child: Text('Warm Theme'),
                ),
              ],
              icon: Icon(Icons.color_lens, color: iconColor),
            ),
            IconButton(
              icon: Icon(
                isVerticalScrollMode ? Icons.view_carousel : Icons.view_stream,
                color: iconColor,
              ),
              onPressed: controller.toggleScrollMode,
            ),
          ],
        ),
        body: isLoading
            ? Container(
                color: backgroundColor,
                child: const Center(
                  child: SpinKitFadingCircle(color: Colors.white,
                    size: 30.0,
                  ),
                ),
              )
            : pages.isEmpty
                ? Container(
                    color: backgroundColor,
                    child: Center(
                      child: Text('No pages available', style: TextStyle(color: textColor)),
                    ),
                  )
                : Container(
                    color: backgroundColor,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: ColorFiltered(
                              colorFilter: backgroundColor == const Color.fromARGB(255, 195, 169, 128)
                                  ? const ColorFilter.mode(
                                      Color.fromARGB(255, 255, 235, 205), // BlanchedAlmond tint
                                      BlendMode.multiply, // Multiply perfectly tints whites while keeping blacks dark
                                    )
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.multiply,
                                    ),
                              child: MangaPageViewer(
                                pages: pages,
                                currentPage: controller.currentPage.value,
                                pageController: controller.pageController,
                                onPageChanged: controller.onPageChanged,
                                nextChapterId: controller.nextChapterId.value,
                                readNextChapter: controller.readNextChapter,
                                isVerticalScrollMode: isVerticalScrollMode,
                                onRefresh: controller.refreshPages,
                              ),
                            ),
                          ),
                          if (!isVerticalScrollMode)
                            MangaNavigationBar(
                              currentPage: controller.currentPage.value,
                              totalPages: pages.length,
                              previousPage: controller.previousPage,
                              nextPage: controller.nextPage,
                              iconColor: iconColor,
                              textColor: textColor,
                              backgroundColor: appBarColor,
                            ),
                        ],
                      ),
                    ),
                  ),
      );
    });
  }
}

