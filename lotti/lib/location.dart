import 'package:dart_geohash/dart_geohash.dart';
import 'package:location/location.dart';
import 'package:lotti/classes/geolocation.dart';

class DeviceLocation {
  late Location location;

  DeviceLocation() {
    location = Location();
    init();
  }

  void init() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<LocationData> getCurrentLocation() async {
    LocationData _locationData = await location.getLocation();
    return _locationData;
  }

  static String getGeoHash({
    required double latitude,
    required double longitude,
  }) {
    return GeoHasher().encode(longitude, latitude);
  }

  Future<Geolocation?> getCurrentGeoLocation() async {
    LocationData locationData = await location.getLocation();
    DateTime now = DateTime.now();
    double? longitude = locationData.longitude;
    double? latitude = locationData.latitude;
    if (longitude != null && latitude != null) {
      return Geolocation(
        createdAt: now,
        timezone: now.timeZoneName,
        utcOffset: now.timeZoneOffset.inMinutes,
        latitude: latitude,
        longitude: longitude,
        altitude: locationData.altitude,
        speed: locationData.speed,
        accuracy: locationData.accuracy,
        heading: locationData.heading,
        headingAccuracy: locationData.headingAccuracy,
        speedAccuracy: locationData.speedAccuracy,
        geohashString: getGeoHash(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
  }
}
