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

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
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
          backgroundColor: AppColors.dangerText,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan tanggal mulai dan selesai.'),
          backgroundColor: AppColors.dangerText,
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
          backgroundColor: AppColors.successText,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final errorMsg = ref.read(leaveActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Gagal mengirim pengajuan cuti.'),
          backgroundColor: AppColors.dangerText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(leaveTypesProvider);
    final balancesAsync = ref.watch(leaveBalanceProvider);
    final actionState = ref.watch(leaveActionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Text('Ajukan Cuti & Izin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Jenis Cuti
              const Text(
                'Jenis Cuti / Izin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              typesAsync.when(
                loading: () => const AppSkeleton(height: 48),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: AppDimensions.cardBorderRadius,
                    border: Border.all(
                      color: AppColors.dangerBorder,
                      width: AppDimensions.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppErrorState.cleanErrorMessage(error.toString()) ?? 'Gagal memuat jenis cuti.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppDimensions.inputBorderRadius,
                        borderSide: const BorderSide(
                          color: AppColors.borderNeutral,
                          width: AppDimensions.borderWidth,
                        ),
                      ),
                    ),
                    items: types.map((LeaveTypeModel type) {
                      final quotaInfo = type.quota_days > 0
                          ? ' (${type.quota_days} hari)'
                          : '';
                      return DropdownMenuItem<int>(
                        value: type.id_leave_types,
                        child: Text('${type.name}$quotaInfo'),
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

              const SizedBox(height: AppDimensions.space20),

              // 2. Tanggal Mulai & Tanggal Selesai
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        InkWell(
                          onTap: _pickStartDate,
                          borderRadius: AppDimensions.inputBorderRadius,
                          child: Container(
                            height: AppDimensions.minTouchTarget,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: AppDimensions.inputBorderRadius,
                              border: Border.all(
                                color: AppColors.hairline,
                                width: AppDimensions.borderWidth,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(width: AppDimensions.space8),
                                Expanded(
                                  child: Text(
                                    _startDate != null
                                        ? _displayDateFormat.format(_startDate!)
                                        : 'Pilih Tanggal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _startDate != null
                                          ? AppColors.inkPrimary
                                          : AppColors.inkMuted,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        InkWell(
                          onTap: _pickEndDate,
                          borderRadius: AppDimensions.inputBorderRadius,
                          child: Container(
                            height: AppDimensions.minTouchTarget,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: AppDimensions.inputBorderRadius,
                              border: Border.all(
                                color: AppColors.hairline,
                                width: AppDimensions.borderWidth,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(width: AppDimensions.space8),
                                Expanded(
                                  child: Text(
                                    _endDate != null
                                        ? _displayDateFormat.format(_endDate!)
                                        : 'Pilih Tanggal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _endDate != null
                                          ? AppColors.inkPrimary
                                          : AppColors.inkMuted,
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

              const SizedBox(height: AppDimensions.space16),

              // 3. Calculation Display: "Durasi: X Hari Kerja"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppDimensions.cardBorderRadius,
                  border: Border.all(
                    color: AppColors.hairline,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: AppColors.actionAccent,
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Text(
                      'Durasi: $_calculatedWorkingDays Hari Kerja',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // 4. Alasan Cuti
              const Text(
                'Alasan Cuti / Izin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextFormField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan pengajuan cuti secara jelas',
                  contentPadding: const EdgeInsets.all(AppDimensions.space16),
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.inputBorderRadius,
                    borderSide: const BorderSide(
                      color: AppColors.borderNeutral,
                      width: AppDimensions.borderWidth,
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

              const SizedBox(height: AppDimensions.space20),

              // 5. Bukti Izin / Surat Dokter
              const Text(
                'Surat Dokter / Bukti Izin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              if (_pickedFile == null)
                InkWell(
                  onTap: _pickAttachment,
                  borderRadius: AppDimensions.buttonBorderRadius,
                  child: Container(
                    height: AppDimensions.minTouchTarget,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: AppDimensions.buttonBorderRadius,
                      border: Border.all(
                        color: AppColors.hairline,
                        width: AppDimensions.borderWidth,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 20,
                          color: AppColors.inkMuted,
                        ),
                        SizedBox(width: AppDimensions.space8),
                        Text(
                          'Pilih Berkas / Foto Lampiran',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppDimensions.cardBorderRadius,
                    border: Border.all(
                      color: AppColors.hairline,
                      width: AppDimensions.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 20,
                        color: AppColors.actionAccent,
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: Text(
                          _pickedFile!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.dangerText,
                        ),
                        onPressed: _removeAttachment,
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppDimensions.space32),

              // 6. Submit Button
              AppButton(
                text: 'Kirim Pengajuan',
                isLoading: actionState.isLoading,
                onPressed: actionState.isLoading ? null : _submitForm,
              ),
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
          color: AppColors.dangerBg,
          borderRadius: AppDimensions.cardBorderRadius,
          border: Border.all(
            color: AppColors.dangerBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.dangerText),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: Text(
                AppErrorState.cleanErrorMessage(error.toString()) ??
                    'Gagal memuat informasi sisa kuota cuti.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.dangerText,
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
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.inkMuted),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      'Sisa cuti tahunan: ${defaultBalance.remaining_days} hari. Pilih jenis cuti untuk melihat kuota spesifik.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
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
              ? AppColors.dangerBg
              : isExceeded
                  ? AppColors.warningBg
                  : const Color(0xFFF8FAFC);
          final cardBorder = isDepleted
              ? AppColors.dangerBorder
              : isExceeded
                  ? AppColors.warningBorder
                  : const Color(0xFFE2E8F0);
          final accentColor = isDepleted
              ? AppColors.dangerText
              : isExceeded
                  ? AppColors.warningText
                  : AppColors.actionAccent;

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
                            color: AppColors.inkPrimary,
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
                            ? const Color(0xFFFEE2E2)
                            : isExceeded
                                ? const Color(0xFFFEF3C7)
                                : AppColors.orangeTint,
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
                      backgroundColor: const Color(0xFFE2E8F0),
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
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Total Kuota: $total hari',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkMuted,
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
                        color: AppColors.warningText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Durasi pengajuan ($_calculatedWorkingDays hari kerja) melebihi sisa kuota ($remaining hari).',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warningText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isDepleted) ...[
                  const SizedBox(height: AppDimensions.space8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: AppColors.dangerText,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kuota untuk jenis cuti ini telah habis.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.dangerText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_calculatedWorkingDays > 0 && remaining >= _calculatedWorkingDays) ...[
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    'Estimasi sisa setelah pengajuan: ${remaining - _calculatedWorkingDays} hari',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        if (selectedType != null && selectedType.quota_days > 0) {
          return Container(
            margin: const EdgeInsets.only(top: AppDimensions.space8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.inkMuted),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    'Batas kuota maksimal: ${selectedType.quota_days} hari.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: AppDimensions.space8),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
            vertical: AppDimensions.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.actionAccent),
              SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  'Jenis pengajuan ini tidak mengurangi kuota cuti tahunan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
