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
  // 🔥 НОВОЕ ПОЛЕ: Кешируем результат проверки изображения
  bool? _posterValidationCache;

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
      '_posterValidated': _posterValidationCache, // Сохраняем кеш валидации
    };
  }

  // 🔥 БАЗОВАЯ ПРОВЕРКА: Только структура URL (быстрая)
  bool get hasBasicPosterUrl {
    if (poster == null || poster!.isEmpty) {
      return false;
    }

    // Проверяем, что это не placeholder URL
    if (poster!.contains('placeholder.com') ||
        poster!.contains('via.placeholder.com')) {
      return false;
    }

    // Проверяем, что URL выглядит валидно
    final uri = Uri.tryParse(poster!);
    if (uri == null || !uri.hasScheme) {
      return false;
    }

    return true;
  }

  // 🔥 ПОЛНАЯ ПРОВЕРКА: Включает результат HTTP-проверки (если есть)
  bool get hasValidPoster {
    // Если нет базового URL - сразу false
    if (!hasBasicPosterUrl) return false;

    // Если есть кешированный результат проверки - используем его
    if (_posterValidationCache != null) return _posterValidationCache!;

    // Иначе считаем валидным до проверки (будет проверено асинхронно)
    return true;
  }

  // 🔥 НОВЫЙ МЕТОД: Установка результата валидации
  void setPosterValidation(bool isValid) {
    _posterValidationCache = isValid;
  }

  // 🔥 НОВЫЙ МЕТОД: Сброс кеша валидации
  void resetPosterValidation() {
    _posterValidationCache = null;
  }

  // 🔥 НОВЫЙ МЕТОД: Проверка, была ли уже валидация
  bool get isPosterValidationCached => _posterValidationCache != null;

  String get fullPosterUrl {
    // Используем hasValidPoster для проверки
    if (hasValidPoster) {
      return poster!;
    }

    return 'https://via.placeholder.com/300x450/1A1A2E/FFFFFF?text=${Uri.encodeComponent(title)}';
  }

  double get rating {
    if (imdbRating == null) return 0.0;
    return double.tryParse(imdbRating!) ?? 0.0;
  }

  List<String> get genreList {
    if (genre == null) return [];
    return genre!.split(', ').map((g) => g.trim()).toList();
  }

  // 🔥 НОВЫЙ МЕТОД: Создание копии с обновленной валидацией
  Movie copyWithPosterValidation(bool isValid) {
    final newMovie = Movie(
      imdbID: imdbID,
      title: title,
      plot: plot,
      poster: poster,
      year: year,
      imdbRating: imdbRating,
      genre: genre,
      director: director,
      actors: actors,
      runtime: runtime,
      type: type,
    );
    newMovie._posterValidationCache = isValid;
    return newMovie;
  }
}
