import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../home/presentation/home_screen.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const List<Map<String, String>> _demoAccounts = [
    {
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@solusidigital.co.id',
      'role': 'Software Engineer (EMP-001)',
    },
    {
      'name': 'Dewi Lestari',
      'email': 'dewi.lestari@solusidigital.co.id',
      'role': 'Staff (EMP-002)',
    },
    {
      'name': 'Rizky Pratama',
      'email': 'rizky.pratama@solusidigital.co.id',
      'role': 'Staff (EMP-003)',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials([String email = 'ahmad.fauzi@solusidigital.co.id']) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password';
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.inkPrimary),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kembali',
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Header (HR Hub Two-Pill Logo & Name)
                  const HrHubLogo(
                    size: 54,
                    showText: true,
                    subtitle: 'Portal Presensi & Administrasi Karyawan',
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Masuk menggunakan kredensial perusahaan Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          if (authState.errorMessage != null &&
                              authState.errorMessage!.isNotEmpty) ...[
                            Container(
                              key: const Key('login_error_banner'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space12,
                                vertical: AppDimensions.space12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: AppColors.dangerBorder,
                                  width: AppDimensions.borderWidth,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: AppColors.dangerText,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space8),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.dangerText,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space16),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Kerja',
                              hintText: 'nama@perusahaan.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email kerja wajib diisi';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF94A3B8),
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
                                return 'Kata sandi wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          // Submit Action Button
                          AppButton(
                            text: 'Masuk ke Akun',
                            isLoading: authState.isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Demo Credential Helper & Quick Switch Chips
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _fillDemoCredentials(),
                              icon: const Icon(
                                Icons.vpn_key_outlined,
                                size: 14,
                                color: AppColors.inkMuted,
                              ),
                              label: const Text(
                                'Gunakan Akun Demo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space8),

                          // Quick Chips for Seeded Employees
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.space12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 14,
                                      color: AppColors.inkMuted,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Akun Karyawan Demo:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _demoAccounts.map((account) {
                                    final isSelected =
                                        _emailController.text == account['email'];
                                    return ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      backgroundColor: isSelected
                                          ? AppColors.orangeTint
                                          : AppColors.canvasLight,
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.actionAccent
                                            : const Color(0xFFCBD5E1),
                                        width: 1.0,
                                      ),
                                      label: Text(
                                        account['name']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.actionAccent
                                              : AppColors.inkPrimary,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _fillDemoCredentials(account['email']!),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Kata sandi default: password',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space24),
                  const Text(
                    'HR Hub • Enterprise Multi-Tenant HRIS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
