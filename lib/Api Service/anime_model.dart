import 'dart:convert';

class Anime {
  final int malId;
  final String title;
  final String url;
  final String trailerThumbnail;

  Anime({
    required this.malId,
    required this.title,
    required this.url,
    required this.trailerThumbnail,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'],
      url: json['url'],
      trailerThumbnail: json['trailer']['images']['large_image_url'] ?? '',
    );
  }

  static List<Anime> parseAnimeList(String responseBody) {
    final parsed = json.decode(responseBody);
    return parsed['data'].map<Anime>((json) => Anime.fromJson(json)).toList();
  }

  @override
  String toString() {
    return 'Anime(malId: $malId, title: $title, url: $url, trailerThumbnail: $trailerThumbnail)';
  }
}
