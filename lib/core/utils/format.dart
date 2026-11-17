String _two(int n) => n.toString().padLeft(2, '0');

/// 12.3 -> "12,3"
String formatNumber(double value, {int decimals = 1}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String formatDayMonth(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String formatDateTime(DateTime d) => '${formatDayMonth(d)} ${_two(d.hour)}:${_two(d.minute)}';
