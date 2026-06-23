import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── Helper ────────────────────────────────────────────────────────────────

Widget _shimmerBox({
  required double width,
  double? height,
  double radius = 4,
}) =>
    Container(
      width: width,
      height: height ?? 14,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

// ─── Base wrapper ─────────────────────────────────────────────────────────

class _ShimmerBase extends StatelessWidget {
  final Widget child;
  const _ShimmerBase({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

// ─── Topics shimmer (two pill buttons per row) ─────────────────────────────

class TopicsShimmer extends StatelessWidget {
  final int itemCount;
  const TopicsShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Flexible(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 52,
                  radius: 12,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _shimmerBox(
                  width: double.infinity,
                  height: 52,
                  radius: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Material card shimmer ─────────────────────────────────────────────────

class MaterialsShimmer extends StatelessWidget {
  final int itemCount;
  const MaterialsShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(width: double.infinity, height: 16),
                          const SizedBox(height: 8),
                          _shimmerBox(width: 200, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _shimmerBox(width: 48, height: 48, radius: 8),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _shimmerBox(width: 60, height: 20, radius: 10),
                    const SizedBox(width: 8),
                    _shimmerBox(width: 80, height: 20, radius: 10),
                    const SizedBox(width: 8),
                    _shimmerBox(width: 50, height: 20, radius: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Subtopic card shimmer (re-exported for convenience) ──────────────────

class SubtopicShimmerList extends StatelessWidget {
  final int itemCount;
  const SubtopicShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _shimmerBox(width: 48, height: 48, radius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: double.infinity, height: 16),
                      const SizedBox(height: 8),
                      _shimmerBox(width: double.infinity, height: 12),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _shimmerBox(width: 80, height: 20, radius: 8),
                          const SizedBox(width: 8),
                          _shimmerBox(width: 30, height: 20, radius: 6),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _shimmerBox(width: 14, height: 14, radius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
