import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/controllers/history_controller.dart';
import 'package:apites/pages/history/history_manga_card.dart';
import 'package:apites/widgets/shimmer_loading.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showSettings(BuildContext context, HistoryController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2F33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('History Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFFF6444),
                title: const Text('Track Reading History', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Record manga you open here', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: controller.historyService.isEnabled.value,
                onChanged: controller.setTrackingEnabled,
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear History'),
                  onPressed: () {
                    Get.back();
                    _confirmClearHistory(context, controller);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, HistoryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Clear History?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all manga from your history. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              controller.clearHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HistoryController controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
        ),
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 237, 237, 237)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'History settings',
            onPressed: () => _showSettings(context, controller),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF23272A),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const FavoriteListShimmer();
        }

        if (controller.historyMangaDetails.isEmpty) {
          return const Center(
            child: Text(
              'No history yet',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFFF6444),
          onRefresh: () => controller.loadHistory(isRefresh: true),
          child: ListView.builder(
            itemCount: controller.historyMangaDetails.length,
            itemBuilder: (context, index) {
              final manga = controller.historyMangaDetails[index];
              return HistoryMangaCard(
                key: ValueKey(manga.id),
                manga: manga,
                onRemove: () => controller.removeFromHistory(manga.id),
              );
            },
          ),
        );
      }),
    );
  }
}
