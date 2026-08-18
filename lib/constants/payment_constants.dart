import 'package:flutter/material.dart';

/// Unified payment provider keys — must match backend PaymentProvider enum exactly.
/// Backend source: subscriptions/models.py -> PaymentProvider(TextChoices)
class PaymentProvider {
  PaymentProvider._(); // prevent instantiation

  static const String mpesa = 'Mpesa';
  static const String airtel = 'Airtel';
  static const String tigo = 'Tigo';
  static const String halopesa = 'Halopesa';
  static const String azampesa = 'Azampesa';
  static const String crdb = 'CRDB';
  static const String nmb = 'NMB';
  static const String bank = 'bank';

  /// Default fallback provider (matches backend default)
  static const String defaultProvider = mpesa;

  /// All mobile money providers (for UI selection)
  static const List<PaymentProviderOption> mobileProviders = [
    PaymentProviderOption(value: mpesa, label: 'M-Pesa', icon: Icons.phone_android),
    PaymentProviderOption(value: airtel, label: 'Airtel Money', icon: Icons.phone_iphone),
    PaymentProviderOption(value: tigo, label: 'Tigo Pesa', icon: Icons.phone),
    PaymentProviderOption(value: halopesa, label: 'Halo Pesa', icon: Icons.account_balance_wallet),
    PaymentProviderOption(value: azampesa, label: 'Azam Pesa', icon: Icons.account_balance),
  ];
}

/// A single selectable payment provider option for UI rendering.
class PaymentProviderOption {
  final String value;
  final String label;
  final IconData icon;

  const PaymentProviderOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  /// Convert to legacy Map format used by some screens
  Map<String, dynamic> toMap() => {
        'value': value,
        'label': label,
        'icon': icon,
        'id': value,
        'name': label,
      };
}
