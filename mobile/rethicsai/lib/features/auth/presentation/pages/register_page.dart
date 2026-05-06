import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/social_login_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedCountry = 'Nigeria';
  
  // Comprehensive list of African countries for inclusivity
  final List<String> _countries = [
    'Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi',
    'Cameroon', 'Cape Verde', 'Central African Republic', 'Chad', 'Comoros',
    'Democratic Republic of Congo', 'Republic of Congo', 'Djibouti', 'Egypt',
    'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia', 'Gabon', 'Gambia',
    'Ghana', 'Guinea', 'Guinea-Bissau', 'Ivory Coast', 'Kenya', 'Lesotho',
    'Liberia', 'Libya', 'Madagascar', 'Malawi', 'Mali', 'Mauritania', 'Mauritius',
    'Morocco', 'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Rwanda',
    'São Tomé and Príncipe', 'Senegal', 'Seychelles', 'Sierra Leone', 'Somalia',
    'South Africa', 'South Sudan', 'Sudan', 'Tanzania', 'Togo', 'Tunisia',
    'Uganda', 'Zambia', 'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      // Provide audio feedback for validation errors
      HapticFeedback.mediumImpact();
      return;
    }
    
    if (!_acceptTerms) {
      _showAccessibleSnackBar(
        context,
        'auth.terms_required'.tr(),
        isError: true,
      );
      HapticFeedback.mediumImpact();
      return;
    }

    // Animate button press
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    // Provide success feedback
    HapticFeedback.lightImpact();

    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        country: _selectedCountry,
      ),
    );
  }

  void _showAccessibleSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          semanticsLabel: message, // For screen readers
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Longer duration for accessibility
        action: SnackBarAction(
          label: 'common.ok'.tr(),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'auth.email_required'.tr();
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value!)) {
      return 'auth.invalid_email'.tr();
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'auth.password_required'.tr();
    }
    if (value!.length < 6) {
      return 'auth.password_min_length'.tr();
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'auth.password_required'.tr();
    }
    if (value != _passwordController.text) {
      return 'auth.passwords_dont_match'.tr();
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldKey) {
    if (value?.isEmpty ?? true) {
      return '${fieldKey}_required'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _showAccessibleSnackBar(
              context,
              'auth.welcome_to_rethicsai'.tr(),
              isError: false,
            );
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (state is AuthFailure) {
            _showAccessibleSnackBar(
              context,
              state.message,
              isError: true,
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            
            return Scaffold(
              body: Stack(
                children: [
                  // Background
                  const AfricanPatternBackground(),
                  
                  // Content
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Back button with accessibility
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Semantics(
                                  label: 'Go back',
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.9),
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: AppTheme.spacingL),
                              
                              // Header
                              Text(
                                'auth.create_account'.tr(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                                textAlign: TextAlign.center,
                                semanticsLabel: 'Create your Rethicssec account',
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'auth.join_africa_cybersecurity'.tr(),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Registration Form
                              Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                  children: [
                                    // Name fields in a row for better UX
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AuthFormField(
                                            controller: _firstNameController,
                                            labelText: 'auth.first_name'.tr(),
                                            hintText: 'Enter your first name',
                                            prefixIcon: Icons.person,
                                            keyboardType: TextInputType.name,
                                            validator: (value) => _validateRequired(value, 'auth.first_name'),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.spacingM),
                                        Expanded(
                                          child: AuthFormField(
                                            controller: _lastNameController,
                                            labelText: 'auth.last_name'.tr(),
                                            hintText: 'Enter your last name',
                                            prefixIcon: Icons.person_outline,
                                            keyboardType: TextInputType.name,
                                            validator: (value) => _validateRequired(value, 'auth.last_name'),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Email
                                    AuthFormField(
                                      controller: _emailController,
                                      labelText: 'auth.email'.tr(),
                                      hintText: 'auth.enter_email'.tr(),
                                      prefixIcon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Phone and Country
                                    Row(
                                      children: [
                                        // Country dropdown
                                        Expanded(
                                          flex: 2,
                                          child: Semantics(
                                            label: 'Select your country',
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 12),
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedCountry,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText: 'auth.country'.tr(),
                                                  labelStyle: TextStyle(
                                                    color: AppTheme.onSurfaceVariant,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    backgroundColor: Colors.white,
                                                  ),
                                                  floatingLabelStyle: TextStyle(
                                                    color: AppTheme.secondaryColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    backgroundColor: Colors.white,
                                                  ),
                                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                                  prefixIcon: Icon(
                                                    Icons.flag_outlined,
                                                    color: AppTheme.secondaryColor,
                                                    size: 22,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[50],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.5),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                                                  ),
                                                  focusedErrorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(color: AppTheme.errorColor, width: 2.5),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 20,
                                                  ),
                                                ),
                                                isExpanded: true,
                                                items: _countries.map((country) {
                                                  return DropdownMenuItem(
                                                    value: country,
                                                    child: Text(
                                                      country,
                                                      style: TextStyle(
                                                        color: AppTheme.primaryColor,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCountry = value!;
                                                  });
                                                },
                                                dropdownColor: Colors.white,
                                                icon: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: AppTheme.secondaryColor,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: AppTheme.spacingM),
                                        
                                        // Phone field
                                        Expanded(
                                          flex: 3,
                                          child: AuthFormField(
                                            controller: _phoneController,
                                            labelText: 'auth.phone_number'.tr(),
                                            hintText: '+234 801 234 5678',
                                            prefixIcon: Icons.phone,
                                            keyboardType: TextInputType.phone,
                                            validator: (value) => _validateRequired(value, 'auth.phone'),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Password
                                    AuthFormField(
                                      controller: _passwordController,
                                      labelText: 'auth.password'.tr(),
                                      hintText: 'auth.enter_password'.tr(),
                                      prefixIcon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      validator: _validatePassword,
                                      suffixIcon: Semantics(
                                        label: _obscurePassword ? 'Show password' : 'Hide password',
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Confirm Password
                                    AuthFormField(
                                      controller: _confirmPasswordController,
                                      labelText: 'auth.confirm_password'.tr(),
                                      hintText: 'Confirm your password',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscureConfirmPassword,
                                      validator: _validateConfirmPassword,
                                      suffixIcon: Semantics(
                                        label: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Terms and Privacy Checkbox
                                    Semantics(
                                      label: 'Terms and Privacy Policy agreement',
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _acceptTerms,
                                            onChanged: (value) {
                                              setState(() {
                                                _acceptTerms = value!;
                                              });
                                              HapticFeedback.selectionClick();
                                            },
                                            activeColor: AppTheme.primaryColor,
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _acceptTerms = !_acceptTerms;
                                                });
                                                HapticFeedback.selectionClick();
                                              },
                                              child: Text(
                                                'auth.terms_privacy'.tr(),
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingXL),
                                    
                                    // Register Button
                                    Semantics(
                                      label: 'Create your account',
                                      child: PremiumButton(
                                        text: 'auth.create_account'.tr(),
                                        onPressed: isLoading ? null : () => _handleRegister(context),
                                        isLoading: isLoading,
                                        gradient: AppTheme.africanSunsetGradient,
                                        width: double.infinity,
                                        height: 56,
                                        icon: Icons.person_add,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingXL),
                                    
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.grey[300])),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'auth.or_continue_with'.tr(),
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.grey[300])),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingL),
                                    
                                    // Social Login Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SocialLoginButton(
                                            icon: Icons.g_mobiledata,
                                            label: 'Google',
                                            onPressed: isLoading ? null : () {
                                              context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SocialLoginButton(
                                            icon: Icons.apple,
                                            label: 'Apple',
                                            onPressed: isLoading ? null : () {
                                              context.read<AuthBloc>().add(AuthAppleSignInRequested());
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: AppTheme.spacingXL),
                                    
                                    // Login Link
                                    Semantics(
                                      label: 'Already have an account? Sign in',
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'auth.already_have_account'.tr(),
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'auth.sign_in'.tr(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryColor,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}