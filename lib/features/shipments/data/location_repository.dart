import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PlaceResult {
  final String? placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> types;
  final String? district;
  final String? sector;
  final String? locationType;
  final String? source;
  final double? confidence;
  final bool verificationRequired;
  final double? accuracyMeters;

  const PlaceResult({
    this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.types = const [],
    this.district,
    this.sector,
    this.locationType,
    this.source,
    this.confidence,
    this.verificationRequired = true,
    this.accuracyMeters,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        placeId: j['place_id']?.toString() ?? j['placeId']?.toString(),
        name: j['name']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        lat: _num(j['lat']),
        lng: _num(j['lng']),
        types: (j['types'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        district: j['district']?.toString(),
        sector: j['sector']?.toString(),
        locationType: j['location_type']?.toString(),
        source: j['source']?.toString(),
        confidence: _nullableNum(j['confidence']),
        verificationRequired: j['verification_required'] == null
            ? true
            : j['verification_required'] == true,
        accuracyMeters: _nullableNum(j['accuracy_meters']),
      );

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;

  static double? _nullableNum(dynamic v) {
    if (v == null) return null;
    return v is num ? v.toDouble() : double.tryParse('$v');
  }

  Map<String, dynamic> toMap() => {
        'place_id': placeId,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'types': types,
        'district': district,
        'sector': sector,
        'location_type': locationType,
        'source': source,
        'confidence': confidence,
        'verification_required': verificationRequired,
        'accuracy_meters': accuracyMeters,
      };
}

class LocationRepository {
  final ApiClient _api;
  LocationRepository(this._api);

  Future<List<PlaceResult>> search(String query, {double? lat, double? lng}) async {
    final q = <String, dynamic>{'q': query};
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

  Future<PlaceResult?> reverse(double lat, double lng) async {
    final r = await _api.get(
      '/api/locations/reverse',
      query: {'lat': lat, 'lng': lng},
    );
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    if ((d['address'] ?? '').toString().isEmpty) return null;
    return PlaceResult.fromJson(d);
  }

  Future<PlaceResult> verify({
    required double lat,
    required double lng,
    String? locationType,
    String? inputText,
    double? accuracyMeters,
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      if (locationType != null && locationType.isNotEmpty)
        'location_type': locationType,
      if (inputText != null && inputText.trim().isNotEmpty)
        'input_text': inputText.trim(),
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
    };

    final r = await _api.post('/api/locations/verify', body: body);
    final d = Map<String, dynamic>.from(r['data'] ?? {});
    return PlaceResult.fromJson(d);
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(ref.watch(apiClientProvider)),
);
