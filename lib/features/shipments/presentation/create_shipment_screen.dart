import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/kigali.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/shipment_repository.dart';
import 'shipments_view_model.dart';
class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});
  @override ConsumerState<CreateShipmentScreen> createState() => _S();
}
class _S extends ConsumerState<CreateShipmentScreen> {
  int _step = 0; bool _loading = false;
  final _k = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  final _pa = TextEditingController(); final _pn = TextEditingController(); Map<String, dynamic>? _ph;
  final _da = TextEditingController(); final _dn = TextEditingController(); Map<String, dynamic>? _dh;
  final _rn = TextEditingController(); final _rp = TextEditingController();
  final _sn = TextEditingController(); final _sp = TextEditingController();
  final _desc = TextEditingController(); final _w = TextEditingController(text: '1');
  String _cat = 'documents'; bool _fragile = false; bool _sig = false;
  @override void initState() { super.initState(); final d = ref.read(draftProvider); if (d.parcelCategory.isNotEmpty) _cat = d.parcelCategory; }
  @override void dispose() { for (final c in [_pa,_pn,_da,_dn,_rn,_rp,_sn,_sp,_desc,_w]) { c.dispose(); } super.dispose(); }
  Future<void> _next() async {
    if (!_k[_step].currentState!.validate()) return;
    if (_step == 0 && _ph == null) { _sn2('Pick a pickup neighborhood'); return; }
    if (_step == 1 && _dh == null) { _sn2('Pick a delivery neighborhood'); return; }
    if (_step < 2) { setState(() => _step++); return; }
    await _quote();
  }
  Future<void> _quote() async {
    setState(() => _loading = true);
    try {
      final q = await ref.read(shipmentRepositoryProvider).quote(pickupLat: _ph!['lat'], pickupLng: _ph!['lng'], deliveryLat: _dh!['lat'], deliveryLng: _dh!['lng'], parcelWeightKg: double.tryParse(_w.text) ?? 1);
      final d = CreateShipmentDraft()
        ..pickupLat = _ph!['lat'] ..pickupLng = _ph!['lng'] ..pickupAddress = _pa.text.trim().isEmpty ? _ph!['name'] : _pa.text.trim() ..pickupNotes = _pn.text.trim()
        ..deliveryLat = _dh!['lat'] ..deliveryLng = _dh!['lng'] ..deliveryAddress = _da.text.trim().isEmpty ? _dh!['name'] : _da.text.trim() ..deliveryNotes = _dn.text.trim()
        ..senderName = _sn.text.trim() ..senderPhone = _sp.text.trim() ..recipientName = _rn.text.trim() ..recipientPhone = _rp.text.trim()
        ..parcelDescription = _desc.text.trim() ..parcelCategory = _cat ..parcelWeightKg = double.tryParse(_w.text) ?? 1 ..isFragile = _fragile ..requiresSignature = _sig ..quote = q;
      ref.read(draftProvider.notifier).state = d;
      if (mounted) context.push('/shipments/quote');
    } catch (e) { _sn2(e.toString().replaceAll('ApiException: ', '')); } finally { if (mounted) setState(() => _loading = false); }
  }
  void _sn2(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.bg,
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _step == 0 ? context.pop() : setState(() => _step--)), title: Text('New delivery · ${_step + 1}/3')),
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(children: List.generate(3, (i) { final on = i <= _step;
        return Expanded(child: Container(margin: EdgeInsets.only(right: i < 2 ? 8 : 0), height: 6, decoration: BoxDecoration(color: on ? AppColors.orange : AppColors.ink200, borderRadius: BorderRadius.circular(999)))); }))),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _k[_step], child: [_pickup(), _delivery(), _parcel()][_step]))),
      Padding(padding: const EdgeInsets.all(20), child: PelekaButton(label: _step == 2 ? 'Review price' : 'Continue', icon: _step == 2 ? Icons.calculate_outlined : Icons.arrow_forward, loading: _loading, onPressed: _next)),
    ])));
  Widget _pickup() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Where are we picking up?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
    const SizedBox(height: 6), const Text('Choose a neighborhood in Kigali.', style: TextStyle(fontSize: 13, color: AppColors.ink500)),
    const SizedBox(height: 20), _hoods(_ph, (h) => setState(() => _ph = h)), const SizedBox(height: 16),
    PelekaTextField(label: 'Street / building', hint: 'e.g. KG 9 Ave, near Ubumwe Grande', controller: _pa, prefixIcon: Icons.location_on_outlined),
    const SizedBox(height: 14), PelekaTextField(label: 'Notes for the rider (optional)', hint: 'Gate code, floor, landmarks…', controller: _pn, maxLines: 3, prefixIcon: Icons.sticky_note_2_outlined),
    const SizedBox(height: 20), PelekaCard(color: AppColors.blueLight, child: Row(children: const [Icon(Icons.info_outline, size: 18, color: AppColors.blue), SizedBox(width: 12),
      Expanded(child: Text('Peleka only delivers within Kigali City for now.', style: TextStyle(fontSize: 12, color: AppColors.navy)))])),
  ]);
  Widget _delivery() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Where should we deliver?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
    const SizedBox(height: 20), _hoods(_dh, (h) => setState(() => _dh = h)), const SizedBox(height: 16),
    PelekaTextField(label: 'Street / building', hint: 'e.g. KG 200 St, near Kimironko Market', controller: _da, prefixIcon: Icons.location_on),
    const SizedBox(height: 14), PelekaTextField(label: 'Recipient name', hint: 'Full name of the person receiving', controller: _rn, prefixIcon: Icons.person_outline, validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
    const SizedBox(height: 14), PelekaTextField(label: 'Recipient phone', hint: '+2507XX XXX XXX', controller: _rp, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().length < 6) ? 'Required' : null),
    const SizedBox(height: 14), PelekaTextField(label: 'Delivery notes (optional)', hint: 'How to reach the recipient…', controller: _dn, maxLines: 3, prefixIcon: Icons.sticky_note_2_outlined),
  ]);
  Widget _parcel() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Tell us about the parcel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)), const SizedBox(height: 20),
    const Padding(padding: EdgeInsets.only(left: 4, bottom: 6), child: Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink700))),
    Wrap(spacing: 8, runSpacing: 8, children: ParcelCategories.all.map((c) { final s = _cat == c.id;
      return GestureDetector(onTap: () => setState(() => _cat = c.id), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: s ? AppColors.navy : Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: s ? AppColors.navy : AppColors.ink200)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(c.icon, size: 14, color: s ? Colors.white : AppColors.ink500), const SizedBox(width: 6),
          Text(c.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s ? Colors.white : AppColors.ink700))]))); }).toList()),
    const SizedBox(height: 16), PelekaTextField(label: 'Description', hint: 'e.g. A4 documents in a brown envelope', controller: _desc, maxLines: 2, prefixIcon: Icons.description_outlined, validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
    const SizedBox(height: 14), PelekaTextField(label: 'Weight (kg)', hint: '1', controller: _w, prefixIcon: Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) { final x = double.tryParse(v ?? ''); if (x == null || x <= 0) return 'Enter a positive weight'; if (x > 200) return 'Contact support for > 200 kg'; return null; }),
    const SizedBox(height: 20), PelekaTextField(label: 'Sender name (you)', hint: 'Full name', controller: _sn, prefixIcon: Icons.person_outline, validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
    const SizedBox(height: 14), PelekaTextField(label: 'Sender phone', hint: '+2507XX XXX XXX', controller: _sp, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().length < 6) ? 'Required' : null),
    const SizedBox(height: 20), _tg(Icons.warning_amber_rounded, 'Fragile', 'Handle with extra care.', _fragile, (v) => setState(() => _fragile = v)),
    const SizedBox(height: 8), _tg(Icons.draw_outlined, 'Require signature', 'Rider must collect recipient signature.', _sig, (v) => setState(() => _sig = v)),
  ]);
  Widget _hoods(Map<String, dynamic>? sel, void Function(Map<String, dynamic>) onPick) => Wrap(spacing: 8, runSpacing: 8, children: Kigali.neighborhoods.map((h) { final s = sel?['name'] == h['name'];
    return GestureDetector(onTap: () => onPick(h), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: s ? AppColors.navy : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: s ? AppColors.navy : AppColors.ink200)),
      child: Text(h['name'], style: TextStyle(color: s ? Colors.white : AppColors.ink800, fontWeight: FontWeight.w600, fontSize: 12)))); }).toList());
  Widget _tg(IconData i, String t, String sub, bool v, void Function(bool) on) => PelekaCard(onTap: () => on(!v), child: Row(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(12)), child: Icon(i, size: 18, color: AppColors.orange)),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)), Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.ink500))])),
    Switch(value: v, onChanged: on, activeColor: AppColors.orange)]));
}
