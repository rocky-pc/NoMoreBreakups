import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Entrance animations
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  // Soft floating blobs
  late final AnimationController _blobController;
  late final Animation<double> _blob1;
  late final Animation<double> _blob2;
  late final Animation<double> _blob3;

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
    ));
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOutBack),
      ),
    );

    // Floating blobs (subtle & slow)
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _blobController.repeat(reverse: true);

    _blob1 = Tween<double>(begin: -14, end: 12).animate(
      CurvedAnimation(parent: _blobController, curve: Curves.easeInOutSine),
    );
    _blob2 = Tween<double>(begin: 12, end: -14).animate(
      CurvedAnimation(
        parent: _blobController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutSine),
      ),
    );
    _blob3 = Tween<double>(begin: -10, end: 16).animate(
      CurvedAnimation(
        parent: _blobController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeInOutSine),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _register() async {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (displayName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).signUp(email, password, displayName);

    if (mounted) {
      final authState = ref.read(authControllerProvider);
      authState.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! You can now log in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Fluid soft-gradient backdrop
          _buildFluidBackdrop(isDarkMode),

          // Main form content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand Header
                          _buildBrandHeader(isDarkMode),

                          const SizedBox(height: 36),

                          // Glassmorphic Form Card
                          _buildFormCard(isLoading, isDarkMode),

                          const SizedBox(height: 24),

                          // Back to Login Link
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                            child: Text(
                              'Already have an account? Log In',
                              style: AppStyles.bodyText.copyWith(
                                color: AppColors.rose,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Brand Header (Icon + Gradient Title + Subtitle)
  // ---------------------------------------------------------------------
  Widget _buildBrandHeader(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.rose.withAlpha(38),
                AppColors.rose.withAlpha(8),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 44,
            color: AppColors.rose,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.rose,
              AppColors.rose.withAlpha(170),
              AppColors.rose,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Create Account  ',
            textAlign: TextAlign.center,
            style: AppStyles.brandName.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start your journey of healing & growth',
          style: AppStyles.caption.copyWith(
            color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Soft Glass Form Card
  // ---------------------------------------------------------------------
  Widget _buildFormCard(bool isLoading, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDarkMode
            ? Colors.white.withAlpha(12)
            : Colors.white.withAlpha(210),
        border: Border.all(
          color: AppColors.rose.withAlpha(isDarkMode ? 40 : 25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withAlpha(28),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 40 : 12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: Column(
              children: [
                // Display Name Field
                _buildInputField(
                  controller: _displayNameController,
                  labelText: 'Display Name',
                  icon: Icons.person_outline_rounded,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),

                // Email Field
                _buildInputField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildInputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 28),

                // Sign Up Button
                _buildSignUpButton(isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppStyles.bodyText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppStyles.bodyText.copyWith(
          color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withAlpha(8)
            : Colors.white.withAlpha(160),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.rose.withAlpha(30),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.rose.withAlpha(120),
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
          size: 22,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Gradient Sign Up Button
  // ---------------------------------------------------------------------
  Widget _buildSignUpButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.rose,
            AppColors.rose.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withAlpha(90),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _register,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.4,
              ),
            )
                : Text(
              'Create Account ',
              style: AppStyles.buttonText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Soft Floating Gradient Backdrop
  // ---------------------------------------------------------------------
  Widget _buildFluidBackdrop(bool isDarkMode) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _blobController,
          builder: (context, _) {
            return Stack(
              children: [
                // Base background color
                Container(
                  color: isDarkMode
                      ? const Color(0xFF121212)
                      : const Color(0xFFFFF8FA),
                ),

                // Blob 1 – Top Left
                Positioned(
                  top: -80 + _blob1.value,
                  left: -60 + _blob1.value * 0.6,
                  child: _blob(240, AppColors.rose.withAlpha(isDarkMode ? 55 : 42)),
                ),

                // Blob 2 – Top Right
                Positioned(
                  top: 40 + _blob2.value,
                  right: -80 + _blob2.value * 0.5,
                  child: _blob(200, AppColors.rose.withAlpha(isDarkMode ? 40 : 28)),
                ),

                // Blob 3 – Bottom
                Positioned(
                  bottom: -70 + _blob3.value,
                  left: -40 + _blob3.value * 0.4,
                  child: _blob(220, AppColors.rose.withAlpha(isDarkMode ? 35 : 22)),
                ),

                // Fullscreen Blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
        ),
      ),
    );
  }
}