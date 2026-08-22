import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:apites/models/manga_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:apites/widgets/glass_badge.dart';

class FavoriteMangaCard extends StatelessWidget {
  final MangaModel manga;
  final int index;

  const FavoriteMangaCard({
    super.key,
    required this.manga,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final title = manga.title;
    final desc = manga.description;
    final imageUrl = manga.coverUrl ?? "https://via.placeholder.com/150";
    final genres = manga.genres.take(4).toList();

    return GestureDetector(
      key: ValueKey(manga.id),
      onTap: () {
        Get.to(() => DetailScreen(mangaId: manga.id));
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
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: const Color(0xFF2C2F33),
                  highlightColor: const Color(0xFF3F4349),
                  child: Container(color: Colors.white),
                ),
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
                      runSpacing: 4.0,
                      children: genres
                          .map((genre) => GlassBadge(label: genre))
                          .toList(),
                    ),
                    if (manga.updatedLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        manga.updatedLabel!,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
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
