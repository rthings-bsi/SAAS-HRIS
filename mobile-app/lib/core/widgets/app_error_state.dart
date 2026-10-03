import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String retryText;
  final VoidCallback? onRetry;
  final bool isCard;

  const AppErrorState({
    super.key,
    this.title = 'Terjadi Kesalahan',
    this.message,
    this.retryText = 'Muat Ulang',
    this.onRetry,
    this.isCard = false,
  });

  /// Strips technical prefixes and provides friendly messages
  static String? cleanErrorMessage(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;

    // Extract message if formatted as ApiException(statusCode: ..., message: ..., errors: ...)
    final apiExceptionPattern = RegExp(
      r'ApiException\([^)]*message:\s*([^,)]+)',
      caseSensitive: false,
    );
    final apiMatch = apiExceptionPattern.firstMatch(text);
    if (apiMatch != null) {
      final extracted = apiMatch.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        text = extracted;
      }
    }

    // Strip DioException prefix variants (e.g. "DioException [bad response]: ...")
    text = text.replaceAll(
      RegExp(r'^DioException\s*(\[[^\]]*\])?:\s*', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'^DioException\s*\[[^\]]*\]\s*', caseSensitive: false),
      '',
    );

    // Strip common technical exception prefixes
    text = text.replaceAll(
      RegExp(
        r'^(ApiException|Exception|ClientException|SocketException|TimeoutException|FormatException):\s*',
        caseSensitive: false,
      ),
      '',
    );

    // Remove wrapping quotes if present
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      if (text.length >= 2) {
        text = text.substring(1, text.length - 1).trim();
      }
    }

    // Friendly message for missing employee profile
    if (text.toLowerCase().contains('profil karyawan tidak ditemukan')) {
      return 'Profil karyawan Anda belum terhubung atau belum didaftarkan di sistem. Hubungi bagian HR/Admin perusahaan Anda.';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage = cleanErrorMessage(message);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: AppDimensions.cardBorderRadius,
            border: Border.all(
              color: AppColors.dangerBorder,
              width: AppDimensions.borderWidth,
            ),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 24,
            color: AppColors.dangerText,
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
        if (displayMessage != null && displayMessage.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space8),
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: AppDimensions.space20),
          AppButton(
            text: retryText,
            onPressed: onRetry,
            width: 160,
            variant: AppButtonVariant.primary,
          ),
        ],
      ],
    );

    if (isCard) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          color: AppColors.canvasLight,
          borderRadius: AppDimensions.cardBorderRadius,
          border: Border.all(
            color: AppColors.borderNeutral,
            width: AppDimensions.borderWidth,
          ),
        ),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: content,
      ),
    );
  }
}
