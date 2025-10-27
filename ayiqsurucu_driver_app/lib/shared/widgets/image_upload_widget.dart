import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/language_provider.dart';

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
  bool _isUploading = false;

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
        await _uploadImage(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar(_getLocalizedString('errorPickingImage'));
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
        await _uploadImage(image.path);
      }
    } catch (e) {
      print('Error taking photo: $e');
      _showErrorSnackBar(_getLocalizedString('errorTakingPhoto'));
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final token = await _getStoredToken();

      if (token == null) {
        setState(() {
          _isUploading = false;
        });
        _showErrorSnackBar(_getLocalizedString('notAuthenticated'));
        return;
      }

      final fileName = path.basename(imagePath);

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/uploads/upload-document'),
      );

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      print('🔍 Upload headers: ${request.headers}');

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          imagePath,
          filename: fileName,
        ),
      );

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        setState(() {
          _selectedImagePath = data['filePath'];
        });

        widget.onImageSelected(data['filePath']);
        _showSuccessSnackBar(_getLocalizedString('imageUploadedSuccessfully'));
      } else {
        _showErrorSnackBar(_getLocalizedString('imageUploadFailed'));
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorSnackBar(_getLocalizedString('errorUploadingImage'));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting stored token: $e');
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
    widget.onImageSelected(null);
  }

  String _getLocalizedString(String key) {
    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    final translations = {
      'en': {
        'addImage': 'Add Image',
        'camera': 'Camera',
        'gallery': 'Gallery',
        'uploading': 'Uploading...',
        'uploaded': 'Uploaded',
        'storedOnServer': 'Stored on server',
        'errorPickingImage': 'Error selecting image',
        'errorTakingPhoto': 'Error taking photo',
        'imageUploadedSuccessfully': 'Image uploaded successfully',
        'imageUploadFailed': 'Image upload failed',
        'errorUploadingImage': 'Error uploading image',
        'notAuthenticated': 'You must be logged in to upload images',
      },
      'ru': {
        'addImage': 'Добавить изображение',
        'camera': 'Камера',
        'gallery': 'Галерея',
        'uploading': 'Загрузка...',
        'uploaded': 'Загружено',
        'storedOnServer': 'Сохранено на сервере',
        'errorPickingImage': 'Ошибка при выборе изображения',
        'errorTakingPhoto': 'Ошибка при съемке фото',
        'imageUploadedSuccessfully': 'Изображение успешно загружено',
        'imageUploadFailed': 'Не удалось загрузить изображение',
        'errorUploadingImage': 'Ошибка при загрузке изображения',
        'notAuthenticated':
            'Вы должны быть авторизованы для загрузки изображений',
      },
      'uz': {
        'addImage': 'Rasm qo\'shish',
        'camera': 'Kamera',
        'gallery': 'Galereya',
        'uploading': 'Yuklanmoqda...',
        'uploaded': 'Yuklandi',
        'storedOnServer': 'Serverda saqlanildi',
        'errorPickingImage': 'Rasm tanlashda xato',
        'errorTakingPhoto': 'Foto chakishda xato',
        'imageUploadedSuccessfully': 'Rasm muvaffaqiyatli yuklandi',
        'imageUploadFailed': 'Rasm yuklanmadi',
        'errorUploadingImage': 'Rasm yuklashda xato',
        'notAuthenticated': 'Rasmlarni yuklash uchun tizimga kirishingiz kerak',
      },
    };

    return translations[lang]?[key] ?? translations['en']![key]!;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
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
                  _getLocalizedString('addImage'),
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
                        label: Text(_getLocalizedString('camera')),
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
                        label: Text(_getLocalizedString('gallery')),
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
          onTap: _isUploading ? null : _showImageOptions,
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
                _isUploading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 8.h),
                          Text(
                            _getLocalizedString('uploading'),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _selectedImagePath != null
                    ? Stack(
                      children: [
                        // Image preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child:
                              _selectedImagePath!.startsWith('http')
                                  ? Image.network(
                                    '${AppConstants.baseUrl}${_selectedImagePath!}',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.surface,
                                        child: Icon(
                                          Icons.image,
                                          color: AppColors.textSecondary,
                                          size: 32.sp,
                                        ),
                                      );
                                    },
                                  )
                                  : Image.file(
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
                                  _getLocalizedString('uploaded'),
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
                          _getLocalizedString('addImage'),
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
            _getLocalizedString('storedOnServer'),
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
