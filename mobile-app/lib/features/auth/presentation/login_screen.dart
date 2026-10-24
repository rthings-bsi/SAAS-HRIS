import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _hasEmailText = false;
  String _selectedLanguage = 'ID';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  void _handleEmailChanged() {
    final hasText = _emailController.text.isNotEmpty;
    if (hasText != _hasEmailText) {
      setState(() {
        _hasEmailText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

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
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bantuan Akun & Kata Sandi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Helpdesk Internal HRIS PT SPINDO',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Untuk keamanan data perusahaan, perubahan kata sandi diproses langsung oleh IT & HR Administrator.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mail_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'admin.hr@spindo.com',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 18, thickness: 1, color: Color(0xFFF1F5F9)),
                    Row(
                      children: [
                        Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '+62 31 740-2345 (Ext. 104)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Tutup',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicySheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kebijakan Privasi & Ketentuan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Standar Perlindungan Data Enterprise',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                icon: Icons.lock_rounded,
                iconColor: const Color(0xFF1D4ED8),
                bgColor: const Color(0xFFEFF6FF),
                title: 'Keamanan Data Enterprise',
                desc: 'Data presensi dienkripsi dengan standar TLS 256-bit dan terisolasi per tenant perusahaan.',
              ),
              const SizedBox(height: 10),
              _buildPrivacyPoint(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                title: 'Akses Lokasi (Geofencing)',
                desc: 'GPS hanya diakses saat Clock In / Clock Out untuk memverifikasi radius kantor.',
              ),
              const SizedBox(height: 16),
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
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Semantics(
      button: true,
      label: 'Pilih Bahasa',
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
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xEBFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
                const Icon(Icons.language_rounded, size: 15, color: Color(0xFF475569)),
                const SizedBox(width: 5),
                Text(
                  _selectedLanguage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
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
    final emailFocused = _emailFocusNode.hasFocus;
    final passwordFocused = _passwordFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFE),
      body: Stack(
        children: [
          // 1. Top-Left Soft Ambient Blue Curves (Matching 3.webp)
          Positioned(
            top: 0,
            left: 0,
            width: 175,
            height: 185,
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _TopLeftAmbientPainter(),
              ),
            ),
          ),

          // 2. Bottom-Left Soft Sage Green Corner Curve (Matching 3.webp)
          Positioned(
            bottom: 0,
            left: 0,
            width: 85,
            height: 95,
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _BottomLeftGreenWavePainter(),
              ),
            ),
          ),

          // 3. Bottom-Right PT SPINDO Factory & Steel Pipes (Clean Arc from 3.webp)
          Positioned(
            bottom: 0,
            right: 0,
            width: 248,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/login-bg-spindo.jpg',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

          // 4. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered Brand Identity: HR HUB Logo
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF003893),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22003893),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const HrTwoPeopleLogo(
                            size: 34,
                            leftColor: Colors.white,
                            rightColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Centered Heading: "Selamat Datang" (Datang in Blue)
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Selamat ',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Datang',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0040C1),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Center(
                        child: Text(
                          'Masuk dengan akun HRIS Anda untuk mengakses sistem.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Floating Pristine White Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C0F172A),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error Banner
                              if (authState.errorMessage != null &&
                                  authState.errorMessage!.isNotEmpty) ...[
                                Container(
                                  key: const Key('login_error_banner'),
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          size: 16,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Input Field 1: Email Kerja
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email Kerja',
                                  hintStyle: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: emailFocused
                                      ? const Color(0xFFF0F7FF)
                                      : Colors.white,
                                  prefixIcon: Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                    color: emailFocused
                                        ? const Color(0xFF0040C1)
                                        : const Color(0xFF64748B),
                                  ),
                                  suffixIcon: _hasEmailText
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            size: 17,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          tooltip: 'Hapus teks',
                                          onPressed: () => _emailController.clear(),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0040C1),
                                      width: 1.6,
                                    ),
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
                              const SizedBox(height: 12),

                              // Input Field 2: Kata Sandi
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _handleLogin(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Kata Sandi',
                                  hintStyle: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: passwordFocused
                                      ? const Color(0xFFF0F7FF)
                                      : Colors.white,
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: passwordFocused
                                        ? const Color(0xFF0040C1)
                                        : const Color(0xFF64748B),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: const Color(0xFF64748B),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0040C1),
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kata sandi wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Options Row: Ingat Saya & Lupa Kata Sandi
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
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
                                              width: 18,
                                              height: 18,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _rememberMe = val ?? false;
                                                  });
                                                },
                                                activeColor: const Color(0xFF0040C1),
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
                                                  fontSize: 12.5,
                                                  color: Color(0xFF334155),
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
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0040C1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Primary CTA Button: Masuk
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0040C1),
                                      Color(0xFF1E60E6),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x350040C1),
                                      blurRadius: 14,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: authState.isLoading ? null : _handleLogin,
                                    borderRadius: BorderRadius.circular(14),
                                    splashColor: Colors.white24,
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: 48),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                        horizontal: 16,
                                      ),
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Masuk',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // "atau" Divider
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'atau',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Security & Multi-Tenant Guarantee
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Enkripsi SSL 256-bit  •  Multi-Tenant Isolasi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Privacy Policy Link
                              Center(
                                child: InkWell(
                                  onTap: _showPrivacyPolicySheet,
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      'Kebijakan Privasi & Ketentuan Layanan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bottom Brand Bar: "SPINDO | Building a Stronger Future"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'S P I N D O',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              color: Color(0xFF003893),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 1,
                            height: 12,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const Flexible(
                            child: Text(
                              'Building a Stronger Future',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 54),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Top-Right Language Selector (Anchored to top-right corner)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 16,
            child: _buildLanguageSelector(),
          ),
        ],
      ),
    );
  }
}

/// Soft ambient blue curve on top-left of the canvas (matching 3.webp)
class _TopLeftAmbientPainter extends CustomPainter {
  const _TopLeftAmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPaint = Paint()
      ..color = const Color(0xFFEEF6FD)
      ..style = PaintingStyle.fill;

    final outerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..quadraticBezierTo(w * 0.65, h * 0.55, 0, h)
      ..close();
    canvas.drawPath(outerPath, outerPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFFDDEAF8)
      ..style = PaintingStyle.fill;

    final innerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.62, 0)
      ..quadraticBezierTo(w * 0.42, h * 0.42, 0, h * 0.68)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft sage green corner curve on bottom-left (matching 3.webp)
class _BottomLeftGreenWavePainter extends CustomPainter {
  const _BottomLeftGreenWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rimPaint = Paint()
      ..color = const Color(0xFFE1EEE0)
      ..style = PaintingStyle.fill;

    final rimPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.12)
      ..quadraticBezierTo(w * 0.55, h * 0.45, w, h)
      ..close();
    canvas.drawPath(rimPath, rimPaint);

    final fillPaint = Paint()
      ..color = const Color(0xFFAED5AB)
      ..style = PaintingStyle.fill;

    final fillPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.18)
      ..quadraticBezierTo(w * 0.50, h * 0.48, w * 0.94, h)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
