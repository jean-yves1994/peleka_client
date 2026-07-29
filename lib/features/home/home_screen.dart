import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/kigali.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/peleka_card.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/presentation/auth_view_model.dart';
import '../shipments/presentation/shipments_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final first = (auth.user?.fullName ?? '').split(' ').first;
    final recent = ref.watch(myShipmentsProvider(null));
    return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(myShipmentsProvider),
                color: AppColors.orange,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  'Hello${first.isNotEmpty ? ", $first" : ""} 👋',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy)),
                              const Text('Where should we deliver today?',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.ink500))
                            ])),
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: AppColors.navyLight,
                                borderRadius: BorderRadius.circular(14)),
                            child: Center(
                                child: Text(
                                    first.isEmpty
                                        ? '👤'
                                        : first[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy))))
                      ]),
                      const SizedBox(height: 20),
                      _Hero(onNew: () {
                        ref.read(draftProvider.notifier).state =
                            CreateShipmentDraft();
                        context.push('/shipments/create');
                      }),
                      const SizedBox(height: 24),
                      const Text('What are you sending?',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 104,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: ParcelCategories.all.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final c = ParcelCategories.all[i];
                                return _Cat(
                                    cat: c,
                                    onTap: () {
                                      ref.read(draftProvider.notifier).state =
                                          CreateShipmentDraft()
                                            ..parcelCategory = c.id;
                                      context.push('/shipments/create');
                                    });
                              })),
                      const SizedBox(height: 28),
                      Row(children: [
                        const Expanded(
                            child: Text('Recent shipments',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy))),
                        TextButton(
                            onPressed: () => context.go('/shipments'),
                            child: const Text('See all'))
                      ]),
                      const SizedBox(height: 8),
                      recent.when(
                          loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.orange))),
                          error: (e, _) => Text('Failed to load: $e',
                              style: const TextStyle(color: AppColors.error)),
                          data: (rows) {
                            if (rows.isEmpty)
                              return PelekaCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: const [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 32, color: AppColors.ink400),
                                    SizedBox(height: 12),
                                    Text('No shipments yet',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy)),
                                    SizedBox(height: 4),
                                    Text(
                                        'Send your first parcel from anywhere in Kigali.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.ink500))
                                  ]));
                            return Column(
                                children: rows
                                    .take(4)
                                    .map((s) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: PelekaCard(
                                            onTap: () => context
                                                .push('/shipments/${s.id}'),
                                            child: Row(children: [
                                              Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          AppColors.navyLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14)),
                                                  child: const Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      color: AppColors.navy,
                                                      size: 20)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(s.trackingNumber,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .navy)),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        '${s.pickupCity ?? "—"} → ${s.deliveryCity ?? "—"}',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .ink500)),
                                                    const SizedBox(height: 6),
                                                    StatusBadge(s.status)
                                                  ])),
                                              Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                        money(s.totalPrice,
                                                            currency:
                                                                s.currency),
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: AppColors
                                                                .navy)),
                                                    const SizedBox(height: 4),
                                                    Text(relative(s.createdAt),
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .ink500))
                                                  ]),
                                            ]))))
                                    .toList());
                          }),
                    ]))));
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onNew;
  const _Hero({required this.onNew});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onNew,
      child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: AppColors.navy.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12))
              ]),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999)),
                      child: const Text('🇷🇼 Kigali only',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                  const SizedBox(height: 12),
                  const Text('Book a delivery',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  const Text('Fast, reliable, tracked.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(999)),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('New delivery',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.white)
                      ]))
                ])),
            Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.delivery_dining,
                    size: 44, color: Colors.white)),
          ])));
}

class _Cat extends StatelessWidget {
  final ParcelCategory cat;
  final VoidCallback onTap;
  const _Cat({required this.cat, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 88,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.ink100)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(cat.icon, size: 22, color: AppColors.blue)),
            const SizedBox(height: 6),
            Text(cat.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink800))
          ])));
}
