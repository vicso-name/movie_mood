class TopMoviesDatabase {
  // 🎬 Статический список лучших фильмов по категориям с IMDb ID
  static const Map<String, List<String>> topMovieCollections = {
    'all_time_classics': [
      'tt0111161', // The Shawshank Redemption (1994)
      'tt0068646', // The Godfather (1972)
      'tt0071562', // The Godfather: Part II (1974)
      'tt0468569', // The Dark Knight (2008)
      'tt0050083', // 12 Angry Men (1957)
      'tt0108052', // Schindler's List (1993)
      'tt0167260', // The Lord of the Rings: The Return of the King (2003)
      'tt0110912', // Pulp Fiction (1994)
      'tt0167261', // The Lord of the Rings: The Fellowship of the Ring (2001)
      'tt0060196', // The Good, the Bad and the Ugly (1966)
      'tt0120737', // The Lord of the Rings: The Two Towers (2002)
      'tt0137523', // Fight Club (1999)
      'tt0109830', // Forrest Gump (1994)
      'tt0080684', // Star Wars: Episode V - The Empire Strikes Back (1980)
      'tt0073486', // One Flew Over the Cuckoo's Nest (1975)
      'tt0099685', // Goodfellas (1990)
      'tt0076759', // Star Wars: Episode IV - A New Hope (1977)
      'tt0047478', // Seven Samurai (1954)
      'tt0317219', // Cars (2006)
      'tt0102926', // The Silence of the Lambs (1991)
      'tt0038650', // It's a Wonderful Life (1946)
      'tt0118799', // Life Is Beautiful (1997)
      'tt0114369', // Se7en (1995)
      'tt0120815', // Saving Private Ryan (1998)
      'tt0110413', // Léon: The Professional (1994)
    ],

    'modern_masterpieces': [
      'tt1375666', // Inception (2010)
      'tt0816692', // Interstellar (2014)
      'tt0407887', // The Departed (2006)
      'tt0482571', // The Prestige (2006)
      'tt0910970', // WALL-E (2008)
      'tt1853728', // Django Unchained (2012)
      'tt0361748', // Inglourious Basterds (2009)
      'tt1345836', // The Dark Knight Rises (2012)
      'tt0978762', // Mary and Max (2009)
      'tt0434409', // V for Vendetta (2005)
      'tt1049413', // Up (2009)
      'tt0364569', // Oldboy (2003)
      'tt6751668', // Parasite (2019)
      'tt7286456', // Joker (2019)
      'tt4154756', // Avengers: Endgame (2019)
      'tt4154664', // Captain America: Civil War (2016)
      'tt2015381', // Guardians of the Galaxy (2014)
      'tt0887912', // In the Valley of Elah (2007)
      'tt1392190', // Mad Max: Fury Road (2015)
      'tt1856101', // Blade Runner 2049 (2017)
      'tt1895587', // Spotlight (2015)
      'tt2582802', // Whiplash (2014)
      'tt2380307', // Coco (2017)
      'tt0405094', // Lives of Others (2006)
      'tt0372784', // Batman Begins (2005)
    ],

    'blockbuster_hits': [
      'tt0848228', // The Avengers (2012)
      'tt0120338', // Titanic (1997)
      'tt0499549', // Avatar (2009)
      'tt2527336', // Star Wars: The Last Jedi (2017)
      'tt2488496', // Star Wars: The Force Awakens (2015)
      'tt2527338', // Star Wars: The Rise of Skywalker (2019)
      'tt1825683', // Black Panther (2018)
      'tt0369610', // Jurassic World (2015)
      'tt1065073', // Boyhood (2014)
      'tt0088763', // Back to the Future (1985)
      'tt0087469', // Indiana Jones and the Temple of Doom (1984)
      'tt0082971', // Raiders of the Lost Ark (1981)
      'tt0089881', // Back to the Future Part II (1989)
      'tt0090605', // Aliens (1986)
      'tt0078748', // Alien (1979)
      'tt0103064', // Terminator 2: Judgment Day (1991)
      'tt0088247', // The Terminator (1984)
      'tt0112573', // Braveheart (1995)
      'tt0266543', // Finding Nemo (2003)
      'tt0317705', // The Incredibles (2004)
      'tt0435761', // Toy Story 3 (2010)
      'tt0114709', // Toy Story (1995)
      'tt0120363', // Toy Story 2 (1999)
      'tt4881806', // Toy Story 4 (2019)
      'tt0133093', // The Matrix (1999)
    ],

    'award_winners': [
      'tt0338013', // Eternal Sunshine of the Spotless Mind (2004)
      'tt0253474', // The Pianist (2002)
      'tt0407887', // The Departed (2006)
      'tt1504320', // The King's Speech (2010)
      'tt1454468', // Gravity (2013)
      'tt1663202', // The Revenant (2015)
      'tt4633694', // Spider-Man: Into the Spider-Verse (2018)
      'tt2096673', // Inside Out (2015)
      'tt3783958', // La La Land (2016)
      'tt1305806', // The Secret in Their Eyes (2009)
      'tt0993846', // The Wolf of Wall Street (2013)
      'tt0206634', // Children of Men (2006)
      'tt1832382', // A Separation (2011)
      'tt1205489', // Gran Torino (2008)
      'tt0405159', // Million Dollar Baby (2004)
      'tt0264464', // Catch Me If You Can (2002)
      'tt0268978', // A Beautiful Mind (2001)
      'tt0268126', // Traffic (2000)
      'tt0167404', // The Sixth Sense (1999)
      'tt0120689', // The Green Mile (1999)
      'tt0119217', // Good Will Hunting (1997)
      'tt0112641', // Casino (1995)
      'tt0180093', // Requiem for a Dream (2000)
      'tt0910970', // WALL-E (2008)
      'tt0434409', // V for Vendetta (2005)
    ],

    'recent_gems': [
      'tt6966692', // Green Book (2018)
      'tt7131622', // Once Upon a Time in Hollywood (2019)
      'tt8503618', // Hamilton (2020)
      'tt10872600', // Spider-Man: No Way Home (2021)
      'tt9032400', // Eternals (2021)
      'tt9114286', // Black Widow (2021)
      'tt1877830', // X-Men: Days of Future Past (2014)
      'tt9376612', // Shang-Chi and the Legend of the Ten Rings (2021)
      'tt9243946', // El Camino: A Breaking Bad Movie (2019)
      'tt8367814', // The Mandalorian (2019)
      'tt1160419', // Dune (2021)
      'tt15398776', // Oppenheimer (2023)
      'tt15239678', // Barbie (2023)
      'tt9362722', // Spider-Man: Across the Spider-Verse (2023)
      'tt6791350', // Guardians of the Galaxy Vol. 3 (2023)
      'tt10298810', // The Menu (2022)
      'tt9419884', // Doctor Strange in the Multiverse of Madness (2022)
      'tt9376612', // Shang-Chi and the Legend of the Ten Rings (2021)
      'tt11564570', // Top Gun: Maverick (2022)
      'tt8503618', // Hamilton (2020)
      'tt1950186', // Ford v Ferrari (2019)
      'tt8579674', // 1917 (2019)
      'tt9362722', // Spider-Man: Across the Spider-Verse (2023)
      'tt4154796', // Avengers: Infinity War (2018)
      'tt9243946', // El Camino: A Breaking Bad Movie (2019)
    ],

    'action_packed': [
      'tt0133093', // The Matrix (1999)
      'tt0234215', // The Matrix Reloaded (2003)
      'tt0242653', // The Matrix Revolutions (2003)
      'tt2911666', // John Wick (2014)
      'tt4425200', // John Wick: Chapter 2 (2017)
      'tt6146586', // John Wick: Chapter 3 - Parabellum (2019)
      'tt10366206', // John Wick: Chapter 4 (2023)
      'tt0458339', // Captain America: The First Avenger (2011)
      'tt1843866', // Captain America: The Winter Soldier (2014)
      'tt3498820', // Captain America: Civil War (2016)
      'tt0478970', // Ant-Man (2015)
      'tt5095030', // Ant-Man and the Wasp (2018)
      'tt10954600', // Ant-Man and the Wasp: Quantumania (2023)
      'tt1631867', // Fast Five (2011)
      'tt1905041', // Fast & Furious 6 (2013)
      'tt2820852', // Furious 7 (2015)
      'tt4630562', // The Fate of the Furious (2017)
      'tt6806448', // Fast & Furious Presents: Hobbs & Shaw (2019)
      'tt5433138', // F9 (2021)
      'tt5433140', // Fast X (2023)
      'tt0482571', // The Prestige (2006)
      'tt1375666', // Inception (2010)
      'tt0816692', // Interstellar (2014)
      'tt1856101', // Blade Runner 2049 (2017)
      'tt1392190', // Mad Max: Fury Road (2015)
    ],

    'family_favorites': [
      'tt0266543', // Finding Nemo (2003)
      'tt0317705', // The Incredibles (2004)
      'tt0435761', // Toy Story 3 (2010)
      'tt0114709', // Toy Story (1995)
      'tt0120363', // Toy Story 2 (1999)
      'tt4881806', // Toy Story 4 (2019)
      'tt0910970', // WALL-E (2008)
      'tt1049413', // Up (2009)
      'tt2096673', // Inside Out (2015)
      'tt2380307', // Coco (2017)
      'tt6105098', // The Lion King (2019)
      'tt0120762', // The Lion King (1994)
      'tt0245429', // Spirited Away (2001)
      'tt0347149', // Howl's Moving Castle (2004)
      'tt0096283', // My Neighbor Totoro (1988)
      'tt1587310', // Frozen (2013)
      'tt4520988', // Frozen II (2019)
      'tt2948372', // Zootopia (2016)
      'tt3521164', // Moana (2016)
      'tt4196776', // Turning Red (2022)
      'tt13320622', // Luca (2021)
      'tt7146812', // Onward (2020)
      'tt0892769', // How to Train Your Dragon (2010)
      'tt1646971', // How to Train Your Dragon 2 (2014)
      'tt2386490', // The Good Dinosaur (2015)
    ],
  };

  // 🏷️ Метаданные категорий для UI
  static const Map<String, CategoryInfo> categoryInfo = {
    'all_time_classics': CategoryInfo(
      name: 'All-Time Classics',
      description: 'Timeless masterpieces that defined cinema',
      emoji: '🏆',
      color: 0xFFFFD700, // Gold
    ),
    'modern_masterpieces': CategoryInfo(
      name: 'Modern Masterpieces',
      description: 'Contemporary films that redefined storytelling',
      emoji: '✨',
      color: 0xFF4A90E2, // Blue
    ),
    'blockbuster_hits': CategoryInfo(
      name: 'Blockbuster Hits',
      description: 'Box office champions that captivated millions',
      emoji: '💥',
      color: 0xFFE74C3C, // Red
    ),
    'award_winners': CategoryInfo(
      name: 'Award Winners',
      description: 'Oscar and Golden Globe acclaimed films',
      emoji: '🎭',
      color: 0xFF9B59B6, // Purple
    ),
    'recent_gems': CategoryInfo(
      name: 'Recent Gems',
      description: 'Outstanding films from the last few years',
      emoji: '💎',
      color: 0xFF1ABC9C, // Teal
    ),
    'action_packed': CategoryInfo(
      name: 'Action Packed',
      description: 'High-octane thrillers and adventures',
      emoji: '⚡',
      color: 0xFFFF6B35, // Orange
    ),
    'family_favorites': CategoryInfo(
      name: 'Family Favorites',
      description: 'Perfect movies for the whole family',
      emoji: '👨‍👩‍👧‍👦',
      color: 0xFF27AE60, // Green
    ),
  };

  // 📊 Получить все категории для UI
  static List<String> getAllCategories() {
    return topMovieCollections.keys.toList();
  }

  // 🎬 Получить фильмы конкретной категории
  static List<String> getMoviesForCategory(String category) {
    return topMovieCollections[category] ?? [];
  }

  // 📝 Получить информацию о категории
  static CategoryInfo? getCategoryInfo(String category) {
    return categoryInfo[category];
  }

  // 🔍 Поиск категорий по запросу
  static List<String> searchCategories(String query) {
    if (query.trim().isEmpty) return getAllCategories();

    final normalizedQuery = query.toLowerCase().trim();
    final List<String> matches = [];

    for (final category in getAllCategories()) {
      final info = getCategoryInfo(category);
      if (info != null) {
        final normalizedName = info.name.toLowerCase();
        final normalizedDescription = info.description.toLowerCase();

        if (normalizedName.contains(normalizedQuery) ||
            normalizedDescription.contains(normalizedQuery) ||
            category.contains(normalizedQuery)) {
          matches.add(category);
        }
      }
    }

    return matches;
  }

  // 🎲 Получить случайную категорию
  static String getRandomCategory() {
    final categories = getAllCategories();
    return categories[(DateTime.now().millisecondsSinceEpoch) %
        categories.length];
  }

  // 📈 Популярные категории (для быстрого доступа)
  static List<String> getPopularCategories() {
    return [
      'all_time_classics',
      'modern_masterpieces',
      'blockbuster_hits',
      'recent_gems',
    ];
  }

  // 📊 Получить статистику базы данных
  static Map<String, dynamic> getDatabaseStats() {
    int totalMovies = 0;
    final categoryCount = topMovieCollections.length;

    for (final movies in topMovieCollections.values) {
      totalMovies += movies.length;
    }

    // Подсчет уникальных фильмов
    final uniqueMovies = <String>{};
    for (final movies in topMovieCollections.values) {
      uniqueMovies.addAll(movies);
    }

    return {
      'total_categories': categoryCount,
      'total_movie_entries': totalMovies,
      'unique_movies': uniqueMovies.length,
      'average_per_category': (totalMovies / categoryCount).round(),
    };
  }
}

// 📋 Класс информации о категории
class CategoryInfo {
  final String name;
  final String description;
  final String emoji;
  final int color;

  const CategoryInfo({
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
  });
}
