import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Colors based on the UI provided
class AdminColors {
  static const sidebarBg = Color(0xFF0F172A);
  static const sidebarItemActive = Color(0xFF2563EB);
  static const sidebarItemHover = Color(0xFF1E293B);
  static const sidebarText = Color(0xFF94A3B8);
  static const sidebarTextActive = Colors.white;
  
  static const bg = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  
  static const primaryBlue = Color(0xFF2563EB);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.bg,
      drawer: isDesktop ? null : const Drawer(child: _Sidebar()),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const SizedBox(width: 260, child: _Sidebar()),
          Expanded(
            child: Column(
              children: [
                _Header(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: 24),
                        _buildStatCards(),
                        const SizedBox(height: 24),
                        _buildMainContentGrid(isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminColors.textPrimary)),
            SizedBox(height: 4),
            Text("Welcome back! Here's what's happening with EthioClass.", style: TextStyle(color: AdminColors.textSecondary, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Course'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.5,
        children: const [
          _StatCard(title: 'Total Students', value: '10,248', growth: '+ 12.5%', icon: Icons.group, color: AdminColors.purple),
          _StatCard(title: 'Total Courses', value: '256', growth: '+ 8.3%', icon: Icons.menu_book, color: AdminColors.primaryBlue),
          _StatCard(title: 'Total Videos', value: '1,245', growth: '+ 15.7%', icon: Icons.play_circle_fill, color: AdminColors.success),
          _StatCard(title: 'Total Enrollments', value: '18,324', growth: '+ 11.3%', icon: Icons.school, color: AdminColors.orange),
        ],
      );
    });
  }

