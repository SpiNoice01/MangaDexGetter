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

  // Search for authors
  static Future<List<Map<String, String>>> searchAuthors(String name) async {
    if (name.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse("${AppConstants.baseUrl}/author?name=${Uri.encodeComponent(name)}&limit=10"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authors = data['data'] as List<dynamic>;
        return authors.map((author) {
          return {
            'id': author['id'].toString(),
            'name': author['attributes']['name'].toString(),
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching authors: $e");
    }
    return [];
  }

  // Get list of Manga
  static Future<List<MangaModel>> getMangaList({
    String title = '',
    String authorName = '',
    int limit = 10,
    int offset = 0,
    String? sortOrder,
    String? includedTagId,
    String? status,
    bool hideNsfw = false,
  }) async {
    String contentRating = hideNsfw 
        ? "&contentRating[]=safe&contentRating[]=suggestive" 
        : "&contentRating[]=safe&contentRating[]=suggestive&contentRating[]=erotica&contentRating[]=pornographic";
        
    String url = "${AppConstants.baseUrl}/manga?includes[]=cover_art$contentRating&limit=$limit&offset=$offset";
    
    if (authorName.isNotEmpty) {
      final authorResponse = await http.get(Uri.parse("${AppConstants.baseUrl}/author?name=${Uri.encodeComponent(authorName)}&limit=5"));
      if (authorResponse.statusCode == 200) {
        final authorData = json.decode(authorResponse.body);
        final authors = authorData['data'] as List<dynamic>;
        if (authors.isEmpty) return []; // No authors found
        
        for (var author in authors) {
          url += "&authors[]=${author['id']}";
        }
      } else {
        return [];
      }
    } else if (title.isNotEmpty) {
      url += "&title=${Uri.encodeComponent(title)}";
    }
    if (sortOrder != null) {
      url += "&order[$sortOrder]=desc";
    }
    if (includedTagId != null && includedTagId.isNotEmpty) {
      url += "&includedTags[]=$includedTagId";
    }
    if (status != null && status.isNotEmpty) {
      url += "&status[]=$status";
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

  // Get chapters for a manga (feed), newest/oldest first depending on isAscending
  static Future<List<Map<String, dynamic>>> getMangaChapters(
    String mangaId, {
    required int limit,
    required int offset,
    bool isAscending = true,
    String translatedLanguage = 'en',
  }) async {
    final order = isAscending ? 'asc' : 'desc';
    final langQuery = translatedLanguage == 'all' ? '' : 'translatedLanguage[]=$translatedLanguage&';
    final response = await http.get(Uri.parse(
        '${AppConstants.baseUrl}/manga/$mangaId/feed?${langQuery}order[chapter]=$order&limit=$limit&offset=$offset'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load manga chapters');
    }
  }

  // Get single chapter details
  static Future<Map<String, dynamic>> getChapterDetails(String chapterId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/chapter/$chapterId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load chapter details');
    }
  }

  // Get chapter page image URLs
  static Future<List<String>> getChapterPages(String chapterId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/at-home/server/$chapterId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final baseUrl = data['baseUrl'];
      final hash = data['chapter']['hash'];
      final pages = data['chapter']['data'];
      return pages.map<String>((page) => "$baseUrl/data/$hash/$page").toList();
    } else {
      throw Exception('Failed to load chapter pages');
    }
  }

  // Get the chapter immediately following [currentChapterId] in the feed
  static Future<Map<String, dynamic>?> getNextChapter(
    String mangaId,
    String currentChapterId, {
    String translatedLanguage = 'en',
  }) async {
    final chapters = await getMangaChapters(mangaId, limit: 100, offset: 0, translatedLanguage: translatedLanguage);
    for (int i = 0; i < chapters.length; i++) {
      if (chapters[i]['id'] == currentChapterId && i + 1 < chapters.length) {
        return chapters[i + 1];
      }
    }
    return null;
  }

  // Get author details
  static Future<Map<String, dynamic>> getAuthorDetails(String authorId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/author/$authorId'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load author details');
    }
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
