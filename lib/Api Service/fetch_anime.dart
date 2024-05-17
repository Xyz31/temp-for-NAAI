import 'dart:convert';
import 'package:http/http.dart' as http;

class Anime {
  final String title;
  final String type;
  final String synopsis;
  final String rating;
  final String year;
  final String imageUrl;

  Anime({
    required this.title,
    required this.type,
    required this.synopsis,
    required this.rating,
    required this.year,
    required this.imageUrl,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      title: json['data']['title'] as String,
      type: json['data']['type'] as String,
      synopsis: json['data']['synopsis'] as String,
      rating: json['data']['rating'] as String,
      year: json['data']['year'] as String,
      imageUrl: json['data']['images']['jpg']['large_image_url'] as String,
    );
  }
}

class AnimeService {
  static Future<List<Anime>> fetchAnimeList(String query) async {
    const baseurl = "https://api.jikan.moe/v4/anime/";

    final url = baseurl + query;

    try {
      final response = await http.get(Uri.parse(baseurl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);

        final List<dynamic> animeData = jsonData['data'];

        // Parse the list of anime data into a list of Anime objects
        final List<Anime> animeList = animeData.map((json) {
          return Anime.fromJson(json);
        }).toList();

        return animeList;
      } else {
        throw Exception('Failed to load anime data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
