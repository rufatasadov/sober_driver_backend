import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../cubit/profile_cubit.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEarnings();
    });
  }

  Future<void> _loadEarnings() async {
    final profileCubit = context.read<ProfileCubit>();
    await profileCubit.getDriverEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Gəlir Hesabatı',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const LoadingScreen();
          }

          if (state is ProfileError) {
            return _buildErrorWidget(state.message);
          }

          // Get earnings from cubit state
          final earnings = context.read<ProfileCubit>().getDriverEarnings();

          return FutureBuilder<Map<String, dynamic>?>(
            future: earnings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (snapshot.hasError || snapshot.data == null) {
                return _buildErrorWidget(
                  snapshot.error?.toString() ??
                      'Gəlir məlumatları yüklənə bilmədi',
                );
              }

              final earningsData = snapshot.data!;

              return SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(earningsData),

                    SizedBox(height: 32.h),

                    // Daily Earnings Chart
                    _buildDailyEarningsChart(earningsData),

                    SizedBox(height: 32.h),

                    // Weekly Breakdown
                    _buildWeeklyBreakdown(earningsData),

                    SizedBox(height: 32.h),

                    // Monthly Summary
                    _buildMonthlySummary(earningsData),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> earnings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Bugün',
                '${earnings['today']?.toString() ?? '0'} AZN',
                Icons.today,
                AppColors.primary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryCard(
                'Bu Həftə',
                '${earnings['thisWeek']?.toString() ?? '0'} AZN',
                Icons.date_range,
                AppColors.info,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Bu Ay',
                '${earnings['thisMonth']?.toString() ?? '0'} AZN',
                Icons.calendar_month,
                AppColors.success,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSummaryCard(
                'Ümumi',
                '${earnings['total']?.toString() ?? '0'} AZN',
                Icons.account_balance_wallet,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyEarningsChart(Map<String, dynamic> earnings) {
    final dailyEarnings = earnings['dailyEarnings'] as List<dynamic>? ?? [];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son 7 Gün',
            style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 20.h),
          if (dailyEarnings.isEmpty)
            Container(
              height: 200.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Hələ məlumat yoxdur',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dailyEarnings.length,
                itemBuilder: (context, index) {
                  final day = dailyEarnings[index];
                  final amount = day['amount'] as double? ?? 0.0;
                  final date = day['date'] as String? ?? '';
                  final maxAmount = dailyEarnings
                      .map((e) => (e['amount'] as double? ?? 0.0))
                      .reduce((a, b) => a > b ? a : b);

                  return Container(
                    width: 60.w,
                    margin: EdgeInsets.only(right: 8.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height:
                              maxAmount > 0 ? (amount / maxAmount) * 150.h : 0,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          amount.toStringAsFixed(0),
                          style: AppTheme.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDay(date),
                          style: AppTheme.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdown(Map<String, dynamic> earnings) {
    final weeklyBreakdown = earnings['weeklyBreakdown'] as List<dynamic>? ?? [];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Həftəlik Bölgü',
            style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16.h),
          if (weeklyBreakdown.isEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: Text(
                  'Hələ məlumat yoxdur',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...weeklyBreakdown.map((week) => _buildWeekItem(week)).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekItem(Map<String, dynamic> week) {
    final weekNumber = week['week'] as int? ?? 0;
    final amount = week['amount'] as double? ?? 0.0;
    final trips = week['trips'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                weekNumber.toString(),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Həftə $weekNumber',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$trips sifariş',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} AZN',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(Map<String, dynamic> earnings) {
    final monthlySummary =
        earnings['monthlySummary'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylıq Xülasə',
            style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow(
            'Ümumi Gəlir',
            '${monthlySummary['totalEarnings']?.toString() ?? '0'} AZN',
          ),
          _buildSummaryRow(
            'Sifariş Sayı',
            '${monthlySummary['totalTrips']?.toString() ?? '0'}',
          ),
          _buildSummaryRow(
            'Orta Sifariş Dəyəri',
            '${monthlySummary['averageOrderValue']?.toString() ?? '0'} AZN',
          ),
          _buildSummaryRow(
            'Ən Yaxşı Gün',
            '${monthlySummary['bestDay']?.toString() ?? 'N/A'}',
          ),
          _buildSummaryRow(
            'Ən Yaxşı Gün Gəliri',
            '${monthlySummary['bestDayEarnings']?.toString() ?? '0'} AZN',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTheme.heading3.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 8.h),
          Text(
            'Zəhmət olmasa yenidən cəhd edin',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadEarnings,
            child: const Text('Yenidən cəhd et'),
          ),
        ],
      ),
    );
  }

  String _formatDay(String date) {
    try {
      final dateTime = DateTime.parse(date);
      final weekdays = ['B', 'Ç', 'Ç', 'C', 'C', 'Ş', 'B'];
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      return 'N/A';
    }
  }
}