  Widget _buildMainContentGrid(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
              children: [
                const _RecentCoursesTable(),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(child: _RecentStudentsList()),
                    SizedBox(width: 24),
                    Expanded(child: _RecentReviewsList()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Column(
              children: const [
                _QuickActions(),
                SizedBox(height: 24),
                _EnrollmentsChart(),
                SizedBox(height: 24),
                _SystemOverview(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Mobile/Tablet stack view
      return Column(
        children: const [
          _RecentCoursesTable(),
          SizedBox(height: 24),
          _QuickActions(),
          SizedBox(height: 24),
          _EnrollmentsChart(),
          SizedBox(height: 24),
          _RecentStudentsList(),
          SizedBox(height: 24),
          _RecentReviewsList(),
          SizedBox(height: 24),
          _SystemOverview(),
        ],
      );
    }
  }
}

// ---------------------------------------------------------
// SIDEBAR
// ---------------------------------------------------------
class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.school, color: AdminColors.primaryBlue, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('EthioClass', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Admin Panel', style: TextStyle(color: AdminColors.sidebarText, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(icon: Icons.dashboard, label: 'Dashboard', isActive: true),
                _SidebarItem(icon: Icons.menu_book, label: 'Courses'),
                _SidebarItem(icon: Icons.category, label: 'Categories'),
                _SidebarItem(icon: Icons.play_circle_outline, label: 'Lessons (Videos)'),
                _SidebarItem(icon: Icons.people_outline, label: 'Students'),
                _SidebarItem(icon: Icons.person_outline, label: 'Instructors'),
                _SidebarItem(icon: Icons.assignment_outlined, label: 'Enrollments'),
                _SidebarItem(icon: Icons.star_border, label: 'Reviews'),
                _SidebarItem(icon: Icons.quiz_outlined, label: 'Quiz & Exams'),
                _SidebarItem(icon: Icons.card_membership, label: 'Certificates'),
                _SidebarItem(icon: Icons.notifications_none, label: 'Notifications'),
                _SidebarItem(icon: Icons.mail_outline, label: 'Messages'),
                _SidebarItem(icon: Icons.settings_outlined, label: 'Settings'),
                _SidebarItem(icon: Icons.pie_chart_outline, label: 'Reports'),
                _SidebarItem(icon: Icons.article_outlined, label: 'System Logs'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarItem(
              icon: Icons.open_in_new,
              label: 'Visit Website',
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _SidebarItem({required this.icon, required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? AdminColors.sidebarItemActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AdminColors.sidebarTextActive : AdminColors.sidebarText, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AdminColors.sidebarTextActive : AdminColors.sidebarText,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HEADER
// ---------------------------------------------------------
class _Header extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _Header({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.cardBg,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width <= 900)
            IconButton(icon: const Icon(Icons.menu, color: AdminColors.textPrimary), onPressed: onMenuTap),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search, color: AdminColors.textSecondary), onPressed: () {}),
          const SizedBox(width: 8),
          _HeaderIcon(icon: Icons.notifications_none, badgeCount: 8),
          const SizedBox(width: 8),
          _HeaderIcon(icon: Icons.mail_outline, badgeCount: 5),
          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: AdminColors.border),
          const SizedBox(width: 16),
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: AdminColors.primaryBlue, child: Text('A', style: TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Admin', style: TextStyle(color: AdminColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('Super Admin', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  const _HeaderIcon({required this.icon, required this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon, color: AdminColors.textSecondary), onPressed: () {}),
        Positioned(
          right: 6, top: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AdminColors.primaryBlue, shape: BoxShape.circle),
            child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// STAT CARD
// ---------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title, value, growth;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.growth, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(growth, style: const TextStyle(color: AdminColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              const Text('vs last month', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// RECENT COURSES TABLE
// ---------------------------------------------------------
class _RecentCoursesTable extends StatelessWidget {
  const _RecentCoursesTable();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Courses',
      action: const Text('View All', style: TextStyle(color: AdminColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(color: AdminColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
          dataTextStyle: const TextStyle(color: AdminColors.textPrimary, fontSize: 14),
          dividerThickness: 1,
          columns: const [
            DataColumn(label: Text('Course')),
            DataColumn(label: Text('Instructor')),
            DataColumn(label: Text('Students')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: [
            _buildRow('Math - Grade 12', 'Grade 12', 'Abebe Kebede', '1,245', 'Published', AdminColors.success),
            _buildRow('English Language', 'Grade 11', 'Betelhem T.', '980', 'Published', AdminColors.success),
            _buildRow('Physics - Grade 12', 'Grade 12', 'Dr. Yoseph', '875', 'Published', AdminColors.success),
            _buildRow('Chemistry - Grade 11', 'Grade 11', 'Meseret A.', '645', 'Published', AdminColors.success),
            _buildRow('Biology - Grade 10', 'Grade 10', 'Dawit M.', '512', 'Draft', AdminColors.warning),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(String title, String subtitle, String instructor, String students, String status, Color statusColor) {
    return DataRow(cells: [
      DataCell(Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.book, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      )),
      DataCell(Row(
        children: [
          const CircleAvatar(radius: 12, backgroundColor: AdminColors.border, child: Icon(Icons.person, size: 14, color: AdminColors.textSecondary)),
          const SizedBox(width: 8),
          Text(instructor),
        ],
      )),
      DataCell(Text(students)),
      DataCell(Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600))),
      DataCell(Row(
        children: [
          _ActionButton(icon: Icons.remove_red_eye_outlined),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.edit_outlined),
          const SizedBox(width: 8),
          _ActionButton(icon: Icons.more_horiz),
        ],
      )),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  const _ActionButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AdminColors.bg, borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: AdminColors.textSecondary),
    );
  }
}

// ---------------------------------------------------------
// RECENT STUDENTS & REVIEWS
// ---------------------------------------------------------
class _RecentStudentsList extends StatelessWidget {
  const _RecentStudentsList();
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Students',
      action: const Text('View All', style: TextStyle(color: AdminColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
      child: Column(
        children: [
          _StudentTile('Rahma Mohammed', 'rahma@email.com', 'Grade 12', 'May 20, 2026'),
          const Divider(color: AdminColors.border),
          _StudentTile('Abel Tesfaye', 'abel@email.com', 'Grade 11', 'May 20, 2026'),
          const Divider(color: AdminColors.border),
          _StudentTile('Sara Ali', 'sara@email.com', 'Grade 10', 'May 19, 2026'),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final String name, email, grade, date;
  const _StudentTile(this.name, this.email, this.grade, this.date);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: AdminColors.border, child: Icon(Icons.person, color: AdminColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(email, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(grade, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 24),
          Text(date, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RecentReviewsList extends StatelessWidget {
  const _RecentReviewsList();
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Reviews',
      action: const Text('View All', style: TextStyle(color: AdminColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
      child: Column(
        children: [
          _ReviewTile('Lulit G.', 'Great course! Very helpful.', 'Math - Grade 12', 'May 20, 2026'),
          const Divider(color: AdminColors.border),
          _ReviewTile('Yonas M.', 'Well explained content.', 'Physics - Grade 12', 'May 19, 2026'),
          const Divider(color: AdminColors.border),
          _ReviewTile('Mekdes T.', 'Excellent teaching!', 'Chemistry - Grade 11', 'May 19, 2026'),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name, comment, course, date;
  const _ReviewTile(this.name, this.comment, this.course, this.date);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 18, backgroundColor: AdminColors.border, child: Icon(Icons.person, color: AdminColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: AdminColors.warning, size: 12),
                    const Icon(Icons.star, color: AdminColors.warning, size: 12),
                    const Icon(Icons.star, color: AdminColors.warning, size: 12),
                    const Icon(Icons.star, color: AdminColors.warning, size: 12),
                    const Icon(Icons.star, color: AdminColors.warning, size: 12),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(course, style: const TextStyle(color: AdminColors.primaryBlue, fontSize: 11)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// RIGHT COLUMN: Quick Actions, Chart, System Overview
// ---------------------------------------------------------
class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      child: Column(
        children: [
          _ActionRow(icon: Icons.add_box_outlined, label: 'Add New Course'),
          const Divider(color: AdminColors.border),
          _ActionRow(icon: Icons.play_circle_outline, label: 'Add New Video'),
          const Divider(color: AdminColors.border),
          _ActionRow(icon: Icons.folder_open, label: 'Add New Category'),
          const Divider(color: AdminColors.border),
          _ActionRow(icon: Icons.person_add_alt, label: 'Add New Instructor'),
          const Divider(color: AdminColors.border),
          _ActionRow(icon: Icons.notifications_none, label: 'Send Notification'),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AdminColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 14))),
          const Icon(Icons.chevron_right, color: AdminColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

class _EnrollmentsChart extends StatelessWidget {
  const _EnrollmentsChart();
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Enrollments Overview',
      action: Row(
        children: const [
          Text('This Month', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
          Icon(Icons.keyboard_arrow_down, color: AdminColors.textSecondary, size: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AdminColors.border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, _) => Text(val.toInt() == 0 ? '0' : '${(val/1000).toStringAsFixed(1)}K', style: const TextStyle(color: AdminColors.textSecondary, fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
                    switch(val.toInt()) {
                      case 0: return const Text('May 1', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10));
                      case 1: return const Text('May 8', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10));
                      case 2: return const Text('May 15', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10));
                      case 3: return const Text('May 22', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10));
                      case 4: return const Text('May 29', style: TextStyle(color: AdminColors.textSecondary, fontSize: 10));
                    }
                    return const Text('');
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 500), FlSpot(0.5, 450), FlSpot(1, 900), FlSpot(1.5, 400), FlSpot(2, 700), FlSpot(2.5, 1200), FlSpot(3, 1300), FlSpot(3.5, 1400), FlSpot(4, 1800)],
                    isCurved: true,
                    color: AdminColors.primaryBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AdminColors.primaryBlue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Total Enrollments', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
          Row(
            children: const [
              Text('2,456', style: TextStyle(color: AdminColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Icon(Icons.arrow_upward, color: AdminColors.success, size: 14),
              Text('14.6%', style: TextStyle(color: AdminColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Text('vs last month', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemOverview extends StatelessWidget {
  const _SystemOverview();
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'System Overview',
      child: Row(
        children: [
          SizedBox(
            width: 100, height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: 0.85, strokeWidth: 8, backgroundColor: AdminColors.border, valueColor: const AlwaysStoppedAnimation(AdminColors.primaryBlue)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('85%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('System Health', style: TextStyle(fontSize: 9, color: AdminColors.textSecondary)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _SystemRow('Server Status', 'Online', AdminColors.success),
                const SizedBox(height: 8),
                _SystemRow('Database', 'Healthy', AdminColors.success),
                const SizedBox(height: 8),
                _SystemRow('Storage Used', '62%', AdminColors.textPrimary),
                const SizedBox(height: 8),
                _SystemRow('Active Users', '1,248', AdminColors.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _SystemRow(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ---------------------------------------------------------
// HELPER COMPONENT
// ---------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;

  const _SectionCard({required this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
