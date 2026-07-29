import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/format.dart';
import '../shipments/data/shipment_repository.dart';
import '../shipments/presentation/shipments_view_model.dart';
class TrackingScreen extends ConsumerStatefulWidget {
  final String id;
  const TrackingScreen({super.key, required this.id});
  @override ConsumerState<TrackingScreen> createState() => _S();
}
class _S extends ConsumerState<TrackingScreen> {
  final _map = MapController(); Timer? _t; Map<String, dynamic>? _track; bool _loading = true;
  @override void initState() { super.initState(); _load(); _t = Timer.periodic(const Duration(seconds: 8), (_) => _load()); }
  @override void dispose() { _t?.cancel(); super.dispose(); }
  Future<void> _load() async { try { final d = await ref.read(shipmentRepositoryProvider).track(widget.id); if (mounted) setState(() { _track = d; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  @override
  Widget build(BuildContext context) {
    final a = ref.watch(shipmentDetailProvider(widget.id));
    return Scaffold(backgroundColor: AppColors.bg, appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()), title: const Text('Live tracking')),
      body: a.when(loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)), error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) { final s = d.shipment; final pickup = LatLng(s.pickupLat, s.pickupLng); final delivery = LatLng(s.deliveryLat, s.deliveryLng);
          LatLng? rider; final r = _track?['rider_last_location']; if (r != null && r['lat'] != null && r['lng'] != null) rider = LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble());
          WidgetsBinding.instance.addPostFrameCallback((_) { if (_track != null && !_loading) { try { _map.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints([pickup, delivery, if (rider != null) rider]), padding: const EdgeInsets.all(60))); } catch (_) {} } });
          return Column(children: [
            Expanded(child: FlutterMap(mapController: _map, options: MapOptions(initialCenter: pickup, initialZoom: 13, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom)),
              children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.peleka_client'),
                PolylineLayer(polylines: [Polyline(points: rider == null ? [pickup, delivery] : [pickup, rider, delivery], strokeWidth: 3, color: AppColors.blue.withOpacity(0.6))]),
                MarkerLayer(markers: [Marker(point: pickup, width: 40, height: 40, child: _pin(AppColors.blue, Icons.trip_origin)),
                  Marker(point: delivery, width: 40, height: 40, child: _pin(AppColors.orange, Icons.location_on)),
                  if (rider != null) Marker(point: rider, width: 48, height: 48, child: _pin(AppColors.navy, Icons.two_wheeler))])])),
            Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(s.trackingNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy))), StatusBadge(s.status)]), const SizedBox(height: 12),
                Row(children: [const Icon(Icons.alt_route, size: 14, color: AppColors.ink500), const SizedBox(width: 6), Text('${s.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                  const SizedBox(width: 12), const Icon(Icons.two_wheeler, size: 14, color: AppColors.ink500), const SizedBox(width: 6), Text(rider != null ? 'Rider on the way' : 'Waiting for rider', style: const TextStyle(fontSize: 12, color: AppColors.ink500))]),
                const SizedBox(height: 8), Row(children: [const Icon(Icons.wifi, size: 12, color: AppColors.orange), const SizedBox(width: 6), Text('Auto-refreshes every 8s · updated ${relative(DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppColors.ink500))])])),
          ]); }));
  }
  Widget _pin(Color c, IconData i) => Container(decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(i, color: Colors.white, size: 18));
}
