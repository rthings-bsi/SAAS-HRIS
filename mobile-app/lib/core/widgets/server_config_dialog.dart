import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../network/network_provider.dart';

class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(serverBaseUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _selectPreset(String url) {
    setState(() {
      _urlController.text = url;
      _testResult = null;
    });
  }

  Future<void> _testConnection() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Alamat URL tidak boleh kosong.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (_) => true,
        ),
      );

      final cleanBase = rawUrl.endsWith('/')
          ? rawUrl.substring(0, rawUrl.length - 1)
          : rawUrl;
      final pingUrl = '$cleanBase/leaves/types';

      final response = await testDio.get(pingUrl);
      if (!mounted) return;

      setState(() {
        _isTesting = false;
        _testSuccess = true;
        _testResult = 'Koneksi Berhasil! Server merespons (HTTP ${response.statusCode}).';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Gagal terhubung ke server.';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Koneksi timeout (4 detik). Pastikan IP Wi-Fi benar dan port 8000 terbuka.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Koneksi ditolak. Pastikan backend Laravel berjalan di host 0.0.0.0.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMsg = e.message!;
      }

      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = errorMsg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Kesalahan: $e';
      });
    }
  }

  Future<void> _applyAndSave() async {
    final targetUrl = _urlController.text.trim();
    if (targetUrl.isEmpty) return;

    await ref.read(serverBaseUrlProvider.notifier).setBaseUrl(targetUrl);

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alamat server aktif: $targetUrl'),
        backgroundColor: AppColors.inkPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = ref.watch(serverBaseUrlProvider);

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.cardBorderRadius,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orangeTint,
              borderRadius: AppDimensions.buttonBorderRadius,
              border: Border.all(color: AppColors.orangeBorder),
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: AppColors.actionAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Alamat Server',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih preset jaringan atau ubah IP host backend Laravel:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildPresetOption(
                title: 'Wi-Fi LAN (PC Laptop)',
                subtitle: 'Gunakan jika HP & Laptop di Wi-Fi yang sama',
                url: ApiEndpoints.defaultLanUrl,
              ),
              const SizedBox(height: 8),
              _buildPresetOption(
                title: 'USB Kabel (ADB Reverse)',
                subtitle: 'Memerlukan: adb reverse tcp:8000 tcp:8000',
                url: ApiEndpoints.defaultUsbUrl,
              ),
              const SizedBox(height: 8),
              _buildPresetOption(
                title: 'Android Studio Emulator',
                subtitle: 'Khusus emulator Android di PC (10.0.2.2)',
                url: ApiEndpoints.defaultEmulatorUrl,
              ),
              const SizedBox(height: 16),
              const Text(
                'URL Endpoint API Aktif:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppColors.inkPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.xxx:8000/api/v1',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.borderNeutral,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.buttonBorderRadius,
                    borderSide: const BorderSide(color: AppColors.borderNeutral),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.buttonBorderRadius,
                    borderSide: const BorderSide(color: AppColors.borderNeutral),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.buttonBorderRadius,
                    borderSide: const BorderSide(
                      color: AppColors.actionAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  foregroundColor: AppColors.actionAccent,
                  side: const BorderSide(color: AppColors.actionAccent),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppDimensions.buttonBorderRadius,
                  ),
                ),
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.actionAccent,
                        ),
                      )
                    : const Icon(Icons.wifi_find_rounded, size: 18),
                label: Text(
                  _isTesting ? 'Sedang Menguji...' : 'Uji Koneksi Server',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: AppDimensions.buttonBorderRadius,
                    border: Border.all(
                      color: _testSuccess
                          ? AppColors.successBorder
                          : AppColors.dangerBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _testSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _testSuccess
                            ? AppColors.successText
                            : AppColors.dangerText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _testSuccess
                                ? AppColors.successText
                                : AppColors.dangerText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tersimpan saat ini: $activeUrl',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(70, AppDimensions.minTouchTarget),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Batal',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(120, AppDimensions.minTouchTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: AppDimensions.buttonBorderRadius,
            ),
          ),
          onPressed: _applyAndSave,
          child: const Text(
            'Terapkan & Simpan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetOption({
    required String title,
    required String subtitle,
    required String url,
  }) {
    final isSelected = _urlController.text.trim() == url.trim();

    return InkWell(
      onTap: () => _selectPreset(url),
      borderRadius: AppDimensions.buttonBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeTint : AppColors.surfaceMuted,
          borderRadius: AppDimensions.buttonBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.actionAccent : AppColors.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.actionAccent : AppColors.inkMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.actionAccent
                          : AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: isSelected
                          ? AppColors.actionHover
                          : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
