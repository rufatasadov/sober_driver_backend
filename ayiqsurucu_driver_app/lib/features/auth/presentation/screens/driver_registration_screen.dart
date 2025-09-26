import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();

  bool _isLoading = false;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    _selectedYear = _yearController.text;
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final vehicleInfo = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'color': _colorController.text.trim(),
        'plateNumber': _plateController.text.trim(),
      };

      final success = await authProvider.registerDriver(
        licenseNumber: _licenseController.text.trim(),
        vehicleInfo: vehicleInfo,
      );

      if (success) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(authProvider.error ?? 'Qeydiyyat tamamlanmadı');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xəta'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  Future<void> _selectYear() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (index) => currentYear - index);

    final selectedYear = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('İl seçin'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  return ListTile(
                    title: Text(year.toString()),
                    selected: year.toString() == _selectedYear,
                    onTap: () => Navigator.pop(context, year),
                  );
                },
              ),
            ),
          ),
    );

    if (selectedYear != null) {
      setState(() {
        _selectedYear = selectedYear.toString();
        _yearController.text = _selectedYear!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Sürücü Qeydiyyatı',
          style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Sürücü kimi işləmək üçün məlumatlarınızı doldurun',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // License Number
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Sürücülük vəsiqəsi nömrəsi',
                    hintText: 'AZE123456789',
                    prefixIcon: Icon(
                      Icons.credit_card,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sürücülük vəsiqəsi nömrəsi tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Vehicle Info Section
                Text('Avtomobil Məlumatları', style: AppTheme.heading3),

                SizedBox(height: 16.h),

                // Make
                TextFormField(
                  controller: _makeController,
                  decoration: InputDecoration(
                    labelText: 'Marka',
                    hintText: 'Toyota',
                    prefixIcon: Icon(
                      Icons.directions_car,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Marka tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Model
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: 'Camry',
                    prefixIcon: Icon(
                      Icons.car_rental,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Model tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Year
                TextFormField(
                  controller: _yearController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'İl',
                    hintText: '2020',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _selectYear,
                    ),
                  ),
                  onTap: _selectYear,
                ),

                SizedBox(height: 16.h),

                // Color
                TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    labelText: 'Rəng',
                    hintText: 'Ağ',
                    prefixIcon: Icon(
                      Icons.color_lens,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Rəng tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Plate Number
                TextFormField(
                  controller: _plateController,
                  decoration: InputDecoration(
                    labelText: 'Nömrə nişanı',
                    hintText: '10-AA-123',
                    prefixIcon: Icon(
                      Icons.confirmation_number,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nömrə nişanı tələb olunur';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Register button
                LoadingButton(
                  text: 'Qeydiyyatı Tamamla',
                  onPressed: _registerDriver,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24.h),

                // Info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.warning,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Qeydiyyatdan sonra məlumatlarınız yoxlanılacaq və təsdiqləndikdən sonra işə başlaya biləcəksiniz',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
