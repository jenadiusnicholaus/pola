import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/content_creation_screen.dart';
import '../utils/user_role_manager.dart';

/// Custom floating action button for content creation
class ContentCreationFAB extends StatelessWidget {
  final String hubType;
  final String? heroTag;
  final VoidCallback? onContentCreated;

  const ContentCreationFAB({
    super.key,
    required this.hubType,
    this.heroTag,
    this.onContentCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag ?? 'content_creation_$hubType',
      onPressed: () => _navigateToCreation(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
    );
  }

  void _navigateToCreation() async {
    final result = await Get.to(
      () => const ContentCreationScreen(),
      arguments: {'hubType': hubType},
      transition: Transition.rightToLeft,
    );

    print('🔄 ContentCreationFAB: Navigation result = $result');
    print('🔄 ContentCreationFAB: Has callback = ${onContentCreated != null}');

    // If content was successfully created, trigger refresh
    if (result == true && onContentCreated != null) {
      print('🔄 ContentCreationFAB: Triggering refresh callback');
      // Small delay to ensure navigation is complete
      await Future.delayed(const Duration(milliseconds: 100));
      onContentCreated!();
    }
  }

  String _getLabel() {
    switch (hubType) {
      case 'advocates':
        return 'Create Post';
      case 'students':
        return 'Add Material';
      case 'forum':
        return 'New Post';
      default:
        return 'Create';
    }
  }
}

/// Menu-style FAB with multiple options
class ContentCreationMenu extends StatefulWidget {
  final String hubType;
  final String? heroTag;
  final Map<String, dynamic>?
      presetData; // For passing topic or other preset data
  final VoidCallback? onContentCreated;

  const ContentCreationMenu({
    super.key,
    required this.hubType,
    this.heroTag,
    this.presetData,
    this.onContentCreated,
  });

  @override
  State<ContentCreationMenu> createState() => _ContentCreationMenuState();
}

class _ContentCreationMenuState extends State<ContentCreationMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonAnimations;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _buttonAnimations = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentTypes = _getContentTypes();

    // Check if user can create content in this hub
    final canCreate = UserRoleManager.canCreateContentInHub(widget.hubType);
    print(
        '🔍 ContentCreationMenu: Hub "${widget.hubType}" - Can create content: $canCreate');

    if (!canCreate) {
      print(
          '🔍 ContentCreationMenu: Hiding FAB for hub "${widget.hubType}" - insufficient permissions');
      return const SizedBox.shrink();
    }

    print('🔍 ContentCreationMenu: Showing FAB for hub "${widget.hubType}"');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            0.7, // Limit to 70% of screen height
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...contentTypes
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  return AnimatedBuilder(
                    animation: _buttonAnimations,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonAnimations.value,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 8,
                            top: index == 0 ? 8 : 0,
                          ),
                          child: Opacity(
                            opacity: _buttonAnimations.value,
                            child: SizedBox(
                              height: 36, // Smaller than normal FAB
                              child: FloatingActionButton.extended(
                                heroTag:
                                    '${widget.heroTag ?? 'menu'}_${type['key']}',
                                onPressed: () => _createContent(type['key']),
                                icon: Icon(type['icon']),
                                label: Text(type['label']),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                })
                .toList()
                .reversed,
            FloatingActionButton(
              heroTag: widget.heroTag ?? 'main_fab_${widget.hubType}',
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(_isOpen ? Icons.close : Icons.add),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _createContent(String contentType) async {
    _toggle(); // Close menu first

    final arguments = <String, dynamic>{
      'hubType': widget.hubType,
      'defaultContentType': contentType,
    };

    // Add preset data if available (e.g., current topic)
    if (widget.presetData != null) {
      arguments.addAll(widget.presetData!);
    }

    print('🔄 ContentCreationMenu: Navigating with args = $arguments');

    final result = await Get.to(
      () => const ContentCreationScreen(),
      arguments: arguments,
      transition: Transition.rightToLeft,
    );

    print('🔄 ContentCreationMenu: Navigation result = $result');
    print(
        '🔄 ContentCreationMenu: Has callback = ${widget.onContentCreated != null}');

    // If content was successfully created, trigger refresh
    if (result == true && widget.onContentCreated != null) {
      print('🔄 ContentCreationMenu: Triggering refresh callback');
      print('🔄 Hub type: ${widget.hubType}');
      // Small delay to ensure navigation is complete and backend processing is done
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onContentCreated!();
    } else {
      print(
          '🔄 ContentCreationMenu: No refresh needed - result: $result, hasCallback: ${widget.onContentCreated != null}');
    }
  }

  List<Map<String, dynamic>> _getContentTypes() {
    switch (widget.hubType) {
      case 'advocates':
        return [
          {'key': 'discussion', 'label': 'Discussion', 'icon': Icons.forum},
          {'key': 'article', 'label': 'Article', 'icon': Icons.article},
          {'key': 'news', 'label': 'News', 'icon': Icons.newspaper},
          {'key': 'case_study', 'label': 'Case Study', 'icon': Icons.gavel},
        ];
      case 'students':
        return [
          {'key': 'notes', 'label': 'Notes', 'icon': Icons.note},
          {'key': 'past_papers', 'label': 'Past Papers', 'icon': Icons.quiz},
          {
            'key': 'assignment',
            'label': 'Assignment',
            'icon': Icons.assignment
          },
          {'key': 'discussion', 'label': 'Discussion', 'icon': Icons.forum},
        ];
      case 'forum':
        return [
          {'key': 'discussion', 'label': 'Discussion', 'icon': Icons.forum},
          {'key': 'question', 'label': 'Question', 'icon': Icons.help},
          {'key': 'general', 'label': 'General', 'icon': Icons.chat},
          {'key': 'news', 'label': 'News', 'icon': Icons.newspaper},
        ];
      case 'legal_ed':
        return [
          {'key': 'lecture', 'label': 'Lecture', 'icon': Icons.video_library},
          {'key': 'article', 'label': 'Article', 'icon': Icons.article},
          {'key': 'tutorial', 'label': 'Tutorial', 'icon': Icons.school},
          {'key': 'case_study', 'label': 'Case Study', 'icon': Icons.gavel},
        ];
      default:
        return [
          {'key': 'discussion', 'label': 'Discussion', 'icon': Icons.forum},
        ];
    }
  }
}
