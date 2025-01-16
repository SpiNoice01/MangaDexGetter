import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/pages/detail/detail_screen.dart';

class CarouselSliderWidget extends StatelessWidget {
  final List<Map<String, dynamic>> mangaList;

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
        final imageUrl = manga['coverUrl'] ?? "https://via.placeholder.com/150";
        final title = manga['attributes']['title']?['en'] ?? "Unknown Title";
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
                        runSpacing: 2.0,
                        children: genres
                            .take(5)
                            .map((genre) => Chip(
                                  label: Text(genre),
                                  backgroundColor:
                                      Colors.black.withOpacity(0.5),
                                  labelStyle: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                ))
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
