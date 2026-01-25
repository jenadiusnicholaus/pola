import 'package:flutter/material.dart';
import '../utils/mention_parser.dart';

/// A text field that supports @mentions with autocomplete
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final Function(List<int> mentionedUserIds)? onMentionsChanged;
  final Future<List<MentionSuggestion>> Function(String query)?
      onSearchMentions;
  final List<MentionSuggestion> fallbackUsers; // Users from existing comments

  const MentionTextField({
    super.key,
    required this.controller,
    this.hintText = 'Write a comment...',
    this.maxLines = 3,
    this.onMentionsChanged,
    this.onSearchMentions,
    this.fallbackUsers = const [],
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  List<MentionSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  String _currentMentionQuery = '';
  int _mentionStartPosition = -1;
  final Map<String, int> _usernamesToIds =
      {}; // Track username -> userId mapping

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 MentionTextField initialized');
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    debugPrint('🎬 MentionTextField disposed');
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    debugPrint('📝 _onTextChanged triggered!');
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    debugPrint('📝 Text changed: "$text" | Cursor: $cursorPosition');

    // Check if cursor position is valid
    if (cursorPosition < 0 || text.isEmpty) {
      if (_showSuggestions) {
        _hideSuggestions();
      }
      return;
    }

    // Check if user is typing a mention
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    debugPrint(
        '📝 Last @ index: $lastAtIndex | Text before cursor: "$textBeforeCursor"');

    if (lastAtIndex != -1 &&
        (lastAtIndex == 0 ||
            text[lastAtIndex - 1] == ' ' ||
            text[lastAtIndex - 1] == '\n')) {
      // User is typing a mention
      final query =
          textBeforeCursor.substring(lastAtIndex + 1).trim(); // Trim whitespace

      debugPrint('📝 Mention query: "$query"');

      // Check if there's a space in the middle (which means mention is complete)
      // But allow empty query (just @) or query without spaces
      if (!query.contains(' ')) {
        _mentionStartPosition = lastAtIndex;
        _currentMentionQuery = query;
        debugPrint('📝 Searching mentions for: "$query"');
        _searchMentions(query);
        return;
      }
    }

    // Hide suggestions if not in mention mode
    if (_showSuggestions) {
      _hideSuggestions();
    }

    // Parse and notify about mentions
    _notifyMentionsChanged();
  }

  Future<void> _searchMentions(String query) async {
    debugPrint('🔍 Searching mentions with query: "$query"');

    // If query is short (less than 2 chars), show fallback users from comments
    if (query.length < 2) {
      debugPrint(
          '🔍 Query short, showing fallback users: ${widget.fallbackUsers.length}');
      if (widget.fallbackUsers.isNotEmpty) {
        // Filter fallback users by query if there's any text
        final filteredFallback = query.isEmpty
            ? widget.fallbackUsers
            : widget.fallbackUsers
                .where((user) =>
                    user.username.toLowerCase().contains(query.toLowerCase()) ||
                    user.displayName
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();

        if (mounted) {
          setState(() {
            _suggestions = filteredFallback;
            _showSuggestions = filteredFallback.isNotEmpty;
            _isSearching = false;
          });
        }
        return;
      } else {
        // No fallback users, hide suggestions
        if (mounted) {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
            _isSearching = false;
          });
        }
        return;
      }
    }

    // Only search API if callback is provided
    if (widget.onSearchMentions == null) {
      debugPrint('🔍 No API callback provided');
      return;
    }

    // Show loading state
    if (mounted) {
      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });
    }

    // Call API to search users
    try {
      debugPrint('🔍 Calling API with query: "$query"');
      final suggestions = await widget.onSearchMentions!(query);
      debugPrint('🔍 API returned ${suggestions.length} users');

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('🔍 API error: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _isSearching = false;
        });
      }
    }
  }

  void _insertMention(MentionSuggestion suggestion) {
    debugPrint('📝 Inserting mention: @${suggestion.username}');
    debugPrint('📝 Mention start position: $_mentionStartPosition');
    debugPrint('📝 Current text: "${widget.controller.text}"');
    debugPrint('📝 Cursor position: ${widget.controller.selection.baseOffset}');

    // Safety check for invalid state
    if (_mentionStartPosition < 0) {
      debugPrint('📝 Invalid mention position, aborting');
      _hideSuggestions();
      return;
    }

    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Handle edge case where cursor position is invalid
    final endPos =
        cursorPos >= 0 && cursorPos <= text.length ? cursorPos : text.length;

    // Make sure we don't go out of bounds
    final startPos = _mentionStartPosition.clamp(0, text.length);

    final newText =
        '${text.substring(0, startPos)}@${suggestion.username} ${text.substring(endPos)}';

    debugPrint('📝 New text: "$newText"');

    // Calculate new cursor position
    final newCursorPos =
        startPos + suggestion.username.length + 2; // @ + username + space

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    debugPrint('📝 New cursor position: $newCursorPos');

    // Store the username -> userId mapping
    _usernamesToIds[suggestion.username] = suggestion.userId;

    _hideSuggestions();
    _notifyMentionsChanged();

    debugPrint(
        '📝 Insertion complete. Final text: "${widget.controller.text}"');
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  void _notifyMentionsChanged() {
    if (widget.onMentionsChanged == null) return;

    final userIds = MentionParser.extractMentionedUserIds(
      widget.controller.text,
      _usernamesToIds,
    );
    widget.onMentionsChanged!(userIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show suggestions ABOVE the text field (like Instagram/Twitter)
        if (_showSuggestions && (_suggestions.isNotEmpty || _isSearching)) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Searching users...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          debugPrint(
                              '👆 User tapped on: ${suggestion.username}');
                          _insertMention(suggestion);
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                backgroundImage: suggestion.avatarUrl != null &&
                                        suggestion.avatarUrl!.isNotEmpty
                                    ? NetworkImage(suggestion.avatarUrl!)
                                    : null,
                                child: suggestion.avatarUrl == null ||
                                        suggestion.avatarUrl!.isEmpty
                                    ? Text(
                                        suggestion.displayName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '@${suggestion.username}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],

        // Simple text field without extra decoration
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          onChanged: (value) {
            _onTextChanged();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Model for mention suggestions
class MentionSuggestion {
  final int userId;
  final String username;
  final String displayName;
  final String? avatarUrl;

  MentionSuggestion({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory MentionSuggestion.fromJson(Map<String, dynamic> json) {
    return MentionSuggestion(
      userId: json['id'] ?? json['user_id'] ?? 0,
      username: json['username'] ?? '',
      displayName: json['display_name'] ??
          json['full_name'] ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      avatarUrl: json['avatar_url'] ?? json['profile_picture'],
    );
  }
}
