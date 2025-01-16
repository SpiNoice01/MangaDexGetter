import 'package:flutter/material.dart';

class MangaNavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback previousPage;
  final VoidCallback nextPage;
  final Color iconColor;
  final Color textColor;

  const MangaNavigationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.previousPage,
    required this.nextPage,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: previousPage,
          ),
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: TextStyle(color: textColor),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: iconColor),
            onPressed: nextPage,
          ),
        ],
      ),
    );
  }
}
