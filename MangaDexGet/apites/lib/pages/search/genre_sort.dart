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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedGenreId,
              dropdownColor: const Color(0xFF2C2F33),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: genres.map((tag) {
                return DropdownMenuItem<String>(
                  value: tag['id'],
                  child: Text(tag['name']!),
                );
              }).toList(),
              onChanged: (newValue) {
                final selectedTag = genres.firstWhere((tag) => tag['id'] == newValue);
                onGenreChanged(selectedTag['id']!, selectedTag['name']!);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: selectedSortId,
              dropdownColor: const Color(0xFF2C2F33),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: sortOptions.map((sortOption) {
                return DropdownMenuItem<String>(
                  value: sortOption['id'],
                  child: Text(sortOption['name']!),
                );
              }).toList(),
              onChanged: (newValue) {
                final selectedOption = sortOptions.firstWhere((option) => option['id'] == newValue);
                onSortChanged(selectedOption['id']!, selectedOption['name']!);
              },
            ),
          ),
        ],
      ),
    );
  }
}
