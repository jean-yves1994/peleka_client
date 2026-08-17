import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/format.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/shipment_repository.dart';
import 'shipments_view_model.dart';

/// Review & pay.
///
/// PAY-BEFORE FLOW:
///   Creating the shipment no longer drops the user on the detail page.
///   The shipment is created as `pending_payment` and we immediately route
///   to `/pay`, which opens the Paypack checkout in a WebView.
class QuoteReviewScreen extends ConsumerStatefulWidget {
  const QuoteReviewScreen({super.key});
  @override
  ConsumerState<QuoteReviewScreen> createState() => _S();
}

class _S extends ConsumerState<QuoteReviewScreen> {
  final _promo = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final d = ref.read(draftProvider);
    if (_promo.text.trim().isEmpty) return;
    try {
      final q = await ref.read(shipmentRepositoryProvider).quote(
            pickupLat: d.pickupLat!,
            pickupLng: d.pickupLng!,
            deliveryLat: d.deliveryLat!,
            deliveryLng: d.deliveryLng!,
            discountCode: _promo.text.trim(),
          );
      ref.read(draftProvider.notifier).update((x) => x
        ..discountCode = _promo.text.trim()
        ..quote = q);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Promo applied — saved ${money(q.discountAmount, currency: q.currency)}'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('ApiException: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _confirmAndPay() async {
    setState(() => _confirming = true);
    try {
      final s = await ref.read(shipmentRepositoryProvider).create(
            ref.read(draftProvider).toCreateBody(),
          );
      ref.invalidate(myShipmentsProvider);
      if (!mounted) return;

      // Clear the draft so a back-navigation doesn't re-submit it.
      ref.read(draftProvider.notifier).state = CreateShipmentDraft();

      // Standard customers pay before dispatch. Premier customers are placed
      // on invoice terms and can be assigned immediately.
      if (s.paymentRequired) {
        context.go('/pay?shipmentId=${s.id}&trackingNumber=${Uri.encodeComponent(s.trackingNumber)}');
      } else {
        context.go('/shipments/${s.id}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('ApiException: ', '')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final q = d.quote;
    if (q == null)
      return const Scaffold(body: Center(child: Text('No quote yet')));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Review shipment'),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              // Route
              PelekaCard(
                child: Column(children: [
                  _l(Icons.trip_origin, d.pickupAddress ?? '', 'Pickup',
                      AppColors.blue),
                  const Divider(height: 20, color: AppColors.ink100),
                  _l(Icons.location_on, d.deliveryAddress ?? '', 'Delivery',
                      AppColors.orange),
                ]),
              ),
              const SizedBox(height: 12),

              // Parcel
              PelekaCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Parcel', d.parcelDescription),
                      _kv('Category', titleCase(d.parcelCategory)),
                      _kv('Distance', '${q.distanceKm.toStringAsFixed(1)} km'),
                      if (d.isFragile) _kv('Fragile', 'Yes'),
                    ]),
              ),
              const SizedBox(height: 12),

              // Parties
              PelekaCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Sender', '${d.senderName} · ${d.senderPhone}'),
                      _kv('Recipient',
                          '${d.recipientName} · ${d.recipientPhone}'),
                    ]),
              ),
              const SizedBox(height: 20),

              // Promo
              Row(children: [
                Expanded(
                  child: PelekaTextField(
                    label: 'Promo code',
                    hint: 'e.g. MURAHO10',
                    controller: _promo,
                    prefixIcon: Icons.local_offer_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: OutlinedButton(
                      onPressed: _apply, child: const Text('Apply')),
                ),
              ]),
              const SizedBox(height: 20),

              // Price breakdown
              PelekaCard(
                color: AppColors.navyLight,
                child: Column(children: [
                  _p('Base fare', q.baseFare, q.currency),
                  _p('Distance fee', q.distanceFee, q.currency),
                  const Divider(height: 20),
                  _p('Subtotal', q.subtotal, q.currency, bold: true),
                  if (q.discountAmount > 0)
                    _p('Discount', -q.discountAmount, q.currency,
                        color: AppColors.success),
                  _p('VAT (18%)', q.taxAmount, q.currency),
                  const Divider(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy)),
                        Text(money(q.totalPrice, currency: q.currency),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.orange)),
                      ]),
                ]),
              ),
              const SizedBox(height: 16),

              PelekaCard(
                color: AppColors.blueLight,
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    q.paymentRequired
                        ? 'Payment is required before this shipment is released to riders.'
                        : 'Your Premier account can dispatch this shipment now. Payment can be settled later.',
                    style: const TextStyle(fontSize: 12, color: AppColors.navy),
                  )),
                ]),
              ),
            ]),
          ),

          // ⭐ Button now reads "Pay RWF x,xxx"
          Padding(
            padding: const EdgeInsets.all(20),
            child: PelekaButton(
              label: q.paymentRequired ? 'Continue to payment' : 'Confirm shipment',
              icon: q.paymentRequired ? Icons.lock : Icons.check_circle_outline,
              loading: _confirming,
              onPressed: _confirmAndPay,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _l(IconData i, String a, String l, Color c) => Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(i, size: 18, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l,
                style: const TextStyle(fontSize: 11, color: AppColors.ink500)),
            Text(a,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          ]),
        ),
      ]);

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 120,
              child: Text(k,
                  style:
                      const TextStyle(color: AppColors.ink500, fontSize: 12))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _p(String l, double a, String cu, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? AppColors.ink700)),
          Text(money(a, currency: cu),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: color ?? AppColors.navy)),
        ]),
      );
}
