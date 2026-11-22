import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_card.dart';
import '../data/shipment_repository.dart';

class GuestShipmentScreen extends ConsumerStatefulWidget {
  final String id;
  const GuestShipmentScreen({super.key, required this.id});
  @override
  ConsumerState<GuestShipmentScreen> createState() => _GuestShipmentScreenState();
}

class _GuestShipmentScreenState extends ConsumerState<GuestShipmentScreen> {
  late Future<Map<String, dynamic>> _shipment;
  @override
  void initState() { super.initState(); _load(); }
  void _load() { _shipment = ref.read(shipmentRepositoryProvider).guestDetail(widget.id); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Your delivery'),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/shipments/create'),
          icon: const Icon(Icons.add, color: AppColors.orange),
          label: const Text('New shipment', style: TextStyle(color: AppColors.orange)),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _shipment,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.orange));
        if (snapshot.hasError || !snapshot.hasData) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 44, color: AppColors.orange),
          const SizedBox(height: 12),
          const Text('We could not load this delivery. Please try again.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => setState(_load), child: const Text('Retry')),
        ])));
        final s = snapshot.data!;
        String value(String key) => s[key]?.toString() ?? '—';
        return RefreshIndicator(onRefresh: () async => setState(_load), color: AppColors.orange, child: ListView(padding: const EdgeInsets.all(20), children: [
          PelekaCard(color: AppColors.navyLight, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tracking number', style: TextStyle(fontSize: 12, color: AppColors.ink500)),
            const SizedBox(height: 6),
            SelectableText(value('tracking_number'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
            const SizedBox(height: 12),
            Text(value('status').replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orange)),
          ])),
          const SizedBox(height: 12),
          PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pickup', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 4), Text(value('pickup_address')),
            const Divider(height: 24),
            const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 4), Text(value('delivery_address')),
          ])),
          const SizedBox(height: 12),
          PelekaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Parcel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 6), Text(value('parcel_description')),
            const SizedBox(height: 12),
            const Text('Payment status', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 4), Text(value('payment_status').replaceAll('_', ' ').toUpperCase()),
            const SizedBox(height: 8), Text(value('total_price') + ' ' + value('currency'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.orange)),
          ])),
        ]));
      },
    ),
  );
}