import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/cameroon.dart';

/// Outcome of a device-location address detection.
class CameroonDetection {
  final Placemark? placemark;

  /// True when a position was obtained and reverse-geocoded.
  final bool detected;

  /// True when the detected country is Cameroon.
  final bool inCameroon;

  const CameroonDetection({
    this.placemark,
    this.detected = false,
    this.inCameroon = false,
  });
}

/// Uses the device's location to (best-effort) prefill a delivery address and
/// enforce the "address must be in Cameroon" rule. Geocoding is platform
/// geocoder-backed and can fail (no permission, no provider, offline) — every
/// failure degrades to manual entry instead of blocking the form.
abstract final class CameroonLocator {
  static const Set<String> _cmNames = {
    'cameroon',
    'cameroun',
    'kamerun',
    'camerounaise',
  };

  /// Requests location permission, gets the current position and reverse
  /// geocodes it. Returns [CameroonDetection.detected] false on any failure.
  static Future<CameroonDetection> detect() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const CameroonDetection();
      }
      final position = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) return const CameroonDetection();
      return CameroonDetection(
        placemark: placemarks.first,
        detected: true,
        inCameroon: _isCameroon(placemarks.first),
      );
    } catch (_) {
      return const CameroonDetection();
    }
  }

  /// True when the placemark's country resolves to Cameroon (by name or ISO
  /// `CM`). Handles the VPN case: a device abroad reports a foreign country.
  static bool _isCameroon(Placemark placemark) {
    final country = (placemark.country ?? '').toLowerCase();
    final iso = (placemark.isoCountryCode ?? '').toLowerCase();
    return iso == 'cm' || _cmNames.any(country.contains);
  }

  /// Maps the placemark's administrative area onto one of the 10 Cameroon
  /// regions (e.g. "Centre", "Littoral", "West"). Returns null when it doesn't
  /// match, so the form falls back to the user's profile region / manual pick.
  static String? regionFromPlacemark(Placemark placemark) {
    final area = (placemark.administrativeArea ?? '').trim();
    if (area.isEmpty) return null;
    for (final region in kCameroonRegions) {
      if (region.toLowerCase() == area.toLowerCase()) return region;
    }
    return null;
  }

  /// Composes a human address line from the placemark's parts.
  static String addressLineFrom(Placemark placemark) => [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
}
