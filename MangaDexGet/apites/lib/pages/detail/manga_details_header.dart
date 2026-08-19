import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apites/models/manga_model.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:apites/widgets/glass_badge.dart';
import 'package:apites/widgets/favorite_button.dart';

class MangaDetailsHeader extends StatelessWidget {
  final MangaModel mangaDetails;
  final String authorName;

  const MangaDetailsHeader({
    super.key,
    required this.mangaDetails,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mangaDetails.coverUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: CachedNetworkImage(
              imageUrl: mangaDetails.coverUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SpinKitFadingCircle(color: Colors.white, size: 30.0),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                mangaDetails.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FavoriteButton(mangaId: mangaDetails.id),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mangaDetails.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: mangaDetails.genres
              .map((tag) => GlassBadge(label: tag))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Author: $authorName',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Status: ${mangaDetails.status ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Created At: ${mangaDetails.createdAt?.toLocal().toString().split(' ')[0] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(
          color: Color.fromARGB(65, 255, 255, 255),
          thickness: 1,
        ),
      ],
    );
  }
}
