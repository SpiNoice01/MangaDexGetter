import 'package:flutter/material.dart';

class GenreSortDropdown extends StatelessWidget {
  final String selectedGenre;
  final String selectedSort;
  final List<String> genres;
  final List<String> sortOptions;
  final Function(String) onGenreChanged;
  final Function(String) onSortChanged;

  const GenreSortDropdown({
    super.key,
    required this.selectedGenre,
    required this.selectedSort,
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
              value: selectedGenre,
              dropdownColor: const Color(0xFF2C2F33),
              style: const TextStyle(color: Colors.white),
              items: genres.map((String genre) {
                return DropdownMenuItem<String>(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
              onChanged: (newValue) {
                onGenreChanged(newValue!);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: selectedSort,
              dropdownColor: const Color(0xFF2C2F33),
              style: const TextStyle(color: Colors.white),
              items: sortOptions.map((String sortOption) {
                return DropdownMenuItem<String>(
                  value: sortOption,
                  child: Text(sortOption),
                );
              }).toList(),
              onChanged: (newValue) {
                onSortChanged(newValue!);
              },
            ),
          ),
        ],
      ),
    );
  }
}
