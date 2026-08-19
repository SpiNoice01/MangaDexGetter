class MangaModel {
  final String id;
  final String title;
  final String description;
  final List<String> genres;
  final String? coverUrl;
  final DateTime? createdAt;
  final String? status;

  MangaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genres,
    this.coverUrl,
    this.createdAt,
    this.status,
  });

  factory MangaModel.fromJson(Map<String, dynamic> json) {
    // If loading from SharedPreferences cache (flat structure, no 'attributes')
    if (json.containsKey('title') && !json.containsKey('attributes')) {
      return MangaModel(
        id: json['id']?.toString() ?? "",
        title: json['title']?.toString() ?? "Unknown Title",
        description: json['description']?.toString() ?? "No Description",
        genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        coverUrl: json['coverUrl']?.toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
        status: json['status']?.toString(),
      );
    }

    // Extract title (prefer English, fallback to any available, then default)
    String parsedTitle = "Unknown Title";
    if (json['attributes']?['title'] != null && (json['attributes']['title'] as Map).isNotEmpty) {
      final titleMap = json['attributes']['title'] as Map<String, dynamic>;
      parsedTitle = titleMap['en']?.toString() ?? 
                    titleMap.values.firstOrNull?.toString() ?? 
                    "Unknown Title";
    } else if (json['attributes']?['altTitles'] != null) {
      // Fallback to altTitles if primary title object is completely empty
      final altTitles = json['attributes']['altTitles'] as List<dynamic>;
      if (altTitles.isNotEmpty) {
        final firstAlt = altTitles.first as Map<String, dynamic>;
        parsedTitle = firstAlt['en']?.toString() ?? 
                      firstAlt.values.firstOrNull?.toString() ?? 
                      "Unknown Title";
      }
    }

    // Extract description
    String parsedDesc = "No Description";
    if (json['attributes']?['description'] != null && (json['attributes']['description'] as Map).isNotEmpty) {
      final descMap = json['attributes']['description'] as Map<String, dynamic>;
      parsedDesc = descMap['en']?.toString() ?? 
                   descMap.values.firstOrNull?.toString() ?? 
                   "No Description";
    }

    // Extract genres/tags
    List<String> parsedGenres = [];
    if (json['attributes']?['tags'] != null) {
      final tags = json['attributes']['tags'] as List<dynamic>;
      parsedGenres = tags.map((tag) {
        return tag['attributes']?['name']?['en']?.toString() ?? "Unknown";
      }).toList();
    }
    
    // Add contentRating to genres if not safe
    if (json['attributes']?['contentRating'] != null && json['attributes']['contentRating'] != 'safe') {
      String rating = json['attributes']['contentRating'].toString();
      rating = "${rating[0].toUpperCase()}${rating.substring(1)}";
      parsedGenres.insert(0, rating); // Put it at the beginning so it's always visible
    }

    // Extract coverUrl
    String? parsedCover = json['coverUrl']?.toString();
    
    // Extract createdAt
    DateTime? parsedCreatedAt;
    if (json['attributes']?['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['attributes']['createdAt'].toString());
    }
    
    // Extract status
    String? parsedStatus = json['attributes']?['status']?.toString();

    return MangaModel(
      id: json['id']?.toString() ?? "",
      title: parsedTitle,
      description: parsedDesc,
      genres: parsedGenres,
      coverUrl: parsedCover,
      createdAt: parsedCreatedAt,
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genres': genres,
      'coverUrl': coverUrl,
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
    };
  }
}
