import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MangaGrid extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final bool isLoadingMore;
  final ScrollController scrollController;

  const MangaGrid({
    super.key,
    required this.searchResults,
    required this.isLoadingMore,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        controller: scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.5,
        ),
        itemCount: searchResults.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == searchResults.length) {
            return const Center(
              child: SpinKitFadingCircle(
                color: Colors.white,
                size: 50.0,
              ),
            );
          }
          final manga = searchResults[index];

          // Extract manga details
          final title = manga['attributes']['title']?['en'] ?? "Unknown Title";
          final desc =
              manga['attributes']['description']?['en'] ?? "No Description";
          final imageUrl =
              manga['coverUrl'] ?? "https://via.placeholder.com/150";

          return Card(
            color: const Color(0xFF2C2F33),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(mangaId: manga['id']),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
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
                      imageBuilder: (context, imageProvider) => ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Image(
                          image: imageProvider,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0)
                        .copyWith(bottom: 12.0),
                    child: Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
