import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/constants/api_constants.dart';

class GeocodingService {
  /// Get coordinates from address (Geocoding)
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final url = ApiConstants.getGeocodingUrl(address);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AqariPropertyApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final location = results[0];
          return {
            'lat': double.parse(location['lat']),
            'lng': double.parse(location['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  /// Get address from coordinates (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = ApiConstants.getReverseGeocodingUrl(lat, lng);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AqariPropertyApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Get current location using device GPS
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('Get current location error: $e');
      return null;
    }
  }
}
