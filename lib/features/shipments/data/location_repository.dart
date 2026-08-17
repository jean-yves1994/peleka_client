import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PlaceResult {
  final String? placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> types;

  const PlaceResult({this.placeId, required this.name, required this.address, required this.lat, required this.lng, this.types = const []});

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
    placeId: j['place_id']?.toString(),
    name: j['name']?.toString() ?? '',
    address: j['address']?.toString() ?? '',
    lat: _num(j['lat']),
    lng: _num(j['lng']),
    types: (j['types'] as List? ?? []).map((e) => e.toString()).toList(),
  );

  static double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;

  Map<String, dynamic> toMap() => {'place_id': placeId, 'name': name, 'address': address, 'lat': lat, 'lng': lng, 'types': types};
}

class LocationRepository {
  final ApiClient _api;
  LocationRepository(this._api);

  Future<List<PlaceResult>> search(String query, {double? lat, double? lng}) async {
    final q = <String, dynamic>{'q': query};
    if (lat != null && lng != null) { q['lat'] = lat; q['lng'] = lng; }
    final r = await _api.get('/api/locations/search', query: q);
    final data = r['data'];
    final list = data is List ? data : (data is Map && data['places'] is List ? data['places'] : const []);
    return list.map((e) => PlaceResult.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<PlaceResult?> reverse(double lat, double lng) async {
    final r = await _api.get('/api/locations/reverse', query: {'lat': lat, 'lng': lng});
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    if ((d['address'] ?? '').toString().isEmpty) return null;
    return PlaceResult.fromJson(d);
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository(ref.watch(apiClientProvider)));
