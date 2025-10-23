import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController(text: 'operator');
  final _passwordController = TextEditingController(text: 'operator123');
  bool _otpSent = false;
  bool _isLoading = false;
  String _loginType = 'operator'; // 'operator', 'dispatcher', 'admin', 'otp'

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendOtp(_phoneController.text);

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.otpSent),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.verifyOtp(_phoneController.text, _otpController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _operatorLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.operatorLogin(
          _usernameController.text, _passwordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _dispatcherLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.dispatcherLogin(
          _usernameController.text, _passwordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Dispatcher login error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _adminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.adminLogin(
          _usernameController.text, _passwordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Helper method to get the appropriate login function
  VoidCallback? _getLoginFunction() {
    switch (_loginType) {
      case 'operator':
        return _operatorLogin;
      case 'dispatcher':
        return _dispatcherLogin;
      case 'admin':
        return _adminLogin;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo və başlıq
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.local_taxi,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),
                      Text(
                        AppStrings.loginTitle,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),

                      // Login type selection
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            // First row - Operator and Dispatcher
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _loginType = 'operator';
                                        _otpSent = false;
                                        _otpController.clear();
                                        _usernameController.text = 'operator';
                                        _passwordController.text =
                                            'operator123';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _loginType == 'operator'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        AppStrings.operatorLogin,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _loginType == 'operator'
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.divider,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _loginType = 'dispatcher';
                                        _otpSent = false;
                                        _otpController.clear();
                                        _usernameController.text = 'dispatcher';
                                        _passwordController.text =
                                            'dispatcher123';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _loginType == 'dispatcher'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        AppStrings.dispatcherLogin,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _loginType == 'dispatcher'
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                            // Second row - Admin and OTP
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _loginType = 'admin';
                                        _otpSent = false;
                                        _otpController.clear();
                                        _usernameController.text = 'admin';
                                        _passwordController.text = 'admin123';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _loginType == 'admin'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        AppStrings.adminLogin,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _loginType == 'admin'
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.divider,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _loginType = 'otp';
                                        _otpSent = false;
                                        _otpController.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _loginType == 'otp'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'OTP Girişi',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _loginType == 'otp'
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),

                      // Login Form based on selected type
                      if (_loginType != 'otp') ...[
                        // Username/Password forms for operator, dispatcher, admin
                        CustomTextField(
                          controller: _usernameController,
                          labelText: 'İstifadəçi Adı',
                          hintText: _loginType == 'operator'
                              ? 'operator'
                              : _loginType == 'dispatcher'
                                  ? 'dispatcher'
                                  : 'admin',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'İstifadəçi adı tələb olunur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.padding),
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Şifrə',
                          hintText: '••••••••',
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifrə tələb olunur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.padding),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            onPressed: _isLoading ? null : _getLoginFunction(),
                            text: _isLoading ? AppStrings.loading : 'Daxil Ol',
                            icon: _isLoading ? null : Icons.login,
                          ),
                        ),
                      ] else ...[
                        // OTP Login Form
                        CustomTextField(
                          controller: _phoneController,
                          labelText: AppStrings.phoneNumber,
                          hintText: '+994501234567',
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField;
                            }
                            if (!RegExp(r'^\+994\d{9}$').hasMatch(value)) {
                              return AppStrings.invalidPhone;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.padding),

                        // OTP kodu
                        if (_otpSent) ...[
                          CustomTextField(
                            controller: _otpController,
                            labelText: AppStrings.otpCode,
                            hintText: '123456',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.requiredField;
                              }
                              if (value.length != 6) {
                                return AppStrings.invalidOtp;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.padding),
                        ],

                        // Düymələr
                        SizedBox(
                          width: double.infinity,
                          child: _otpSent
                              ? CustomButton(
                                  onPressed: _isLoading ? null : _verifyOtp,
                                  text: _isLoading
                                      ? AppStrings.loading
                                      : AppStrings.verifyOtp,
                                  icon: _isLoading ? null : Icons.verified,
                                )
                              : CustomButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  text: _isLoading
                                      ? AppStrings.loading
                                      : AppStrings.sendOtp,
                                  icon: _isLoading ? null : Icons.send,
                                ),
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: AppSizes.padding),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _otpSent = false;
                                _otpController.clear();
                              });
                            },
                            child: Text(
                              'Telefon nömrəsini dəyiş',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
