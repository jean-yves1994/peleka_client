import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/format.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/payment_repository.dart';
import '../../shipments/presentation/shipments_view_model.dart';

/// Paypack Mobile Money payment (Request-to-Pay).
///
/// No WebView: the customer confirms their MoMo number in the app, we push a
/// charge to their phone, they approve with their PIN, and we poll until the
/// backend (webhook or live lookup) marks the payment paid.
///
/// Route: /pay?shipmentId=...&trackingNumber=...
class PaymentScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  final String trackingNumber;
  const PaymentScreen({
    super.key,
    required this.shipmentId,
    required this.trackingNumber,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

enum _Phase { enterPhone, requesting, waiting, success, failed }

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _phone = TextEditingController();
  _Phase _phase = _Phase.enterPhone;
  String? _error;
  String? _paymentId;
  double _amount = 0;
  String _currency = 'RWF';
  Timer? _pollTimer;
  int _elapsed = 0; // seconds spent waiting for approval

  static const _timeoutSeconds = 150; // MoMo prompts usually expire ~2 min

  @override
  void initState() {
    super.initState();
    if (widget.shipmentId.trim().isEmpty) {
      _phase = _Phase.failed;
      _error = 'Missing shipment reference. Please reopen this payment from '
          'the shipment screen.';
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _validPhone(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    var local = digits;
    if (local.startsWith('250')) local = local.substring(3);
    if (local.length == 9 && local.startsWith('7')) local = '0$local';
    return RegExp(r'^07\d{8}$').hasMatch(local);
  }

  Future<void> _request() async {
    if (!_validPhone(_phone.text)) {
      setState(() => _error = 'Enter a valid Mobile Money number, e.g. 0788111222');
      return;
    }
    setState(() {
      _phase = _Phase.requesting;
      _error = null;
    });
    try {
      final init = await ref
          .read(paymentRepositoryProvider)
          .initiatePaypack(widget.shipmentId, phone: _phone.text.trim());
      _paymentId = init.paymentId;
      _amount = init.amount;
      _currency = init.currency;
      if (!mounted) return;
      setState(() {
        _phase = _Phase.waiting;
        _elapsed = 0;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = e.toString().replaceAll('ApiException: ', '');
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _elapsed += 3;
      _pollOnce();
      if (_elapsed >= _timeoutSeconds) {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _phase = _Phase.failed;
            _error = "We didn't get a confirmation in time. If you approved the "
                "payment it may still land shortly — check the shipment screen. "
                "Otherwise you can try again.";
          });
        }
      }
    });
    _pollOnce();
  }

  Future<void> _pollOnce() async {
    if (_paymentId == null) return;
    try {
      final status = await ref.read(paymentRepositoryProvider).status(_paymentId!);
      if (!mounted) return;
      if (status == 'paid') {
        _pollTimer?.cancel();
        ref.invalidate(myShipmentsProvider);
        setState(() => _phase = _Phase.success);
      } else if (status == 'failed') {
        _pollTimer?.cancel();
        setState(() {
          _phase = _Phase.failed;
          _error = 'The payment was declined or cancelled. You can try again.';
        });
      }
    } catch (_) {
      // Transient error — keep polling.
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _phase == _Phase.requesting || _phase == _Phase.waiting;
    return PopScope(
      canPop: !busy,
      onPopInvoked: (didPop) {
        if (!didPop && busy) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmLeave),
        ),
        body: SafeArea(
          child: switch (_phase) {
            _Phase.enterPhone => _enterPhone(),
            _Phase.requesting => _spinner('Sending request to your phone…'),
            _Phase.waiting => _waiting(),
            _Phase.success => _result(
                icon: Icons.check_circle,
                color: AppColors.success,
                title: 'Payment successful',
                subtitle: 'Your delivery ${widget.trackingNumber} is confirmed and '
                    'will be assigned to a rider shortly.',
                primaryLabel: 'View shipment',
                onPrimary: () => context.go('/shipments/${widget.shipmentId}'),
              ),
            _Phase.failed => _result(
                icon: Icons.error_outline,
                color: AppColors.error,
                title: 'Payment not completed',
                subtitle: _error ?? 'Something went wrong.',
                primaryLabel: 'Try again',
                onPrimary: () => setState(() {
                  _phase = _Phase.enterPhone;
                  _error = null;
                }),
                secondaryLabel: widget.shipmentId.trim().isEmpty
                    ? 'Back to shipments'
                    : 'Back to shipment',
                onSecondary: () => widget.shipmentId.trim().isEmpty
                    ? context.go('/shipments')
                    : context.go('/shipments/${widget.shipmentId}'),
              ),
          },
        ),
      ),
    );
  }

  // ── Step 1: phone entry ─────────────────────────────────────────────
  Widget _enterPhone() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.smartphone, color: AppColors.orange, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Pay with Mobile Money',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 8),
          const Text(
            "We'll send a payment request to your phone. Approve it with your "
            'Mobile Money PIN to confirm the delivery.',
            style: TextStyle(fontSize: 13, color: AppColors.ink500, height: 1.5),
          ),
          const SizedBox(height: 24),
          PelekaTextField(
            label: 'Mobile Money number',
            hint: '0788111222',
            controller: _phone,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          const Text('MTN, Airtel and Tigo are supported.',
              style: TextStyle(fontSize: 11, color: AppColors.ink500)),
          if (_error != null) ...[const SizedBox(height: 12), _banner(_error!)],
          const SizedBox(height: 20),
          PelekaCard(
            color: AppColors.blueLight,
            child: Row(children: const [
              Icon(Icons.lock_outline, size: 18, color: AppColors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your PIN is entered on your own phone — never in this app.',
                  style: TextStyle(fontSize: 12, color: AppColors.navy),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          PelekaButton(
            label: 'Send payment request',
            icon: Icons.send,
            onPressed: _request,
          ),
        ],
      );

  // ── Step 2: waiting for approval ────────────────────────────────────
  Widget _waiting() {
    final remaining = (_timeoutSeconds - _elapsed).clamp(0, _timeoutSeconds);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
          ),
          const SizedBox(height: 28),
          const Text('Check your phone',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 10),
          Text(
            'Enter your Mobile Money PIN to approve the payment'
            '${_amount > 0 ? ' of ${money(_amount, currency: _currency)}' : ''}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink500, height: 1.4),
          ),
          const SizedBox(height: 24),
          PelekaCard(
            child: Row(children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppColors.ink500),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Waiting for confirmation… ${remaining}s',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink700)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Text(
            "Didn't get a prompt? Dial your Mobile Money menu to check pending "
            'approvals, or go back and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.ink500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    if (_phase == _Phase.success) {
      context.go('/shipments/${widget.shipmentId}');
      return;
    }
    if (_phase == _Phase.enterPhone || _phase == _Phase.failed) {
      if (widget.shipmentId.trim().isEmpty) {
        context.go('/shipments');
      } else {
        context.go('/shipments/${widget.shipmentId}');
      }
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Stop waiting?'),
        content: const Text(
          'Your shipment stays unpaid until the payment is confirmed. If you '
          'already approved it on your phone, it may still complete — you can '
          'check the shipment screen.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep waiting')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _pollTimer?.cancel();
      context.go('/shipments/${widget.shipmentId}');
    }
  }

  Widget _spinner(String label) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: AppColors.orange),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: AppColors.ink500)),
        ]),
      );

  Widget _banner(String m) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFF991B1B), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(m, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13))),
        ]),
      );

  Widget _result({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 44),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink500, height: 1.4)),
          const SizedBox(height: 28),
          PelekaButton(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            PelekaButton(label: secondaryLabel, outlined: true, onPressed: onSecondary),
          ],
        ]),
      );
}
