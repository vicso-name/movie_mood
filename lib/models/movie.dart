class Movie {
  final String imdbID;
  final String title;
  final String? plot;
  final String? poster;
  final String year;
  final String? imdbRating;
  final String? genre;
  final String? director;
  final String? actors;
  final String? runtime;
  final String type;

  Movie({
    required this.imdbID,
    required this.title,
    this.plot,
    this.poster,
    required this.year,
    this.imdbRating,
    this.genre,
    this.director,
    this.actors,
    this.runtime,
    required this.type,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      imdbID: json['imdbID'] ?? '',
      title: json['Title'] ?? '',
      plot: json['Plot'] != 'N/A' ? json['Plot'] : null,
      poster: json['Poster'] != 'N/A' ? json['Poster'] : null,
      year: json['Year'] ?? '',
      imdbRating: json['imdbRating'] != 'N/A' ? json['imdbRating'] : null,
      genre: json['Genre'] != 'N/A' ? json['Genre'] : null,
      director: json['Director'] != 'N/A' ? json['Director'] : null,
      actors: json['Actors'] != 'N/A' ? json['Actors'] : null,
      runtime: json['Runtime'] != 'N/A' ? json['Runtime'] : null,
      type: json['Type'] ?? 'movie',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imdbID': imdbID,
      'Title': title,
      'Plot': plot,
      'Poster': poster,
      'Year': year,
      'imdbRating': imdbRating,
      'Genre': genre,
      'Director': director,
      'Actors': actors,
      'Runtime': runtime,
      'Type': type,
    };
  }

  String get fullPosterUrl {
    return poster ??
        'https://via.placeholder.com/300x450/1A1A2E/FFFFFF?text=${Uri.encodeComponent(title)}';
  }

  double get rating {
    if (imdbRating == null) return 0.0;
    return double.tryParse(imdbRating!) ?? 0.0;
  }

  List<String> get genreList {
    if (genre == null) return [];
    return genre!.split(', ').map((g) => g.trim()).toList();
  }
}
