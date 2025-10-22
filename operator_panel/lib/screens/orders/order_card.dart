import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onAssignDriver;
  final VoidCallback onShowDetails;

  const OrderCard({
    super.key,
    required this.order,
    required this.onShowDetails,
    this.onAssignDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sifariş #${order['orderNumber']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(order['status']?.toString() ?? ''),
              ],
            ),
            const SizedBox(height: AppSizes.padding),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.pickup,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        order['pickup']['address'] ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.destination,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        order['destination']['address'] ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        softWrap: true,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.fare}: ${order['fare']?['total'] ?? '-'} ₼',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    if ((order['status'] == 'pending') &&
                        onAssignDriver != null)
                      ElevatedButton(
                        onPressed: onAssignDriver,
                        child: Text(AppStrings.assignDriver),
                      ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    OutlinedButton(
                      onPressed: onShowDetails,
                      child: Text(AppStrings.details),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = AppStrings.pending;
        break;
      case 'accepted':
        color = AppColors.info;
        text = AppStrings.accepted;
        break;
      case 'in_progress':
        color = AppColors.primary;
        text = AppStrings.inProgress;
        break;
      case 'completed':
        color = AppColors.success;
        text = AppStrings.completed;
        break;
      case 'cancelled':
        color = AppColors.error;
        text = AppStrings.cancelled;
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
