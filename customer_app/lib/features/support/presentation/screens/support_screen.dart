import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'Ümumi sual'},
    {'value': 'technical', 'label': 'Texniki problem'},
    {'value': 'payment', 'label': 'Ödəniş problemi'},
    {'value': 'order', 'label': 'Sifariş problemi'},
    {'value': 'other', 'label': 'Digər'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate sending message
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesajınız göndərildi. Tezliklə sizinlə əlaqə saxlayacağıq'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear form
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon zəngi edilə bilmədi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email göndərilə bilmədi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dəstək'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contact Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Əlaqə məlumatları',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildContactItem(
                      icon: Icons.phone,
                      title: 'Telefon',
                      subtitle: '+994 12 345 67 89',
                      onTap: () => _makePhoneCall('+994123456789'),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildContactItem(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: 'support@ayiqsurucu.az',
                      onTap: () => _sendEmail('support@ayiqsurucu.az'),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildContactItem(
                      icon: Icons.access_time,
                      title: 'İş saatları',
                      subtitle: 'Hər gün 24 saat',
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // FAQ Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tez-tez verilən suallar',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildFAQItem(
                      question: 'Sifariş necə yaradılır?',
                      answer: 'Ana səhifədə "Taksi sifariş et" düyməsini basın, götürülmə və təyinat ünvanlarını daxil edin, ödəniş üsulunu seçin və sifarişi yaradın.',
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildFAQItem(
                      question: 'Sifarişi necə ləğv edə bilərəm?',
                      answer: 'Sifarişiniz hələ qəbul edilməyibsə, sifariş izləmə səhifəsində "Ləğv et" düyməsini basaraq sifarişi ləğv edə bilərsiniz.',
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildFAQItem(
                      question: 'Hansı ödəniş üsulları mövcuddur?',
                      answer: 'Nəğd ödəniş, bank kartı və onlayn ödəniş üsulları mövcuddur.',
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Contact Form
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bizə yazın',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      // Category selection
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kateqoriya',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad və soyad',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ad və soyad tələb olunur';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tələb olunur';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Düzgün email daxil edin';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Message field
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mesaj',
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mesaj tələb olunur';
                          }
                          if (value.length < 10) {
                            return 'Mesaj minimum 10 simvol olmalıdır';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Göndər',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Text(
            answer,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
