import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/role_specific_info.dart';
import '../widgets/subscription_card.dart';
import '../../user_verification/widgets/profile_verification_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller once in initState
    controller = Get.put(ProfileController(), tag: 'profile_screen');
  }

  @override
  void dispose() {
    // Clean up controller when screen is disposed
    Get.delete<ProfileController>(tag: 'profile_screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshProfile,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile screen
              Get.snackbar(
                'Coming Soon',
                'Profile editing feature will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoading && controller.profile == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading profile...'),
              ],
            ),
          );
        }

        // Error state
        if (controller.error.isNotEmpty && controller.profile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.refreshProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Profile loaded
        final profile = controller.profile;
        if (profile == null) {
          return const Center(
            child: Text('No profile data available'),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header (Avatar, Name, Role) - Full width with top spacing
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: ProfileHeader(profile: profile),
                ),

                // Content with padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verification Status
                      const ProfileVerificationCard(),
                      const SizedBox(height: 16),

                      // Subscription Info
                      SubscriptionCard(subscription: profile.subscription),
                      const SizedBox(height: 16),

                      // Basic Information
                      ProfileInfoCard(
                        title: 'Personal Information',
                        icon: Icons.person,
                        children: [
                          _buildInfoRow(
                            profile.userRole.roleName == 'law_firm'
                                ? 'Name'
                                : 'Full Name',
                            profile.fullName,
                          ),
                          _buildInfoRow('Email', profile.email),
                          // Hide personal details for law firms
                          if (profile.userRole.roleName != 'law_firm') ...[
                            _buildInfoRow('Date of Birth', profile.dateOfBirth),
                            _buildInfoRow(
                                'Gender', _getGenderDisplay(profile.gender)),
                          ],
                          if (profile.idNumber != null)
                            _buildInfoRow('ID Number', profile.idNumber!),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Information
                      ProfileInfoCard(
                        title: 'Contact Information',
                        icon: Icons.contact_phone,
                        children: [
                          _buildInfoRow('Phone', profile.contact.phoneNumber,
                              trailing: profile.contact.phoneIsVerified
                                  ? Icon(Icons.verified,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20)
                                  : Icon(Icons.error_outline,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 20)),
                          if (profile.contact.website != null)
                            _buildInfoRow('Website', profile.contact.website!),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address Information
                      if (profile.address.regionName != null)
                        ProfileInfoCard(
                          title: 'Address',
                          icon: Icons.location_on,
                          children: [
                            if (profile.address.regionName != null)
                              _buildInfoRow(
                                  'Region', profile.address.regionName!),
                            if (profile.address.districtName != null)
                              _buildInfoRow(
                                  'District', profile.address.districtName!),
                            if (profile.address.ward != null)
                              _buildInfoRow('Ward', profile.address.ward!),
                            if (profile.address.officeAddress != null)
                              _buildInfoRow('Office Address',
                                  profile.address.officeAddress!),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Role-Specific Information
                      RoleSpecificInfo(profile: profile),
                      const SizedBox(height: 24),

                      // Account Information
                      ProfileInfoCard(
                        title: 'Account Details',
                        icon: Icons.info_outline,
                        children: [
                          _buildInfoRow(
                              'Member Since', _formatDate(profile.dateJoined)),
                          if (profile.lastLogin != null)
                            _buildInfoRow(
                                'Last Login', _formatDate(profile.lastLogin!)),
                          _buildInfoRow('Account Status',
                              profile.isActive ? 'Active' : 'Inactive',
                              trailing: Icon(
                                profile.isActive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: profile.isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                size: 20,
                              )),
                          _buildInfoRow('Verification',
                              profile.isVerified ? 'Verified' : 'Not Verified',
                              trailing: Icon(
                                profile.isVerified
                                    ? Icons.verified
                                    : Icons.error_outline,
                                color: profile.isVerified
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                size: 20,
                              )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Permissions Section (collapsible)
                      ExpansionTile(
                        title: Text(
                          'Permissions (${profile.permissions.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.security),
                        children: profile.permissions
                            .map((perm) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.check, size: 16),
                                  title: Text(
                                    perm.replaceAll('_', ' ').titleCase,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderDisplay(String gender) {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return gender;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

extension StringExtension on String {
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
