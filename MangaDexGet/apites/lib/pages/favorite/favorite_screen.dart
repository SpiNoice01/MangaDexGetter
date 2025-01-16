import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/services/mangadex_services.dart';
import 'package:apites/pages/favorite/favorite_manga_card.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<String> favoriteMangaIds = [];
  List<Map<String, dynamic>> favoriteMangaDetails = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('likedManga') ?? [];
    setState(() {
      favoriteMangaIds = ids;
    });
    await fetchFavoriteMangaDetails(ids);
  }

  Future<void> fetchFavoriteMangaDetails(List<String> ids) async {
    List<Map<String, dynamic>> mangaDetails = [];
    for (String id in ids) {
      final manga = await MangaDexService.getMangaDetails(id);
      mangaDetails.add(manga);
    }
    setState(() {
      favoriteMangaDetails = mangaDetails;
    });
  }

  Future<void> saveFavoritesOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedManga', favoriteMangaIds);
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = favoriteMangaDetails.removeAt(oldIndex);
      favoriteMangaDetails.insert(newIndex, item);

      final id = favoriteMangaIds.removeAt(oldIndex);
      favoriteMangaIds.insert(newIndex, id);
    });
    saveFavoritesOrder();
  }

  Future<void> _refreshFavorites() async {
    await loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true to indicate changes
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorites',
            style: TextStyle(
              color: Color.fromARGB(255, 237, 237, 237),
            ),
          ),
          backgroundColor: const Color(0xFF2C2F33),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 237, 237, 237),
          ),
        ),
        backgroundColor: const Color(0xFF23272A),
        body: favoriteMangaDetails.isEmpty
            ? const Center(
                child: Text(
                  'No favorites yet',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshFavorites,
                child: ReorderableListView.builder(
                  onReorder: onReorder,
                  itemCount: favoriteMangaDetails.length,
                  itemBuilder: (context, index) {
                    final manga = favoriteMangaDetails[index];
                    return FavoriteMangaCard(
                      key: ValueKey(manga['id']),
                      manga: manga,
                      index: index,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
