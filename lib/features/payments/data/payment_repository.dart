import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// Result of pushing a Mobile Money charge to the customer's phone.
class PaymentInit {
  final String paymentId;
  final String ref;
  final String status; // 'pending' — customer must approve on their phone
  final double amount;
  final String currency;
  final String phoneLast4;
  final String message;

  const PaymentInit({
    required this.paymentId,
    required this.ref,
    required this.status,
    required this.amount,
    required this.currency,
    required this.phoneLast4,
    required this.message,
  });

  factory PaymentInit.fromJson(Map<String, dynamic> j) => PaymentInit(
        paymentId: j['payment_id'].toString(),
        ref: j['ref']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        amount: (j['amount'] is num)
            ? (j['amount'] as num).toDouble()
            : double.tryParse('${j['amount']}') ?? 0,
        currency: j['currency']?.toString() ?? 'RWF',
        phoneLast4: j['phone_last4']?.toString() ?? '',
        message: j['message']?.toString() ??
            'Check your phone and enter your Mobile Money PIN to approve.',
      );
}

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  /// Push a Mobile Money charge (Request-to-Pay) for a shipment that is in
  /// `pending_payment`. [phone] is optional — the backend falls back to the
  /// phone on the customer's account.
  Future<PaymentInit> initiatePaypack(String shipmentId, {String? phone}) async {
    final body = <String, dynamic>{'shipment_id': shipmentId};
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
    final res = await _api.post('/api/payments/paypack/initiate', body: body);
    return PaymentInit.fromJson(Map<String, dynamic>.from(res['data']));
  }

  /// Poll a payment's status: 'pending' | 'paid' | 'failed'.
  /// The backend also does a live Paypack lookup while still pending, so this
  /// settles even if the webhook is delayed.
  Future<String> status(String paymentId) async {
    final res = await _api.get('/api/payments/$paymentId');
    return (res['data']?['status'] ?? 'pending').toString();
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
