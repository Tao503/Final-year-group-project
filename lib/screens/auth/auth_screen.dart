import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import 'complete_profile_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final AuthController _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔵 Starting auth process...');
    bool success = false;

    try {
      if (_isLogin) {
        print('🔵 Attempting sign in...');
        success = await _authController.signIn(
          _nameController.text.trim(), // Using name field for student ID
          _passwordController.text,
          rememberMe: _rememberMe,
        );
      } else {
        print('🔵 Attempting sign up...');
        success = await _authController.signUp(
          _nameController.text.trim(), // Using name field for student ID
          _passwordController.text,
        );
      }

      print('🔵 Auth result: $success');
      print('🔵 Error message: ${_authController.errorMessage.value}');

      if (success && mounted) {
        print('✅ Auth successful');
        // Check if profile needs completion
        if (!_isLogin && _authController.needsProfileCompletion) {
          print(
            '🔵 Profile needs completion, navigating to complete profile...',
          );
          Get.offAll(
                () => CompleteProfileScreen(email: _nameController.text.trim()),
          );
        } else {
          print('✅ Navigating to home...');
          Get.offAll(() => const HomeScreen());
        }
      } else if (mounted) {
        final errorMsg = _authController.errorMessage.value;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.isNotEmpty
                  ? errorMsg
                  : 'Authentication failed. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Auth handler');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          GradientButton(
            text: 'Send Reset Link',
            gradient: AppTheme.accentGradient,
            icon: Icons.send,
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _authController.resetPassword(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _authController.errorMessage.value.isEmpty
                          ? 'Password reset link sent to your email!'
                          : _authController.errorMessage.value,
                    ),
                    backgroundColor: _authController.errorMessage.value.isEmpty
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 1000,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple,
              AppTheme.primaryTeal,
              AppTheme.accentCoral,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),

                        // Logo and title
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 30),

                        AnimatedGradientText(
                          text: 'NILE FIND',
                          gradient: AppTheme.accentGradient,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Welcome back to your community',
                          style: AppStyles.bodyLargeStatic.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Auth form
                        GlassmorphismCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Auth mode toggle
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(15),
                                              gradient: _isLogin
                                                  ? AppTheme.accentGradient
                                                  : null,
                                            ),
                                            child: Text(
                                              'Login',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _isLogin
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(15),
                                              gradient: !_isLogin
                                                  ? AppTheme.accentGradient
                                                  : null,
                                            ),
                                            child: Text(
                                              'Sign Up',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: !_isLogin
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Student ID or Email field (for both login and sign up)
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: _isLogin ? 'Student ID or Email' : 'Email',
                                    labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryTeal,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your student ID or email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryTeal,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Remember Me checkbox (only for login)
                                if (_isLogin)
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primaryTeal,
                                        checkColor: Colors.white,
                                        fillColor:
                                        WidgetStateProperty.resolveWith((
                                            states,
                                            ) {
                                          if (states.contains(
                                            WidgetState.selected,
                                          )) {
                                            return AppTheme.primaryTeal;
                                          }
                                          return Colors.white.withOpacity(
                                            0.2,
                                          );
                                        }),
                                      ),
                                      Text(
                                        'Remember Me',
                                        style: AppStyles.bodyMediumStatic
                                            .copyWith(
                                          color: Colors.white.withOpacity(
                                            0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 20),

                                // Auth button
                                Obx(
                                      () => GradientButton(
                                    text: _isLogin ? 'Login' : 'Sign Up',
                                    gradient: AppTheme.accentGradient,
                                    icon: _isLogin
                                        ? Icons.login
                                        : Icons.person_add,
                                    isLoading: _authController.isLoading.value,
                                    onPressed: _handleAuth,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Forgot password (only for login)
                                if (_isLogin)
                                  TextButton(
                                    onPressed: () {
                                      _showForgotPasswordDialog(context);
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppStyles.bodyMediumStatic
                                          .copyWith(
                                        color: Colors.white.withOpacity(
                                          0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
