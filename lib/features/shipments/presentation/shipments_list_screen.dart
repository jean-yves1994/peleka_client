import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/format.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/status_badge.dart';
import 'shipments_view_model.dart';

/// My shipments list.
///
/// UPDATED for pay-before:
///  • New "Unpaid" filter chip (status = pending_payment).
///  • Unpaid rows show an inline "Pay now" button that resumes checkout.
class ShipmentsListScreen extends ConsumerStatefulWidget {
  const ShipmentsListScreen({super.key});
  @override
  ConsumerState<ShipmentsListScreen> createState() => _S();
}

class _S extends ConsumerState<ShipmentsListScreen> {
  String? _f;

  final _filters = const [
    (null, 'All'),
    ('pending_payment', 'Unpaid'), // ← new
    ('awaiting_assignment', 'Pending'),
    ('assigned', 'Assigned'),
    ('in_transit', 'In transit'),
    ('delivered', 'Delivered'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(myShipmentsProvider(_f));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My shipments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(draftProvider.notifier).state = CreateShipmentDraft();
              context.push('/shipments/create');
            },
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final s = _f == f.$1;
              return ChoiceChip(
                label: Text(f.$2),
                selected: s,
                onSelected: (_) => setState(() => _f = f.$1),
                backgroundColor: Colors.white,
                selectedColor: AppColors.navy,
                labelStyle: TextStyle(color: s ? Colors.white : AppColors.ink700, fontWeight: FontWeight.w600, fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: s ? AppColors.navy : AppColors.ink200),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(myShipmentsProvider),
            color: AppColors.orange,
            child: a.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 80),
                    Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.ink400)),
                    SizedBox(height: 12),
                    Center(child: Text('No shipments here', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy))),
                    SizedBox(height: 4),
                    Center(child: Text('Try another filter or book a delivery.', style: TextStyle(fontSize: 12, color: AppColors.ink500))),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = rows[i];
                    final unpaid = s.status == 'pending_payment';
                    return PelekaCard(
                      onTap: () => context.push('/shipments/${s.id}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(s.trackingNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy))),
                          StatusBadge(s.status),
                        ]),
                        const SizedBox(height: 10),
                        _row(Icons.trip_origin, s.pickupAddress, AppColors.blue),
                        const SizedBox(height: 6),
                        _row(Icons.location_on, s.deliveryAddress, AppColors.orange),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.ink400),
                          const SizedBox(width: 4),
                          Text('${s.parcelWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                          const SizedBox(width: 12),
                          const Icon(Icons.alt_route, size: 14, color: AppColors.ink400),
                          const SizedBox(width: 4),
                          Text('${s.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                          const Spacer(),
                          Text(money(s.totalPrice, currency: s.currency),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.orange)),
                        ]),

                        // ── Inline "Pay now" for unpaid shipments ──────
                        if (unpaid) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock, size: 16),
                              label: Text('Pay now · ${money(s.totalPrice, currency: s.currency)}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                await context.push(
                                  '/pay?shipmentId=${s.id}&trackingNumber=${Uri.encodeComponent(s.trackingNumber)}',
                                );
                                ref.invalidate(myShipmentsProvider);
                              },
                            ),
                          ),
                        ],
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _row(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 14, color: c),
        const SizedBox(width: 6),
        Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.ink700))),
      ]);
}
