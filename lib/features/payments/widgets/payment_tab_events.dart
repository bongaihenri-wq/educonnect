import 'package:flutter/material.dart';

/// Bus minimal de communication tab → page (déclenche le rechargement global)
class PaymentTabEvents {
  PaymentTabEvents._();
  static final instance = PaymentTabEvents._();
  final listeners = <VoidCallback>[];

  void notifyChanged() {
    for (final l in listeners) {
      l();
    }
  }
}
