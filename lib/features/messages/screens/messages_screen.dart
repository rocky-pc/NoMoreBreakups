import 'package:flutter/material.dart';
import '../../../core/constants/app_styles.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('No Messages Yet', style: AppStyles.headingMedium),
            const SizedBox(height: 8),
            const Text('Connect with the community and start talking.'),
          ],
        ),
      ),
    );
  }
}
