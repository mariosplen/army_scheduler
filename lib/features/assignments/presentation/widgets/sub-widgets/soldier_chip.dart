import 'package:flutter/material.dart';

class SoldierChip extends StatelessWidget {
  const SoldierChip({Key? key, required this.text, this.onDelete})
      : super(key: key);

  final String text;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Chip(
      deleteButtonTooltipMessage: 'Αφαίρεση',
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.white,
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      shape: const StadiumBorder(
        side: BorderSide(color: Colors.black12),
      ),
    );
  }
}
