import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FavoriteMangaList extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteMangaList;
  final Function(String) truncateTitle;

  const FavoriteMangaList({
    super.key,
    required this.favoriteMangaList,
    required this.truncateTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your Favorites',
            style: TextStyle(
              color: Color.fromARGB(255, 226, 226, 226),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteMangaList.length,
            itemBuilder: (context, index) {
              final manga = favoriteMangaList[index];
              final title =
                  manga['attributes']['title']?['en'] ?? "Unknown Title";
              final truncatedTitle = truncateTitle(title);
              final imageUrl =
                  manga['coverUrl'] ?? "https://via.placeholder.com/150";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(mangaId: manga['id']),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: const Color(0xFF2C2F33),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SpinKitFadingCircle(
                                color: Colors.white,
                                size: 50.0,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          truncatedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
