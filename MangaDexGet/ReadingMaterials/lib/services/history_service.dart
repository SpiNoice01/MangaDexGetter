import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apites/core/constants/app_constants.dart';

class HistoryService extends GetxService {
  var historyIds = <String>[].obs; // most recently viewed first
  var isEnabled = true.obs;

  Future<HistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(AppConstants.historyTrackingEnabledKey) ?? true;
    historyIds.assignAll(prefs.getStringList(AppConstants.historyMangaIdsKey) ?? []);
    return this;
  }

  Future<void> recordView(String mangaId) async {
    if (!isEnabled.value) return;

    final updated = List<String>.from(historyIds)..remove(mangaId);
    updated.insert(0, mangaId);
    if (updated.length > AppConstants.maxHistoryEntries) {
      updated.removeRange(AppConstants.maxHistoryEntries, updated.length);
    }
    historyIds.assignAll(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.historyMangaIdsKey, updated);
  }

  Future<void> removeFromHistory(String mangaId) async {
    final updated = List<String>.from(historyIds)..remove(mangaId);
    historyIds.assignAll(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.historyMangaIdsKey, updated);
  }

  Future<void> clearHistory() async {
    historyIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.historyMangaIdsKey);
  }

  Future<void> setTrackingEnabled(bool value) async {
    isEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.historyTrackingEnabledKey, value);
  }
}
