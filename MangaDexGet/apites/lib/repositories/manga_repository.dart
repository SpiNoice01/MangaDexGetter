import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:apites/core/constants/app_constants.dart';
import 'package:apites/models/manga_model.dart';

class MangaRepository {
  // Helper to extract cover URL from relationships
  // By default we request the 256px thumbnail to save massive amounts of RAM and Bandwidth
  static String? _extractCoverUrl(String mangaId, List<dynamic>? relationships, {bool isThumbnail = true}) {
    if (relationships == null) return null;
    
    final coverArt = relationships.firstWhere(
      (rel) => rel['type'] == 'cover_art',
      orElse: () => null,
    ) as Map<String, dynamic>?;

    final coverFileName = coverArt?['attributes']?['fileName'];
    if (coverFileName != null) {
      final baseUrl = "${AppConstants.uploadsUrl}/covers/$mangaId/$coverFileName";
      // MangaDex supports .256.jpg and .512.jpg for lightweight thumbnails!
      return isThumbnail ? "$baseUrl.256.jpg" : baseUrl;
    }
    return null;
  }

  // Get list of Manga
  static Future<List<MangaModel>> getMangaList({
    String title = '',
    int limit = 10,
    int offset = 0,
    String? sortOrder,
    String? includedTagId,
  }) async {
    String url = "${AppConstants.baseUrl}/manga?includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic&limit=$limit&offset=$offset";
    if (title.isNotEmpty) {
      url += "&title=$title";
    }
    if (sortOrder != null) {
      url += "&order[$sortOrder]=desc";
    }
    if (includedTagId != null && includedTagId.isNotEmpty) {
      url += "&includedTags[]=$includedTagId";
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mangaList = (data['data'] as List<dynamic>);

      return mangaList.map((manga) {
        final coverUrl = _extractCoverUrl(manga['id'], manga['relationships'] as List<dynamic>?);
        manga['coverUrl'] = coverUrl; // Inject for model parsing
        return MangaModel.fromJson(manga);
      }).toList();
    } else {
      throw Exception('Failed to load manga');
    }
  }

  // Get list of Manga by IDs (batch fetch)
  static Future<List<MangaModel>> getMangaListByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    // MangaDex allows up to 100 ids per request
    String url = "${AppConstants.baseUrl}/manga?includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic&limit=${ids.length}";
    for (var id in ids) {
      url += "&ids[]=$id";
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mangaList = (data['data'] as List<dynamic>);

      return mangaList.map((manga) {
        final coverUrl = _extractCoverUrl(manga['id'], manga['relationships'] as List<dynamic>?);
        manga['coverUrl'] = coverUrl;
        return MangaModel.fromJson(manga);
      }).toList();
    } else {
      throw Exception('Failed to load manga batch');
    }
  }

  // Get popular Manga
  static Future<List<MangaModel>> getPopularManga() async {
    final response = await http.get(Uri.parse(
        "${AppConstants.baseUrl}/manga?includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic&order[followedCount]=desc&limit=10"));
        
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mangaList = (data['data'] as List<dynamic>);

      return mangaList.map((manga) {
        final coverUrl = _extractCoverUrl(manga['id'], manga['relationships'] as List<dynamic>?);
        manga['coverUrl'] = coverUrl;
        return MangaModel.fromJson(manga);
      }).toList();
    } else {
      throw Exception('Failed to load popular manga');
    }
  }

  // Get manga details (Full size cover)
  static Future<MangaModel> getMangaDetails(String mangaId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/manga/$mangaId?includes[]=cover_art'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        final mangaData = data['data'];
        final coverUrl = _extractCoverUrl(mangaId, mangaData['relationships'] as List<dynamic>?, isThumbnail: false);
        mangaData['coverUrl'] = coverUrl;
        return MangaModel.fromJson(mangaData);
      }
      throw Exception('Manga data is null');
    }
    throw Exception('Failed to load manga details: ${response.reasonPhrase}');
  }

  // Get manga tags (genres, formats, themes)
  static Future<List<Map<String, String>>> getMangaTags() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/manga/tag'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tags = (data['data'] as List<dynamic>);
      
      List<Map<String, String>> tagList = [];
      for (var tag in tags) {
        final id = tag['id'] as String;
        final name = tag['attributes']['name']['en'] as String;
        // Group can be genre, format, theme, etc.
        final group = tag['attributes']['group'] as String; 
        
        // Let's include everything except content warnings to keep the UI simple
        if (group != 'content') {
          tagList.add({'id': id, 'name': name});
        }
      }
      
      // Sort alphabetically by name
      tagList.sort((a, b) => a['name']!.compareTo(b['name']!));
      return tagList;
    }
    throw Exception('Failed to load tags');
  }
}
