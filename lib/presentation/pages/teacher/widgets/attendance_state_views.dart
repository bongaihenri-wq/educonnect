import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const EmptyView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 64, color: Colors.grey),
          const Text("Aucune classe aujourd'hui", style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onRetry, child: const Text("Rafraîchir")),
        ],
      ),
    );
  }
}

class AttendanceStateViews {
  static void showErrorSnackBar(BuildContext context, String error, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        action: SnackBarAction(label: 'Réessayer', onPressed: onRetry),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
