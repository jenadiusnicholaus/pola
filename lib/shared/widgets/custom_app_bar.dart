import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_sizes.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String? title;
  final bool showLogo;
  final bool showTagline;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double? expandedHeight;
  final Widget? flexibleSpace;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.showTagline = true,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive expanded height
    final screenHeight = MediaQuery.of(context).size.height;
    final baseHeight = showTagline ? 140.0 : 100.0;
    final responsiveHeight = (screenHeight * 0.18).clamp(baseHeight, 180.0);

    return SliverAppBar(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: AppColors.black,
      elevation: 2,
      automaticallyImplyLeading: automaticallyImplyLeading,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight ?? responsiveHeight,
      actions: actions,
      centerTitle: true,
      toolbarHeight: 56.0, // Standard toolbar height
      collapsedHeight: 56.0, // Ensure consistent collapsed height
      flexibleSpace: flexibleSpace ?? _buildCustomFlexibleSpace(),
      stretch: true, // Allow stretch on over-scroll
      stretchTriggerOffset: 100.0,
    );
  }

  Widget _buildExpandedLogoSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available space
        final availableHeight = constraints.maxHeight;
        final iconSize = (availableHeight * 0.25).clamp(20.0, 32.0);
        final titleSize = (availableHeight * 0.2).clamp(18.0, 28.0);
        final taglineSize = (availableHeight * 0.12).clamp(10.0, 14.0);
        final spacing = (availableHeight * 0.05).clamp(2.0, 8.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Justice scale icon at the top
            Text(
              '⚖️',
              style: TextStyle(
                fontSize: iconSize,
              ),
            ),
            SizedBox(height: spacing),

            // POLA in the middle
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.black,
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                letterSpacing: titleSize * 0.05,
              ),
            ),

            // Horizontal line separator
            Container(
              width: (titleSize * 2.5).clamp(40.0, 80.0),
              height: 2,
              color: AppColors.black,
              margin: EdgeInsets.symmetric(vertical: spacing * 0.5),
            ),

            if (showTagline && availableHeight > 80) ...[
              // Tagline at the bottom (only show if enough space)
              Text(
                'The lawyer you carry',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCustomFlexibleSpace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings = context
            .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
        final expandRatio =
            settings?.maxExtent != null && settings?.minExtent != null
                ? ((settings!.currentExtent - settings.minExtent) /
                        (settings.maxExtent - settings.minExtent))
                    .clamp(0.0, 1.0)
                : 1.0;

        // Smooth curve for transitions
        final smoothRatio = Curves.easeInOut.transform(expandRatio);

        return Container(
          color: AppColors.primaryAmber,
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Expanded logo with smooth fade and proper constraints
                if (showLogo)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (smoothRatio * 1.2 - 0.2).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Center(
                          child: Transform.scale(
                            scale: (0.8 + smoothRatio * 0.2).clamp(0.8, 1.0),
                            child: _buildExpandedLogoSection(),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Collapsed logo with smooth fade and slide
                if (showLogo)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12 + (smoothRatio * 16), // Slight vertical movement
                    child: Opacity(
                      opacity: (1.0 - smoothRatio * 1.5).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale:
                            (0.9 + (1.0 - smoothRatio) * 0.1).clamp(0.9, 1.0),
                        child: Center(
                          child: _buildCollapsedLogo(),
                        ),
                      ),
                    ),
                  ),

                // Compact title for non-logo mode
                if (!showLogo)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Center(
                      child: _buildCompactTitle(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedLogo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = (screenWidth * 0.045).clamp(16.0, 20.0);
        final textSize = (screenWidth * 0.045).clamp(16.0, 20.0);
        final spacing = (screenWidth * 0.015).clamp(4.0, 8.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Justice scale icon
            Text(
              '⚖️',
              style: TextStyle(
                fontSize: iconSize,
              ),
            ),
            SizedBox(width: spacing),

            // POLA text
            Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.black,
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                letterSpacing: textSize * 0.04,
              ),
            ),
            SizedBox(width: spacing * 0.7),

            // Small horizontal line
            Container(
              width: textSize,
              height: 1,
              color: AppColors.black,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactTitle() {
    return Text(
      title ?? AppStrings.appName,
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// Traditional AppBar for backward compatibility
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showTagline;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.showTagline = true,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: AppColors.black,
      elevation: 2,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: showLogo ? _buildLogoSection() : _buildTitleSection(),
      actions: actions,
      toolbarHeight: showTagline ? 80.0 : AppSizes.appBarHeight,
      centerTitle: true,
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Justice scale icon at the top
        const Text(
          '⚖️',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        // POLA in the middle
        Text(
          AppStrings.appName,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        // Horizontal line separator
        Container(
          width: 60,
          height: 1.5,
          color: AppColors.black,
          margin: const EdgeInsets.symmetric(vertical: 2),
        ),
        if (showTagline) ...[
          // Tagline at the bottom
          const Text(
            'The lawyer you carry',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleSection() {
    return Text(
      title ?? AppStrings.appName,
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(showTagline ? 80.0 : AppSizes.appBarHeight);
}

// Alternative compact app bar for inner pages
class CompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CompactAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: AppColors.black,
      elevation: 2,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.gavel,
            color: AppColors.black,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: actions,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);
}
