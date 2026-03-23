import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case 'placed':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'preparing':
        return Colors.amber;
      case 'ready_for_pickup':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.teal;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'pending_verification':
        return Colors.orange;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getLabel() {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
