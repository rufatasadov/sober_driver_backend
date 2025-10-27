import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/language_provider.dart';

class PrivacyPolicyWidget extends StatefulWidget {
  final bool isAccepted;
  final ValueChanged<bool> onChanged;

  const PrivacyPolicyWidget({
    super.key,
    required this.isAccepted,
    required this.onChanged,
  });

  @override
  State<PrivacyPolicyWidget> createState() => _PrivacyPolicyWidgetState();
}

class _PrivacyPolicyWidgetState extends State<PrivacyPolicyWidget> {
  String _privacyPolicyText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final lang = languageProvider.currentLanguage;

      // Load only the text for the current language
      final String fullText = await rootBundle.loadString(
        'driver_privacy_policy.txt',
      );

      // Extract text for current language
      String policyText = '';
      if (lang == 'en') {
        policyText = _extractLanguageText(fullText, 'en');
      } else if (lang == 'ru') {
        policyText = _extractLanguageText(fullText, 'ru');
      } else if (lang == 'uz') {
        policyText = _extractLanguageText(fullText, 'uz');
      } else {
        policyText = _extractLanguageText(fullText, 'en'); // Default to English
      }

      setState(() {
        _privacyPolicyText = policyText;
        _isLoading = false;
      });
    } catch (e) {
      final lang =
          Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      final errorMessages = {
        'en': 'Privacy policy could not be loaded.',
        'ru': 'Не удалось загрузить политику конфиденциальности.',
        'uz': 'Maxfiylik siyosati yuklana olmadi.',
      };

      setState(() {
        _privacyPolicyText = errorMessages[lang] ?? errorMessages['en']!;
        _isLoading = false;
      });
    }
  }

  String _extractLanguageText(String fullText, String lang) {
    // The file has 3 sections separated by empty lines
    // Section 1: Russian (lines 1-60)
    // Section 2: Uzbek (lines 62-121)
    // Section 3: English (lines 123-182)

    final lines = fullText.split('\n');
    int startLine = 0;
    int endLine = 0;

    if (lang == 'en') {
      // English section (third section)
      startLine = 123;
      endLine = 183;
    } else if (lang == 'ru') {
      // Russian section (first section)
      startLine = 0;
      endLine = 61;
    } else if (lang == 'uz') {
      // Uzbek section (second section)
      startLine = 62;
      endLine = 122;
    } else {
      // Default to Russian
      startLine = 0;
      endLine = 61;
    }

    final selectedLines = lines.sublist(startLine, endLine);
    return selectedLines.join('\n');
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final languageProvider = Provider.of<LanguageProvider>(
          context,
          listen: false,
        );
        final lang = languageProvider.currentLanguage;

        final title =
            lang == 'en'
                ? 'Terms and Conditions'
                : lang == 'ru'
                ? 'Условия использования'
                : lang == 'uz'
                ? 'Shartlar va qoidalar'
                : 'Terms and Conditions';

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTheme.heading3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      child: Text(
                        _privacyPolicyText,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang == 'en'
                    ? 'Close'
                    : lang == 'ru'
                    ? 'Закрыть'
                    : lang == 'uz'
                    ? 'Yopish'
                    : 'Close',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLocalizedText(String key) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final lang = languageProvider.currentLanguage;

    final translations = {
      'en': {
        'termsAndConditions': 'Terms and Conditions',
        'description':
            'By registering as a driver, you agree to our terms and conditions. Please read them carefully before proceeding.',
        'acceptTerms': 'I accept the terms and conditions',
        'viewTerms': 'View Terms',
        'termsAccepted': 'Terms accepted',
      },
      'ru': {
        'termsAndConditions': 'Условия использования',
        'description':
            'Регистрируясь как водитель, вы соглашаетесь с нашими условиями использования. Пожалуйста, внимательно прочитайте их перед продолжением.',
        'acceptTerms': 'Я принимаю условия использования',
        'viewTerms': 'Посмотреть условия',
        'termsAccepted': 'Условия приняты',
      },
      'uz': {
        'termsAndConditions': 'Shartlar va qoidalar',
        'description':
            'Haydovchi sifatida ro\'yxatdan o\'tish orqali siz bizning shartlar va qoidalarimizga rozi bo\'lasiz. Davom etishdan oldin ularni diqqat bilan o\'qing.',
        'acceptTerms': 'Men shartlar va qoidalarga roziman',
        'viewTerms': 'Shartlarni ko\'rish',
        'termsAccepted': 'Shartlar qabul qilindi',
      },
    };

    return translations[lang]?[key] ?? translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              widget.isAccepted
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color:
                    widget.isAccepted
                        ? AppColors.success
                        : AppColors.textSecondary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                _getLocalizedText('termsAndConditions'),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            _getLocalizedText('description'),
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          SizedBox(height: 12.h),

          // Checkbox and View Terms button
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: widget.isAccepted,
                onChanged: (value) => widget.onChanged(value ?? false),
                activeColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),

              SizedBox(width: 8.w),

              // Accept text
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(!widget.isAccepted),
                  child: Text(
                    _getLocalizedText('acceptTerms'),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // View Terms button
              TextButton(
                onPressed: _showPrivacyPolicyDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _getLocalizedText('viewTerms'),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          // Status indicator
          if (widget.isAccepted) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _getLocalizedText('termsAccepted'),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
