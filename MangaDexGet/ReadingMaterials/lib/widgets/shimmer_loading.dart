import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MangaListShimmer extends StatelessWidget {
  const MangaListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2C2F33),
        highlightColor: const Color(0xFF3F4349),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock Carousel
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Mock Title (Popular)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 16.0),
              child: Container(height: 24, width: 150, color: Colors.white),
            ),
            // Mock Horizontal List
            SizedBox(
              height: 150,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Mock Title (Latest)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Container(height: 24, width: 150, color: Colors.white),
            ),
            // Mock Vertical List items (Cards)
            for (int i = 0; i < 4; i++)
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MangaDetailShimmer extends StatelessWidget {
  const MangaDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 24, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 100, color: Colors.white),
                    const SizedBox(height: 16),
                    Container(height: 16, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 16, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 16, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 16, width: 200, color: Colors.white),
          const SizedBox(height: 32),
          Container(
            height: 48, 
            width: double.infinity, 
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(8)
            )
          ),
          const SizedBox(height: 24),
          // Mock Title Chapters
          Container(height: 24, width: 100, color: Colors.white),
          const SizedBox(height: 16),
          // Shimmer chapters
          for (int i = 0; i < 5; i++)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Container(
                 height: 70, 
                 width: double.infinity, 
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8),
                 ),
               ),
             )
        ],
      ),
    );
  }
}

class MangaCardShimmer extends StatelessWidget {
  const MangaCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: Column(
        children: [
          for (int i = 0; i < 2; i++)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

class MangaGridShimmer extends StatelessWidget {
  final int itemCount;
  const MangaGridShimmer({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.5,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}

class MangaGridItemShimmer extends StatelessWidget {
  const MangaGridItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class FavoriteListShimmer extends StatelessWidget {
  const FavoriteListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class ChapterListShimmer extends StatelessWidget {
  const ChapterListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F33),
      highlightColor: const Color(0xFF3F4349),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Container(
                 height: 70, 
                 width: double.infinity, 
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8),
                 ),
               ),
             )
        ],
      ),
    );
  }
}
