import '../../models/location_data.dart';

abstract class LocationProvider {
  Future<List<LocationData>> search(String query);
}
