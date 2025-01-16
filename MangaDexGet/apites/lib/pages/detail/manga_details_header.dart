import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MangaDetailsHeader extends StatelessWidget {
  final Map<String, dynamic> mangaDetails;
  final Map<String, dynamic>? authorDetails;
  final bool isLiked;
  final VoidCallback toggleLike;

  const MangaDetailsHeader({
    super.key,
    required this.mangaDetails,
    this.authorDetails,
    required this.isLiked,
    required this.toggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mangaDetails['coverUrl'] != null)
          ClipRRect(
            borderRadius:
                BorderRadius.circular(5.0), // Set the border radius here
            child: CachedNetworkImage(
              imageUrl: mangaDetails['coverUrl'],
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
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
                mangaDetails['attributes']['title']?['en'] ?? "Unknown Title",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
              onPressed: toggleLike,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mangaDetails['attributes']['description']?['en'] ?? "No Description",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: (mangaDetails['attributes']['tags'] as List<dynamic>)
              .map((tag) => Chip(
                    label: Text(tag['attributes']['name']['en']),
                    backgroundColor: const Color(0xFF2C2F33),
                    labelStyle: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        if (authorDetails != null)
          Text(
            'Author: ${authorDetails!['attributes']['name'] ?? 'Unknown'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Status: ${mangaDetails['attributes']['status'] ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Created At: ${mangaDetails['attributes']['createdAt'] ?? 'Unknown'}',
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
