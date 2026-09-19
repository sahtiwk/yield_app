import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

typedef HarvestPosition = ({double latitude, double longitude});

final currentLocationProvider = Provider<Future<HarvestPosition> Function()>(
  (ref) => () async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError('Location permission unavailable');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  },
);
