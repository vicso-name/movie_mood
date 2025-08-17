class AppStrings {
  // App Error - Technical Messages
  static const String noInternetConnectionTech = 'No internet connection';
  static const String requestTimeoutTech = 'Request timeout';
  static const String apiLimitExceededTech = 'API limit exceeded';
  static const String invalidApiKeyTech = 'Invalid API key';
  static const String resourceNotFoundTech = 'Resource not found';
  static const String serverErrorTech = 'Server error';

  // App Error - User Messages
  static const String checkInternetAndRetry =
      'Check your internet connection and try again';
  static const String requestTakingTooLong =
      'The request is taking too long. Please try again';
  static const String tooManyRequestsWait =
      'Too many requests. Please wait a moment and try again';
  static const String serviceTempUnavailable =
      'Service temporarily unavailable. Please try again later';
  static const String noResultsForSearch = 'No results found for your search';
  static const String serverExperiencingIssues =
      'Server is experiencing issues. Please try again later';
  static const String somethingWentWrongRetry =
      'Something went wrong. Please try again';

  // Main Screen Navigation
  static const String navMood = 'Mood';
  static const String navFavorite = 'Favorite';
  static const String surpriseMeEmoji = '🎲';

  // General
  static const String appName = 'Mood Movies';
  static const String appFullName = 'Movie by Mood';
  static const String back = 'Back';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String noResults = 'No results found';

  // Mood selection screen
  static const String chooseYourMood = 'What’s your mood like?';
  static const String surpriseMe = 'Surprise Me!';
  static const String whatAreYouInTheMoodFor =
      'Choose a mood, and I’ll find movies for you.';
  static const String searchByActorTooltip = 'Search by Actor';
  static const String topMoviesTooltip = 'Top Movies';
  static const String favoritesTooltip = 'Favorites';

  // Mood Detector
  static const String basedOnGenres = 'Based on genres:';
  static const String basedOnTitleKeywords = 'Based on title keywords:';
  static const String autoDetectedCategory = 'Auto-detected category';

  // Actor Search
  static const String searchByActor = 'Search by Actor';
  static const String actorSearchHint =
      'Enter actor name (e.g. Arnold Schwarzenegger)';
  static const String popularActors = 'Popular Actors';
  static const String actorMovies = 'Movies starring';
  static const String noActorResults = 'No movies found for this actor';
  static const String actorNotFound = 'Actor not found in our database';
  static const String addMoreActors =
      'We\'re constantly adding more actors to our database';
  static const String moviesFound = 'movies found';

  // Moods
  static const String moodHappy = 'Happy';
  static const String moodRomantic = 'Romantic';
  static const String moodSad = 'Sad';
  static const String moodCozy = 'Cozy';
  static const String moodInspiring = 'Inspiring';
  static const String moodThrilling = 'Thrilling';

  // Movie list
  static const String moviesFor = 'Movies for';
  static const String rating = 'Rating';
  static const String year = 'Year';
  static const String randomMovies = 'Random Movies';
  static const String suggestOthers = 'Suggest Others';
  static const String showMoreOptions = 'Show More Options';
  static const String findDifferentMovies = 'Find Different Movies';
  static const String getFreshSuggestions = 'Get fresh';
  static const String suggestions = 'suggestions';
  static const String discoverMore = 'Discover more';
  static const String keepExploring = 'Keep exploring new options';
  static const String movieLowercase = 'movie';
  static const String moviesLowercase = 'movies';

  // Movie details
  static const String addToFavorites = 'Add to Favorites';
  static const String removeFromFavorites = 'Remove from Favorites';
  static const String watchOn = 'Watch on';
  static const String overview = 'Overview';
  static const String releaseDate = 'Release Date';
  static const String runtime = 'Runtime';
  static const String genres = 'Genres';

  // Favorites
  static const String favorites = 'Favorites';
  static const String noFavorites = 'No favorite movies yet';
  static const String addSomeMovies =
      'Add some movies to your favorites to see them here';

  // Errors
  static const String networkError = 'Network error';
  static const String serverError = 'Server error';
  static const String unknownError = 'Unknown error';

  // Onboarding
  static const String onboardingWelcomeTitle =
      'Welcome to ${AppStrings.appName}';
  static const String onboardingWelcomeDescription =
      'Discover movies that perfectly match your current mood';
  static const String onboardingActorTitle = 'Search by Your Favorite Actors';
  static const String onboardingActorDescription =
      'Find movies starring your beloved actors instantly';
  static const String onboardingFavoritesTitle = 'Build Your Watchlist';
  static const String onboardingFavoritesDescription =
      'Save movies you love and discover where to watch them';
  static const String onboardingSurpriseTitle = 'Feeling Adventurous?';
  static const String onboardingSurpriseDescription =
      'Let our algorithm surprise you with random discoveries';
  static const String getStarted = 'Get Started';
  static const String continueText = 'Continue';
  static const String skip = 'Skip';

  // Sharing
  static const String shareCollection = 'Share Collection';
  static const String inviteFriends = 'Invite Friends';
  static const String myCollection = 'My Collection';
  static const String movie = 'movie';
  static const String movies = 'movies';
  static const String mood = 'mood';
  static const String moods = 'moods';
  static const String failedToShare = 'Failed to share';
  static const String discoverMoviesByMood =
      'Discover movies that match your mood!';
  static const String usingAppDescription =
      'an amazing app that recommends movies based on how you\'re feeling.';
  static const String searchByMoodFeature =
      'Search by mood (Happy, Romantic, Sad, etc.)';
  static const String findByActorsFeature =
      'Find movies by your favorite actors';
  static const String buildWatchlistFeature = 'Build your personal watchlist';
  static const String randomPicksFeature = 'Get surprised with random picks';
  static const String downloadAppTonight =
      'and find your perfect movie tonight!';
  static const String curatedMoviesText = 'I\'ve curated';
  static const String amazingMoviesOrganized =
      'amazing movies organized by mood! 🍿';
  static const String myMovieMoods = 'My movie moods:';
  static const String someOfMyFavorites = 'Some of my favorites:';
  static const String wantToBuildCollection =
      'Want to build your own movie collection?';
  static const String discoverYourMood =
      'and discover movies that match YOUR mood!';
  static const String imUsing = 'I\'m using';
  static const String download = 'Download';

  // Actor Search Screen
  static const String actorSearchTitle = 'Actor Search';
  static const String actorSearchDescription =
      'Search for movies by your favorite actors. Start typing to see suggestions!';
  static const String tryAnotherActor = 'Try Another Actor';
  static const String moviesFoundSuffix = 'movies found';
  static const String movieFoundSuffix = 'movie found';

  // Movie Details Screen
  static const String addedToCategory = 'Added to';
  static const String categoryText = 'category';
  static const String removedFromFavorites = 'Removed from favorites';
  static const String director = 'Director';
  static const String cast = 'Cast';

  // Top Movies Screen
  static const String topMovies = 'Top Movies';
  static const String curatedMovieCollections = 'Curated Movie Collections';
  static const String discoverBestFilms =
      'Discover the best films across different categories';
  static const String popularCollections = 'Popular Collections';
  static const String allCollections = 'All Collections';
  static const String collections = 'Collections';
  static const String avgCollection = 'Avg/Collection';
  static const String popular = 'POPULAR';
  static const String close = 'Close';
  static const String noMoviesInCollection =
      'No movies found in this collection';
  static const String backToCollections = 'Back to Collections';

  // Loading Widget - General Messages
  static const String loadingGeneral = '⏳ Loading...';
  static const String processing = '🔄 Processing...';
  static const String almostThere = '⚡ Almost there...';

  // Loading Widget - Movie Search
  static const String searchingMovies = '🎬 Searching for movies...';
  static const String analyzingGenres = '🎭 Analyzing genres...';
  static const String checkingRatings = '⭐ Checking ratings...';
  static const String findingBestMatches = '🍿 Finding the best matches...';

  // Loading Widget - Actor Search
  static const String searchingFilmography = '🎭 Searching filmography...';
  static const String findingBestPerformances =
      '🎬 Finding best performances...';
  static const String sortingByRatings = '⭐ Sorting by ratings...';
  static const String almostReady = '🍿 Almost ready...';

  // Loading Widget - Movie Details
  static const String gettingMovieDetails = '📋 Getting movie details...';
  static const String loadingInformation = '🎬 Loading information...';
  static const String fetchingRatings = '⭐ Fetching ratings...';

  // Loading Widget - Mood Specific Messages
  // Happy
  static const String lookingForHappyFilms = '😊 Looking for happy films...';
  static const String findingComedies = '🎭 Finding comedies...';
  static const String searchingFeelGoodMovies =
      '🌟 Searching feel-good movies...';
  static const String almostGotPerfectPicks =
      '🍿 Almost got the perfect picks!';

  // Romantic
  static const String findingRomanticStories = '💕 Finding romantic stories...';
  static const String searchingLoveTales = '❤️ Searching love tales...';
  static const String lookingForDateMovies =
      '🌹 Looking for perfect date movies...';
  static const String almostReadyForRomance = '✨ Almost ready for romance!';

  // Sad
  static const String findingEmotionalDramas = '🎭 Finding emotional dramas...';
  static const String searchingTouchingStories =
      '💧 Searching touching stories...';
  static const String lookingForDeepFilms = '🖤 Looking for deep films...';
  static const String preparingHeartfeltCinema =
      '🎬 Preparing heartfelt cinema...';

  // Cozy
  static const String findingCozyFilms = '🏠 Finding cozy films...';
  static const String searchingComfortMovies = '☕ Searching comfort movies...';
  static const String lookingForWarmStories = '🔥 Looking for warm stories...';
  static const String almostReadyForCoziness = '🧸 Almost ready for coziness!';

  // Inspiring
  static const String findingInspiringStories =
      '⭐ Finding inspiring stories...';
  static const String searchingMotivationalFilms =
      '🚀 Searching motivational films...';
  static const String lookingForSuccessTales =
      '💪 Looking for success tales...';
  static const String almostGotInspiration = '🏆 Almost got your inspiration!';

  // Thrilling
  static const String findingThrillingAdventures =
      '⚡ Finding thrilling adventures...';
  static const String searchingActionPackedFilms =
      '🎯 Searching action-packed films...';
  static const String lookingForAdrenalineRush =
      '💥 Looking for adrenaline rush...';
  static const String almostReadyForExcitement =
      '🔥 Almost ready for excitement!';

  // Default mood
  static const String analyzingYourMood = '🎬 Analyzing your mood...';
  static const String findingPerfectMatches = '🎭 Finding perfect matches...';
  static const String selectingBestOptions = '⭐ Selecting best options...';
  static const String almostReadyDefault = '🍿 Almost ready!';

  // Loading Widget - Additional
  static const String thisMightTakeFewSeconds =
      'This might take a few seconds...';

  // Error Widget
  static const String help = 'Help';
  static const String gotIt = 'Got it';
  static const String connectionTips = 'Connection Tips';
  static const String noInternetConnection = 'No Internet Connection';
  static const String requestTimeout = 'Request Timeout';
  static const String tooManyRequests = 'Too Many Requests';
  static const String serviceUnavailable = 'Service Unavailable';
  static const String notFound = 'Not Found';
  static const String somethingWentWrong = 'Something Went Wrong';
  static const String connectionTipsText =
      '• Check your Wi-Fi or mobile data\n• Make sure you have internet access\n• Try switching between Wi-Fi and mobile data\n• Restart your internet connection';

  // Streaming Availability Widget
  static const String whereToWatch = 'Where to watch';
  static const String movieNotAvailable =
      'This movie is currently not available on major streaming platforms.';
  static const String foundStreamingOptions = 'Found';
  static const String streamingOptionsText = 'streaming options!';
  static const String watchAdToUnlock =
      'Watch a short ad to unlock all streaming platforms and prices';
  static const String watchAdUnlock = 'Watch Ad & Unlock';
  static const String freeTakesSeconds = 'Free • Takes 15-30 seconds';
  static const String loadingAd = 'Loading ad...';
  static const String pleaseWaitStreaming =
      'Please wait while we prepare your streaming options';
  static const String free = 'Free';
  static const String streaming = 'Streaming';
  static const String rent = 'Rent';
  static const String buy = 'Buy';
  static const String platform = 'platform';
  static const String platforms = 'platforms';
  static const String service = 'service';
  static const String services = 'services';
  static const String option = 'option';
  static const String options = 'options';
  static const String from = 'from';
  static const String couldNotOpenStreaming =
      'Could not open streaming service';
}
