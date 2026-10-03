import 'package:flutter/material.dart';
import 'payroll_history_screen.dart';

export 'payroll_history_screen.dart';
export 'payroll_slip_detail_screen.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PayrollHistoryScreen();
  }
}
