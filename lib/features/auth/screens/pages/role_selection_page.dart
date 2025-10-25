import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/registration_controller.dart';
import '../../models/lookup_models.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final controller = Get.find<RegistrationController>();
  int? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = controller.registrationData.userRole == 0
        ? null
        : controller.registrationData.userRole;
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserRoles();
    });
  }

  void _loadUserRoles() async {
    if (mounted) {
      await controller.lookupService.fetchUserRoles();
    }
  }

  void _selectRole(int roleId) {
    setState(() {
      _selectedRole = roleId;
    });
    controller.updateUserRole(roleId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Role',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select which category best describes you. This will determine what information we need to collect.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          Obx(() {
            final roles = controller.lookupService.userRoles;
            print('Roles in UI: ${roles.length} roles loaded');

            if (controller.lookupService.isLoadingRoles) {
              return Container(
                height: 300,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading user roles...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (roles.isEmpty) {
              return Container(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No roles available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check your internet connection and try again.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          controller.lookupService.clearCache();
                          controller.lookupService.fetchUserRoles();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: roles.map((UserRole role) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: _selectedRole == role.id ? 4 : 1,
                    color: _selectedRole == role.id
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    child: InkWell(
                      onTap: () => _selectRole(role.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Role Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedRole == role.id
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                _getRoleIcon(role.id),
                                color: _selectedRole == role.id
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Role Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.getRoleDisplay,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedRole == role.id
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getRoleDescription(role.id),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRoleRequirements(role.id),
                                ],
                              ),
                            ),

                            // Selection Indicator
                            Radio<int>(
                              value: role.id,
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                if (value != null) {
                                  _selectRole(value);
                                }
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 24),

          // Information about next steps
          if (_selectedRole != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Next Steps',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getNextStepsInfo(_selectedRole!),
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(int roleId) {
    switch (roleId) {
      case 1:
        return Icons.gavel; // Lawyer
      case 2:
        return Icons.balance; // Advocate
      case 3:
        return Icons.support_agent; // Paralegal
      case 4:
        return Icons.school; // Law Student
      case 5:
        return Icons.business; // Law Firm
      case 6:
        return Icons.person; // Citizen
      case 7:
        return Icons.cast_for_education; // Lecturer
      default:
        return Icons.person;
    }
  }

  String _getRoleDescription(int roleId) {
    final roles = controller.lookupService.userRoles;
    try {
      final role = roles.firstWhere((role) => role.id == roleId);
      return role.description ?? 'No description available';
    } catch (e) {
      print('Role not found for ID: $roleId');
      return 'Role description not available';
    }
  }

  Widget _buildRoleRequirements(int roleId) {
    List<String> requirements = _getRoleRequirements(roleId);

    return Column(
      children: requirements
          .take(3)
          .map((req) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<String> _getRoleRequirements(int roleId) {
    // TODO: This should come from the API when role requirements endpoint is available
    // For now, return a generic message based on role complexity
    final roles = controller.lookupService.userRoles;
    try {
      roles.firstWhere((role) => role.id == roleId);
      // Return generic requirements based on role type
      // This will be replaced with API data when available
      return [
        'Complete your profile information',
        'Provide role-specific details',
        'Verify your identity if required'
      ];
    } catch (e) {
      return ['Complete registration process'];
    }
  }

  String _getNextStepsInfo(int roleId) {
    // TODO: This should come from the API when role next steps endpoint is available
    final roles = controller.lookupService.userRoles;
    try {
      final role = roles.firstWhere((role) => role.id == roleId);
      // Return generic next steps message
      // This will be replaced with API data when available
      return 'You will need to complete additional information specific to your ${role.getRoleDisplay} role in the next steps.';
    } catch (e) {
      return 'Please complete the registration process in the next steps.';
    }
  }
}
