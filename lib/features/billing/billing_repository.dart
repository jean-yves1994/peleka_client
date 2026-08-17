import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

class BillingShipment {
  final String id;
  final String trackingNumber;
  final String status;
  final double totalPrice;
  final String currency;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String paymentStatus;
  BillingShipment({required this.id, required this.trackingNumber, required this.status, required this.totalPrice, required this.currency, required this.createdAt, this.deliveredAt, required this.paymentStatus});
  factory BillingShipment.fromJson(Map<String,dynamic> j) => BillingShipment(
    id: j['id'].toString(), trackingNumber: j['tracking_number']?.toString() ?? '', status: j['status']?.toString() ?? '',
    totalPrice: _n(j['total_price']), currency: j['currency']?.toString() ?? 'RWF',
    createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    deliveredAt: DateTime.tryParse(j['delivered_at']?.toString() ?? ''), paymentStatus: j['payment_status']?.toString() ?? 'unpaid');
  static double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
}

class BillingSummary {
  final String customerType;
  final double creditLimit;
  final double outstandingBalance;
  final List<BillingShipment> outstandingShipments;
  final List<BillingShipment> history;
  BillingSummary({required this.customerType, required this.creditLimit, required this.outstandingBalance, required this.outstandingShipments, required this.history});
  factory BillingSummary.fromJson(Map<String,dynamic> j) {
    final out = (j['outstanding_shipments'] as List? ?? []).map((e)=>BillingShipment.fromJson(Map<String,dynamic>.from(e))).toList();
    final hist = (j['shipment_history'] as List? ?? []).map((e)=>BillingShipment.fromJson(Map<String,dynamic>.from(e))).toList();
    return BillingSummary(customerType: j['customer_type']?.toString() ?? 'standard', creditLimit: _n(j['credit_limit']), outstandingBalance: _n(j['outstanding_balance']), outstandingShipments: out, history: hist);
  }
  static double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
  bool get isPremier => customerType == 'premier';
}

class BillingRepository {
  final ApiClient _api;
  BillingRepository(this._api);
  Future<BillingSummary> get() async => BillingSummary.fromJson(Map<String,dynamic>.from((await _api.get('/api/me/billing'))['data']));
}
final billingRepositoryProvider = Provider<BillingRepository>((ref)=>BillingRepository(ref.watch(apiClientProvider)));
final billingProvider = FutureProvider.autoDispose<BillingSummary>((ref)=>ref.watch(billingRepositoryProvider).get());
