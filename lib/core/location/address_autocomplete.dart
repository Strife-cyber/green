import 'package:dio/dio.dart';

import '../utils/cameroon.dart';

/// One autocomplete suggestion from the geocoder.
class AddressSuggestion {
  final String displayName;

  /// The Cameroon region this suggestion maps to, if it can be determined.
  final String? region;

  const AddressSuggestion({required this.displayName, this.region});
}

/// Address autocomplete backed by **OpenStreetMap Nominatim** — free, no API
/// key — restricted to Cameroon (`countrycodes=cm`), which also enforces the
/// "address must be in Cameroon" rule as the user types.
///
/// Production caveat: Nominatim is rate-limited and meant for light use; swap
/// this for Google Places Autocomplete when the app ships (same interface).
abstract final class AddressAutocomplete {
  static const String _endpoint = 'https://nominatim.openstreetmap.org/search';

  static Future<List<AddressSuggestion>> search(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    try {
      // Nominatim requires a descriptive User-Agent; we do not use the shared
      // auth client (no tokens here — this is a public geocoder).
      final dio = Dio(
        BaseOptions(
          headers: {
            'User-Agent': 'GreenishApp/1.0 (farm-to-table marketplace; contact: dev@greenish.cm)',
          },
        ),
      );
      final res = await dio.get(
        _endpoint,
        queryParameters: {
          'q': q,
          'format': 'json',
          'countrycodes': 'cm',
          'limit': limit,
          'addressdetails': 1,
        },
      );
      if (res.data is! List) return const [];
      return [
        for (final item in res.data as List)
          if (item is Map<String, dynamic>)
            AddressSuggestion(
              displayName: item['display_name'] as String? ?? '',
              region: _regionOf(item),
            ),
      ].where((s) => s.displayName.isNotEmpty).toList();
    } catch (_) {
      // Offline / rate-limited → just stop suggesting; manual entry still works.
      return const [];
    }
  }

  /// Extracts a Cameroon region from the result's address parts, mapping the
  /// geocoder's `state`/`city` onto one of the 10 regions when possible.
  static String? _regionOf(Map<String, dynamic> item) {
    final address = item['address'];
    if (address is! Map<String, dynamic>) return null;
    final state = address['state'] ?? address['region'] ?? address['city'] ?? address['town'];
    if (state is! String || state.isEmpty) return null;
    final lower = state.toLowerCase();
    for (final region in kCameroonRegions) {
      if (region.toLowerCase() == lower || lower.contains(region.toLowerCase())) {
        return region;
      }
    }
    return null;
  }
}
