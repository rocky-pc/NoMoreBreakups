import 'package:flutter/material.dart';
import '../../../core/constants/app_styles.dart';

class HealingsScreen extends StatelessWidget {
  const HealingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded, size: 64, color: Colors.pink),
            const SizedBox(height: 16),
            Text('Your Healing Journey', style: AppStyles.headingMedium),
            const SizedBox(height: 8),
            const Text('Keep track of your progress and exercises.'),
          ],
        ),
      ),
    );
  }
}
