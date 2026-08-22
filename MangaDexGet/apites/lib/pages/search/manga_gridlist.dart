import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:apites/pages/detail/detail_screen.dart';
import 'package:apites/widgets/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:apites/models/manga_model.dart';

class MangaGrid extends StatelessWidget {
  final List<MangaModel> searchResults;
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
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
          if (index >= searchResults.length) {
            return const MangaGridItemShimmer();
          }
          final manga = searchResults[index];

          final title = manga.title;
          final desc = manga.description;
          final imageUrl = manga.coverUrl ?? "https://via.placeholder.com/150";

          return Card(
            color: const Color(0xFF2C2F33),
            child: InkWell(
              onTap: () {
                Get.to(() => DetailScreen(mangaId: manga.id));
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
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFF2C2F33),
                        highlightColor: const Color(0xFF3F4349),
                        child: Container(color: Colors.white),
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
                        .copyWith(bottom: manga.updatedLabel != null ? 2.0 : 12.0),
                    child: Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (manga.updatedLabel != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0)
                          .copyWith(bottom: 12.0),
                      child: Text(
                        manga.updatedLabel!,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        childCount: searchResults.length + (isLoadingMore ? 3 : 0),
      ),
    );
  }
}
