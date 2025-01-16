import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MangaCard extends StatelessWidget {
  final Map<String, dynamic> manga;
  final Future<bool> Function(String) isFavorite;
  final Function(String) toggleFavorite;

  const MangaCard({
    super.key,
    required this.manga,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final title = manga['attributes']['title']?['en'] ?? "Unknown Title";
    final desc = manga['attributes']['description']?['en'] ?? "No Description";
    final imageUrl = manga['coverUrl'] ?? "https://via.placeholder.com/150";
    final genres = (manga['attributes']['tags'] as List<dynamic>)
        .map((tag) => tag['attributes']['name']['en'] as String)
        .take(3)
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
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Just uploaded!')),
        );
      },
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        color: const Color(0xFF2C2F33),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 120,
                  height: 170,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SpinKitFadingCircle(
                    color: Colors.white,
                    size: 50.0,
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Expanded(
              child: Padding(
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
                                backgroundColor:
                                    const Color.fromARGB(255, 12, 12, 12)
                                        .withOpacity(0.7),
                                labelStyle: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 0),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: isFavorite(manga['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SpinKitFadingCircle(
                            color: Colors.white,
                            size: 50.0,
                          );
                        } else {
                          final isFav = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                            ),
                            onPressed: () => toggleFavorite(manga['id']),
                          );
                        }
                      },
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
