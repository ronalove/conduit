import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../providers/auth_provider.dart';

/// Login screen for IRC server authentication.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    await notifier.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.connecting;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingXxl,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and title
                    _buildHeader(),
                    AppSpacing.gapVerticalXxl,
                    AppSpacing.gapVerticalXxl,

                    // Connection status indicator
                    if (authState.status != AuthStatus.disconnected)
                      _buildStatusIndicator(authState),

                    // Error message
                    if (authState.error != null) ...[
                      _buildErrorMessage(authState.error!),
                      AppSpacing.gapVerticalLg,
                    ],

                    // Username field
                    _buildUsernameField(isLoading),
                    AppSpacing.gapVerticalLg,

                    // Password field
                    _buildPasswordField(isLoading),
                    AppSpacing.gapVerticalLg,

                    // Remember me checkbox
                    _buildRememberMe(isLoading),
                    AppSpacing.gapVerticalXxl,

                    // Login button
                    _buildLoginButton(isLoading),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: const Icon(
            Icons.cable,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        AppSpacing.gapVerticalLg,
        Text(
          'Conduit',
          style: AppTextStyles.displayLarge,
        ),
        AppSpacing.gapVerticalXs,
        Text(
          'IRC Client',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(AuthState state) {
    final (icon, color, text) = switch (state.status) {
      AuthStatus.connecting => (
          Icons.sync,
          AppColors.warning,
          'Connecting...',
        ),
      AuthStatus.authenticating => (
          Icons.lock_outline,
          AppColors.warning,
          'Authenticating...',
        ),
      AuthStatus.connected => (
          Icons.check_circle,
          AppColors.success,
          'Connected',
        ),
      AuthStatus.disconnected => (
          Icons.cloud_off,
          AppColors.textTertiary,
          'Disconnected',
        ),
      AuthStatus.error => (
          Icons.error_outline,
          AppColors.error,
          'Error',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.status == AuthStatus.connecting ||
              state.status == AuthStatus.authenticating)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, size: 16, color: color),
          AppSpacing.gapSm,
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(bool isLoading) {
    return TextFormField(
      controller: _usernameController,
      enabled: !isLoading,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Username',
        hintText: 'your_nickname',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a username';
        }
        if (value.contains(' ')) {
          return 'Username cannot contain spaces';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextFormField(
      controller: _passwordController,
      enabled: !isLoading,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'SASL password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMe(bool isLoading) {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
        ),
        GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
          child: Text(
            'Remember me',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isLoading ? AppColors.textDisabled : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return FilledButton(
      onPressed: isLoading ? null : _handleLogin,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : const Text('Connect'),
      ),
    );
  }
}
