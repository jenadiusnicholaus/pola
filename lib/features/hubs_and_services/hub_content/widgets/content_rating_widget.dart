import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContentRatingWidget extends StatelessWidget {
  final int contentId;
  final String contentTitle;
  final bool showDetailedRatings;

  const ContentRatingWidget({
    super.key,
    required this.contentId,
    required this.contentTitle,
    this.showDetailedRatings = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rate,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Content Rating',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!showDetailedRatings)
                  TextButton(
                    onPressed: () => _showDetailedRatings(context),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall rating
            _buildOverallRating(theme),
            const SizedBox(height: 16),

            // Rating breakdown
            if (showDetailedRatings) ...[
              _buildRatingBreakdown(theme),
              const SizedBox(height: 16),
            ],

            // Add rating button
            _buildAddRatingButton(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating(ThemeData theme) {
    // TODO: Get actual rating data from content
    const averageRating = 4.2;
    const totalRatings = 156;

    return Row(
      children: [
        // Star rating display
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < averageRating.floor()
                  ? Icons.star
                  : index < averageRating
                      ? Icons.star_half
                      : Icons.star_border,
              color: Colors.amber,
              size: 24,
            );
          }),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$totalRatings ratings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBreakdown(ThemeData theme) {
    // TODO: Get actual rating breakdown data
    const ratingData = [
      {'stars': 5, 'count': 89, 'percentage': 0.57},
      {'stars': 4, 'count': 43, 'percentage': 0.28},
      {'stars': 3, 'count': 18, 'percentage': 0.12},
      {'stars': 2, 'count': 4, 'percentage': 0.025},
      {'stars': 1, 'count': 2, 'percentage': 0.015},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ratingData.map((data) => _buildRatingBar(
              theme,
              data['stars'] as int,
              data['count'] as int,
              data['percentage'] as double,
            )),
      ],
    );
  }

  Widget _buildRatingBar(
      ThemeData theme, int stars, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$stars',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRatingButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showRatingDialog(context),
        child: const Text('Rate this content'),
      ),
    );
  }

  void _showDetailedRatings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DetailedRatingsModal(
        contentId: contentId,
        contentTitle: contentTitle,
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        contentId: contentId,
        contentTitle: contentTitle,
      ),
    );
  }
}

class RatingDialog extends StatefulWidget {
  final int contentId;
  final String contentTitle;

  const RatingDialog({
    super.key,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Rate Content'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star rating selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Review text field
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                hintText: 'Share your thoughts about this content...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rating > 0 ? _submitRating : null,
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }

  void _submitRating() {
    // TODO: Submit rating through service
    Navigator.of(context).pop();
    Get.snackbar(
      'Success',
      'Thank you for rating this content!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}

class DetailedRatingsModal extends StatelessWidget {
  final int contentId;
  final String contentTitle;

  const DetailedRatingsModal({
    super.key,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'All Ratings & Reviews',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Overall rating widget
                    ContentRatingWidget(
                      contentId: contentId,
                      contentTitle: contentTitle,
                      showDetailedRatings: true,
                    ),
                    const SizedBox(height: 24),

                    // Individual reviews
                    _buildReviewsList(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(ThemeData theme) {
    // TODO: Get actual reviews data
    final sampleReviews = List.generate(
        10,
        (index) => {
              'id': index,
              'rating': (5 - (index % 5)),
              'review':
                  'This is a sample review text for rating ${5 - (index % 5)}. The content quality is ${index % 2 == 0 ? 'excellent' : 'good'} and I would recommend it.',
              'author': 'User ${index + 1}',
              'date': DateTime.now().subtract(Duration(days: index)),
            });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sampleReviews.map((review) => _buildReviewCard(theme, review)),
      ],
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review['rating'] ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  review['author'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(review['date']),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['review'],
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
