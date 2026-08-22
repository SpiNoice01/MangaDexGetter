import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/controllers/favorite_controller.dart';
import 'package:apites/pages/favorite/favorite_manga_card.dart';
import 'package:apites/widgets/shimmer_loading.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoriteController controller = Get.put(FavoriteController());

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: true); // Return true to indicate changes
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorites',
            style: TextStyle(
              color: Color.fromARGB(255, 237, 237, 237),
            ),
          ),
          backgroundColor: const Color(0xFF2C2F33),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 237, 237, 237),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.back(result: true);
            },
          ),
        ),
        backgroundColor: const Color(0xFF23272A),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const FavoriteListShimmer();
          }

          if (controller.favoriteMangaDetails.isEmpty) {
            return const Center(
              child: Text(
                'No favorites yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFF6444),
            onRefresh: () => controller.loadFavorites(isRefresh: true),
            child: ReorderableListView.builder(
              onReorder: controller.onReorder,
              itemCount: controller.favoriteMangaDetails.length,
              itemBuilder: (context, index) {
                final manga = controller.favoriteMangaDetails[index];
                return FavoriteMangaCard(
                  key: ValueKey(manga.id),
                  manga: manga,
                  index: index,
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
