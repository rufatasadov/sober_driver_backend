import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class WaitingTimerWidget extends StatefulWidget {
  final int freeWaitingMinutes;
  final double paidWaitingRatePerMinute;
  final VoidCallback? onTimerComplete;
  final Function(double)? onAdditionalFee;

  const WaitingTimerWidget({
    super.key,
    required this.freeWaitingMinutes,
    required this.paidWaitingRatePerMinute,
    this.onTimerComplete,
    this.onAdditionalFee,
  });

  @override
  State<WaitingTimerWidget> createState() => _WaitingTimerWidgetState();
}

class _WaitingTimerWidgetState extends State<WaitingTimerWidget> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerActive = false;
  double _additionalFee = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isTimerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;

        // Calculate additional fee after free waiting period
        if (_elapsedSeconds > widget.freeWaitingMinutes * 60) {
          final paidMinutes =
              (_elapsedSeconds - widget.freeWaitingMinutes * 60) / 60;
          _additionalFee = paidMinutes * widget.paidWaitingRatePerMinute;
          widget.onAdditionalFee?.call(_additionalFee);
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
    });
    widget.onTimerComplete?.call();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool get _isFreePeriod => _elapsedSeconds <= widget.freeWaitingMinutes * 60;
  int get _remainingFreeSeconds =>
      _isFreePeriod ? (widget.freeWaitingMinutes * 60) - _elapsedSeconds : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            _isFreePeriod
                ? AppColors.info.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              _isFreePeriod
                  ? AppColors.info.withOpacity(0.3)
                  : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Timer Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: _isFreePeriod ? AppColors.info : AppColors.warning,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                _formatTime(_elapsedSeconds),
                style: AppTheme.heading2.copyWith(
                  color: _isFreePeriod ? AppColors.info : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Status Text
          Text(
            _isFreePeriod ? 'Pulsuz gözləmə dövrü' : 'Pullu gözləmə dövrü',
            style: AppTheme.bodyMedium.copyWith(
              color: _isFreePeriod ? AppColors.info : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (_isFreePeriod) ...[
            SizedBox(height: 8.h),
            Text(
              'Qalan pulsuz vaxt: ${_formatTime(_remainingFreeSeconds)}',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (!_isFreePeriod) ...[
            SizedBox(height: 8.h),
            Text(
              'Əlavə ödəniş: ${_additionalFee.toStringAsFixed(2)} AZN',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Hər dəqiqəyə ${widget.paidWaitingRatePerMinute.toStringAsFixed(2)} AZN',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // Stop Timer Button
          if (_isTimerActive)
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: _stopTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                child: Text(
                  'Müştəri Gəldi',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
