import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/pages/detail/detail_screen.dart';

class FavoriteMangaCard extends StatelessWidget {
  final Map<String, dynamic> manga;
  final int index;

  const FavoriteMangaCard({
    super.key,
    required this.manga,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final title = manga['attributes']['title']?['en'] ?? "Unknown Title";
    final desc = manga['attributes']['description']?['en'] ?? "No Description";
    final imageUrl = manga['coverUrl'] ?? "https://via.placeholder.com/150";
    final genres = (manga['attributes']['tags'] as List<dynamic>)
        .map((tag) => tag['attributes']['name']['en'] as String)
        .take(4)
        .toList();

    return GestureDetector(
      key: ValueKey(manga['id']),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(mangaId: manga['id']),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF2C2F33),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 100,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 3.0,
                      runSpacing: -10.0,
                      children: genres
                          .map((genre) => Chip(
                                label: Text(genre),
                                backgroundColor: Colors.black.withOpacity(0.5),
                                labelStyle: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 0),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
