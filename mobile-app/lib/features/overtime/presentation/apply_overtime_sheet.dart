import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../provider/overtime_provider.dart';

class ApplyOvertimeSheet extends ConsumerStatefulWidget {
  const ApplyOvertimeSheet({super.key});

  @override
  ConsumerState<ApplyOvertimeSheet> createState() => _ApplyOvertimeSheetState();
}

class _ApplyOvertimeSheetState extends ConsumerState<ApplyOvertimeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  double get _durationHours {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) return 0.0;
    return (endMinutes - startMinutes) / 60.0;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 14)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_durationHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus lebih akhir dari jam mulai lembur.'),
          backgroundColor: AppColors.dangerText,
        ),
      );
      return;
    }

    final success = await ref.read(overtimeActionProvider.notifier).applyOvertime(
          date: _dateFormat.format(_selectedDate),
          startTime: _formatTimeOfDay(_startTime),
          endTime: _formatTimeOfDay(_endTime),
          reason: _reasonController.text.trim(),
        );

    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(overtimeActionProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
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

              // Title bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ajukan Lembur Mandiri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: const Color(0xFF64748B),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Permohonan lembur akan dikirimkan ke atasan / HR untuk disetujui.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),

              if (actionState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppColors.dangerText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          actionState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.dangerText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Tanggal Lembur
              const Text(
                'Tanggal Lembur',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppDimensions.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _displayDateFormat.format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.actionAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Jam Mulai & Jam Selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Mulai',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppDimensions.minTouchTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimeOfDay(_startTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const Icon(Icons.access_time_rounded,
                                    size: 18, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Selesai',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppDimensions.minTouchTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimeOfDay(_endTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const Icon(Icons.access_time_filled_rounded,
                                    size: 18, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Duration Preview Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _durationHours > 0
                      ? AppColors.emeraldTint
                      : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _durationHours > 0
                        ? AppColors.emeraldBorder
                        : AppColors.dangerBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _durationHours > 0
                          ? Icons.hourglass_top_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: _durationHours > 0
                          ? AppColors.actionAccent
                          : AppColors.dangerText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _durationHours > 0
                          ? 'Total Estimasi Durasi: ${_durationHours.toStringAsFixed(1)} Jam'
                          : 'Jam selesai harus lebih besar dari jam mulai.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _durationHours > 0
                            ? AppColors.actionAccent
                            : AppColors.dangerText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alasan Lembur
              const Text(
                'Alasan & Rincian Tugas Lembur',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Contoh: Menyelesaikan rekap laporan bulanan dan stok gudang.',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.actionAccent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Alasan lembur wajib diisi.';
                  }
                  if (val.trim().length < 5) {
                    return 'Alasan lembur minimal 5 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tombol Submit
              AppButton(
                text: 'Kirim Pengajuan Lembur',
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                isLoading: actionState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
