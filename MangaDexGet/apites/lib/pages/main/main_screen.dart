import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:apites/collection/colors.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/controllers/main_controller.dart';
import 'package:apites/pages/search/search_manga.dart';
import 'package:apites/pages/favorite/favorite_screen.dart';
import 'package:apites/pages/main/carousel_slider_widget.dart';
import 'package:apites/pages/main/favorite_manga_list.dart';
import 'package:apites/pages/main/manga_card.dart';
import 'package:apites/pages/main/popular_carousel.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final MainController controller = Get.put(MainController());
    final ScrollController scrollController = ScrollController();

    String truncateTitle(String title) {
      const int wordLimit = 1;
      List<String> words = title.split(' ');
      if (words.length > wordLimit) {
        return '${words.sublist(0, wordLimit).join(' ')}...';
      }
      return title;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'lib/assets/mangaDex.svg',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'MangaDex',
              style: TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2F33),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: () {
              Get.to(() => const SearchScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.mangaDex),
            onPressed: () async {
              await Get.to(() => const FavoriteScreen());
              controller.fetchFavoriteManga(); // Refresh after returning
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward,
                color: Color.fromARGB(255, 237, 237, 237)),
            onPressed: () {
              scrollController.animateTo(
                0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF23272A),
      body: RefreshIndicator(
        color: const Color(0xFFFF6444),
        onRefresh: controller.refreshPage,
        child: PagedListView<int, MangaModel>(
          pagingController: controller.pagingController,
          scrollController: scrollController,
          builderDelegate: PagedChildBuilderDelegate<MangaModel>(
            firstPageProgressIndicatorBuilder: (context) => const Center(
              child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
            ),
            newPageProgressIndicatorBuilder: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
              ),
            ),
            itemBuilder: (context, manga, index) {
              if (index == 0) {
                return Obx(() => Column(
                  children: [
                    if (controller.pagingController.itemList != null)
                      CarouselSliderWidget(
                        mangaList: controller.pagingController.itemList!,
                      ),
                    
                    if (controller.popularMangaList.isNotEmpty)
                      PopularCarousel(
                        popularMangaList: controller.popularMangaList.toList(),
                      ),
                    
                    if (controller.favoriteMangaList.isNotEmpty)
                      FavoriteMangaList(
                        favoriteMangaList: controller.favoriteMangaList.toList(),
                        truncateTitle: truncateTitle,
                      ),
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Just uploaded',
                          style: TextStyle(
                            color: Color.fromARGB(255, 226, 226, 226),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ));
              } else {
                return MangaCard(
                  manga: manga,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
