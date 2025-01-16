import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;

  const SearchBar({
    super.key,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Search',
          labelStyle: const TextStyle(color: Colors.white),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              onSearch(searchController.text);
            },
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        onSubmitted: (query) {
          onSearch(query);
        },
      ),
    );
  }
}