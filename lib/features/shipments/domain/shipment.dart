class Shipment {
  final String id; final String trackingNumber; final String status;
  final String senderName; final String senderPhone; final String recipientName; final String recipientPhone;
  final String pickupAddress; final String? pickupCity; final double pickupLat; final double pickupLng;
  final String deliveryAddress; final String? deliveryCity; final double deliveryLat; final double deliveryLng;
  final String parcelDescription; final String? parcelCategory; final double parcelWeightKg;
  final bool isFragile; final bool requiresSignature;
  final double distanceKm; final double totalPrice; final double? discountAmount; final double taxAmount;
  final double? riderEarnings; final String currency; final String? riderId;
  final DateTime createdAt; final DateTime? pickedUpAt; final DateTime? deliveredAt;
  const Shipment({required this.id, required this.trackingNumber, required this.status, required this.senderName, required this.senderPhone,
    required this.recipientName, required this.recipientPhone, required this.pickupAddress, this.pickupCity, required this.pickupLat, required this.pickupLng,
    required this.deliveryAddress, this.deliveryCity, required this.deliveryLat, required this.deliveryLng, required this.parcelDescription, this.parcelCategory,
    required this.parcelWeightKg, required this.isFragile, required this.requiresSignature, required this.distanceKm, required this.totalPrice,
    this.discountAmount, required this.taxAmount, this.riderEarnings, required this.currency, this.riderId, required this.createdAt, this.pickedUpAt, this.deliveredAt});
  factory Shipment.fromJson(Map<String, dynamic> j) {
    double d(v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    DateTime? t(v) => v == null ? null : DateTime.tryParse(v.toString());
    return Shipment(id: j['id'], trackingNumber: j['tracking_number'] ?? '', status: j['status'] ?? 'awaiting_assignment',
      senderName: j['sender_name'] ?? '', senderPhone: j['sender_phone'] ?? '', recipientName: j['recipient_name'] ?? '', recipientPhone: j['recipient_phone'] ?? '',
      pickupAddress: j['pickup_address'] ?? '', pickupCity: j['pickup_city'], pickupLat: d(j['pickup_lat']), pickupLng: d(j['pickup_lng']),
      deliveryAddress: j['delivery_address'] ?? '', deliveryCity: j['delivery_city'], deliveryLat: d(j['delivery_lat']), deliveryLng: d(j['delivery_lng']),
      parcelDescription: j['parcel_description'] ?? '', parcelCategory: j['parcel_category'], parcelWeightKg: d(j['parcel_weight_kg']),
      isFragile: j['is_fragile'] == true, requiresSignature: j['requires_signature'] == true, distanceKm: d(j['distance_km']), totalPrice: d(j['total_price']),
      discountAmount: j['discount_amount'] == null ? null : d(j['discount_amount']), taxAmount: d(j['tax_amount']),
      riderEarnings: j['rider_earnings'] == null ? null : d(j['rider_earnings']), currency: j['currency'] ?? 'RWF', riderId: j['rider_id'],
      createdAt: t(j['created_at']) ?? DateTime.now(), pickedUpAt: t(j['picked_up_at']), deliveredAt: t(j['delivered_at']));
  }
}
class Quote {
  final double distanceKm; final double durationMinutes; final double baseFare; final double distanceFee; final double weightFee;
  final double subtotal; final double discountAmount; final double taxAmount; final double totalPrice; final String currency; final String? discountCode; final String? breakdownNote;
  const Quote({required this.distanceKm, required this.durationMinutes, required this.baseFare, required this.distanceFee, required this.weightFee,
    required this.subtotal, required this.discountAmount, required this.taxAmount, required this.totalPrice, required this.currency, this.discountCode, this.breakdownNote});
  factory Quote.fromJson(Map<String, dynamic> j) {
    double d(v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return Quote(distanceKm: d(j['distance_km']), durationMinutes: d(j['duration_minutes']), baseFare: d(j['base_fare']), distanceFee: d(j['distance_fee']),
      weightFee: d(j['weight_fee']), subtotal: d(j['subtotal']), discountAmount: d(j['discount_amount']), taxAmount: d(j['tax_amount']), totalPrice: d(j['total_price']),
      currency: j['currency'] ?? 'RWF', discountCode: j['discount_code'], breakdownNote: j['breakdown_note']);
  }
}
class ShipmentTimelineEntry {
  final String toStatus; final String? note; final DateTime createdAt;
  const ShipmentTimelineEntry({required this.toStatus, this.note, required this.createdAt});
  factory ShipmentTimelineEntry.fromJson(Map<String, dynamic> j) => ShipmentTimelineEntry(toStatus: j['to_status'], note: j['note'], createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now());
}
class ShipmentDetail {
  final Shipment shipment; final List<ShipmentTimelineEntry> statusHistory; final List<Map<String, dynamic>> proofs; final Map<String, dynamic>? rating; final List<Map<String, dynamic>> payments;
  const ShipmentDetail({required this.shipment, required this.statusHistory, required this.proofs, this.rating, required this.payments});
  factory ShipmentDetail.fromJson(Map<String, dynamic> j) => ShipmentDetail(shipment: Shipment.fromJson(j['shipment']),
    statusHistory: (j['status_history'] as List? ?? []).map((e) => ShipmentTimelineEntry.fromJson(e)).toList(),
    proofs: (j['proofs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
    rating: j['rating'] == null ? null : Map<String, dynamic>.from(j['rating']),
    payments: (j['payments'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList());
}
