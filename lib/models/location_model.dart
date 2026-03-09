// lib/models/location_model.dart

class LocationModel {
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;

  const LocationModel({
    required this.name,
    required this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'] as String,
      country: json['country'] as String? ?? '',
      admin1: json['admin1'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'admin1': admin1,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get displayName {
    final parts = <String>[name];
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      parts.add(admin1!);
    }
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
