import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/healings_controller.dart';

class CreateHealingScreen extends ConsumerStatefulWidget {
  const CreateHealingScreen({super.key});

  @override
  ConsumerState<CreateHealingScreen> createState() => _CreateHealingScreenState();
}

class _CreateHealingScreenState extends ConsumerState<CreateHealingScreen> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  String _selectedMood = 'Healing';
  bool _isPosting = false;

  final List<String> _moods = ['Healing', 'Reflective', 'Letting Go', 'Hopeful', 'Grateful'];

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _submit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your reflection before posting')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      await ref.read(healingsProvider.notifier).createHealing(
            content: text,
            mood: _selectedMood,
            imageFile: _selectedImage,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Healing Entry', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting ? null : _submit,
              child: _isPosting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Selector
            const Text('Select Your State of Mind:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _moods.map((mood) {
                final isSelected = mood == _selectedMood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  selectedColor: AppColors.rose.withValues(alpha: 0.2),
                  onSelected: (val) => setState(() => _selectedMood = mood),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Journal text area
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Share your healing experience, thoughts, or milestone...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 14),

            // Optional Image Preview
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined, color: AppColors.rose),
              label: const Text('Add Reflection Photo', style: TextStyle(color: AppColors.rose)),
            ),
          ],
        ),
      ),
    );
  }
}
