import 'package:flutter/material.dart';

/// Single entry point for all popup dialogs in the app.
///
/// Three patterns share one visual shell (rounded `AlertDialog`, `FilledButton`
/// for confirm, `TextButton` for cancel):
///
/// - **info** — icon + message + single OK button (#1 error, #7 success, #8 success)
/// - **confirm** — title + message + Cancel / Confirm (#2 register, #3 sign-out, #4 promote, #6 approve)
/// - **input** — title + TextField + Cancel / Continue (#5 rejection reason)
class AppDialog {
  const AppDialog._();

  // ---------------------------------------------------------------------------
  // Pattern 1: Info / Error  (single OK)
  // ---------------------------------------------------------------------------

  static Future<void> info({
    required BuildContext context,
    String? title,
    IconData? icon,
    Color? iconColor,
    required String message,
    String confirmLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: icon != null
            ? Icon(
                icon,
                size: 48,
                color: iconColor ?? Theme.of(dialogContext).colorScheme.primary,
              )
            : null,
        title: title != null ? Text(title) : null,
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pattern 2: Confirmation  (Cancel + Confirm)
  // ---------------------------------------------------------------------------

  static Future<bool> confirm({
    required BuildContext context,
    String? title,
    IconData? icon,
    Color? iconColor,
    String? message,
    Widget? content,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: icon != null
            ? Icon(
                icon,
                size: 48,
                color: iconColor ?? Theme.of(dialogContext).colorScheme.primary,
              )
            : null,
        title: title != null ? Text(title) : null,
        content: content ?? (message != null ? Text(message) : null),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  // ---------------------------------------------------------------------------
  // Pattern 3: Input  (TextField + Cancel / Continue)
  // ---------------------------------------------------------------------------

  static Future<String?> input({
    required BuildContext context,
    required String title,
    String? message,
    String hintText = '',
    int maxLines = 3,
    String confirmLabel = 'Continue',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _InputDialog(
        title: title,
        message: message,
        hintText: hintText,
        maxLines: maxLines,
        confirmLabel: confirmLabel,
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    this.message,
    required this.hintText,
    required this.maxLines,
    required this.confirmLabel,
  });

  final String title;
  final String? message;
  final String hintText;
  final int maxLines;
  final String confirmLabel;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
