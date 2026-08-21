import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:no_more_breakups/core/constants/app_colors.dart';
import 'package:no_more_breakups/core/services/storage_service.dart';
import '../controllers/healings_controller.dart';

class CreateHealingScreen extends ConsumerStatefulWidget {
  const CreateHealingScreen({super.key});

  @override
  ConsumerState<CreateHealingScreen> createState() => _CreateHealingScreenState();
}

class _CreateHealingScreenState extends ConsumerState<CreateHealingScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _imagePath;

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _postHealing() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.rose)),
    );

    try {
      String? mediaUrl;
      if (_imagePath != null) {
        mediaUrl = await StorageService.uploadPostImage(File(_imagePath!));
      }

      await ref.read(healingPostsProvider.notifier).createHealing(content, mediaUrl);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share your journey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _postHealing,
            child: const Text('Post', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.rose,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: "What's your story, lesson, or pain? Share it here...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_imagePath!),
                      width: double.infinity,
                      maxHeight: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.rose),
              onPressed: _pickImage,
            ),
            const Spacer(),
            const Text('Share safely with the community', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
