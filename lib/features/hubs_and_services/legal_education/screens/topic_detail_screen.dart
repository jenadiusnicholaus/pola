import 'package:flutter/material.dart';

// TODO: This screen is deprecated - we now use direct topic-to-materials flow
// This is kept as a placeholder to avoid breaking any potential imports

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Detail'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'This screen is deprecated',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('We now use direct topic-to-materials flow'),
            SizedBox(height: 16),
            Text('Please use the topic cards to access materials directly'),
          ],
        ),
      ),
    );
  }
}
