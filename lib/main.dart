import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

// anime_model.dart
class Anime {
  final String title;
  final String type;
  final String synopsis;
  final String rating;
  final String year;
  final String imageUrl;
  final String youtubeURL;

  Anime({
    required this.title,
    required this.type,
    required this.synopsis,
    required this.rating,
    required this.year,
    required this.imageUrl,
    required this.youtubeURL,
  });
}

// anime_service.dart
class AnimeService {
  Future<List<Anime>> fetchAnimeList(String searchString, int page) async {
    final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime?q=$searchString&page=$page'));

    if (response.statusCode == 200) {
      List<Anime> animeList = [];
      final jsonData = json.decode(response.body);

      for (var animeData in jsonData['data']) {
        Anime anime = Anime(
          title: animeData['title'],
          type: animeData['type'],
          synopsis: animeData['synopsis'],
          rating: animeData['rating'],
          year: animeData['year'].toString(),
          imageUrl: animeData['images']['jpg']['large_image_url'].toString(),
          youtubeURL: animeData['trailer']['url'].toString(),
        );
        animeList.add(anime);
      }

      return animeList;
    } else {
      throw Exception('Failed to fetch anime list');
    }
  }
}

// main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anime List',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Anime> animeList = [];
  final AnimeService animeService = AnimeService();
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    loadAnime();
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid URL'),
            content: const Text('The URL is empty or invalid.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  Future<void> loadAnime() async {
    String query = ""; // Add your query here
    setState(() {
      isLoading = true;
    });
    try {
      List<Anime> newAnimeList =
          await animeService.fetchAnimeList(query, currentPage);
      setState(() {
        animeList.addAll(newAnimeList);
        isLoading = false;
      });
    } catch (e) {
      // Handle error
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadMoreAnime() async {
    String query = ""; // Add your query here
    setState(() {
      isLoadingMore = true;
    });
    try {
      List<Anime> newAnimeList =
          await animeService.fetchAnimeList(query, currentPage);
      setState(() {
        animeList.addAll(newAnimeList);
        isLoadingMore = false;
      });
    } catch (e) {
      // Handle error
      print("Inside catch before build");
      print(e);
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime List'),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: AnimeSearchDelegate(animeService),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return isLoading
                ? buildShimmerGrid(crossAxisCount)
                : buildAnimeGrid(crossAxisCount);
          },
        ),
      ),
    );
  }

  Widget buildShimmerGrid(int crossAxisCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 10,
      ),
      itemCount: 9, // Placeholder count for shimmer
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget buildAnimeGrid(int crossAxisCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
      ),
      itemCount: animeList.length + 1, // Add one for the "Load More" button
      itemBuilder: (context, index) {
        if (index == animeList.length) {
          return Center(
            child: isLoadingMore
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentPage++;
                      });
                      loadMoreAnime();
                    },
                    child: const Text('Load More'),
                  ),
          );
        }
        final anime = animeList[index];
        bool isHovering = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return MouseRegion(
              onEnter: (_) => setState(() => isHovering = true),
              onExit: (_) => setState(() => isHovering = false),
              child: GestureDetector(
                onTap: () => _launchURL(context, anime.youtubeURL),
                child: Transform.scale(
                  scale: isHovering ? 1.025 : 1.0,
                  child: Card(
                    elevation: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            anime.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text('Failed to load image ${error}'),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anime.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Year: ${anime.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rating: ${anime.rating}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Link: ${anime.youtubeURL}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AnimeSearchDelegate extends SearchDelegate {
  final AnimeService animeService;

  AnimeSearchDelegate(this.animeService);
  Future<void> _launchURL(BuildContext context, String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid URL'),
            content: const Text('The URL is empty or invalid.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: animeService.fetchAnimeList(query, 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              childAspectRatio: 0.5,
              crossAxisSpacing: 5,
              mainAxisSpacing: 10,
            ),
            itemCount: 9, // Placeholder count for shimmer
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        } else {
          final results = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final anime = results[index];
              bool isHovering = false;

              return StatefulBuilder(
                builder: (context, setState) {
                  return MouseRegion(
                    onEnter: (_) => setState(() => isHovering = true),
                    onExit: (_) => setState(() => isHovering = false),
                    child: GestureDetector(
                      onTap: () => _launchURL(context, anime.youtubeURL),
                      child: Transform.scale(
                        scale: isHovering ? 1.025 : 1.0,
                        child: Card(
                          elevation: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.network(
                                  anime.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child:
                                          Text('Failed to load image ${error}'),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anime.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Year: ${anime.year}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rating: ${anime.rating}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Link: ${anime.youtubeURL}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search Anime'));
  }
}
