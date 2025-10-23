import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class RecentOrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const RecentOrdersList({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSizes.padding),
                Text(
                  'Hələ sifariş yoxdur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length > 5 ? 5 : orders.length, // Limit to 5 items
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderItem(context, order);
        },
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    final fareRaw = order['fare']?['total'];
    final double fare = fareRaw is num
        ? fareRaw.toDouble()
        : double.tryParse(fareRaw?.toString() ?? '0') ?? 0.0;
    final customer = (order['customer'] ?? {}) as Map<String, dynamic>;
    final driver = order['driver'] as Map<String, dynamic>?;

    return ListTile(
      contentPadding: const EdgeInsets.all(AppSizes.padding),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.local_shipping,
          color: statusColor,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              order['orderNumber'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Müştəri: ${customer['name'] ?? ''} (${customer['phone'] ?? ''})',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (driver != null) ...[
            const SizedBox(height: 2),
            Text(
              'Sürücü: ${driver['user']?['name'] ?? ''} (${driver['user']?['phone'] ?? ''})',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            'Qiymət: ${fare.toStringAsFixed(2)} AZN',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Tarix: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () {
          // Sifariş detallarına keç
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppStrings.pending;
      case 'accepted':
        return AppStrings.accepted;
      case 'driver_assigned':
        return AppStrings.driverAssigned;
      case 'driver_arrived':
        return AppStrings.driverArrived;
      case 'in_progress':
        return AppStrings.inProgress;
      case 'completed':
        return AppStrings.completed;
      case 'cancelled':
        return AppStrings.cancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'driver_assigned':
      case 'driver_arrived':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.secondary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
