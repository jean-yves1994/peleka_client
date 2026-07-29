import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/peleka_card.dart';
final _np = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(apiClientProvider).get('/api/me/notifications', query: {'pageSize': 30});
  return (r['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
});
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(_np);
    return Scaffold(backgroundColor: AppColors.bg, appBar: AppBar(title: const Text('Notifications'),
      actions: [IconButton(icon: const Icon(Icons.done_all), tooltip: 'Mark all read', onPressed: () async { try { await ref.read(apiClientProvider).patch('/api/me/notifications', body: {}); ref.invalidate(_np); } catch (_) {} })]),
      body: RefreshIndicator(color: AppColors.orange, onRefresh: () async => ref.invalidate(_np), child: a.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)), error: (e, _) => Center(child: Text('Failed: $e')),
        data: (rows) {
          if (rows.isEmpty) return ListView(children: const [SizedBox(height: 100), Center(child: Icon(Icons.notifications_none, size: 48, color: AppColors.ink400)),
            SizedBox(height: 12), Center(child: Text('No notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy))),
            SizedBox(height: 4), Center(child: Text("You're all caught up.", style: TextStyle(fontSize: 12, color: AppColors.ink500)))]);
          return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) { final n = rows[i]; final read = n['read_at'] != null;
              return PelekaCard(color: read ? Colors.white : AppColors.orangeLight, onTap: () async { if (!read) { try { await ref.read(apiClientProvider).patch('/api/me/notifications/${n['id']}/read'); ref.invalidate(_np); } catch (_) {} } },
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: read ? AppColors.ink100 : AppColors.orange, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.notifications_outlined, size: 16, color: read ? AppColors.ink500 : Colors.white)),
                  const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: read ? FontWeight.w500 : FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 2), Text(n['body'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.ink700)),
                    const SizedBox(height: 4), Text(relative(DateTime.tryParse(n['created_at'] ?? '')), style: const TextStyle(fontSize: 11, color: AppColors.ink400))])),
                  if (!read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle))]));
            });
        })));
  }
}
