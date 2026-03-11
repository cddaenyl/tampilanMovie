import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final String apiKey = '4fe2699c90c03235d9e2c95a6d425d46';
  final String apiUrl = 'https://api.themoviedb.org/3/movie/popular?api_key=';
  final String accessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0ZmUyNjk5YzkwYzAzMjM1ZDllMmM5NWE2ZDQyNWQ0NiIsIm5iZiI6MTczMTUwNDQ3My4zNjI4NDg1LCJzdWIiOiI2NzM0YTY1OGFjNWRkZTdlYjJkZGQ0NzYiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.sqeqv7zg4yxnHvmpfo9CoD_NB9b025Wo62WAV5x_YgU';
  final String accountId = '21627769';
  final Set<int> favorites = {};

  Future<List<dynamic>> fetchMovies() async {
    final response = await http.get(Uri.parse('$apiUrl$apiKey&language=en-US&page=1'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load movies');
    }
  }

    Future<void> toggleFavorite(int movieId, bool addToFavorites) async {
    final String url =
        'https://api.themoviedb.org/3/account/$accountId/favorite';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "media_type": "movie",
        "media_id": movieId,
        "favorite": addToFavorites
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Popular Movies"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMovies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final movies = snapshot.data!;
            return ListView.builder(
              itemCount: (movies.length / 4).ceil(),
              itemBuilder: (context, index) {
                int firstMovie = index * 4;
                int lastMovie = firstMovie + 4;
                final movieRow = movies.sublist(
                  firstMovie,
                  lastMovie > movies.length ? movies.length : lastMovie,
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: movieRow.map((movie) {
                    final title = movie['title'];
                    final posterPath = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';

                    return Expanded(
                      child: Card(
                        margin: EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(movieId: movie['id']),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Image.network(
                                posterPath,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 80,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              //Tambahin tombol favorit
                              IconButton(
                                icon: Icon(
                                  favorites.contains(movie['id'])
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final bool isCurrentlyFavorite = favorites.contains(movie['id']);
                                  try {
                                    await toggleFavorite(movie['id'], !isCurrentlyFavorite);
                                    setState(() {
                                      if (isCurrentlyFavorite) {
                                        favorites.remove(movie['id']);
                                      } else {
                                        favorites.add(movie['id']);
                                      }
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to update favorite status')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class MovieDetailScreen extends StatelessWidget {
  final int movieId;
  final String apiKey = '1acfd875db8b2029a85bf84cd8818774';

  MovieDetailScreen({required this.movieId});

  Future<Map<String, dynamic>> fetchMovieDetails(int id) async {
    final response = await http.get(Uri.parse('https://api.themoviedb.org/3/movie/$id?api_key=$apiKey&language=en-US'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Movie Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchMovieDetails(movieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final movie = snapshot.data!;
            final title = movie['title'];
            final overview = movie['overview'];
            final releaseDate = movie['release_date'];
            final posterPath = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(posterPath, width: 200, height: 300),
                  ),
                  SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("Release Date: $releaseDate"),
                  SizedBox(height: 10),
                  Text(
                    overview,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
