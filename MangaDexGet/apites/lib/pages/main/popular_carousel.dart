import 'package:flutter/material.dart';
import 'package:apites/controllers/main_controller.dart';
import 'package:apites/widgets/glass_badge.dart';
import 'package:apites/collection/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:apites/models/manga_model.dart';

class PopularCarousel extends StatelessWidget {
  final List<MangaModel> popularMangaList;

  const PopularCarousel({super.key, required this.popularMangaList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(height: 350.0),
      items: popularMangaList.map((manga) {
        final title = manga.title;
        final imageUrl = manga.coverUrl ?? "https://via.placeholder.com/150";
        final genres = manga.genres.take(4).toList();

        return GestureDetector(
          onTap: () {
            Get.to(() => DetailScreen(mangaId: manga.id));
          },
          child: Stack(
            children: [
              Card(
                color: const Color(0xFF2C2F33),
                child: Column(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFF2C2F33),
                        highlightColor: const Color(0xFF3F4349),
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 8.0,
                            children: genres
                                .map((genre) => GlassBadge(label: genre))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
