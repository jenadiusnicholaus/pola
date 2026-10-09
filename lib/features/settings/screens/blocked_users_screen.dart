import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../models/safety_models.dart';
import '../services/account_safety_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final AccountSafetyService _service = Get.find<AccountSafetyService>();
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _service.listBlockedUsers();
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load blocked users';
        _isLoading = false;
      });
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock ${user.blockedName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.unblockUser(user.blockedUserId);
      setState(() {
        _blockedUsers.removeWhere((u) => u.id == user.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.blockedName} unblocked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unblock user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Blocked Users'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _blockedUsers.isEmpty
                  ? const Center(child: Text('You have not blocked anyone'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _blockedUsers.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          return Dismissible(
                            key: ValueKey(user.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _unblock(user);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red.shade100,
                              child: const Icon(Icons.lock_open,
                                  color: Colors.red),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryAmber,
                                backgroundImage:
                                    user.blockedProfilePicture != null
                                        ? NetworkImage(
                                            user.blockedProfilePicture!)
                                        : null,
                                child: user.blockedProfilePicture == null
                                    ? Text(user.blockedName.isNotEmpty
                                        ? user.blockedName[0].toUpperCase()
                                        : '?')
                                    : null,
                              ),
                              title: Text(user.blockedName),
                              subtitle: Text(user.reason.isNotEmpty
                                  ? user.reason
                                  : user.blockedEmail),
                              trailing: TextButton(
                                onPressed: () => _unblock(user),
                                child: const Text('Unblock'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
