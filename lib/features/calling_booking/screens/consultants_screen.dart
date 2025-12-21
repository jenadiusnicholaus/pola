import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consultant_controller.dart';
import '../models/consultant_models.dart';
import '../../../widgets/profile_avatar.dart';

class ConsultantsScreen extends StatelessWidget {
  const ConsultantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConsultantController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahakama | Talk to Lawyers'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/buy-credits'),
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'My Credits',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.consultants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => controller.fetchConsultants(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (controller.consultants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No consultants available',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchConsultants(),
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.consultants.length +
                (controller.hasMore.value ? 1 : 0),
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            cacheExtent: 500,
            itemBuilder: (context, index) {
              if (index == controller.consultants.length) {
                // Loading indicator at bottom
                return Obx(() => controller.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink());
              }
              final consultant = controller.consultants[index];
              return RepaintBoundary(
                child: _buildConsultantCard(context, consultant),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildConsultantCard(BuildContext context, Consultant consultant) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: ValueKey('consultant_${consultant.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed('/consultant-detail',
                arguments: {'consultant': consultant});
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Profile Picture, Name and Rating
                Row(
                  children: [
                    // Profile Picture with online indicator
                    Stack(
                      children: [
                        ProfileAvatar(
                          imageUrl: consultant.userDetails.profilePicture,
                          fallbackText: consultant.userDetails.fullName,
                          radius: 28,
                        ),
                        // Online status indicator
                        if (consultant.isOnline)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultant.userDetails.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${consultant.consultantType.toUpperCase()} • ${consultant.yearsOfExperience} yrs',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: consultant.isOnline
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  consultant.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: consultant.isOnline
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Rating badge - minimal
                    if (consultant.averageRating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            consultant.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Specialization
                if (consultant.specialization.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    consultant.specialization,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons based on what consultant offers
                Row(
                  children: [
                    // Mobile Call button
                    if (consultant.offersMobileConsultations)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCallConsultant(consultant),
                          icon: Icon(Icons.phone,
                              size: 15, color: theme.colorScheme.primary),
                          label: Text('Call',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            minimumSize: const Size(0, 38),
                          ),
                        ),
                      ),

                    // Physical consultation button
                    if (consultant.offersPhysicalConsultations) ...[
                      if (consultant.offersMobileConsultations)
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleBookConsultation(consultant),
                          icon: Icon(Icons.calendar_today,
                              size: 15, color: theme.colorScheme.primary),
                          label: Text(
                            'Book',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            minimumSize: const Size(0, 38),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCallConsultant(Consultant consultant) {
    // Navigate to call screen
    Get.toNamed(
      '/call',
      arguments: {
        'consultant': consultant,
      },
    );
  }

  void _handleBookConsultation(Consultant consultant) {
    // Navigate to booking screen - Book button is for physical consultations
    Get.toNamed('/book-consultation', arguments: {
      'consultant': consultant,
      'bookingType': 'physical',
    });
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
