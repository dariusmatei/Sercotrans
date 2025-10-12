import 'package:flutter/material.dart';
import '../api/api_error.dart';

void showApiErrorSnack(BuildContext context, ApiError err) {
  final color = switch (err.type) {
    'network' || 'timeout' => Colors.orange,
    'unauthorized' || 'forbidden' => Colors.redAccent,
    'validation' => Colors.deepOrange,
    'server' => Colors.red,
    _ => Colors.grey,
  };
  final text = err.message.isNotEmpty ? err.message : 'A apărut o eroare.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: color),
  );
}
