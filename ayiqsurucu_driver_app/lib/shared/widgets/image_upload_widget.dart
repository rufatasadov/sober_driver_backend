import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ImageUploadWidget extends StatefulWidget {
  final String label;
  final String? currentImagePath;
  final Function(String?) onImageSelected;
  final bool isRequired;
  final String? frontOrBack; // 'front' or 'back' for different icons

  const ImageUploadWidget({
    super.key,
    required this.label,
    this.currentImagePath,
    required this.onImageSelected,
    this.isRequired = false,
    this.frontOrBack,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.currentImagePath;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Şəkil seçməkdə xəta baş verdi');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      print('Error taking photo: $e');
      _showErrorSnackBar('Foto çəkməkdə xəta baş verdi');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
    widget.onImageSelected(null);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Şəkil əlavə et',
                  style: AppTheme.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _takePhoto();
                        },
                        icon: Icon(Icons.camera_alt, color: AppColors.primary),
                        label: Text('Kamera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                        icon: Icon(
                          Icons.photo_library,
                          color: AppColors.primary,
                        ),
                        label: Text('Qalereya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
    );
  }

  IconData _getIcon() {
    if (widget.frontOrBack == 'front') {
      return Icons.credit_card;
    } else if (widget.frontOrBack == 'back') {
      return Icons.credit_card_outlined;
    }
    return Icons.image;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(_getIcon(), color: AppColors.textSecondary, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              widget.label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired) ...[
              SizedBox(width: 4.w),
              Text(
                '*',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 8.h),

        // Image container
        GestureDetector(
          onTap: _showImageOptions,
          child: Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _selectedImagePath != null
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.textSecondary.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color:
                  _selectedImagePath != null
                      ? AppColors.success.withOpacity(0.05)
                      : AppColors.background,
            ),
            child:
                _selectedImagePath != null
                    ? Stack(
                      children: [
                        // Image preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.file(
                            File(_selectedImagePath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Remove button
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ),

                        // Success indicator
                        Positioned(
                          bottom: 8.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Yükləndi',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.textSecondary,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Şəkil əlavə et',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'JPG, JPEG, PDF',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
          ),
        ),

        // File info
        if (_selectedImagePath != null) ...[
          SizedBox(height: 4.h),
          Text(
            'Fayl: ${_selectedImagePath!.split('/').last}',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.success,
              fontSize: 10.sp,
            ),
          ),
        ],
      ],
    );
  }
}
