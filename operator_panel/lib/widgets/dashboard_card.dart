import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSmall), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20, // Smaller icon
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16, // Smaller icon
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Changed from headlineSmall
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reduced spacing
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      // Changed from bodyMedium
                      color: AppColors.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
