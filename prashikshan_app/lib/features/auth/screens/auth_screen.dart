import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_palette.dart';
import '../auth_service.dart';

enum AuthMode { login, signup }

enum UserType { student, company }

/// Complete authentication screen with email/password and Google Sign-In
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AuthService _authService;

  AuthMode _mode = AuthMode.login;
  UserType _userType = UserType.student;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);

    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
    _nameFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _passwordFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _nameFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  // ==================== VALIDATION ====================

  String? _validateEmail(String email) {
    final bool isValid = email.contains('@') && email.contains('.');
    return isValid ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String password) {
    return password.length >= 6
        ? null
        : 'Password must be at least 6 characters';
  }

  bool _validateForm() {
    setState(() => _errorMessage = null);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Validate email
    final String? emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return false;
    }

    // Validate password
    final String? passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return false;
    }

    // Validate name for signup
    if (_mode == AuthMode.signup) {
      final String name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name');
        return false;
      }
    }

    return true;
  }

  // ==================== EMAIL/PASSWORD AUTHENTICATION ====================

  Future<void> _onEmailPasswordAction() async {
    if (!_validateForm()) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      if (_mode == AuthMode.login) {
        await _authService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signupWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          userType: _userType.toString().split('.').last,
        );
      }
      await _printDebugToken();
    } on AuthException catch (e) {
      debugPrint('AuthException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      setState(() => _errorMessage = e.userMessage ?? e.message);
      _showErrorSnackBar(e.userMessage ?? e.message);
    } on Exception catch (e) {
      debugPrint('Exception: $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'An unexpected error occurred');
      _showErrorSnackBar('Authentication failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ==================== GOOGLE SIGN-IN ====================

  Future<void> _onGoogleAction() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      await _printDebugToken();
    } on AuthException catch (e) {
      debugPrint('AuthException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      setState(() => _errorMessage = e.userMessage ?? e.message);
      _showErrorSnackBar(e.userMessage ?? e.message);
    } on Exception catch (e) {
      debugPrint('Exception: $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Google sign-in failed');
      _showErrorSnackBar('Google sign-in failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _printDebugToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String? token = await user?.getIdToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('TOKEN: $token');
      }
    } catch (e) {
      debugPrint('Token print failed: $e');
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.inter(
      color: AppPalette.textPrimary,
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    );
    final TextStyle subtitleStyle = GoogleFonts.inter(
      color: AppPalette.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (BuildContext context, Widget? child) {
          final double t = _backgroundController.value;
          return Stack(
            children: <Widget>[
              // Animated gradient background
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + (t * 0.4), -1),
                      end: Alignment(1, 1 - (t * 0.35)),
                      colors: const <Color>[
                        AppPalette.background,
                        AppPalette.secondaryA,
                        AppPalette.secondaryB,
                      ],
                    ),
                  ),
                ),
              ),
              // Grid pattern overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GridPainter(opacity: 0.055 + (t * 0.02)),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      children: <Widget>[
                        // Title
                        Text('Prashikshan', style: titleStyle),
                        const SizedBox(height: 8),
                        Text(
                          _mode == AuthMode.login
                              ? 'Sign in to continue'
                              : 'Create your account',
                          style: subtitleStyle,
                        ),
                        const SizedBox(height: 24),

                        // Mode toggle (Login/Signup)
                        _ModeToggle(
                          mode: _mode,
                          onModeChanged: (AuthMode value) {
                            setState(() => _mode = value);
                            setState(() => _errorMessage = null);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Glass card with form
                        _GlassCard(
                          child: Column(
                            children: <Widget>[
                              // User type selector
                              _UserTypeSelector(
                                value: _userType,
                                onChanged: (UserType value) {
                                  setState(() => _userType = value);
                                },
                              ),
                              const SizedBox(height: 18),

                              // Name field (signup only)
                              if (_mode == AuthMode.signup) ...[
                                _GlowInput(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  label: 'Full Name',
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Email field
                              _GlowInput(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),

                              // Password field
                              _GlowInput(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                label: 'Password',
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                              ),
                              const SizedBox(height: 18),

                              // Error message
                              if (_errorMessage != null) ...[
                                Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Email/Password action button
                              SizedBox(
                                width: double.infinity,
                                child: _ActionButton(
                                  busy: _busy,
                                  label: _mode == AuthMode.login
                                      ? 'Sign In'
                                      : 'Create Account',
                                  onPressed: _onEmailPasswordAction,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Divider with OR
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Divider(
                                      color: AppPalette.border,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.inter(
                                        color: AppPalette.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppPalette.border,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Google Sign-In button
                              SizedBox(
                                width: double.infinity,
                                child: _GoogleSignInButton(
                                  busy: _busy,
                                  label: _mode == AuthMode.login
                                      ? 'Continue with Google'
                                      : 'Create with Google',
                                  onPressed: _onGoogleAction,
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
            ],
          );
        },
      ),
    );
  }
}

// ==================== UI COMPONENTS ====================

/// Toggle between Login and Signup modes
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onModeChanged,
  });
  final AuthMode mode;
  final ValueChanged<AuthMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.secondaryA,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedAlign(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            alignment: mode == AuthMode.login
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 136,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppPalette.card,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _SegmentButton(
                  label: 'Login',
                  selected: mode == AuthMode.login,
                  onTap: () => onModeChanged(AuthMode.login),
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  label: 'Signup',
                  selected: mode == AuthMode.signup,
                  onTap: () => onModeChanged(AuthMode.signup),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppPalette.textPrimary : AppPalette.textMuted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// User type selector (Student, University, Company)
class _UserTypeSelector extends StatelessWidget {
  const _UserTypeSelector({
    required this.value,
    required this.onChanged,
  });
  final UserType value;
  final ValueChanged<UserType> onChanged;

  static const List<(UserType, String)> items = <(UserType, String)>[
    (UserType.student, 'Student'),
    (UserType.company, 'Company'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map(((UserType, String) item) {
        final bool selected = value == item.$1;
        return GestureDetector(
          onTap: () => onChanged(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected ? AppPalette.secondaryB : Colors.transparent,
              border: Border.all(color: AppPalette.border),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Text(
              item.$2,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppPalette.textPrimary
                    : AppPalette.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Glass effect card container
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Input field with glow effect on focus
class _GlowInput extends StatelessWidget {
  const _GlowInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final bool focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 22,
                  spreadRadius: 0.5,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: GoogleFonts.inter(
          color: AppPalette.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: focused ? AppPalette.textPrimary : AppPalette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: AppPalette.secondaryB,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
        ),
      ),
    );
  }
}

/// Primary action button for email/password auth
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });
  final String label;
  final Future<void> Function() onPressed;
  final bool busy;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = !widget.busy;
    final double scale = _pressed && interactive ? 1.02 : 1.0;

    return GestureDetector(
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      onTap: interactive ? () => widget.onPressed() : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppPalette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              if (_pressed || widget.busy)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.11),
                  blurRadius: 24,
                  spreadRadius: 0.2,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: widget.busy
                ? _ButtonLoadingDots(
                    key: const ValueKey<String>('loading'),
                    controller: _loadingController,
                  )
                : Text(
                    widget.label,
                    key: const ValueKey<String>('label'),
                    style: GoogleFonts.inter(
                      color: AppPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Google Sign-In button
class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });
  final String label;
  final Future<void> Function() onPressed;
  final bool busy;

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = !widget.busy;
    final double scale = _pressed && interactive ? 1.02 : 1.0;

    return GestureDetector(
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      onTap: interactive ? () => widget.onPressed() : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppPalette.card,
            border: Border.all(color: AppPalette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              if (_pressed || widget.busy)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.11),
                  blurRadius: 24,
                  spreadRadius: 0.2,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: widget.busy
                ? _ButtonLoadingDots(
                    key: const ValueKey<String>('loading'),
                    controller: _loadingController,
                  )
                : Row(
                    key: const ValueKey<String>('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.login,
                        color: AppPalette.textPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          color: AppPalette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Animated loading dots
class _ButtonLoadingDots extends StatelessWidget {
  const _ButtonLoadingDots({
    super.key,
    required this.controller,
  });
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double phase = (controller.value + (index * 0.2)) % 1;
            final double active = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            final double opacity = 0.28 + (active * 0.72);
            final double size = 6 + (active * 2.6);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Grid pattern painter for background
class _GridPainter extends CustomPainter {
  _GridPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 0.4;
    const double gap = 28;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
