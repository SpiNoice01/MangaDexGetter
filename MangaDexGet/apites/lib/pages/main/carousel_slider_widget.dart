import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:apites/models/manga_model.dart';
import 'package:apites/widgets/glass_badge.dart';

class CarouselSliderWidget extends StatelessWidget {
  final List<MangaModel> mangaList;

  const CarouselSliderWidget({super.key, required this.mangaList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 400.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 50),
        autoPlayAnimationDuration: const Duration(seconds: 5),
        enlargeCenterPage: true,
        viewportFraction: 1.0,
      ),
      items: mangaList.map((manga) {
        final imageUrl = manga.coverUrl ?? "https://via.placeholder.com/150";
        final title = manga.title;
        final genres = manga.genres.take(4).toList();

        return GestureDetector(
          onTap: () {
            Get.to(() => DetailScreen(mangaId: manga.id));
          },
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(imageUrl),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: const Alignment(0, -1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 8.0,
                        children: genres
                            .take(5)
                            .map((genre) => GlassBadge(label: genre))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (manga.updatedLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          manga.updatedLabel!,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ],
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
