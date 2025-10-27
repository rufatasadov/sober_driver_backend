import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedLanguage;

  List<IntroPageData> get _pages {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final lang = languageProvider.currentLanguage;

    final titles = {
      'en': [
        'Welcome to Driver App',
        'Track Your Earnings',
        'Accept Orders Quickly',
      ],
      'ru': [
        'Добро пожаловать в Driver App',
        'Отслеживайте заработок',
        'Принимайте заказы быстро',
      ],
      'uz': [
        'Driver App-ga xush kelibsiz',
        'Daromadingizni kuzating',
        'Buyurtmalarni tez qabul qiling',
      ],
    };

    final descriptions = {
      'en': [
        'Manage your rides efficiently and earn more with our driver platform.',
        'Monitor your daily and weekly earnings in real-time.',
        'Get notified about new orders and accept them with a single tap.',
      ],
      'ru': [
        'Эффективно управляйте поездками и зарабатывайте больше с нашей платформой.',
        'Следите за дневным и недельным заработком в реальном времени.',
        'Получайте уведомления о новых заказах и принимайте их одним касанием.',
      ],
      'uz': [
        'Safaringizni samarali boshqaring va driver platforma orqali ko\'proq toping.',
        'Kunlik va haftalik daromadingizni real vaqtda kuzatib boring.',
        'Yangi buyurtmalar haqida xabardor bo\'ling va bitta bosish bilan qabul qiling.',
      ],
    };

    return [
      IntroPageData(
        title: titles[lang]![0],
        description: descriptions[lang]![0],
        icon: Icons.directions_car,
      ),
      IntroPageData(
        title: titles[lang]![1],
        description: descriptions[lang]![1],
        icon: Icons.trending_up,
      ),
      IntroPageData(
        title: titles[lang]![2],
        description: descriptions[lang]![2],
        icon: Icons.notifications_active,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language');
    setState(() {
      _selectedLanguage = savedLanguage ?? 'en';
    });

    // Set language in provider
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    await languageProvider.setLanguage(savedLanguage ?? 'en');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Language',
                  style: AppTheme.heading3.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 24.h),
                _buildLanguageOption('en', 'English', '🇬🇧'),
                SizedBox(height: 12.h),
                _buildLanguageOption('ru', 'Русский', '🇷🇺'),
                SizedBox(height: 12.h),
                _buildLanguageOption('uz', 'O\'zbek', '🇺🇿'),
                SizedBox(height: 24.h),
              ],
            ),
          ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = _selectedLanguage == code;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    return InkWell(
      onTap: () async {
        setState(() {
          _selectedLanguage = code;
        });

        await languageProvider.setLanguage(code);

        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 24.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                name,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  String _getText(String lang, String key) {
    final texts = {
      'skip': {'en': 'Skip', 'ru': 'Пропустить', 'uz': 'O\'tish'},
      'next': {'en': 'Next', 'ru': 'Далее', 'uz': 'Keyingi'},
      'getStarted': {'en': 'Get Started', 'ru': 'Начать', 'uz': 'Boshlash'},
    };

    return texts[key]![lang] ?? texts[key]!['en']!;
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Language selection and Skip button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _showLanguageSelection,
                    icon: Icon(Icons.language, size: 18.sp),
                    label: Text(
                      _selectedLanguage == 'en'
                          ? 'EN'
                          : _selectedLanguage == 'ru'
                          ? 'RU'
                          : 'UZ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeIntro,
                    child: Text(
                      _getText(languageProvider.currentLanguage, 'skip'),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildIntroPage(_pages[index]);
                },
              ),
            ),

            // Page indicators and button
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: _currentPage == index ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? _getText(languageProvider.currentLanguage, 'next')
                            : _getText(
                              languageProvider.currentLanguage,
                              'getStarted',
                            ),
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(IntroPageData data) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 60.sp, color: AppColors.primary),
          ),

          SizedBox(height: 40.h),

          // Title
          Text(
            data.title,
            style: AppTheme.heading2.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Description
          Text(
            data.description,
            style: AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class IntroPageData {
  final String title;
  final String description;
  final IconData icon;

  IntroPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
