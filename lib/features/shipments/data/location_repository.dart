import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PlaceResult {
  final String? placeId;
  final String? knownLocationId;
  final String name;
  final String address;
  final String? city;
  final String? district;
  final String? sector;
  final String source;
  final double lat;
  final double lng;
  final double? accuracyMeters;
  final List<String> types;

  const PlaceResult({
    this.placeId,
    this.knownLocationId,
    required this.name,
    required this.address,
    this.city,
    this.district,
    this.sector,
    this.source = 'external',
    required this.lat,
    required this.lng,
    this.accuracyMeters,
    this.types = const [],
  });

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        placeId: j['place_id']?.toString(),
        knownLocationId: j['id']?.toString(),
        name: j['name']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        city: j['city']?.toString(),
        district: j['district']?.toString(),
        sector: j['sector']?.toString(),
        source: j['source']?.toString() ?? 'external',
        lat: _num(j['lat']),
        lng: _num(j['lng']),
        accuracyMeters: _nullableNum(j['accuracy_meters']),
        types: (j['types'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;

  static double? _nullableNum(dynamic v) => v == null
      ? null
      : v is num
          ? v.toDouble()
          : double.tryParse(v.toString());

  Map<String, dynamic> toMap() => {
        'place_id': placeId,
        'id': knownLocationId,
        'name': name,
        'address': address,
        'city': city,
        'district': district,
        'sector': sector,
        'source': source,
        'lat': lat,
        'lng': lng,
        'accuracy_meters': accuracyMeters,
        'types': types,
      };
}

class LocationRepository {
  final ApiClient _api;
  LocationRepository(this._api);

  Future<List<PlaceResult>> search(String query, {double? lat, double? lng}) async {
    final q = <String, dynamic>{'q': query, 'limit': 8};
    if (lat != null && lng != null) {
      q['lat'] = lat;
      q['lng'] = lng;
    }
    final r = await _api.get('/api/locations/search', query: q);
    final data = r['data'];
    final list = data is List
        ? data
        : (data is Map && data['places'] is List ? data['places'] : const []);
    return list
        .map((e) => PlaceResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PlaceResult?> reverse(double lat, double lng, {double? accuracyMeters}) async {
    final r = await _api.get('/api/locations/reverse', query: {'lat': lat, 'lng': lng});
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    if ((d['address'] ?? '').toString().isEmpty) return null;
    if (accuracyMeters != null) d['accuracy_meters'] = accuracyMeters;
    return PlaceResult.fromJson(d);
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(ref.watch(apiClientProvider)),
);
