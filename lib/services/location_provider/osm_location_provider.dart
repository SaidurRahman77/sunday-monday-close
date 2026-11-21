import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/location_data.dart';
import 'location_provider.dart';

/// Public Nominatim adapter. Requests are user-triggered (not autocomplete)
/// and throttled to respect the public service's usage policy.
class OsmLocationProvider implements LocationProvider {
  OsmLocationProvider({
    http.Client? client,
    this.baseUrl = 'https://nominatim.openstreetmap.org',
  }) : _client = client ?? _sharedClient;

  static final http.Client _sharedClient = http.Client();
  final http.Client _client;
  final String baseUrl;
  static DateTime? _lastRequestAt;
  static Future<void> _requestQueue = Future<void>.value();
  static final Map<String, List<LocationData>> _searchCache = {};
  static const Duration _minimumRequestInterval = Duration(seconds: 1);

  @override
  Future<List<LocationData>> search(String query) async {
    final trimmed = query.trim();
    final cacheKey = trimmed.toLowerCase();
    final cached = _searchCache[cacheKey];
    if (cached != null) return cached;
    if (trimmed.length < 3) {
      throw Exception('Enter at least 3 characters to search.');
    }

    final baseUri = Uri.parse(baseUrl);
    if (baseUri.scheme != 'https' || baseUri.host.isEmpty) {
      throw Exception('Location search provider configuration is invalid.');
    }
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final uri = baseUri.replace(
      path: '$basePath/search',
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'bd',
        'accept-language': 'en,bn',
      },
    );

    final response = await _queuedGet(uri);

    if (response.statusCode != 200) {
      throw Exception('Location search is temporarily unavailable. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      _searchCache[cacheKey] = const [];
      return const [];
    }

    final locations = decoded.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final address = item['address'] is Map
          ? Map<String, dynamic>.from(item['address'] as Map)
          : <String, dynamic>{};
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      final city = _firstNonEmpty([
        address['city'],
        address['town'],
        address['municipality'],
        address['village'],
      ]);
      final district = _firstNonEmpty([
        address['county'],
        address['state_district'],
        address['district'],
      ]);
      final country = address['country']?.toString() ?? 'Bangladesh';
      final displayParts = <String>[];
      for (final part in [
        item['name'],
        address['neighbourhood'],
        address['suburb'],
        city,
        district,
        country,
      ]) {
        final value = part?.toString().trim();
        if (value != null && value.isNotEmpty &&
            !displayParts.any((existing) => existing.toLowerCase() == value.toLowerCase())) {
          displayParts.add(value);
        }
      }
      var display = displayParts.join(', ').isEmpty
          ? (item['display_name']?.toString() ?? trimmed)
          : displayParts.join(', ');
      if (display.length > 100) {
        final conciseParts = [city, district, country]
            .whereType<String>()
            .where((part) => part.trim().isNotEmpty)
            .toList();
        display = conciseParts.join(', ');
      }
      if (display.length > 100) {
        display = display.substring(0, 100).trim();
      }

      return LocationData(
        provider: 'osm',
        providerPlaceId: 'osm:${item['osm_type'] ?? 'place'}:${item['osm_id'] ?? ''}',
        formattedAddress: display,
        latitude: lat,
        longitude: lon,
        city: city,
        district: district,
        country: country,
      );
    }).whereType<LocationData>().toList();
    _searchCache[cacheKey] = locations;
    return locations;
  }

  Future<http.Response> _queuedGet(Uri uri) {
    final completer = Completer<http.Response>();
    _requestQueue = _requestQueue.then((_) async {
      final previous = _lastRequestAt;
      if (previous != null) {
        final elapsed = DateTime.now().difference(previous);
        final wait = _minimumRequestInterval - elapsed;
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequestAt = DateTime.now();
      try {
        final headers = <String, String>{
          'Accept': 'application/json',
        };
        // Browsers control User-Agent/Referer headers. On mobile/desktop,
        // identify this application explicitly as required by Nominatim.
        if (!kIsWeb) {
          headers['User-Agent'] =
              'SundayMondayClose/1.0 (location search)';
        }
        final response = await _client.get(
          uri,
          headers: headers,
        ).timeout(const Duration(seconds: 15));
        completer.complete(response);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
