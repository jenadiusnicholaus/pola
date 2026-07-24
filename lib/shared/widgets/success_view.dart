import 'package:flutter/material.dart';

/// A reusable, theme-adaptive success view that works as a dialog,
/// full-screen body, or bottom sheet content.
///
/// It animates a checkmark icon and adapts its colors to the current
/// Material 3 color scheme, so it looks correct in both light and dark mode.
class SuccessView extends StatefulWidget {
  /// Main heading, e.g. "Payment Successful!".
  final String title;

  /// Optional subtitle / body text.
  final String? message;

  /// Extra widgets shown below the message (transaction IDs, bullet lists, etc.).
  final Widget? details;

  /// Label for the primary action button.
  final String primaryButtonLabel;

  /// Called when the primary button is pressed.
  final VoidCallback? onPrimaryPressed;

  /// Optional label for a secondary action button.
  final String? secondaryButtonLabel;

  /// Called when the secondary button is pressed.
  final VoidCallback? onSecondaryPressed;

  /// Icon shown in the animated badge. Defaults to a checkmark.
  final IconData icon;

  /// Whether to play the scale/bounce animation.
  final bool useAnimation;

  /// When true, the view is wrapped in a [Dialog] shape suitable for
  /// [showDialog] / [Get.dialog]. When false, it can be placed directly
  /// inside a [Scaffold] body or a [BottomSheet].
  final bool showAsDialog;

  const SuccessView({
    super.key,
    this.title = 'Success!',
    this.message,
    this.details,
    this.primaryButtonLabel = 'Done',
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.icon = Icons.check_circle_rounded,
    this.useAnimation = true,
    this.showAsDialog = false,
  });

  /// Convenience constructor for showing as a dialog.
  const SuccessView.dialog({
    super.key,
    this.title = 'Success!',
    this.message,
    this.details,
    this.primaryButtonLabel = 'Done',
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.icon = Icons.check_circle_rounded,
    this.useAnimation = true,
  }) : showAsDialog = true;

  /// Show the success view as a modal dialog.
  static Future<T?> show<T>(
    BuildContext context, {
    String title = 'Success!',
    String? message,
    Widget? details,
    String primaryButtonLabel = 'Done',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
    IconData icon = Icons.check_circle_rounded,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SuccessView.dialog(
        title: title,
        message: message,
        details: details,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonLabel: secondaryButtonLabel,
        onSecondaryPressed: onSecondaryPressed,
        icon: icon,
      ),
    );
  }

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 45,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _ringAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    if (widget.useAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = _buildContent(context, theme, colorScheme);

    if (widget.showAsDialog) {
      return Dialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: content,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAnimatedIcon(colorScheme),
        const SizedBox(height: 24),
        Text(
          widget.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.details != null) ...[
          const SizedBox(height: 20),
          widget.details!,
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed:
                widget.onPrimaryPressed ?? () => Navigator.of(context).pop(),
            icon: Icon(Icons.check, color: colorScheme.onPrimary),
            label: Text(widget.primaryButtonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.secondaryButtonLabel != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: widget.onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(widget.secondaryButtonLabel!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnimatedIcon(ColorScheme colorScheme) {
    final iconSize = 88.0;
    final badgeColor = colorScheme.primary;
    final iconColor = colorScheme.onPrimary;

    return SizedBox(
      width: iconSize + 32,
      height: iconSize + 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding decorative ring
              Opacity(
                opacity: widget.useAnimation
                    ? ((1.5 - _ringAnimation.value) * 0.8).clamp(0.0, 0.4)
                    : 0.0,
                child: Transform.scale(
                  scale: _ringAnimation.value,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
              // Solid background circle
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withOpacity(0.15),
                ),
              ),
              // Animated checkmark
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: iconSize * 0.75,
                  height: iconSize * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor,
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: iconSize * 0.45,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
