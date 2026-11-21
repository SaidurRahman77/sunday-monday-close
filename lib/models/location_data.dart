class LocationData {
  const LocationData({
    required this.provider,
    required this.providerPlaceId,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.city,
    this.district,
    this.country = 'Bangladesh',
  });

  final String provider;
  final String providerPlaceId;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? city;
  final String? district;
  final String country;

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'providerPlaceId': providerPlaceId,
        'formattedAddress': formattedAddress,
        'latitude': latitude,
        'longitude': longitude,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (district != null && district!.isNotEmpty)
          'district': district,
        'country': country,
      };

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      provider: map['provider']?.toString() ?? 'legacy',
      providerPlaceId: map['providerPlaceId']?.toString() ?? '',
      formattedAddress: map['formattedAddress']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      city: map['city']?.toString(),
      district: map['district']?.toString(),
      country: map['country']?.toString() ?? 'Bangladesh',
    );
  }

  bool get hasValidCoordinates =>
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180 &&
      !(latitude == 0 && longitude == 0);
}
