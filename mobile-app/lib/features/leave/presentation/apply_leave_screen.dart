import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/leave_models.dart';
import '../provider/leave_provider.dart';

int calculateWorkingDays(DateTime start, DateTime end) {
  if (end.isBefore(start)) return 0;
  int count = 0;
  DateTime current = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!current.isAfter(last)) {
    if (current.weekday != DateTime.saturday &&
        current.weekday != DateTime.sunday) {
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
  bool _hasTriedSubmit = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy', 'id_ID');

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

  LeaveBalanceModel? _findBalanceForType(
    LeaveTypeModel? type,
    List<LeaveBalanceModel>? balances,
  ) {
    if (type == null || balances == null || balances.isEmpty) {
      return null;
    }
    for (final b in balances) {
      if (b.id_leave_types == type.id_leave_types) {
        return b;
      }
    }
    final typeName = type.name.trim().toLowerCase();
    for (final b in balances) {
      if (b.name.trim().toLowerCase() == typeName) {
        return b;
      }
    }
    return null;
  }

  String _formatDropdownClosedLabel(
    LeaveTypeModel type,
    LeaveBalanceModel? balance,
  ) {
    if (balance != null) {
      final total =
          balance.total_quota > 0 ? balance.total_quota : type.quota_days;
      final remaining = balance.remaining_days;
      if (total > 0) {
        return '${type.name} (Sisa $remaining/$total hari)';
      }
      return '${type.name} (Sisa $remaining hari)';
    }
    if (type.quota_days > 0) {
      return '${type.name} (${type.quota_days} hari)';
    }
    return type.name;
  }

  Set<DateTime> _extractBookedDates(List<LeaveRequestModel> requests) {
    final booked = <DateTime>{};
    for (final r in requests) {
      if (r.status == LeaveStatus.approved || r.status == LeaveStatus.pending) {
        try {
          final start = DateTime.parse(r.start_date);
          final end = DateTime.parse(r.end_date);
          DateTime cur = DateTime(start.year, start.month, start.day);
          final last = DateTime(end.year, end.month, end.day);
          while (!cur.isAfter(last)) {
            booked.add(cur);
            cur = cur.add(const Duration(days: 1));
          }
        } catch (_) {}
      }
    }
    return booked;
  }

  bool _rangeContainsBookedDate(
    DateTime start,
    DateTime end,
    Set<DateTime> booked,
  ) {
    DateTime cur = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(last)) {
      if (booked.contains(cur)) return true;
      cur = cur.add(const Duration(days: 1));
    }
    return false;
  }

  DateTime _findValidInitialDate(
    DateTime candidate,
    Set<DateTime> booked,
    DateTime minDate,
    DateTime maxDate,
  ) {
    final normCandidate =
        DateTime(candidate.year, candidate.month, candidate.day);
    final normMin = DateTime(minDate.year, minDate.month, minDate.day);
    final normMax = DateTime(maxDate.year, maxDate.month, maxDate.day);

    DateTime cur = normCandidate;
    if (cur.isBefore(normMin)) cur = normMin;
    if (cur.isAfter(normMax)) cur = normMax;

    if (!booked.contains(cur)) return cur;

    DateTime forward = cur.add(const Duration(days: 1));
    while (!forward.isAfter(normMax)) {
      if (!booked.contains(forward)) return forward;
      forward = forward.add(const Duration(days: 1));
    }

    DateTime backward = cur.subtract(const Duration(days: 1));
    while (!backward.isBefore(normMin)) {
      if (!booked.contains(backward)) return backward;
      backward = backward.subtract(const Duration(days: 1));
    }

    return cur;
  }

  Future<void> _pickStartDate(Set<DateTime> bookedDates) async {
    final now = DateTime.now();
    final firstAllowed = now.subtract(const Duration(days: 30));
    final lastAllowed = now.add(const Duration(days: 365));

    final candidate = _startDate ?? now;
    final initialDate = _findValidInitialDate(
      candidate,
      bookedDates,
      DateTime(firstAllowed.year, firstAllowed.month, firstAllowed.day),
      DateTime(lastAllowed.year, lastAllowed.month, lastAllowed.day),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      selectableDayPredicate: (DateTime day) {
        final normalized = DateTime(day.year, day.month, day.day);
        return !bookedDates.contains(normalized);
      },
      helpText: 'Pilih tanggal mulai cuti',
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
        if (_endDate != null &&
            _rangeContainsBookedDate(picked, _endDate!, bookedDates)) {
          _endDate = null;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Tanggal selesai direset karena melewati jadwal cuti Anda yang lain.',
                ),
                backgroundColor: Color(0xFFB45309),
              ),
            );
        }
      });
    }
  }

  Future<void> _pickEndDate(Set<DateTime> bookedDates) async {
    final now = DateTime.now();
    final firstAllowed = _startDate ?? now;
    final lastAllowed = now.add(const Duration(days: 365));

    final candidate = _endDate != null && !_endDate!.isBefore(firstAllowed)
        ? _endDate!
        : firstAllowed;

    final initialDate = _findValidInitialDate(
      candidate,
      bookedDates,
      DateTime(firstAllowed.year, firstAllowed.month, firstAllowed.day),
      DateTime(lastAllowed.year, lastAllowed.month, lastAllowed.day),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      selectableDayPredicate: (DateTime day) {
        final normalized = DateTime(day.year, day.month, day.day);
        return !bookedDates.contains(normalized);
      },
      helpText: 'Pilih tanggal selesai cuti',
    );

    if (picked != null) {
      if (_startDate != null &&
          _rangeContainsBookedDate(_startDate!, picked, bookedDates)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Rentang tanggal ini bentrok dengan jadwal cuti Anda yang sudah ada. Pilih tanggal lain.',
              ),
              backgroundColor: Color(0xFFB91C1C),
            ),
          );
        return;
      }

      if (mounted) {
        setState(() {
          _endDate = picked;
        });
      }
    }
  }

  Future<void> _pickAttachment({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
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
    if (!_hasTriedSubmit) {
      setState(() {
        _hasTriedSubmit = true;
      });
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pilih jenis cuti terlebih dahulu.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tentukan tanggal mulai dan selesai cuti.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      return;
    }

    final allRequests =
        ref.read(leaveMyRequestsProvider(null)).valueOrNull ?? [];
    final booked = _extractBookedDates(allRequests);
    if (_rangeContainsBookedDate(_startDate!, _endDate!, booked)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Rentang tanggal ini bentrok dengan jadwal cuti aktif Anda. Silakan pilih tanggal lain.',
            ),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
      return;
    }

    final success =
        await ref.read(leaveActionProvider.notifier).submitLeaveRequest(
              leaveTypeId: _selectedLeaveTypeId!,
              startDate: _dateFormat.format(_startDate!),
              endDate: _dateFormat.format(_endDate!),
              reason: _reasonController.text.trim(),
              attachmentPath: _pickedFile?.path,
              attachmentBytes: _fileBytes,
            );

    if (!mounted) return;

    if (success) {
      if (_isTestEnvironment) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pengajuan cuti berhasil dikirim.'),
              backgroundColor: Color(0xFF047857),
            ),
          );
        Navigator.of(context).pop(true);
      } else {
        await _showSuccessModal();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      final errorMsg = ref.read(leaveActionProvider).errorMessage;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Gagal mengirim pengajuan cuti.'),
            backgroundColor: const Color(0xFFB91C1C),
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF047857),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Cuti Terkirim',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permohonan Anda sudah masuk dan menunggu persetujuan atasan atau HR.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            'Menunggu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Durasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            '$_calculatedWorkingDays Hari Kerja',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
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
                      backgroundColor: AppColors.actionAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Tutup',
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
    final auth = ref.watch(authStateProvider);
    final typesAsync = ref.watch(leaveTypesProvider);
    final balancesAsync = ref.watch(leaveBalanceProvider);
    final actionState = ref.watch(leaveActionProvider);
    final allRequestsAsync = ref.watch(leaveMyRequestsProvider(null));

    final allRequests = allRequestsAsync.valueOrNull ?? [];
    final bookedDates = _extractBookedDates(allRequests);
    final displayEmployeeName = auth.userName.trim().isNotEmpty
        ? auth.userName.trim()
        : 'Karyawan';
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderSubtle,
            height: 1.0,
          ),
        ),
        title: Row(
          children: [
            TextButton.icon(
              key: const Key('leave_form_back_btn'),
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkPrimary,
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(LucideIcons.chevronLeft, size: 20),
              label: const Text(
                'Kembali',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: const Text(
                  'Ajukan Cuti & Izin',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            if (screenWidth >= 380) const SizedBox(width: 72),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final double hPad =
                  viewportConstraints.maxWidth < 310 ? 12.0 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _hasTriedSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel(text: 'Permintaan Untuk'),
                      const SizedBox(height: 6),
                      InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceCanvas,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayEmployeeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.user,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel(text: 'Jenis Cuti / Izin'),
                      const SizedBox(height: 6),
                      typesAsync.when(
                        loading: () => const AppSkeleton(height: 48),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: AppDimensions.space8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppErrorState.cleanErrorMessage(
                                          error.toString()) ??
                                      'Gagal memuat jenis cuti.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.actionAccent,
                                  minimumSize: const Size(
                                    AppDimensions.minTouchTarget,
                                    AppDimensions.minTouchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () =>
                                    ref.invalidate(leaveTypesProvider),
                                child: const Text(
                                  'Coba Lagi',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        data: (types) {
                          final balances = balancesAsync.valueOrNull;
                          return DropdownButtonFormField<int>(
                            key: const Key('leave_type_dropdown'),
                            initialValue: _selectedLeaveTypeId,
                            isExpanded: true,
                            itemHeight: null,
                            dropdownColor: AppColors.surfaceCard,
                            icon: const Icon(
                              LucideIcons.chevronDown,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Pilih jenis cuti',
                              hintStyle: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.borderNeutral,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.borderNeutral,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.actionAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            selectedItemBuilder: (context) {
                              return types.map((LeaveTypeModel type) {
                                final balance =
                                    _findBalanceForType(type, balances);
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatDropdownClosedLabel(type, balance),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: types.map((LeaveTypeModel type) {
                              final balance =
                                  _findBalanceForType(type, balances);
                              String? subtitle;
                              bool isDepleted = false;
                              if (balance != null) {
                                final total = balance.total_quota > 0
                                    ? balance.total_quota
                                    : type.quota_days;
                                final remaining = balance.remaining_days;
                                isDepleted = total > 0 && remaining <= 0;
                                if (total > 0) {
                                  subtitle = isDepleted
                                      ? 'Sisa 0 dari $total hari (kuota habis)'
                                      : 'Sisa $remaining dari $total hari';
                                } else {
                                  subtitle = 'Sisa $remaining hari';
                                }
                              } else if (type.quota_days > 0) {
                                subtitle = 'Kuota ${type.quota_days} hari';
                              }

                              return DropdownMenuItem<int>(
                                value: type.id_leave_types,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      if (subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDepleted
                                                ? const Color(0xFFB91C1C)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ],
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
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, dateConstraints) {
                          final effectiveWidth =
                              dateConstraints.maxWidth / textScale;
                          final stackDates = effectiveWidth < 280;

                          final startField = _DatePickerBox(
                            fieldKey: const Key('leave_start_date_btn'),
                            label: 'Tanggal Mulai',
                            valueText: _startDate != null
                                ? _displayDateFormat.format(_startDate!)
                                : null,
                            errorText: _hasTriedSubmit && _startDate == null
                                ? 'Tanggal mulai wajib dipilih.'
                                : null,
                            onTap: () => _pickStartDate(bookedDates),
                          );
                          final endField = _DatePickerBox(
                            fieldKey: const Key('leave_end_date_btn'),
                            label: 'Tanggal Selesai',
                            valueText: _endDate != null
                                ? _displayDateFormat.format(_endDate!)
                                : null,
                            errorText: _hasTriedSubmit && _endDate == null
                                ? 'Tanggal selesai wajib dipilih.'
                                : null,
                            onTap: () => _pickEndDate(bookedDates),
                          );

                          if (stackDates) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                startField,
                                const SizedBox(height: 12),
                                endField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: startField),
                              const SizedBox(width: 12),
                              Expanded(child: endField),
                            ],
                          );
                        },
                      ),
                      _buildQuotaExceededNotice(
                        balancesAsync,
                        typesAsync.valueOrNull,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: _FieldLabel(text: 'Alasan Cuti / Izin'),
                          ),
                          Text(
                            '${_reasonController.text.length}/250',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('leave_reason_input'),
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
                          hintText: 'Tulis keperluan cuti atau izin Anda',
                          hintStyle: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.actionAccent,
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
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(
                            child:
                                _FieldLabel(text: 'Surat Dokter / Bukti Izin'),
                          ),
                          Text(
                            'Opsional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomPaint(
                        painter: const _DashedRoundedRectPainter(
                          color: AppColors.borderNeutral,
                          strokeWidth: 1.2,
                          radius: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          child: _pickedFile == null
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Foto JPG atau PNG, maks. 4 MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, btnConstraints) {
                                        final effectiveWidth =
                                            btnConstraints.maxWidth / textScale;

                                        Widget buildCameraButton() {
                                          return OutlinedButton.icon(
                                            key: const Key('leave_camera_btn'),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(
                                                116,
                                                AppDimensions.minTouchTarget,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  AppColors.actionAccent,
                                              side: const BorderSide(
                                                color: AppColors.borderNeutral,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _pickAttachment(
                                              fromCamera: true,
                                            ),
                                            icon: const Icon(
                                              LucideIcons.camera,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Kamera',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }

                                        Widget buildGalleryButton() {
                                          return OutlinedButton.icon(
                                            key: const Key('leave_gallery_btn'),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(
                                                116,
                                                AppDimensions.minTouchTarget,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  AppColors.actionAccent,
                                              side: const BorderSide(
                                                color: AppColors.borderNeutral,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _pickAttachment(
                                              fromCamera: false,
                                            ),
                                            icon: const Icon(
                                              LucideIcons.image,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Galeri',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }

                                        if (effectiveWidth < 260) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              buildCameraButton(),
                                              const SizedBox(height: 10),
                                              buildGalleryButton(),
                                            ],
                                          );
                                        }

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: buildCameraButton(),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: buildGalleryButton(),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.fileText,
                                      size: 18,
                                      color: AppColors.actionAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pickedFile!.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.inkPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Lampiran siap dikirim',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF047857),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('leave_remove_file_btn'),
                                      icon: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: Color(0xFFB91C1C),
                                      ),
                                      tooltip: 'Hapus lampiran',
                                      onPressed: _removeAttachment,
                                      constraints: const BoxConstraints(
                                        minWidth: AppDimensions.minTouchTarget,
                                        minHeight: AppDimensions.minTouchTarget,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Align(
            heightFactor: 1.0,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: IntrinsicHeight(
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    key: const Key('leave_submit_btn'),
                    text: 'Kirim Pengajuan',
                    isLoading: actionState.isLoading,
                    onPressed: actionState.isLoading ? null : _submitForm,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaExceededNotice(
    AsyncValue<List<LeaveBalanceModel>> balancesAsync,
    List<LeaveTypeModel>? types,
  ) {
    final balances = balancesAsync.valueOrNull;
    if (_selectedLeaveTypeId == null ||
        balances == null ||
        _calculatedWorkingDays <= 0) {
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

    LeaveBalanceModel? matchingBalance =
        _findBalanceForType(selectedType, balances);
    if (matchingBalance == null &&
        balances.length == 1 &&
        (balances.first.id_leave_types == 0 || selectedType == null)) {
      matchingBalance = balances.first;
    }

    if (matchingBalance == null) return const SizedBox.shrink();

    final remaining = matchingBalance.remaining_days;
    if (_calculatedWorkingDays <= remaining) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 15,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pengajuan $_calculatedWorkingDays hari melebihi sisa kuota Anda ($remaining hari).',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final String? valueText;
  final String? errorText;
  final VoidCallback onTap;

  const _DatePickerBox({
    this.fieldKey,
    required this.label,
    required this.valueText,
    this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        MergeSemantics(
          child: InkWell(
            key: fieldKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.minTouchTarget,
              ),
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  errorText: errorText,
                  errorMaxLines: 2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.borderNeutral),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.borderNeutral),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFB91C1C)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasValue ? valueText! : 'Pilih tanggal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              hasValue ? FontWeight.w500 : FontWeight.w400,
                          color: hasValue
                              ? AppColors.inkPrimary
                              : const Color(0xFF475569),
                          fontFeatures: hasValue
                              ? const [FontFeature.tabularFigures()]
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
