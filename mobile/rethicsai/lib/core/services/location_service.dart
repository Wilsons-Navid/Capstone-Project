import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class LocationService {
  static const String _tag = 'LocationService';
  
  static Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.w(_tag, 'Location permissions are denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Logger.w(_tag, 'Location permissions are permanently denied');
        return false;
      }
      
      Logger.i(_tag, 'Location permission granted');
      return true;
    } catch (e) {
      Logger.e(_tag, 'Error checking location permission', e);
      return false;
    }
  }
  
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      Logger.e(_tag, 'Error checking location service status', e);
      return false;
    }
  }
  
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.w(_tag, 'Location services are disabled');
        return null;
      }
      
      // Check permissions
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        Logger.w(_tag, 'Location permission not granted');
        return null;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      Logger.i(_tag, 'Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      Logger.e(_tag, 'Error getting current location', e);
      return null;
    }
  }
  
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // For now, return coordinates as string
      // In production, you might want to use geocoding to get actual address
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      Logger.e(_tag, 'Error converting coordinates to address', e);
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }
  
  static Future<String?> getCurrentLocationAddress() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) return null;
      
      return await getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      Logger.e(_tag, 'Error getting current location address', e);
      return null;
    }
  }
  
  static Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) return null;
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      Logger.e(_tag, 'Error getting current coordinates', e);
      return null;
    }
  }
}