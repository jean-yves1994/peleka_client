import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/format.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/shipment_repository.dart';
import 'shipments_view_model.dart';

/// Shipment detail.
///
/// UPDATED for pay-before:
///  • Shows a prominent "Pay now" card when status == 'pending_payment',
///    so a customer who abandoned checkout can resume from here.
///  • Refreshes automatically after returning from the payment screen.
///  • Allows cancelling an unpaid shipment (see backend note in README).
class ShipmentDetailScreen extends ConsumerWidget {
  final String id;
  const ShipmentDetailScreen({super.key, required this.id});

  static const _active = {
    'assigned', 'rider_en_route_to_pickup', 'picked_up', 'in_transit', 'out_for_delivery',
  };
  // Statuses a customer may cancel from the app.
  static const _cancellable = {'pending_payment', 'awaiting_assignment', 'assigned'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(shipmentDetailProvider(id));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/shipments'),
        ),
        title: const Text('Shipment'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(shipmentDetailProvider(id))),
        ],
      ),
      body: a.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load shipment.\n\n$e', textAlign: TextAlign.center)),
        ),
        data: (d) {
          final s = d.shipment;
          final active = _active.contains(s.status);
          final unpaid = s.status == 'pending_payment';

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shipmentDetailProvider(id)),
            color: AppColors.orange,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              // ── Header ─────────────────────────────────────────────
              Row(children: [
                Expanded(child: Text(s.trackingNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy))),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: s.trackingNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracking number copied'), backgroundColor: AppColors.navy));
                  },
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                StatusBadge(s.status),
                const SizedBox(width: 8),
                Text(dateTime(s.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
              ]),
              const SizedBox(height: 20),

              // ── PAY NOW (resume checkout) ──────────────────────────
              if (unpaid) ...[
                PelekaCard(
                  color: AppColors.orangeLight,
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Payment required',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    const Text(
                      'This delivery is saved but not paid yet. We assign a rider as soon as payment is confirmed.',
                      style: TextStyle(fontSize: 13, color: AppColors.ink700, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    PelekaButton(
                      label: 'Pay ${money(s.totalPrice, currency: s.currency)}',
                      icon: Icons.lock,
                      onPressed: () async {
                        // Resume the Flutterwave checkout for this shipment.
                        await context.push(
                          '/pay?shipmentId=${s.id}&trackingNumber=${Uri.encodeComponent(s.trackingNumber)}',
                        );
                        // Coming back? Re-fetch so a completed payment shows immediately.
                        ref.invalidate(shipmentDetailProvider(id));
                        ref.invalidate(myShipmentsProvider);
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── Live tracking / call rider (active only) ───────────
              if (active) ...[
                PelekaButton(
                  label: 'Track live on map',
                  icon: Icons.location_on,
                  onPressed: () => context.push('/shipments/${s.id}/track'),
                ),
                const SizedBox(height: 12),
                if (s.riderId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call the rider'),
                    onPressed: () async {
                      try {
                        final c = await ref.read(shipmentRepositoryProvider).contact(s.id);
                        final r = c['rider'];
                        if (r == null) {
                          _sn(context, 'Rider not assigned yet.', false);
                        } else {
                          _contact(context, r);
                        }
                      } catch (e) {
                        _sn(context, e.toString().replaceAll('ApiException: ', ''), false);
                      }
                    },
                  ),
                const SizedBox(height: 20),
              ],

              // ── Route ──────────────────────────────────────────────
              PelekaCard(child: Column(children: [
                _line(Icons.trip_origin, s.pickupAddress, 'Pickup · ${s.pickupCity ?? "—"}', AppColors.blue),
                Container(margin: const EdgeInsets.only(left: 20), height: 20, width: 1, color: AppColors.ink200),
                _line(Icons.location_on, s.deliveryAddress, 'Delivery · ${s.deliveryCity ?? "—"}', AppColors.orange),
              ])),
              const SizedBox(height: 12),

              // ── Timeline ───────────────────────────────────────────
              PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Status timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 12),
                ...d.statusHistory.asMap().entries.map((e) {
                  final i = e.key, h = e.value;
                  final last = i == d.statusHistory.length - 1;
                  return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: last ? AppColors.orange : AppColors.ink400, shape: BoxShape.circle)),
                      if (i < d.statusHistory.length - 1) Expanded(child: Container(width: 1, color: AppColors.ink200)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(titleCase(h.toStatus), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      if (h.note != null) Text(h.note!, style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                      Text(dateTime(h.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.ink400)),
                    ]))),
                  ]));
                }),
              ])),
              const SizedBox(height: 12),

              // ── Parties ────────────────────────────────────────────
              PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _party('Sender', s.senderName, s.senderPhone),
                const Divider(height: 20, color: AppColors.ink100),
                _party('Recipient', s.recipientName, s.recipientPhone),
              ])),
              const SizedBox(height: 12),

              // ── Parcel ─────────────────────────────────────────────
              PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Parcel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 8),
                Text(s.parcelDescription, style: const TextStyle(color: AppColors.ink700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip('${s.parcelWeightKg.toStringAsFixed(1)} kg'),
                  _chip('${s.distanceKm.toStringAsFixed(1)} km'),
                  if (s.parcelCategory != null) _chip(titleCase(s.parcelCategory!)),
                  if (s.isFragile) _chip('Fragile', color: AppColors.warning),
                  if (s.requiresSignature) _chip('Signature', color: AppColors.blue),
                ]),
              ])),
              const SizedBox(height: 12),

              // ── Pricing ────────────────────────────────────────────
              PelekaCard(color: AppColors.navyLight, child: Column(children: [
                if (s.discountAmount != null && s.discountAmount! > 0)
                  _pl('Discount', '−${money(s.discountAmount, currency: s.currency)}', false, color: AppColors.success),
                _pl('VAT (18%)', money(s.taxAmount, currency: s.currency), false),
                const Divider(height: 16),
                _pl(unpaid ? 'Amount due' : 'Total paid', money(s.totalPrice, currency: s.currency), true),
              ])),
              const SizedBox(height: 20),

              // ── Cancel (incl. unpaid) ──────────────────────────────
              if (_cancellable.contains(s.status))
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel this shipment'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: Color(0xFFFECACA))),
                  onPressed: () async {
                    final r = await _reason(context);
                    if (r == null) return;
                    try {
                      await ref.read(shipmentRepositoryProvider).cancel(s.id, r);
                      ref.invalidate(shipmentDetailProvider(id));
                      ref.invalidate(myShipmentsProvider);
                      if (context.mounted) _sn(context, 'Shipment cancelled', true);
                    } catch (e) {
                      if (context.mounted) _sn(context, e.toString().replaceAll('ApiException: ', ''), false);
                    }
                  },
                ),

              // ── Rate (delivered) ───────────────────────────────────
              if (s.status == 'delivered' && d.rating == null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Rate this delivery'),
                  onPressed: () => _rate(context, ref, s.id),
                ),

              if (d.rating != null)
                PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Row(children: List.generate(5, (i) => Icon(
                    i < (d.rating!['score'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning, size: 24))),
                  if (d.rating!['comment'] != null && (d.rating!['comment'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"${d.rating!['comment']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.ink700)),
                  ],
                ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _line(IconData i, String a, String l, Color c) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(i, size: 18, color: c)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(fontSize: 11, color: AppColors.ink500)),
          Text(a, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
        ])),
      ]);

  Widget _party(String l, String n, String p) => Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_outline, size: 18, color: AppColors.navy)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(fontSize: 11, color: AppColors.ink500)),
          Text(n, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
          Text(p, style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
        ])),
      ]);

  Widget _chip(String l, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: (color ?? AppColors.navy).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
        child: Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? AppColors.navy)),
      );

  Widget _pl(String l, String v, bool bold, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: bold ? 15 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? (bold ? AppColors.navy : AppColors.ink700))),
          Text(v, style: TextStyle(fontSize: bold ? 17 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? (bold ? AppColors.orange : AppColors.navy))),
        ]),
      );

  void _contact(BuildContext c, Map r) => showModalBottomSheet(
        context: c, backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.ink200, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          Text('Contact ${r['name'] ?? 'rider'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.phone, color: AppColors.blue),
            title: Text(r['phone'] ?? '—'),
            trailing: const Icon(Icons.copy, size: 18),
            onTap: () {
              Clipboard.setData(ClipboardData(text: r['phone'] ?? ''));
              Navigator.pop(c);
              _sn(c, 'Phone copied to clipboard', true);
            },
          ),
        ])),
      );

  Future<String?> _reason(BuildContext c) async {
    final t = TextEditingController();
    return showDialog<String>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Cancel shipment?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This cannot be undone. Please tell us why:', style: TextStyle(color: AppColors.ink500, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'Reason')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Never mind')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(c, t.text.trim().isEmpty ? 'Changed my mind' : t.text.trim()),
            child: const Text('Cancel shipment'),
          ),
        ],
      ),
    );
  }

  void _rate(BuildContext c, WidgetRef ref, String sid) {
    int score = 5;
    final cm = TextEditingController();
    showModalBottomSheet(
      context: c, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setState) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.ink200, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          const Text('How was your delivery?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
            iconSize: 40,
            icon: Icon(i < score ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.warning),
            onPressed: () => setState(() => score = i + 1),
          ))),
          const SizedBox(height: 12),
          TextField(controller: cm, maxLines: 3, decoration: const InputDecoration(hintText: 'Add a comment (optional)…')),
          const SizedBox(height: 16),
          PelekaButton(label: 'Submit rating', icon: Icons.send, onPressed: () async {
            try {
              await ref.read(shipmentRepositoryProvider).rate(sid, score: score, comment: cm.text.trim());
              ref.invalidate(shipmentDetailProvider(sid));
              if (ctx.mounted) Navigator.pop(ctx);
              if (ctx.mounted) _sn(ctx, 'Thanks for the rating!', true);
            } catch (e) {
              if (ctx.mounted) _sn(ctx, e.toString().replaceAll('ApiException: ', ''), false);
            }
          }),
        ]))),
      ),
    );
  }

  void _sn(BuildContext c, String m, bool ok) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? AppColors.success : AppColors.error));
}
