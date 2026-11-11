import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../data/leave_models.dart';

class LeaveStatusBadge extends StatelessWidget {
  final LeaveStatus status;

  const LeaveStatusBadge({super.key, required this.status});

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

class LeaveApprovalDialog extends StatefulWidget {
  final LeaveRequestModel item;
  final bool isApprove;

  const LeaveApprovalDialog({
    super.key,
    required this.item,
    required this.isApprove,
  });

  @override
  State<LeaveApprovalDialog> createState() => _LeaveApprovalDialogState();
}

class _LeaveApprovalDialogState extends State<LeaveApprovalDialog> {
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
    final empName =
        (widget.item.employee_name != null && widget.item.employee_name!.isNotEmpty)
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
                widget.isApprove ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isApprove ? 'Setujui Cuti Staf?' : 'Tolak Cuti Staf?',
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
                  ? 'Anda akan menyetujui pengajuan ${widget.item.leave_type_name} dari $empName selama ${widget.item.total_days} hari (${widget.item.start_date} s/d ${widget.item.end_date}).'
                  : 'Anda akan menolak pengajuan ${widget.item.leave_type_name} dari $empName (${widget.item.start_date} s/d ${widget.item.end_date}).',
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
                    : 'Tuliskan alasan penolakan cuti...',
                errorText: _validationError,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderNeutral),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderNeutral),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.actionAccent,
                    width: 1.5,
                  ),
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
                widget.isApprove ? AppColors.actionAccent : const Color(0xFFB91C1C),
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
