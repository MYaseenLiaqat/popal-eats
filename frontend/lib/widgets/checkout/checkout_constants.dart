import 'package:flutter/material.dart';

/// Layout and motion tokens for checkout flow.
abstract final class CheckoutConstants {
  static const cardRadius = 20.0;
  static const animDuration = Duration(milliseconds: 260);
  static const animCurve = Curves.easeOutCubic;

  /// Placeholder until Delivery Tracking screen ships.
  static const trackOrderRouteName = 'delivery_tracking';
}

enum CheckoutPaymentMethod { cash, card, wallet }

extension CheckoutPaymentMethodX on CheckoutPaymentMethod {
  String get label => switch (this) {
        CheckoutPaymentMethod.cash => 'Cash on Delivery',
        CheckoutPaymentMethod.card => 'Credit / Debit Card',
        CheckoutPaymentMethod.wallet => 'Wallet',
      };

  IconData get icon => switch (this) {
        CheckoutPaymentMethod.cash => Icons.payments_outlined,
        CheckoutPaymentMethod.card => Icons.credit_card_outlined,
        CheckoutPaymentMethod.wallet => Icons.account_balance_wallet_outlined,
      };
}
