import 'package:flutter/material.dart';
import 'package:apites/collection/colors.dart';
import 'package:apites/controllers/main_controller.dart';
import 'package:apites/widgets/glass_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:apites/models/manga_model.dart';

import 'package:apites/widgets/favorite_button.dart';

class MangaCard extends StatelessWidget {
  final MangaModel manga;

  const MangaCard({
    super.key,
    required this.manga,
  });

  @override
  Widget build(BuildContext context) {
    final title = manga.title;
    final desc = manga.description;
    final imageUrl = manga.coverUrl ?? "https://via.placeholder.com/150";
    final genres = manga.genres.take(3).toList();

    return GestureDetector(
      onTap: () async {
        await Get.to(() => DetailScreen(mangaId: manga.id));
        if (Get.isRegistered<MainController>()) {
          Get.find<MainController>().fetchFavoriteManga();
        }
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
                  placeholder: (context, url) => const SpinKitFadingCircle(color: Colors.white,
                    size: 30.0,
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
                          .map((genre) => GlassBadge(label: genre))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    FavoriteButton(mangaId: manga.id),
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
