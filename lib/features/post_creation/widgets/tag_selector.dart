import 'package:flutter/material.dart';

class TagSelector extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableTags.map((tag) {
        final isSelected = widget.selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            final updated = List<String>.from(widget.selectedTags);
            if (selected) {
              updated.add(tag);
            } else {
              updated.remove(tag);
            }
            widget.onTagsChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
