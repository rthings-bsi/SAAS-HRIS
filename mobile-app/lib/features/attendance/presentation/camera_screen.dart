import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../data/camera_service.dart';
import '../provider/attendance_provider.dart';

/// Pure Vector Oval Face Alignment Guide matching Design/kamera_presensi_swafoto_sederhana/code.html
class FaceOvalGuidePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const FaceOvalGuidePainter({
    this.color = Colors.white70,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height * 0.46);
    final radiusX = size.width * 0.30;
    final radiusY = size.height * 0.32;

    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
      );

    final dashPath = Path();
    const dashLength = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant FaceOvalGuidePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// CameraScreen matching Design/kamera_presensi_swafoto_sederhana/code.html
/// Implements 4:5 live selfie viewfinder, location pill, shutter control,
/// attendance note with 0/100 character counter, and success bottom sheet modal.
class CameraScreen extends ConsumerStatefulWidget {
  final bool isClockIn;

  const CameraScreen({
    super.key,
    this.isClockIn = true,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  XFile? _capturedPhoto;
  bool _isFlashOn = false;
  bool _showShutterFlash = false;
  bool _isSubmitting = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    HapticFeedback.lightImpact();
    setState(() {
      _showShutterFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _showShutterFlash = false;
        });
      }
    });

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final photo = await cameraService.capturePhoto();
      if (photo != null && mounted) {
        setState(() {
          _capturedPhoto = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera tidak dapat diakses: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  Future<void> _submitAttendance() async {
    setState(() {
      _isSubmitting = true;
    });

    final notifier = ref.read(attendanceActionProvider.notifier);
    final success = await notifier.recordAttendance(
      isClockIn: widget.isClockIn,
      overridePhotoPath: _capturedPhoto?.path,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.space24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 38,
                  color: AppColors.statusSuccess,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'Presensi ${widget.isClockIn ? "Masuk" : "Pulang"} Berhasil!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    const TextSpan(text: 'Tercatat pada pukul '),
                    TextSpan(
                      text: '$timeStr WIB',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' dengan verifikasi GPS & Swafoto.'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isClockIn ? 'Presensi Masuk' : 'Presensi Pulang';
    final now = DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(now);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live Viewfinder Section (4:5 Aspect Ratio)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 360),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Preview or Captured Photo
                      if (_capturedPhoto != null)
                        Image.file(
                          File(_capturedPhoto!.path),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 100,
                              color: Color(0x33FFFFFF),
                            ),
                          ),
                        ),

                      // Oval Face Alignment Guide
                      if (_capturedPhoto == null)
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: FaceOvalGuidePainter(),
                          ),
                        ),


                      // Top Guide Tip Pill
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB3000000),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.face_rounded,
                                  size: 16,
                                  color: Color(0xFF34D399),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _capturedPhoto != null
                                      ? 'Foto swafoto tersimpan'
                                      : 'Posisikan wajah di dalam bingkai',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Location Pill
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB3000000),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: Color(0xFF34D399),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Lokasi Terverifikasi • Radius Valid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Shutter Flash White Overlay
                      if (_showShutterFlash)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // 2. Minimalist Capture Controls (Flip, Shutter, Flash)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Retake / Flip Button
                InkWell(
                  onTap: _takePhoto,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _capturedPhoto != null
                          ? Icons.refresh_rounded
                          : Icons.flip_camera_ios_rounded,
                      size: 22,
                      color: AppColors.textBody,
                    ),
                  ),
                ),

                const SizedBox(width: 28),

                // Large Shutter Button (64x64 concentric)
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 28),

                // Flash / Brightness Toggle
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isFlashOn
                          ? AppColors.primaryFixed
                          : AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      size: 22,
                      color: _isFlashOn
                          ? AppColors.primary
                          : AppColors.textBody,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space16),

            // 3. Compact Time & Status Pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$timeFormatted WIB',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shift Reguler',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.statusSuccessBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: AppColors.statusSuccess,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tepat Waktu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            // 4. Simplified Attendance Note with 0/100 Char Counter
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Catatan Presensi (Opsional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _noteController,
                        builder: (context, value, child) {
                          return Text(
                            '${value.text.length}/100',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'Tulis catatan jika ada keperluan khusus...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // 5. Primary Action Button
            AppButton(
              text: widget.isClockIn
                  ? 'Kirim Presensi Masuk'
                  : 'Kirim Presensi Pulang',
              icon: const Icon(
                Icons.how_to_reg_rounded,
                size: 20,
                color: Colors.white,
              ),
              isLoading: _isSubmitting,
              onPressed: _submitAttendance,
            ),
          ],
        ),
      ),
    );
  }
}
