class ChapterModel {
  final String id;
  final String title;
  final String chapter;
  final String volume;
  final String translatedLanguage;
  final int pages;

  ChapterModel({
    required this.id,
    required this.title,
    required this.chapter,
    required this.volume,
    required this.translatedLanguage,
    required this.pages,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    final rawTitle = attributes['title']?.toString() ?? '';
    final chapterNum = attributes['chapter']?.toString() ?? '';
    final titleString = rawTitle.isNotEmpty 
        ? rawTitle 
        : (chapterNum.isNotEmpty ? 'Chapter $chapterNum' : 'Oneshot');

    return ChapterModel(
      id: json['id']?.toString() ?? "",
      title: titleString,
      chapter: chapterNum,
      volume: attributes['volume']?.toString() ?? '',
      translatedLanguage: attributes['translatedLanguage']?.toString() ?? 'en',
      pages: attributes['pages'] as int? ?? 0,
    );
  }
}
