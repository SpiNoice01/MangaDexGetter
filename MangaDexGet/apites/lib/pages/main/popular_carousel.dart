import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PopularCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> popularMangaList;

  const PopularCarousel({super.key, required this.popularMangaList});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(height: 350.0),
      items: popularMangaList.map((manga) {
        final title = manga['attributes']['title']?['en'] ?? "Unknown Title";
        final imageUrl = manga['coverUrl'] ?? "https://via.placeholder.com/150";
        final genres = (manga['attributes']['tags'] as List<dynamic>)
            .map((tag) => tag['attributes']['name']['en'] as String)
            .take(4)
            .toList();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(mangaId: manga['id']),
              ),
            );
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
                      placeholder: (context, url) => const Center(
                        child: SpinKitFadingCircle(
                          color: Colors.white,
                          size: 50.0,
                        ),
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
                            runSpacing: -10.0,
                            children: genres
                                .map((genre) => Chip(
                                      label: Text(genre),
                                      backgroundColor:
                                          Colors.black.withOpacity(0.5),
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.0,
                                        vertical: 0.0,
                                      ),
                                    ))
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
