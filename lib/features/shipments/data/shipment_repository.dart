import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/shipment.dart';
class ShipmentRepository {
  final ApiClient _api;
  ShipmentRepository(this._api);
  Future<Quote> quote({required double pickupLat, required double pickupLng, required double deliveryLat, required double deliveryLng,
    required double parcelWeightKg, String? pickupCity, String? deliveryCity, String? discountCode}) async {
    final b = <String, dynamic>{'pickup_lat': pickupLat, 'pickup_lng': pickupLng, 'delivery_lat': deliveryLat, 'delivery_lng': deliveryLng, 'parcel_weight_kg': parcelWeightKg};
    if (pickupCity != null) b['pickup_city'] = pickupCity; if (deliveryCity != null) b['delivery_city'] = deliveryCity;
    if (discountCode != null && discountCode.isNotEmpty) b['discount_code'] = discountCode;
    return Quote.fromJson(Map<String, dynamic>.from((await _api.post('/api/shipments/quote', body: b))['data']));
  }
  Future<Shipment> create(Map<String, dynamic> b) async => Shipment.fromJson(Map<String, dynamic>.from((await _api.post('/api/shipments', body: b))['data']['shipment']));
  Future<List<Shipment>> myShipments({int page = 1, int pageSize = 20, String? status}) async {
    final q = <String, dynamic>{'page': page, 'pageSize': pageSize}; if (status != null) q['status'] = status;
    final r = await _api.get('/api/shipments', query: q);
    return (r['data'] as List).map((e) => Shipment.fromJson(Map<String, dynamic>.from(e))).toList();
  }
  Future<ShipmentDetail> detail(String id) async => ShipmentDetail.fromJson(Map<String, dynamic>.from((await _api.get('/api/shipments/$id'))['data']));
  Future<void> cancel(String id, String reason) async => _api.post('/api/shipments/$id/cancel', body: {'reason': reason});
  Future<void> rate(String id, {required int score, String? comment}) async => _api.post('/api/shipments/$id/rating', body: {'score': score, if (comment != null && comment.isNotEmpty) 'comment': comment});
  Future<Map<String, dynamic>> contact(String id) async => Map<String, dynamic>.from((await _api.get('/api/shipments/$id/contact'))['data']);
  Future<Map<String, dynamic>> track(String id) async => Map<String, dynamic>.from((await _api.get('/api/shipments/$id/track'))['data']);
}
final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) => ShipmentRepository(ref.watch(apiClientProvider)));
