import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location_data.dart';
import 'location_provider/location_provider.dart';
import 'location_provider/osm_location_provider.dart';

class LocationService {
  LocationService({LocationProvider? provider}) : _provider = provider;

  final LocationProvider? _provider;
  static const String _defaultSearchBaseUrl =
      'https://nominatim.openstreetmap.org';

  Future<List<LocationData>> searchBangladesh(String query) async {
    final injectedProvider = _provider;
    if (injectedProvider != null) {
      return injectedProvider.search(query);
    }

    // This setting allows administrators to switch to another compatible
    // geocoding endpoint without shipping a new app build.
    var baseUrl = _defaultSearchBaseUrl;
    try {
      final settings = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get();
      final configured = settings.data()?['locationSearchBaseUrl']
          ?.toString()
          .trim();
      if (configured != null && configured.isNotEmpty) {
        baseUrl = configured;
      }
    } catch (_) {
      // Public Nominatim remains the safe default if settings cannot be read.
    }

    return OsmLocationProvider(baseUrl: baseUrl).search(query);
  }
}
