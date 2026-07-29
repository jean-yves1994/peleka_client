import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shipment_repository.dart';
import '../domain/shipment.dart';
final myShipmentsProvider = FutureProvider.autoDispose.family<List<Shipment>, String?>((ref, status) => ref.watch(shipmentRepositoryProvider).myShipments(status: status));
final shipmentDetailProvider = FutureProvider.autoDispose.family<ShipmentDetail, String>((ref, id) => ref.watch(shipmentRepositoryProvider).detail(id));
class CreateShipmentDraft {
  double? pickupLat; double? pickupLng; String? pickupAddress;
  double? deliveryLat; double? deliveryLng; String? deliveryAddress;
  String senderName = ''; String senderPhone = ''; String recipientName = ''; String recipientPhone = '';
  String parcelDescription = ''; String parcelCategory = 'documents'; double parcelWeightKg = 1;
  bool isFragile = false; bool requiresSignature = false; String pickupNotes = ''; String deliveryNotes = ''; String? discountCode; Quote? quote;
  Map<String, dynamic> toCreateBody() => {
    'sender_name': senderName, 'sender_phone': senderPhone, 'recipient_name': recipientName, 'recipient_phone': recipientPhone,
    'pickup_address': pickupAddress ?? '', 'pickup_city': 'Kigali', 'pickup_lat': pickupLat, 'pickup_lng': pickupLng, 'pickup_notes': pickupNotes,
    'delivery_address': deliveryAddress ?? '', 'delivery_city': 'Kigali', 'delivery_lat': deliveryLat, 'delivery_lng': deliveryLng, 'delivery_notes': deliveryNotes,
    'parcel_description': parcelDescription, 'parcel_category': parcelCategory, 'parcel_weight_kg': parcelWeightKg, 'is_fragile': isFragile, 'requires_signature': requiresSignature,
    if (discountCode != null && discountCode!.isNotEmpty) 'discount_code': discountCode,
  };
}
final draftProvider = StateProvider<CreateShipmentDraft>((_) => CreateShipmentDraft());
