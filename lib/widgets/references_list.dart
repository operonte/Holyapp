import 'package:flutter/material.dart';

/// Muestra las citas bíblicas de respaldo (1 a 3) de una pregunta.
class ReferencesList extends StatelessWidget {
  const ReferencesList({super.key, required this.references});
  final List<String> references;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ref in references)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ref,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
