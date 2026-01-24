import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nearby_lawyers_controller.dart';
import '../models/nearby_lawyer_model.dart';
import '../../calling_booking/models/consultant_models.dart' as calling;
import '../../../widgets/profile_avatar.dart';
import '../../../services/permission_service.dart';
import '../../../utils/navigation_helper.dart';

class NearbyLawyersScreen extends StatelessWidget {
  const NearbyLawyersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NearbyLawyersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Lawyers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          final theme = Theme.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: theme.colorScheme.error.withOpacity(0.5)),
                SizedBox(height: 16),
                Text(
                  controller.error!,
                  style: TextStyle(
                      fontSize: 16,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.refresh,
                  icon: Icon(Icons.refresh),
                  label: Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (controller.lawyers.isEmpty) {
          final theme = Theme.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(
                  'No lawyers found nearby',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Try increasing the search radius',
                  style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showFilterDialog(context, controller),
                  child: Text('Adjust Filters'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 90, // Space for floating button
                ),
                itemCount: controller.lawyers.length + 2,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context, controller);
                  }

                  if (index == controller.lawyers.length + 1) {
                    // Loading indicator at bottom
                    return controller.isLoadingMore
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SizedBox.shrink();
                  }

                  final lawyer = controller.lawyers[index - 1];
                  return RepaintBoundary(
                    child: _LawyerCard(
                      key: ValueKey('lawyer_${lawyer.id}'),
                      lawyer: lawyer,
                    ),
                  );
                },
              ),
            ),
            // Floating "View on Map" button
            _buildViewOnMapButton(context, controller),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(
      BuildContext context, NearbyLawyersController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on,
                  color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found ${controller.count} ${controller.count == 1 ? 'lawyer' : 'lawyers'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Within ${controller.radius}km radius',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (controller.userLocation != null) ...[
            SizedBox(height: 4),
            Text(
              'Your location: ${controller.userLocation!.latitude.toStringAsFixed(4)}, ${controller.userLocation!.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewOnMapButton(
      BuildContext context, NearbyLawyersController controller) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Get.toNamed('/lawyers-map');
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'View on Map',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '(${controller.count})',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static calling.Consultant _convertToConsultant(NearbyLawyer lawyer) {
    debugPrint('🔄 Converting NearbyLawyer to Consultant:');
    debugPrint('   lawyer.id (profile ID): ${lawyer.id}');
    debugPrint('   lawyer.userId: ${lawyer.userId}');
    debugPrint('   lawyer.userDetails.id: ${lawyer.userDetails.id}');
    debugPrint('   lawyer.name: ${lawyer.userDetails.fullName}');
    
    return calling.Consultant(
      id: lawyer.id,
      userDetails: calling.UserDetails(
        id: lawyer.userDetails.id,
        email: lawyer.userDetails.email ?? '',
        firstName: lawyer.userDetails.firstName ?? '',
        lastName: lawyer.userDetails.lastName ?? '',
        fullName: lawyer.userDetails.fullName ?? '',
        phoneNumber: lawyer.userDetails.phoneNumber,
        profilePicture: lawyer.userDetails.profilePicture,
      ),
      consultantType: lawyer.consultantType,
      specialization: lawyer.specialization ?? '',
      yearsOfExperience: lawyer.yearsOfExperience ?? 0,
      offersMobileConsultations: lawyer.offersMobileConsultations,
      offersPhysicalConsultations: lawyer.offersPhysicalConsultations,
      city: lawyer.city,
      isAvailable: lawyer.isAvailable,
      totalConsultations: lawyer.totalConsultations,
      totalEarnings: lawyer.totalEarnings,
      averageRating: lawyer.averageRating ?? 0.0,
      totalReviews: lawyer.totalReviews,
      pricing: calling.ConsultantPricing(
        mobile: calling.PricingDetails(
          price: lawyer.pricing.mobile.price.toString(),
          consultantShare: lawyer.pricing.mobile.consultantShare.toString(),
          platformShare: lawyer.pricing.mobile.platformShare.toString(),
        ),
      ),
      isOnline: lawyer.isOnline,
    );
  }

  void _showFilterDialog(
      BuildContext context, NearbyLawyersController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Radius: ${controller.radius}km',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: controller.radius,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${controller.radius}km',
              onChanged: (value) {
                controller.updateRadius(value);
              },
            ),
            SizedBox(height: 16),
            Text('Professional Types:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text('Advocates'),
                      selected: controller.selectedTypes.contains('advocate'),
                      onSelected: (_) => controller.toggleUserType('advocate'),
                    ),
                    FilterChip(
                      label: Text('Lawyers'),
                      selected: controller.selectedTypes.contains('lawyer'),
                      onSelected: (_) => controller.toggleUserType('lawyer'),
                    ),
                    FilterChip(
                      label: Text('Paralegals'),
                      selected: controller.selectedTypes.contains('paralegal'),
                      onSelected: (_) => controller.toggleUserType('paralegal'),
                    ),
                    FilterChip(
                      label: Text('Law Firms'),
                      selected: controller.selectedTypes.contains('law_firm'),
                      onSelected: (_) => controller.toggleUserType('law_firm'),
                    ),
                  ],
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  final NearbyLawyer lawyer;

  const _LawyerCard({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final consultant = NearbyLawyersScreen._convertToConsultant(lawyer);
            Get.toNamed('/consultant-detail',
                arguments: {'consultant': consultant});
          },
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.all(16),
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
                // Header with profile picture and basic info
                Row(
                  children: [
                    // Profile Picture with online indicator
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ProfileAvatar(
                            imageUrl: lawyer.profilePicture,
                            fallbackText: lawyer.name ?? '?',
                            radius: 27,
                          ),
                        ),
                        // Online indicator
                        if (lawyer.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
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
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                lawyer.getUserTypeLabel(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lawyer.isOnline
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lawyer.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: lawyer.isOnline
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.location_on,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4)),
                              SizedBox(width: 2),
                              Text(
                                '${lawyer.distanceKm.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Specialization
                if (lawyer.specialization != null) ...[
                  SizedBox(height: 12),
                  Text(
                    lawyer.specialization!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                      height: 1.3,
                    ),
                  ),
                ],

                // Experience & Location in a compact row
                SizedBox(height: 10),
                Row(
                  children: [
                    // Experience
                    if (lawyer.yearsOfExperience != null) ...[
                      Icon(Icons.work_outline,
                          size: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      SizedBox(width: 4),
                      Text(
                        '${lawyer.yearsOfExperience} yrs',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    // Location
                    if (lawyer.location.officeAddress != null) ...[
                      if (lawyer.yearsOfExperience != null) ...[
                        SizedBox(width: 12),
                        Text('•',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3))),
                        SizedBox(width: 12),
                      ],
                      Icon(Icons.location_city,
                          size: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lawyer.location.officeAddress!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                // Action buttons
                SizedBox(height: 14),
                Row(
                  children: [
                    // Call button - only show if mobile consultations offered
                    if (lawyer.offersMobileConsultations) ...[
                      OutlinedButton.icon(
                        onPressed: () => _callLawyer(context, lawyer),
                        icon: Icon(Icons.phone, size: 15),
                        label: Text('Call',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withOpacity(0.5),
                            width: 1,
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    // Book button - only show for LAW FIRMS that offer physical consultations
                    if (lawyer.offersPhysicalConsultations &&
                        lawyer.consultantType.toLowerCase() == 'law_firm') ...[
                      OutlinedButton.icon(
                        onPressed: () => _bookConsultation(context, lawyer),
                        icon: Icon(Icons.calendar_today,
                            size: 15, color: theme.colorScheme.primary),
                        label: Text('Book',
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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

  void _callLawyer(BuildContext context, NearbyLawyer lawyer) async {
    // Check permission to talk to lawyer
    if (!NavigationHelper.checkPermissionOrShowUpgrade(
        context, PermissionFeature.talkToLawyer)) {
      return;
    }

    final consultant = NearbyLawyersScreen._convertToConsultant(lawyer);
    Get.toNamed('/call', arguments: {'consultant': consultant});
  }

  void _bookConsultation(BuildContext context, NearbyLawyer lawyer) {
    // Check permission to book consultation
    if (!NavigationHelper.checkPermissionOrShowUpgrade(
        context, PermissionFeature.bookConsultation)) {
      return;
    }

    final consultant = NearbyLawyersScreen._convertToConsultant(lawyer);
    // Book button is for physical consultations
    Get.toNamed('/book-consultation', arguments: {
      'consultant': consultant,
      'bookingType': 'physical',
    });
  }
}
