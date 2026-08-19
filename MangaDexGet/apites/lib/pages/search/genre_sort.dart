import 'package:flutter/material.dart';

class GenreSortDropdown extends StatelessWidget {
  final String selectedGenreId;
  final String selectedSortId;
  final List<Map<String, String>> genres;
  final List<Map<String, String>> sortOptions;
  final Function(String, String) onGenreChanged;
  final Function(String, String) onSortChanged;

  const GenreSortDropdown({
    super.key,
    required this.selectedGenreId,
    required this.selectedSortId,
    required this.genres,
    required this.sortOptions,
    required this.onGenreChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterMenu(
              context,
              title: 'Genre',
              selectedValue: selectedGenreId,
              items: genres,
              onSelected: (id) {
                final name = genres.firstWhere((e) => e['id'] == id)['name']!;
                onGenreChanged(id, name);
              }
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterMenu(
              context,
              title: 'Sort By',
              selectedValue: selectedSortId,
              items: sortOptions,
              onSelected: (id) {
                final name = sortOptions.firstWhere((e) => e['id'] == id)['name']!;
                onSortChanged(id, name);
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu(BuildContext context, {required String title, required String selectedValue, required List<Map<String, String>> items, required Function(String) onSelected}) {
    final selectedName = items.firstWhere((e) => e['id'] == selectedValue, orElse: () => {'name': 'Unknown'})['name']!;
    
    return PopupMenuButton<String>(
      color: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => items.map((item) => PopupMenuItem<String>(
        value: item['id'],
        child: Text(item['name']!, style: const TextStyle(color: Colors.white)),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    selectedName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
