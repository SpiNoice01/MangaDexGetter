class AppConstants {
  static const String baseUrl = "https://api.mangadex.org";
  static const String uploadsUrl = "https://uploads.mangadex.org";
  
  // SharedPreferences Keys
  static const String likedMangaKey = "likedManga";
  static const String cachedMangaListKey = "mangaList";
  static const String historyMangaIdsKey = "historyMangaIds";
  static const String historyTrackingEnabledKey = "historyTrackingEnabled";
  static const String showVerticalReadOverlayKey = "showVerticalReadOverlay";
  static const String showVerticalPageNumberKey = "showVerticalPageNumber";

  // Most-recently-viewed manga ids kept in history
  static const int maxHistoryEntries = 100;
}
