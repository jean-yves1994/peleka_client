import 'package:intl/intl.dart';

/// Money formatting. Defaults to RWF (Rwandan Franc) which has no practical
/// decimal subunit, so we render whole numbers: "RWF 2,242".
String money(dynamic a, {String currency = 'RWF'}) {
  if (a == null) return '—';
  final v = a is num ? a.toDouble() : double.tryParse(a.toString()) ?? 0;
  final cur = currency.toUpperCase();
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: cur == 'RWF' ? 'RWF ' : '$cur ',
    decimalDigits: cur == 'RWF' ? 0 : 2,
  ).format(v);
}

String dateTime(DateTime? d) => d == null ? '—' : DateFormat('MMM d, HH:mm').format(d.toLocal());

String relative(DateTime? d) {
  if (d == null) return '—';
  final x = DateTime.now().difference(d);
  if (x.inSeconds < 60) return '${x.inSeconds}s ago';
  if (x.inMinutes < 60) return '${x.inMinutes}m ago';
  if (x.inHours < 24) return '${x.inHours}h ago';
  return '${x.inDays}d ago';
}

String titleCase(String s) => s
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
