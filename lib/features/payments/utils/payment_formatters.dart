class PaymentFormatters {
  static String fmt(num v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  static String fmtDateTime(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    if (s.length < 16) return s;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)} à ${s.substring(11, 16)}';
  }
}
