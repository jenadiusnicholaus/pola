import 'package:flutter/material.dart';
import '../../hubs_and_services/hub_content/screens/bookmarks_screen.dart';

/// Redirect to the hubs implementation of bookmarks so the bottom
/// navigation uses the unified bookmarks UI.
class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookmarksScreen();
  }
}
