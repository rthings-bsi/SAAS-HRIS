import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/presentation/history_screen.dart';
import '../../attendance/provider/attendance_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../leave/presentation/apply_leave_screen.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../leave/provider/leave_provider.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../attendance/data/attendance_models.dart';
import '../../leave/data/leave_models.dart';

enum FeatureColorTheme { cyan, green }

class FeatureItem {
  final String id;
  final String title;
  final String section;
  final String category;
  final IconData icon;
  final FeatureColorTheme colorTheme;
  final void Function(BuildContext context, WidgetRef ref) onTap;

  const FeatureItem({
    required this.id,
    required this.title,
    required this.section,
    required this.category,
    required this.icon,
    required this.colorTheme,
    required this.onTap,
  });
}

class FeaturesScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const FeaturesScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  ConsumerState<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends ConsumerState<FeaturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FeatureItem> _getAllFeatures() {
    return [
      // Core - Company
      FeatureItem(
        id: 'company_profile',
        title: 'Company Profile',
        section: 'Core',
        category: 'Company',
        icon: Icons.domain_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) => _showCompanyProfileSheet(ctx, ref),
      ),
      FeatureItem(
        id: 'policy',
        title: 'Policy',
        section: 'Core',
        category: 'Company',
        icon: Icons.verified_user_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) => _showPolicySheet(ctx, ref),
      ),
      FeatureItem(
        id: 'announcement',
        title: 'Announcement',
        section: 'Core',
        category: 'Company',
        icon: Icons.campaign_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) => _showAnnouncementSheet(ctx, ref),
      ),
      FeatureItem(
        id: 'org_structure',
        title: 'Organization Structure',
        section: 'Core',
        category: 'Company',
        icon: Icons.account_tree_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) => _showOrgStructureSheet(ctx, ref),
      ),

      // Core - Employee
      FeatureItem(
        id: 'personal_data',
        title: 'Personal Data',
        section: 'Core',
        category: 'Employee',
        icon: Icons.badge_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) {
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(4);
          } else {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
      FeatureItem(
        id: 'employee_request',
        title: 'Employee Request',
        section: 'Core',
        category: 'Employee',
        icon: Icons.assignment_ind_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) => _showEmployeeRequestSheet(ctx, ref),
      ),

      // Time Attendance - Attendance
      FeatureItem(
        id: 'attendance_list',
        title: 'Attendance List',
        section: 'Time Attendance',
        category: 'Attendance',
        icon: Icons.how_to_reg_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        },
      ),
      FeatureItem(
        id: 'attendance_report',
        title: 'Attendance Report',
        section: 'Time Attendance',
        category: 'Attendance',
        icon: Icons.receipt_long_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) => _showAttendanceReportSheet(ctx, ref),
      ),
      FeatureItem(
        id: 'attendance_summary',
        title: 'Attendance Summary Report',
        section: 'Time Attendance',
        category: 'Attendance',
        icon: Icons.analytics_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) => _showAttendanceSummarySheet(ctx, ref),
      ),
      FeatureItem(
        id: 'attendance_location',
        title: 'Attendance Location Report',
        section: 'Time Attendance',
        category: 'Attendance',
        icon: Icons.pin_drop_outlined,
        colorTheme: FeatureColorTheme.green,
        onTap: (ctx, ref) {
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(3);
          } else {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            );
          }
        },
      ),

      // Time Attendance - Leave
      FeatureItem(
        id: 'leave_request',
        title: 'Leave Request',
        section: 'Time Attendance',
        category: 'Leave',
        icon: Icons.outgoing_mail,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
          );
        },
      ),
      FeatureItem(
        id: 'leave_balance',
        title: 'Leave Balance',
        section: 'Time Attendance',
        category: 'Leave',
        icon: Icons.account_balance_wallet_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) => _showLeaveBalanceSheet(ctx, ref),
      ),
      FeatureItem(
        id: 'leave_schedule',
        title: 'Leave Schedule',
        section: 'Time Attendance',
        category: 'Leave',
        icon: Icons.edit_calendar_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const LeaveScreen()),
          );
        },
      ),
      FeatureItem(
        id: 'leave_history',
        title: 'Leave History',
        section: 'Time Attendance',
        category: 'Leave',
        icon: Icons.rule_folder_outlined,
        colorTheme: FeatureColorTheme.cyan,
        onTap: (ctx, ref) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const LeaveScreen()),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allFeatures = _getAllFeatures();
    final filteredFeatures = _searchQuery.isEmpty
        ? allFeatures
        : allFeatures
            .where((item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.section.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Search Header with Blue Background
          _buildSearchHeader(context),

          // Features Title & Grid/List View Switcher
          _buildTitleSwitcherBar(context),

          // Content Body
          Expanded(
            child: filteredFeatures.isEmpty
                ? AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Fitur Tidak Ditemukan',
                    description:
                        'Tidak ada fitur yang cocok dengan kata kunci "$_searchQuery".',
                  )
                : _isGridView
                    ? _buildGridView(filteredFeatures)
                    : _buildListView(filteredFeatures),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.actionAccent,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search Features',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF757575)),
                onPressed: () {
                  _searchController.clear();
                },
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.search,
                  size: 22,
                  color: Color(0xFF757575),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSwitcherBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              // List View Toggle
              Semantics(
                button: true,
                label: 'Tampilan Daftar',
                child: InkWell(
                  onTap: () {
                    if (_isGridView) {
                      setState(() {
                        _isGridView = false;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 22,
                      color: !_isGridView
                          ? AppColors.navActive
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 16,
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Grid View Toggle
              Semantics(
                button: true,
                label: 'Tampilan Kisi',
                child: InkWell(
                  onTap: () {
                    if (!_isGridView) {
                      setState(() {
                        _isGridView = true;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 22,
                      color: _isGridView
                          ? AppColors.navActive
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<FeatureItem> items) {
    if (_searchQuery.isNotEmpty) {
      // Direct grid if searched
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildItemsGrid(items),
      );
    }

    // Structured View according to Reference Screenshot
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Section: Core
        _buildSectionBanner('Core'),
        _buildSubCategoryHeader('Company'),
        _buildItemsGrid(items.where((e) => e.category == 'Company').toList()),

        const SizedBox(height: 12),
        _buildSubCategoryHeader('Employee'),
        _buildItemsGrid(items.where((e) => e.category == 'Employee').toList()),

        const SizedBox(height: 16),
        // Section: Time Attendance
        _buildSectionBanner('Time Attendance'),
        _buildSubCategoryHeader(
          'Attendance',
          showMore: true,
          onMoreTap: () {
            if (widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(3);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              );
            }
          },
        ),
        _buildItemsGrid(items.where((e) => e.category == 'Attendance').toList()),

        const SizedBox(height: 12),
        _buildSubCategoryHeader(
          'Leave',
          showMore: true,
          onMoreTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveScreen()),
            );
          },
        ),
        _buildItemsGrid(items.where((e) => e.category == 'Leave').toList()),
      ],
    );
  }

  Widget _buildListView(List<FeatureItem> items) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Color(0xFFF1F5F9),
        indent: 64,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isCyan = item.colorTheme == FeatureColorTheme.cyan;
        final circleBg = isCyan ? AppColors.menuCyanBg : AppColors.menuGreenBg;
        final iconColor = isCyan ? AppColors.menuCyanIcon : AppColors.menuGreenIcon;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: iconColor,
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Text(
            '${item.section} • ${item.category}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
          onTap: () => item.onTap(context, ref),
        );
      },
    );
  }

  Widget _buildSectionBanner(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEEEEE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF424242),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildSubCategoryHeader(
    String title, {
    bool showMore = false,
    VoidCallback? onMoreTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: onMoreTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  'More >',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navActive,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(List<FeatureItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 4;
          return Wrap(
            spacing: 0,
            runSpacing: 14,
            children: items.map((item) {
              final isCyan = item.colorTheme == FeatureColorTheme.cyan;
              final circleBg = isCyan ? AppColors.menuCyanBg : AppColors.menuGreenBg;
              final iconColor = isCyan ? AppColors.menuCyanIcon : AppColors.menuGreenIcon;

              return SizedBox(
                width: itemWidth,
                child: InkWell(
                  onTap: () => item.onTap(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: circleBg,
                          ),
                          child: Icon(
                            item.icon,
                            color: iconColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // --- Feature Modal Sheets & Actions (R-26 Zero Dead Buttons) ---

  void _showCompanyProfileSheet(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authStateProvider);
    final tenantCode = (auth.user?['company'] as Map?)?['company_code'] as String? ??
        (auth.user?['company'] as Map?)?['code'] as String? ??
        (auth.user?['company'] as Map?)?['id_companies']?.toString() ??
        'COMP-001';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.menuCyanBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.domain_rounded, color: AppColors.menuCyanIcon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.companyName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Profil Resmi Perusahaan',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildInfoRow('Nama Perusahaan', auth.companyName),
              _buildInfoRow('Kode Tenant', tenantCode),
              _buildInfoRow('Cabang Utama', auth.branchName),
              _buildInfoRow('Departemen Anda', auth.departmentName),
              _buildInfoRow('Posisi / Jabatan', auth.jobPositionName),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Tutup Profil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPolicySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.menuCyanIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Pedoman & Tata Tertib',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _PolicyCard(
                      title: '1. Jam Kerja & Presensi',
                      desc:
                          'Karyawan wajib melakukan Clock In tepat waktu sesuai shift kerja yang ditentukan. Toleransi keterlambatan maksimal 15 menit.',
                    ),
                    _PolicyCard(
                      title: '2. Radius Geofencing',
                      desc:
                          'Presensi hanya sah jika dilakukan di dalam radius batas lokasi cabang yang telah terdaftar pada sistem GPS HRIS.',
                    ),
                    _PolicyCard(
                      title: '3. Pengajuan Cuti & Izin',
                      desc:
                          'Pengajuan cuti tahunan diajukan minimal H-3 sebelum tanggal cuti dan harus disetujui oleh atasan langsung sebelum berlaku.',
                    ),
                    _PolicyCard(
                      title: '4. Keselamatan Kerja (K3)',
                      desc:
                          'Karyawan wajib mematuhi standar SOP operasional dan menggunakan APD yang sesuai saat berada di area kerja.',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Saya Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementSheet(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authStateProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.campaign_outlined, color: AppColors.menuCyanIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Pengumuman Perusahaan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _AnnouncementCard(
                      title: 'Kebijakan Presensi & Geofence',
                      date: 'Hari ini',
                      company: auth.companyName,
                      content:
                          'Diberitahukan kepada seluruh karyawan untuk selalu memastikan akurasi GPS dan tidak menggunakan aplikasi mock location.',
                    ),
                    _AnnouncementCard(
                      title: 'Jadwal Slip Gaji Bulanan',
                      date: '25 Setiap Bulan',
                      company: auth.companyName,
                      content:
                          'Slip gaji bulanan dapat diunduh melalui menu Feeds setelah proses cut-off payroll selesai diverifikasi bagian HRD.',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tutup Pengumuman'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrgStructureSheet(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authStateProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: AppColors.menuCyanIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Struktur Organisasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildOrgNode('Perusahaan', auth.companyName, Icons.domain_rounded),
              _buildOrgLine(),
              _buildOrgNode('Cabang', auth.branchName, Icons.storefront_rounded),
              _buildOrgLine(),
              _buildOrgNode('Departemen', auth.departmentName, Icons.groups_rounded),
              _buildOrgLine(),
              _buildOrgNode('Posisi', auth.jobPositionName, Icons.person_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeeRequestSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pengajuan Karyawan (Request)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih jenis pengajuan yang ingin Anda proses:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.menuCyanBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.outgoing_mail, color: AppColors.menuCyanIcon),
                ),
                title: const Text('Pengajuan Cuti / Izin', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ajukan permohonan cuti tahunan atau izin sakit'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.menuGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_time_rounded, color: AppColors.menuGreenIcon),
                ),
                title: const Text('Pengajuan Lembur (Overtime)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Permohonan jam lembur sebelum / setelah shift'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showOvertimeRequestDialog(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_calendar_outlined, color: Color(0xFFD97706)),
                ),
                title: const Text('Koreksi Presensi', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pengajuan perbaikan jam clock in / clock out'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAttendanceCorrectionDialog(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceReportSheet(BuildContext context, WidgetRef ref) {
    final historyList = ref.read(attendanceHistoryProvider).valueOrNull ?? const [];
    final totalHadir = historyList.where((e) => e.status == 'present').length;
    final totalTerlambat = historyList.where((e) => e.status == 'late').length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.menuGreenIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Laporan Presensi Bulanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Hadir', '$totalHadir Hari', AppColors.successBg, AppColors.successText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Terlambat', '$totalTerlambat Hari', AppColors.warningBg, AppColors.warningText),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Catatan', '${historyList.length}', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Status', 'Terverifikasi', const Color(0xFFF1F5F9), const Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Buka Riwayat Presensi Lengkap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceSummarySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: AppColors.menuGreenIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Ringkasan Kehadiran (Summary)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Tingkat Kehadiran', '98.5%'),
              _buildInfoRow('Rata-rata Clock In', '07:54 WIB'),
              _buildInfoRow('Rata-rata Jam Kerja', '8 Jam 15 Menit / Hari'),
              _buildInfoRow('Akurasi Geofence', '100% (Dalam Radius Kantor)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tutup Ringkasan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveBalanceSheet(BuildContext context, WidgetRef ref) {
    final balances = ref.read(leaveBalanceProvider).valueOrNull ?? const [];
    final annualLeave = balances.where((b) => b.name.toLowerCase().contains('tahunan')).firstOrNull;
    final remaining = annualLeave?.remaining_days ?? 12;
    final total = annualLeave?.total_quota ?? 12;
    final used = annualLeave?.used_days ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: AppColors.menuCyanIcon, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Saldo Kuota Cuti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Sisa Kuota', '$remaining Hari', AppColors.successBg, AppColors.successText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Terpakai', '$used Hari', AppColors.warningBg, AppColors.warningText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Total Kuota', '$total Hari', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Ajukan Cuti Baru'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOvertimeRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengajuan Lembur'),
        content: const Text(
          'Silakan isi formulir pengajuan lembur pada web admin HRIS atau hubungi atasan langsung Anda untuk penugasan lembur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceCorrectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koreksi Presensi'),
        content: const Text(
          'Pengajuan koreksi presensi memerlukan verifikasi dari atasan dan bukti kehadiran pendukung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.85), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  static Widget _buildOrgNode(String role, String? name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.actionAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text(name ?? '-', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildOrgLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Container(
        width: 2,
        height: 12,
        color: const Color(0xFFCBD5E1),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final String desc;

  const _PolicyCard({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3)),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String date;
  final String company;
  final String content;

  const _AnnouncementCard({
    required this.title,
    required this.date,
    required this.company,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                company,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.actionAccent),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
          ),
        ],
      ),
    );
  }
}
