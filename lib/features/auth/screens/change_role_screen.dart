import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../services/lookup_service.dart';
import '../models/lookup_models.dart';
import '../../../services/token_storage_service.dart';
import '../../profile/services/profile_service.dart';

class ChangeRoleScreen extends StatefulWidget {
  const ChangeRoleScreen({super.key});

  @override
  State<ChangeRoleScreen> createState() => _ChangeRoleScreenState();
}

class _ChangeRoleScreenState extends State<ChangeRoleScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final LookupService _lookupService = Get.find<LookupService>();
  final ProfileService _profileService = Get.find<ProfileService>();

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _getCurrentRole();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    await _lookupService.fetchUserRoles();
  }

  void _getCurrentRole() {
    // Get current user role from token storage
    final tokenStorage = Get.find<TokenStorageService>();
    _currentRole = tokenStorage.getUserRole()?.toLowerCase();
    debugPrint('Current role: $_currentRole');
  }

  Future<void> _changeRole() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      Get.snackbar(
        'Validation Error',
        'Please select a new role',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.changeRole(
        newRole: _selectedRole!,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        final verificationRequired = response['verification_required'] ?? false;
        final message = response['message'] ?? 'Role changed successfully';
        final newRole = response['new_role'];

        // Update current role display if role change was successful
        if (newRole != null && !verificationRequired) {
          // Fetch updated profile to sync with backend and update local storage
          await _profileService.fetchProfile();

          setState(() {
            _currentRole = newRole.toString().toLowerCase();
            _selectedRole = null; // Clear selection
            _reasonController.clear(); // Clear reason field
          });
        }

        Get.snackbar(
          'Success',
          message,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // Navigate based on whether verification is required
        if (verificationRequired) {
          Get.offAllNamed('/verification');
        } else {
          // Refresh profile and go back
          Get.back(result: true);
        }
      } else {
        final error = response['error'] ?? 'Failed to change role';
        Get.snackbar(
          'Error',
          error,
          icon: const Icon(Icons.error, color: Colors.white),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error changing role: $e');
      Get.snackbar(
        'Error',
        'Failed to change role: $e',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirm Role Change'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Are you sure you want to change your role to $_selectedRole?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Important:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Professional → Professional: Data retained\n'
                        '• Non-professional → Professional: Verification required\n'
                        '• Professional → Non-professional: Not allowed',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Role'),
      ),
      body: Obx(() {
        // Filter out student, lecturer, and citizen roles
        final roles = _lookupService.userRoles
            .where((role) =>
                role.roleName != 'student' &&
                role.roleName != 'lecturer' &&
                role.roleName != 'citizen')
            .toList();

        if (_lookupService.isLoadingRoles) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Role Info
                if (_currentRole != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Role',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentRole!.replaceAll('_', ' ').toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Role Selection
                Text(
                  'Select New Role',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the role that best describes your current professional status',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                // Role Cards
                if (roles.isEmpty)
                  const Center(
                    child: Text('No roles available'),
                  )
                else
                  ...roles.map((role) => _buildRoleCard(role, theme)),

                const SizedBox(height: 24),

                // Reason Field
                Text(
                  'Reason for Change (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'E.g., Graduated from law school, obtained certification, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changeRole,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change Role'),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Data Retention Policy:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '✅ Professional ↔ Professional: All data kept\n'
                        '✅ Student/Citizen → Professional: Verification required\n'
                        '❌ Professional → Student/Citizen: Not allowed',
                        style: TextStyle(fontSize: 12),
                      ),
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

  Widget _buildRoleCard(UserRole role, ThemeData theme) {
    final isSelected = _selectedRole == role.roleName;
    final isCurrent = _currentRole == role.roleName.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrent
              ? null
              : () {
                  setState(() {
                    _selectedRole = role.roleName;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isCurrent
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio Button
                Radio<String>(
                  value: role.roleName,
                  groupValue: _selectedRole,
                  onChanged: isCurrent
                      ? null
                      : (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                ),

                const SizedBox(width: 12),

                // Role Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            role.getRoleDisplay,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'CURRENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (role.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          role.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
