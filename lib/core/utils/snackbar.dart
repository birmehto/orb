import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {int seconds = 2}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: seconds),
    ),
  );
}
