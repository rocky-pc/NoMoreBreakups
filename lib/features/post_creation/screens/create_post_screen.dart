import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage_service.dart';
import '../../feed/models/post_model.dart';
import '../../../shared_widgets/custom_button.dart';
import '../widgets/tag_selector.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  PostType _category = PostType.story;
  final List<String> _selectedTags = [];
  final _imagePicker = ImagePicker();
  String? _imagePath;

  static const _availableTags = [
    'Communication',
    'Trust',
    'Long-Distance',
    'Self-Care',
    'Boundaries',
  ];

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<PostType>(
              segments: const [
                ButtonSegment(value: PostType.story, label: Text('Story'), icon: Icon(Icons.menu_book)),
                ButtonSegment(value: PostType.advice, label: Text('Advice'), icon: Icon(Icons.lightbulb)),
              ],
              selected: {_category},
              onSelectionChanged: (selection) {
                setState(() => _category = selection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Share your story or advice...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TagSelector(
              availableTags: _availableTags,
              selectedTags: _selectedTags,
              onTagsChanged: (tags) {
                setState(() {
                  _selectedTags.clear();
                  _selectedTags.addAll(tags);
                });
              },
            ),
            const SizedBox(height: 16),
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Add Photo'),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Post',
              onPressed: () async {
                final content = _contentController.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter some content')),
                  );
                  return;
                }

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                String? mediaUrl;
                if (_imagePath != null) {
                  mediaUrl = await StorageService.uploadPostImage(File(_imagePath!));
                }

                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  await Supabase.instance.client.from('posts').insert({
                    'user_id': userId,
                    'content': content,
                    'post_type': _category.name,
                    'media_url': mediaUrl,
                    'tags': _selectedTags,
                  });

                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    Navigator.pop(context); // Go back to feed
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating post: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
