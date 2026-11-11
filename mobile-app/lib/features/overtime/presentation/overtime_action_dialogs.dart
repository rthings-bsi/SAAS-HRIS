import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../data/overtime_models.dart';

class OvertimeStatusBadge extends StatelessWidget {
  final OvertimeStatus status;

  const OvertimeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

class CancelOvertimeDialog extends StatefulWidget {
  final OvertimeRequestModel item;

  const CancelOvertimeDialog({super.key, required this.item});

  @override
  State<CancelOvertimeDialog> createState() => _CancelOvertimeDialogState();
}

class _CancelOvertimeDialogState extends State<CancelOvertimeDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startHm =
        OvertimeRequestModel.trimHm(widget.item.start_time) ?? widget.item.start_time;
    final endHm =
        OvertimeRequestModel.trimHm(widget.item.end_time) ?? widget.item.end_time;

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(LucideIcons.circleX, color: AppColors.dangerText, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Batalkan Lembur?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin membatalkan pengajuan lembur tanggal ${widget.item.date} ($startHm - $endHm)?',
              style: const TextStyle(fontSize: 13, color: AppColors.inkPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Perhatian: Pengajuan lembur yang dibatalkan tidak dapat dikembalikan statusnya.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Alasan Pembatalan (Opsional):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Misal: Pekerjaan selesai lebih awal...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Kembali',
            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerText,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final text = _reasonController.text.trim();
            Navigator.of(context).pop(text.isNotEmpty ? text : '');
          },
          child: const Text(
            'Ya, Batalkan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class OvertimeApprovalDialog extends StatefulWidget {
  final OvertimeRequestModel item;
  final bool isApprove;

  const OvertimeApprovalDialog({
    super.key,
    required this.item,
    required this.isApprove,
  });

  @override
  State<OvertimeApprovalDialog> createState() => _OvertimeApprovalDialogState();
}

class _OvertimeApprovalDialogState extends State<OvertimeApprovalDialog> {
  late final TextEditingController _notesController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empName = (widget.item.employee_name != null &&
            widget.item.employee_name!.isNotEmpty)
        ? widget.item.employee_name!
        : 'Karyawan';

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            widget.isApprove ? LucideIcons.circleCheck : LucideIcons.circleX,
            color:
                widget.isApprove ? AppColors.successText : AppColors.dangerText,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isApprove ? 'Setujui Lembur Staf?' : 'Tolak Lembur Staf?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isApprove
                  ? 'Anda akan menyetujui lembur dari $empName pada tanggal ${widget.item.date} (${widget.item.formattedDuration}).'
                  : 'Anda akan menolak pengajuan lembur dari $empName pada tanggal ${widget.item.date}.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isApprove
                  ? 'Catatan Persetujuan (Opsional):'
                  : 'Alasan Penolakan (Wajib Diisi):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() {
                    _validationError = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: widget.isApprove
                    ? 'Tambahkan catatan jika diperlukan...'
                    : 'Tuliskan alasan penolakan lembur...',
                errorText: _validationError,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Batal',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.isApprove ? AppColors.actionAccent : AppColors.dangerText,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            final text = _notesController.text.trim();
            if (!widget.isApprove && text.isEmpty) {
              setState(() {
                _validationError = 'Alasan penolakan wajib diisi.';
              });
              return;
            }
            Navigator.of(context).pop(text);
          },
          child: Text(
            widget.isApprove ? 'Ya, Setujui' : 'Tolak Pengajuan',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
