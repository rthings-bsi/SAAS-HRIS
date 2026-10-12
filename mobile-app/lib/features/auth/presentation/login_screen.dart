import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/network/network_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../../core/widgets/server_config_dialog.dart';
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
  bool _rememberMe = true;
  bool _agreeTerms = true;
  String _selectedLanguage = 'ID';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan setujui Kebijakan Privasi terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

  void _showForgotPasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusModal),
        ),
      ),
      backgroundColor: AppColors.canvasLight,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.actionAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pusat Bantuan Kata Sandi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              const Text(
                'Demi kepatuhan standar keamanan data perusahaan, pemulihan akun dan pengaturan ulang kata sandi dilakukan secara terpusat oleh administrator IT & HR.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 18, color: AppColors.actionAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'hr@solusidigital.co.id',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone_in_talk_outlined, size: 18, color: AppColors.actionAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '+62 21 555-0199 (Ext. 104)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18, color: AppColors.inkMuted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Senin - Jumat: 08:30 - 17:30 WIB',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              AppButton(
                text: 'Saya Mengerti',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusModal),
        ),
      ),
      backgroundColor: AppColors.canvasLight,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.actionAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kebijakan Privasi & Ketentuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _buildPrivacyPoint(
                icon: Icons.lock_outline_rounded,
                title: 'Keamanan Data Enterprise',
                desc: 'Seluruh data presensi dan informasi karyawan diisolasi per tenant perusahaan dan dienkripsi dengan standar TLS 256-bit.',
              ),
              const SizedBox(height: AppDimensions.space12),
              _buildPrivacyPoint(
                icon: Icons.location_on_outlined,
                title: 'Akses Lokasi (Geofencing)',
                desc: 'Akses GPS hanya digunakan saat Anda menekan tombol Clock In / Clock Out untuk memverifikasi radius kantor. Tidak ada pelacakan di latar belakang.',
              ),
              const SizedBox(height: AppDimensions.space12),
              _buildPrivacyPoint(
                icon: Icons.camera_alt_outlined,
                title: 'Swafoto Presensi',
                desc: 'Kamera hanya diaktifkan untuk mengambil bukti kehadiran mandiri secara real-time demi integritas data absensi.',
              ),
              const SizedBox(height: AppDimensions.space20),
              AppButton(
                text: 'Saya Mengerti',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.inkPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServerConfigButton() {
    final activeUrl = ref.watch(serverBaseUrlProvider);
    final isLan = activeUrl.contains('192.168.');
    final isUsb =
        activeUrl.contains('127.0.0.1') || activeUrl.contains('localhost');

    String badgeText = 'Server';
    if (isLan) {
      badgeText = 'LAN';
    } else if (isUsb) {
      badgeText = 'USB';
    }

    return Semantics(
      button: true,
      label: 'Konfigurasi Alamat Server: $activeUrl',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ServerConfigDialog.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvasLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.dns_rounded,
                  size: 14,
                  color: AppColors.actionAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Semantics(
      button: true,
      label: 'Pilih Bahasa. Saat ini ${_selectedLanguage == 'ID' ? 'Bahasa Indonesia' : 'English'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedLanguage = _selectedLanguage == 'ID' ? 'EN' : 'ID';
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _selectedLanguage == 'ID'
                      ? 'Bahasa diubah ke Bahasa Indonesia'
                      : 'Language switched to English',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvasLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 16,
                  color: AppColors.actionAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedLanguage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.inkPrimary),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kembali',
              ),
              actions: [
                _buildServerConfigButton(),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.space16),
                  child: Center(
                    child: _buildLanguageSelector(),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!Navigator.of(context).canPop()) ...[
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildServerConfigButton(),
                          const SizedBox(width: 8),
                          _buildLanguageSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                  ],
                  // Brand Header (HR Hub Custom Two-Pill Logo & Identity)
                  const HrHubLogo(
                    size: 38,
                    showText: true,
                    subtitle: 'Kelola administrasi dan kehadiran kerja lebih mudah',
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space20,
                      vertical: AppDimensions.space16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: AppColors.hairline,
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
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Masuk menggunakan kredensial perusahaan Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space12),

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
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
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        minimumSize: const Size(0, 24),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        Icons.settings_ethernet_rounded,
                                        size: 14,
                                        color: AppColors.actionAccent,
                                      ),
                                      label: const Text(
                                        'Atur Alamat Server',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.actionAccent,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      onPressed: () =>
                                          ServerConfigDialog.show(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space12),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email Kerja',
                              hintText: 'nama@perusahaan.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                                color: AppColors.inkMuted,
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
                          const SizedBox(height: AppDimensions.space12),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.inkMuted,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
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
                          const SizedBox(height: AppDimensions.space8),

                          // Options Row: Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) {
                                              setState(() {
                                                _rememberMe = val ?? false;
                                              });
                                            },
                                            activeColor: AppColors.actionAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Flexible(
                                          child: Text(
                                            'Ingat saya',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.inkMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordSheet,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Lupa kata sandi?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.actionAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space4),

                          // Privacy Policy Agreement
                          InkWell(
                            onTap: () {
                              setState(() {
                                _agreeTerms = !_agreeTerms;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _agreeTerms,
                                      onChanged: (val) {
                                        setState(() {
                                          _agreeTerms = val ?? true;
                                        });
                                      },
                                      activeColor: AppColors.actionAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        const Text(
                                          'Saya menyetujui ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _showPrivacyPolicySheet,
                                          child: const Text(
                                            'Kebijakan Privasi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.actionAccent,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          ' & Ketentuan Layanan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Primary Submit Action Button
                          AppButton(
                            text: 'Masuk ke Akun',
                            isLoading: authState.isLoading,
                            onPressed: _handleLogin,
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
    );
  }
}
