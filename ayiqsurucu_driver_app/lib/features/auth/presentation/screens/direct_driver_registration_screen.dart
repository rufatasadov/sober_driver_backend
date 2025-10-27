import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../shared/widgets/loading_screen.dart';
import '../../../../shared/widgets/privacy_policy_widget.dart';
import '../../../../shared/widgets/image_upload_widget.dart';
import '../cubit/auth_cubit.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class DirectDriverRegistrationScreen extends StatefulWidget {
  const DirectDriverRegistrationScreen({super.key});

  @override
  State<DirectDriverRegistrationScreen> createState() =>
      _DirectDriverRegistrationScreenState();
}

class _DirectDriverRegistrationScreenState
    extends State<DirectDriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _actualAddressController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _privacyPolicyAccepted = false;

  // Image paths
  String? _identityCardFront;
  String? _identityCardBack;
  String? _licenseFront;
  String? _licenseBack;

  // License expiry date
  DateTime? _licenseExpiryDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _actualAddressController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      _showErrorDialog('Please accept the terms and conditions to continue.');
      return;
    }

    if (_licenseExpiryDate == null) {
      _showErrorDialog('Please select license expiry date.');
      return;
    }

    final authCubit = context.read<AuthCubit>();
    setState(() => _isLoading = true);

    try {
      // First create user account
      final userSuccess = await authCubit.createUserAccount(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userSuccess) {
        // Then register as driver (without vehicle info)
        final driverSuccess = await authCubit.registerDriver(
          licenseNumber: _licenseController.text.trim(),
          actualAddress: _actualAddressController.text.trim(),
          licenseExpiryDate: _licenseExpiryDate!,
          identityCardFront: _identityCardFront,
          identityCardBack: _identityCardBack,
          licenseFront: _licenseFront,
          licenseBack: _licenseBack,
        );

        if (driverSuccess) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog(authCubit.error ?? _getErrorMessage(context));
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(authCubit.error ?? _getErrorMessage(context));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(BuildContext context) {
    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    final errors = {
      'en': 'Registration failed. Please try again.',
      'ru': 'Регистрация не удалась. Пожалуйста, попробуйте снова.',
      'uz':
          'Ro\'yxatdan o\'tish muvaffaqiyatsiz. Iltimos, qayta urinib ko\'ring.',
    };

    return errors[lang] ?? errors['en']!;
  }

  void _showErrorDialog(String message) {
    final lang =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              lang == 'en'
                  ? 'Error'
                  : lang == 'ru'
                  ? 'Ошибка'
                  : 'Xato',
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  lang == 'en'
                      ? 'OK'
                      : lang == 'ru'
                      ? 'OK'
                      : 'Tamam',
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;

        // Get localized strings
        final strings = _getLocalizedStrings(lang);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              strings['driverRegistration']!,
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
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: AppColors.success,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              strings['newDriverRegistration']!,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Personal Information Section
                    Text(strings['personalInfo']!, style: AppTheme.heading3),
                    SizedBox(height: 16.h),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: strings['fullName'],
                        hintText: strings['fullNameHint'],
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['fullNameRequired']!;
                        }
                        if (value.length < 2) {
                          return strings['fullNameMinLength']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: strings['phoneNumber'],
                        hintText: '+994 50 123 45 67',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['phoneNumberRequired']!;
                        }
                        if (value.length < 10) {
                          return strings['phoneNumberInvalid']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: strings['username'],
                        hintText: strings['usernameHint'],
                        prefixIcon: Icon(
                          Icons.account_circle,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['usernameRequired']!;
                        }
                        if (value.length < 3) {
                          return strings['usernameMinLength']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: strings['password'],
                        hintText: strings['passwordHint'],
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['passwordRequired']!;
                        }
                        if (value.length < 6) {
                          return strings['passwordMinLength']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: strings['confirmPassword'],
                        hintText: strings['confirmPasswordHint'],
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['confirmPasswordRequired']!;
                        }
                        if (value != _passwordController.text) {
                          return strings['passwordsDoNotMatch']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Driver Information Section
                    Text(strings['driverInfo']!, style: AppTheme.heading3),
                    SizedBox(height: 16.h),

                    // License Number
                    TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: strings['licenseNumber'],
                        hintText: 'AZE123456789',
                        prefixIcon: Icon(
                          Icons.credit_card,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['licenseNumberRequired']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Actual Address
                    TextFormField(
                      controller: _actualAddressController,
                      decoration: InputDecoration(
                        labelText: strings['actualAddress'],
                        hintText: strings['actualAddressHint'],
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings['actualAddressRequired']!;
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // License Expiry Date
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _licenseExpiryDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _licenseExpiryDate != null
                                    ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                                    : strings['licenseExpiryDateHint']!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color:
                                      _licenseExpiryDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Documents Section
                    Text(strings['documents']!, style: AppTheme.heading3),
                    SizedBox(height: 16.h),

                    // Identity Card Front
                    ImageUploadWidget(
                      label: strings['identityCardFront']!,
                      currentImagePath: _identityCardFront,
                      onImageSelected: (path) {
                        setState(() {
                          _identityCardFront = path;
                        });
                      },
                      isRequired: true,
                      frontOrBack: 'front',
                    ),

                    SizedBox(height: 16.h),

                    // Identity Card Back
                    ImageUploadWidget(
                      label: strings['identityCardBack']!,
                      currentImagePath: _identityCardBack,
                      onImageSelected: (path) {
                        setState(() {
                          _identityCardBack = path;
                        });
                      },
                      isRequired: true,
                      frontOrBack: 'back',
                    ),

                    SizedBox(height: 16.h),

                    // License Front
                    ImageUploadWidget(
                      label: strings['licenseFront']!,
                      currentImagePath: _licenseFront,
                      onImageSelected: (path) {
                        setState(() {
                          _licenseFront = path;
                        });
                      },
                      isRequired: true,
                      frontOrBack: 'front',
                    ),

                    SizedBox(height: 16.h),

                    // License Back
                    ImageUploadWidget(
                      label: strings['licenseBack']!,
                      currentImagePath: _licenseBack,
                      onImageSelected: (path) {
                        setState(() {
                          _licenseBack = path;
                        });
                      },
                      isRequired: true,
                      frontOrBack: 'back',
                    ),

                    SizedBox(height: 24.h),

                    // Privacy Policy Section
                    Text(
                      strings['termsAndConditions']!,
                      style: AppTheme.heading3,
                    ),
                    SizedBox(height: 16.h),

                    PrivacyPolicyWidget(
                      isAccepted: _privacyPolicyAccepted,
                      onChanged: (value) {
                        setState(() {
                          _privacyPolicyAccepted = value;
                        });
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Register button
                    LoadingButton(
                      text: strings['register']!,
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
                              strings['infoText']!,
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
      },
    );
  }

  Map<String, String> _getLocalizedStrings(String lang) {
    final translations = {
      'en': {
        'driverRegistration': 'Driver Registration',
        'newDriverRegistration': 'Register as new driver - without OTP',
        'personalInfo': 'Personal Information',
        'driverInfo': 'Driver Information',
        'fullName': 'Full Name',
        'fullNameRequired': 'Full name is required',
        'fullNameHint': 'Enter your first and last name',
        'fullNameMinLength': 'Name must be at least 2 characters',
        'phoneNumber': 'Phone Number',
        'phoneNumberRequired': 'Phone number is required',
        'phoneNumberInvalid': 'Please enter a valid phone number',
        'username': 'Username',
        'usernameRequired': 'Username is required',
        'usernameHint': 'Enter your username',
        'usernameMinLength': 'Username must be at least 3 characters',
        'password': 'Password',
        'passwordRequired': 'Password is required',
        'passwordHint': 'Enter your password',
        'passwordMinLength': 'Password must be at least 6 characters',
        'confirmPassword': 'Confirm Password',
        'confirmPasswordRequired': 'Password confirmation is required',
        'confirmPasswordHint': 'Re-enter your password',
        'passwordsDoNotMatch': 'Passwords do not match',
        'licenseNumber': 'License Number',
        'licenseNumberRequired': 'License number is required',
        'actualAddress': 'Actual Address',
        'actualAddressRequired': 'Actual address is required',
        'actualAddressHint': 'Enter your current address',
        'licenseExpiryDate': 'License Expiry Date',
        'licenseExpiryDateHint': 'Select license expiry date',
        'documents': 'Documents',
        'identityCardFront': 'Identity Card (Front)',
        'identityCardBack': 'Identity Card (Back)',
        'licenseFront': 'Driver License (Front)',
        'licenseBack': 'Driver License (Back)',
        'termsAndConditions': 'Terms and Conditions',
        'register': 'Complete Registration',
        'infoText':
            'After registration, your information will be verified and you can start working after approval',
      },
      'ru': {
        'driverRegistration': 'Регистрация водителя',
        'newDriverRegistration': 'Регистрация нового водителя - без OTP',
        'personalInfo': 'Личная информация',
        'driverInfo': 'Информация о водителе',
        'fullName': 'Полное имя',
        'fullNameRequired': 'Полное имя обязательно',
        'fullNameHint': 'Введите ваше имя и фамилию',
        'fullNameMinLength': 'Имя должно содержать минимум 2 символа',
        'phoneNumber': 'Номер телефона',
        'phoneNumberRequired': 'Номер телефона обязателен',
        'phoneNumberInvalid': 'Введите корректный номер телефона',
        'username': 'Имя пользователя',
        'usernameRequired': 'Имя пользователя обязательно',
        'usernameHint': 'Введите имя пользователя',
        'usernameMinLength':
            'Имя пользователя должно содержать минимум 3 символа',
        'password': 'Пароль',
        'passwordRequired': 'Пароль обязателен',
        'passwordHint': 'Введите пароль',
        'passwordMinLength': 'Пароль должен содержать минимум 6 символов',
        'confirmPassword': 'Подтвердите пароль',
        'confirmPasswordRequired': 'Подтверждение пароля обязательно',
        'confirmPasswordHint': 'Введите пароль повторно',
        'passwordsDoNotMatch': 'Пароли не совпадают',
        'licenseNumber': 'Номер водительского удостоверения',
        'licenseNumberRequired': 'Номер водительского удостоверения обязателен',
        'actualAddress': 'Фактический адрес',
        'actualAddressRequired': 'Фактический адрес обязателен',
        'actualAddressHint': 'Введите ваш текущий адрес',
        'licenseExpiryDate': 'Дата истечения лицензии',
        'licenseExpiryDateHint': 'Выберите дату истечения лицензии',
        'documents': 'Документы',
        'identityCardFront': 'Удостоверение личности (Лицевая сторона)',
        'identityCardBack': 'Удостоверение личности (Обратная сторона)',
        'licenseFront': 'Водительские права (Лицевая сторона)',
        'licenseBack': 'Водительские права (Обратная сторона)',
        'termsAndConditions': 'Условия использования',
        'register': 'Завершить регистрацию',
        'infoText':
            'После регистрации ваша информация будет проверена, и вы сможете начать работу после одобрения',
      },
      'uz': {
        'driverRegistration': 'Haydovchi ro\'yxatdan o\'tish',
        'newDriverRegistration':
            'Yangi haydovchi sifatida ro\'yxatdan o\'tish - OTP siz',
        'personalInfo': 'Shaxsiy ma\'lumotlar',
        'driverInfo': 'Haydovchi ma\'lumotlari',
        'fullName': 'To\'liq ism',
        'fullNameRequired': 'To\'liq ism talab qilinadi',
        'fullNameHint': 'Ism va familyangizni kiriting',
        'fullNameMinLength': 'Ism kamida 2 belgidan iborat bo\'lishi kerak',
        'phoneNumber': 'Telefon raqami',
        'phoneNumberRequired': 'Telefon raqami talab qilinadi',
        'phoneNumberInvalid': 'To\'g\'ri telefon raqamini kiriting',
        'username': 'Foydalanuvchi nomi',
        'usernameRequired': 'Foydalanuvchi nomi talab qilinadi',
        'usernameHint': 'Foydalanuvchi nomingizni kiriting',
        'usernameMinLength':
            'Foydalanuvchi nomi kamida 3 belgidan iborat bo\'lishi kerak',
        'password': 'Parol',
        'passwordRequired': 'Parol talab qilinadi',
        'passwordHint': 'Parolingizni kiriting',
        'passwordMinLength': 'Parol kamida 6 belgidan iborat bo\'lishi kerak',
        'confirmPassword': 'Parolni tasdiqlash',
        'confirmPasswordRequired': 'Parolni tasdiqlash talab qilinadi',
        'confirmPasswordHint': 'Parolingizni qayta kiriting',
        'passwordsDoNotMatch': 'Parollar mos kelmaydi',
        'licenseNumber': 'Guvohnoma raqami',
        'licenseNumberRequired': 'Guvohnoma raqami talab qilinadi',
        'actualAddress': 'Faktik manzil',
        'actualAddressRequired': 'Faktik manzil talab qilinadi',
        'actualAddressHint': 'Hozirgi manzilingizni kiriting',
        'licenseExpiryDate': 'Guvohnoma muddati',
        'licenseExpiryDateHint': 'Guvohnoma muddatini tanlang',
        'documents': 'Hujjatlar',
        'identityCardFront': 'Shaxsiy hujjat (Old tomon)',
        'identityCardBack': 'Shaxsiy hujjat (Orqa tomon)',
        'licenseFront': 'Haydovchilik guvohnomasi (Old tomon)',
        'licenseBack': 'Haydovchilik guvohnomasi (Orqa tomon)',
        'termsAndConditions': 'Shartlar va qoidalar',
        'register': 'Ro\'yxatdan o\'tishni yakunlash',
        'infoText':
            'Ro\'yxatdan o\'tgandan so\'ng, ma\'lumotlaringiz tekshiriladi va tasdiqlangandan keyin ishlashni boshlashingiz mumkin bo\'ladi',
      },
    };

    return translations[lang] ?? translations['en']!;
  }
}
