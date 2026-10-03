import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copia al portapapeles y confirma con un SnackBar.
Future<void> copyToClipboard(BuildContext context, String text,
    {required String confirmation}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(confirmation),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2)));
}
