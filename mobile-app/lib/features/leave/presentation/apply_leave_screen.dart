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
                                color: AppColors.borderNeutral,
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
                                color: AppColors.borderNeutral,
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
                    color: AppColors.borderNeutral,
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
                        color: AppColors.borderNeutral,
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
                      color: AppColors.borderNeutral,
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
}
