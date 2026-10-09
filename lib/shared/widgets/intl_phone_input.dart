import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../utils/phone_utils.dart';

/// International phone input with a searchable country picker
/// (defaults to Tanzania) and live validity feedback:
///
/// - neutral border while the field is empty
/// - green border + check icon when the number is complete/valid
/// - red border + error icon when incomplete/invalid
///
/// Validity is strict for Tanzanian numbers (`255XXXXXXXXX`) and
/// length-based (`minLength`/`maxLength` per country) elsewhere.
class IntlPhoneInput extends StatefulWidget {
  const IntlPhoneInput({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.initialCountryCode = 'TZ',
    this.borderRadius = 8,
    this.filled = false,
    this.fillColor,
    this.contentPadding,
    this.prefixIcon,
    this.showFlags = true,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.invalidNumberMessage,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final String? labelText;
  final String? hintText;
  final String? helperText;

  /// Initial national number (without the country dial code).
  final String? initialValue;

  /// ISO code of the initially selected country. Defaults to `TZ`.
  final String initialCountryCode;

  final double borderRadius;
  final bool filled;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final bool showFlags;

  /// Emits the full international number as digits only
  /// (e.g. `255712345678`, no `+`).
  final ValueChanged<String>? onChanged;

  final ValueChanged<Country>? onCountryChanged;
  final FutureOr<String?> Function(PhoneNumber?)? validator;
  final String? invalidNumberMessage;
  final AutovalidateMode autovalidateMode;

  @override
  State<IntlPhoneInput> createState() => _IntlPhoneInputState();
}

class _IntlPhoneInputState extends State<IntlPhoneInput> {
  late Country _country;
  String _national = '';
  PhoneInputState _state = PhoneInputState.empty;

  @override
  void initState() {
    super.initState();
    _country = countries.firstWhere(
      (c) => c.code == widget.initialCountryCode,
      orElse: () => countries.firstWhere((c) => c.code == 'TZ'),
    );
    final initial = widget.initialValue?.trim() ?? '';
    if (initial.isNotEmpty) {
      _national = initial;
      _state = _isValid(initial, '${_country.dialCode}$initial')
          ? PhoneInputState.valid
          : PhoneInputState.invalid;
    }
  }

  bool _isValid(String national, String complete) {
    if (_country.code == 'TZ') {
      return PhoneUtils.isValidTanzanian(complete);
    }
    final digits = national.replaceAll(RegExp(r'\D'), '');
    return digits.length >= _country.minLength &&
        digits.length <= _country.maxLength;
  }

  void _refreshState() {
    if (_national.trim().isEmpty) {
      _state = PhoneInputState.empty;
    } else {
      _state =
          _isValid(_national, '${_country.dialCode}${_national.trim()}')
              ? PhoneInputState.valid
              : PhoneInputState.invalid;
    }
  }

  void _handleChanged(PhoneNumber phone) {
    setState(() {
      _national = phone.number;
      _refreshState();
    });
    widget.onChanged?.call(phone.completeNumber);
  }

  void _handleCountryChanged(Country country) {
    setState(() {
      _country = country;
      _refreshState();
    });
    widget.onCountryChanged?.call(country);
    // Emit the number again with the new dial code.
    if (_national.trim().isNotEmpty) {
      widget.onChanged
          ?.call('${country.dialCode}${_national.trim()}');
    }
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neutral = theme.colorScheme.outline;
    final accent = _state.isValid
        ? Colors.green.shade600
        : _state.isInvalid
            ? Colors.redAccent
            : null;

    return IntlPhoneField(
      initialValue: widget.initialValue,
      initialCountryCode: widget.initialCountryCode,
      invalidNumberMessage:
          widget.invalidNumberMessage ?? 'Invalid phone number',
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      showCountryFlag: widget.showFlags,
      onChanged: _handleChanged,
      onCountryChanged: _handleCountryChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        contentPadding: widget.contentPadding,
        filled: widget.filled,
        fillColor: widget.fillColor,
        suffixIcon: _state == PhoneInputState.empty
            ? null
            : Icon(
                _state.isValid
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: _state.isValid
                    ? Colors.green.shade600
                    : Colors.redAccent,
                size: 20,
              ),
        border: _border(accent ?? neutral, 1),
        enabledBorder:
            _border(accent ?? neutral, accent != null ? 1.5 : 1),
        focusedBorder:
            _border(accent ?? theme.colorScheme.primary, 2),
      ),
    );
  }
}
