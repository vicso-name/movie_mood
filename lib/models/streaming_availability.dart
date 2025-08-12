class StreamingSource {
  final int sourceId;
  final String name;
  final String type; // 'subscription', 'purchase', 'rent', 'free'
  final String region;
  final String? webUrl;
  final String? iosUrl;
  final String? androidUrl;
  final double? price;
  final String? currency;
  final String? format; // 'HD', 'SD', '4K'

  StreamingSource({
    required this.sourceId,
    required this.name,
    required this.type,
    required this.region,
    this.webUrl,
    this.iosUrl,
    this.androidUrl,
    this.price,
    this.currency,
    this.format,
  });

  factory StreamingSource.fromJson(Map<String, dynamic> json) {
    return StreamingSource(
      sourceId: json['source_id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'subscription',
      region: json['region'] ?? 'US',
      webUrl: json['web_url'],
      iosUrl: json['ios_url'],
      androidUrl: json['android_url'],
      price: json['price']?.toDouble(),
      currency: json['currency'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'name': name,
      'type': type,
      'region': region,
      'web_url': webUrl,
      'ios_url': iosUrl,
      'android_url': androidUrl,
      'price': price,
      'currency': currency,
      'format': format,
    };
  }

  String get displayPrice {
    if (price == null || currency == null) return '';
    return '\$${price!.toStringAsFixed(2)}';
  }

  String? _cachedPreferredUrl;

  String get preferredUrl {
    // Кэшируем результат чтобы не пересчитывать постоянно
    _cachedPreferredUrl ??= webUrl ?? iosUrl ?? androidUrl ?? '';
    return _cachedPreferredUrl!;
  }
}

class StreamingAvailability {
  final String imdbId;
  final List<StreamingSource> subscriptionSources;
  final List<StreamingSource> purchaseSources;
  final List<StreamingSource> rentSources;
  final List<StreamingSource> freeSources;
  final DateTime lastUpdated;

  StreamingAvailability({
    required this.imdbId,
    required this.subscriptionSources,
    required this.purchaseSources,
    required this.rentSources,
    required this.freeSources,
    required this.lastUpdated,
  });

  factory StreamingAvailability.fromWatchmodeJson(
    String imdbId,
    List<dynamic> sources,
  ) {
    final subscriptionSources = <StreamingSource>[];
    final purchaseSources = <StreamingSource>[];
    final rentSources = <StreamingSource>[];
    final freeSources = <StreamingSource>[];

    for (final sourceJson in sources) {
      final source = StreamingSource.fromJson(sourceJson);

      switch (source.type.toLowerCase()) {
        case 'subscription':
        case 'sub':
          subscriptionSources.add(source);
          break;
        case 'purchase':
        case 'buy':
          purchaseSources.add(source);
          break;
        case 'rent':
          rentSources.add(source);
          break;
        case 'free':
        case 'ads':
          freeSources.add(source);
          break;
      }
    }

    // Sort by popularity/recognition (Netflix, Prime, etc. first)
    _sortSourcesByPopularity(subscriptionSources);
    _sortSourcesByPopularity(purchaseSources);
    _sortSourcesByPopularity(rentSources);
    _sortSourcesByPopularity(freeSources);

    return StreamingAvailability(
      imdbId: imdbId,
      subscriptionSources: subscriptionSources,
      purchaseSources: purchaseSources,
      rentSources: rentSources,
      freeSources: freeSources,
      lastUpdated: DateTime.now(),
    );
  }

  factory StreamingAvailability.fromJson(Map<String, dynamic> json) {
    return StreamingAvailability(
      imdbId: json['imdb_id'] ?? '',
      subscriptionSources:
          (json['subscription_sources'] as List<dynamic>?)
              ?.map((e) => StreamingSource.fromJson(e))
              .toList() ??
          [],
      purchaseSources:
          (json['purchase_sources'] as List<dynamic>?)
              ?.map((e) => StreamingSource.fromJson(e))
              .toList() ??
          [],
      rentSources:
          (json['rent_sources'] as List<dynamic>?)
              ?.map((e) => StreamingSource.fromJson(e))
              .toList() ??
          [],
      freeSources:
          (json['free_sources'] as List<dynamic>?)
              ?.map((e) => StreamingSource.fromJson(e))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imdb_id': imdbId,
      'subscription_sources': subscriptionSources
          .map((e) => e.toJson())
          .toList(),
      'purchase_sources': purchaseSources.map((e) => e.toJson()).toList(),
      'rent_sources': rentSources.map((e) => e.toJson()).toList(),
      'free_sources': freeSources.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  bool get hasAnyAvailability =>
      subscriptionSources.isNotEmpty ||
      purchaseSources.isNotEmpty ||
      rentSources.isNotEmpty ||
      freeSources.isNotEmpty;

  bool get isExpired {
    final oneHour = Duration(hours: 1);
    return DateTime.now().difference(lastUpdated) > oneHour;
  }

  List<StreamingSource> get allSources {
    return [
      ...freeSources,
      ...subscriptionSources,
      ...rentSources,
      ...purchaseSources,
    ];
  }

  static void _sortSourcesByPopularity(List<StreamingSource> sources) {
    // Define popularity order
    const popularityMap = {
      'Netflix': 1,
      'Amazon Prime Video': 2,
      'Disney Plus': 3,
      'HBO Max': 4,
      'Hulu': 5,
      'Apple TV Plus': 6,
      'Paramount Plus': 7,
      'Peacock': 8,
      'Tubi': 9,
      'Crackle': 10,
    };

    sources.sort((a, b) {
      final aPriority = popularityMap[a.name] ?? 999;
      final bPriority = popularityMap[b.name] ?? 999;
      return aPriority.compareTo(bPriority);
    });
  }
}
