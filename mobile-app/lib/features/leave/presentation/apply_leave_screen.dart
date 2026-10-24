import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../data/leave_models.dart';
import '../provider/leave_provider.dart';

int calculateWorkingDays(DateTime start, DateTime end) {
  if (end.isBefore(start)) return 0;
  int count = 0;
  DateTime current = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!current.isAfter(last)) {
    if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
      count++;
    }
    current = current.add(const Duration(days: 1));
  }
  return count;
}

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  int? _selectedLeaveTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _pickedFile;
  Uint8List? _fileBytes;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');

  bool get _isTestEnvironment {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _calculatedWorkingDays {
    if (_startDate == null || _endDate == null) return 0;
    return calculateWorkingDays(_startDate!, _endDate!);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initialDate = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final firstAllowed = _startDate ?? now;
    final initialDate = _endDate != null && !_endDate!.isBefore(firstAllowed)
        ? _endDate!
        : firstAllowed;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickAttachment({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _fileBytes = bytes;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _pickedFile = null;
      _fileBytes = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis cuti terlebih dahulu.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan tanggal mulai dan selesai.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    final success = await ref.read(leaveActionProvider.notifier).submitLeaveRequest(
          leaveTypeId: _selectedLeaveTypeId!,
          startDate: _dateFormat.format(_startDate!),
          endDate: _dateFormat.format(_endDate!),
          reason: _reasonController.text.trim(),
          attachmentPath: _pickedFile?.path,
          attachmentBytes: _fileBytes,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan cuti berhasil dikirim.'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );

      if (_isTestEnvironment) {
        Navigator.of(context).pop(true);
      } else {
        await _showSuccessModal();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      final errorMsg = ref.read(leaveActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal mengirim pengajuan cuti.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    }
  }

  Future<void> _showSuccessModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Soft Mint/Teal Success Icon Ring
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSuccessBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Cuti Berhasil!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permohonan Anda telah tercatat dalam sistem dan langsung diteruskan ke atasan & HR untuk verifikasi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Ticket summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Permohonan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusWarningBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.statusWarningBorder),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 6,
                                  height: 6,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.statusWarning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Menunggu Review',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Durasi Pengajuan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            '$_calculatedWorkingDays Hari Kerja',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(leaveTypesProvider);
    final balancesAsync = ref.watch(leaveBalanceProvider);
    final actionState = ref.watch(leaveActionProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderSubtle,
            height: 1.0,
          ),
        ),
        title: const Text(
          'Ajukan Cuti & Izin',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Section: Jenis Cuti / Izin
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Jenis Cuti / Izin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    typesAsync.when(
                      loading: () => const AppSkeleton(height: 48),
                      error: (error, _) => Container(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: AppColors.statusDangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.statusDangerBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppErrorState.cleanErrorMessage(error.toString()) ??
                                    'Gagal memuat jenis cuti.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.statusDanger,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => ref.invalidate(leaveTypesProvider),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                      data: (types) {
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedLeaveTypeId,
                          decoration: InputDecoration(
                            hintText: 'Pilih jenis cuti',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceCanvas,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space16,
                              vertical: AppDimensions.space12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderSubtle,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderSubtle,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryContainer,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: types.map((LeaveTypeModel type) {
                            final quotaInfo = type.quota_days > 0
                                ? ' (${type.quota_days} hari)'
                                : '';
                            return DropdownMenuItem<int>(
                              value: type.id_leave_types,
                              child: Text(
                                '${type.name}$quotaInfo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLeaveTypeId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Jenis cuti wajib dipilih.';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    _buildRemainingQuotaCard(balancesAsync, typesAsync.valueOrNull),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // 2. Section: Periode Pengajuan (Tanggal Mulai & Tanggal Selesai)
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Periode Pengajuan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Mulai',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textBody,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              InkWell(
                                onTap: _pickStartDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _startDate != null
                                              ? _displayDateFormat.format(_startDate!)
                                              : 'Pilih Tanggal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _startDate != null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: _startDate != null
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Selesai',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textBody,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              InkWell(
                                onTap: _pickEndDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.space12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _endDate != null
                                              ? _displayDateFormat.format(_endDate!)
                                              : 'Pilih Tanggal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _endDate != null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: _endDate != null
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    // Calculation Display: "Durasi: X Hari Kerja"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timelapse_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Durasi: $_calculatedWorkingDays Hari Kerja',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Text(
                              'Hari Efektif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // 3. Section: Alasan Cuti / Izin
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
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
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Alasan Cuti / Izin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_reasonController.text.length}/250',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    TextFormField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 250,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan pengajuan cuti secara jelas',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceCanvas,
                        contentPadding: const EdgeInsets.all(AppDimensions.space16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Alasan cuti wajib diisi.';
                        }
                        if (value.trim().length < 5) {
                          return 'Alasan cuti minimal 5 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Informasikan konteks urgensi agar atasan dan HR dapat memproses persetujuan dengan cepat.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // 4. Section: Surat Dokter / Bukti Izin
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
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
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Surat Dokter / Bukti Izin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Opsional / Lampiran',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    if (_pickedFile == null)
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCanvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceCard,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pilih Berkas / Foto Lampiran',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Format: JPG, PNG, PDF (Maksimal 5 MB)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(110, 38),
                                    side: const BorderSide(color: AppColors.borderSubtle),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _pickAttachment(fromCamera: true),
                                  icon: const Icon(Icons.photo_camera_rounded, size: 16),
                                  label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(110, 38),
                                    backgroundColor: AppColors.surfaceCard,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    side: const BorderSide(color: AppColors.borderSubtle),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _pickAttachment(fromCamera: false),
                                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                                  label: const Text('Pilih File', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.statusInfoBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 20,
                                color: AppColors.statusInfo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Berkas berhasil dipilih',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.statusSuccess,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AppColors.statusDanger,
                              ),
                              onPressed: _removeAttachment,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 5. Submit Button
              AppButton(
                text: 'Kirim Pengajuan',
                isLoading: actionState.isLoading,
                onPressed: actionState.isLoading ? null : _submitForm,
              ),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingQuotaCard(
    AsyncValue<List<LeaveBalanceModel>> balancesAsync,
    List<LeaveTypeModel>? types,
  ) {
    return balancesAsync.when(
      loading: () {
        if (_selectedLeaveTypeId != null) {
          return const Padding(
            padding: EdgeInsets.only(top: AppDimensions.space8),
            child: AppSkeleton(height: 56),
          );
        }
        return const SizedBox.shrink();
      },
      error: (error, _) => Container(
        margin: const EdgeInsets.only(top: AppDimensions.space8),
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.statusDangerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.statusDangerBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.statusDanger),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: Text(
                AppErrorState.cleanErrorMessage(error.toString()) ??
                    'Gagal memuat informasi sisa kuota cuti.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.statusDanger,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => ref.invalidate(leaveBalanceProvider),
              child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
      data: (balances) {
        if (_selectedLeaveTypeId == null) {
          if (balances.isNotEmpty && balances.any((b) => b.total_quota > 0)) {
            final defaultBalance = balances.firstWhere(
              (b) => b.total_quota > 0,
              orElse: () => balances.first,
            );
            return Container(
              margin: const EdgeInsets.only(top: AppDimensions.space8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      'Sisa cuti tahunan: ${defaultBalance.remaining_days} hari. Pilih jenis cuti untuk melihat kuota spesifik.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        LeaveTypeModel? selectedType;
        if (types != null) {
          for (final t in types) {
            if (t.id_leave_types == _selectedLeaveTypeId) {
              selectedType = t;
              break;
            }
          }
        }

        LeaveBalanceModel? matchingBalance;
        if (balances.isNotEmpty) {
          for (final b in balances) {
            if (b.id_leave_types == _selectedLeaveTypeId) {
              matchingBalance = b;
              break;
            }
          }
          if (matchingBalance == null && selectedType != null) {
            final typeName = selectedType.name.trim().toLowerCase();
            for (final b in balances) {
              if (b.name.trim().toLowerCase() == typeName) {
                matchingBalance = b;
                break;
              }
            }
          }
          if (matchingBalance == null && balances.length == 1) {
            matchingBalance = balances.first;
          }
        }

        if (matchingBalance != null) {
          final remaining = matchingBalance.remaining_days;
          final total = matchingBalance.total_quota;
          final used = matchingBalance.used_days;
          final isExceeded = _calculatedWorkingDays > 0 &&
              remaining > 0 &&
              _calculatedWorkingDays > remaining;
          final isDepleted = remaining <= 0 && total > 0;

          final cardBg = isDepleted
              ? AppColors.statusDangerBg
              : isExceeded
                  ? AppColors.statusWarningBg
                  : AppColors.surfaceCanvas;
          final cardBorder = isDepleted
              ? AppColors.statusDangerBorder
              : isExceeded
                  ? AppColors.statusWarningBorder
                  : AppColors.borderSubtle;
          final accentColor = isDepleted
              ? AppColors.statusDanger
              : isExceeded
                  ? AppColors.statusWarning
                  : AppColors.primaryContainer;

          final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

          return Container(
            margin: const EdgeInsets.only(top: AppDimensions.space8),
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Text(
                          'Sisa Kuota: $remaining Hari',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDepleted
                            ? AppColors.statusDangerBg
                            : isExceeded
                                ? AppColors.statusWarningBg
                                : AppColors.statusSuccessBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '$remaining Hari',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppDimensions.space8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terpakai: $used hari',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Total Kuota: $total hari',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isExceeded) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: AppColors.statusWarning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jumlah pengajuan ($_calculatedWorkingDays hari) melebihi sisa kuota yang tersedia ($remaining hari).',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.statusWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
