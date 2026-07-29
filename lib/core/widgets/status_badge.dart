import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color _bg() {
    switch (status) {
      case 'delivered': return const Color(0xFFDCFCE7);
      case 'in_transit':
      case 'out_for_delivery':
      case 'picked_up': return AppColors.blueLight;
      case 'assigned':
      case 'rider_en_route_to_pickup': return AppColors.navyLight;
      case 'pending_payment': return AppColors.orangeLight;   // unpaid
      case 'awaiting_assignment': return const Color(0xFFFEF3C7);
      case 'cancelled':
      case 'failed_pickup':
      case 'failed_delivery': return const Color(0xFFFEE2E2);
      default: return AppColors.ink100;
    }
  }

  Color _fg() {
    switch (status) {
      case 'delivered': return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
      case 'picked_up': return AppColors.blue;
      case 'assigned':
      case 'rider_en_route_to_pickup': return AppColors.navy;
      case 'pending_payment': return AppColors.orangeDark;    // unpaid
      case 'awaiting_assignment': return const Color(0xFF92400E);
      case 'cancelled':
      case 'failed_pickup':
      case 'failed_delivery': return AppColors.error;
      default: return AppColors.ink700;
    }
  }

  String _label() {
    if (status == 'pending_payment') return 'Unpaid';
    return status.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _fg(), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_label(), style: TextStyle(color: _fg(), fontWeight: FontWeight.w600, fontSize: 11)),
        ]),
      );
}
