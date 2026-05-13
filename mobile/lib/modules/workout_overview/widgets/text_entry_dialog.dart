import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';

/// Generic single-text-field dialog used for session notes and extra work.
class TextEntryDialog extends StatefulWidget {
  const TextEntryDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    this.initialValue = '',
    this.maxLines = 4,
    this.maxLength,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String initialValue;
  final int maxLines;
  final int? maxLength;

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String hint,
    required String confirmLabel,
    String initialValue = '',
    int maxLines = 4,
    int? maxLength,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextEntryDialog(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
    );
  }

  @override
  State<TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<TextEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(widget.title, style: TextStyle(color: colors.onSurface)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        minLines: 2,
        maxLength: widget.maxLength,
        decoration: InputDecoration(hintText: widget.hint),
        style: TextStyle(color: colors.onSurface),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
