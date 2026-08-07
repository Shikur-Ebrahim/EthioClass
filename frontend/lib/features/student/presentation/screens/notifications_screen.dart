import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _activeTab = 0;
  final _tabs = ['All', 'Courses', 'System', 'Payments'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: CourseColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == _activeTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? CourseColors.yellow : CourseColors.cardBg,
                      border: Border.all(color: active ? CourseColors.yellow : CourseColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_tabs[i],
                        style: TextStyle(
                          color: active ? Colors.black : CourseColors.textSecondary,
                          fontSize: 13,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NotifSectionHeader(title: 'Today'),
                _NotificationTile(
                  icon: Icons.play_circle_fill,
                  iconColor: CourseColors.primaryBlue,
                  title: 'New lesson available',
                  subtitle: 'Physics - Grade 12\nChapter 4: Motion in Two Dimensions is now available.',
                  time: '10:30 AM',
                  isUnread: true,
                ),
                _NotificationTile(
                  icon: Icons.quiz_outlined,
                  iconColor: CourseColors.yellow,
                  title: 'Quiz due tomorrow',
                  subtitle: 'Mathematics - Grade 12\nDon\'t forget: "Calculus Basics" quiz is due tomorrow.',
                  time: '9:15 AM',
                  isUnread: true,
                ),
                _NotificationTile(
                  icon: Icons.download_done,
                  iconColor: CourseColors.success,
                  title: 'Download completed',
                  subtitle: 'Physics - Grade 12\nChapter 2 - Study Guide.pdf has been downloaded successfully.',
                  time: 'Yesterday',
                  isUnread: false,
                ),
                _NotificationTile(
                  icon: Icons.payment,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Payment successful',
                  subtitle: 'You have successfully paid 100 Birr via Telebirr for "Chemistry - Grade 12 Chapter 3".',
                  time: 'Yesterday',
                  isUnread: false,
                ),
                const SizedBox(height: 8),
                _NotifSectionHeader(title: 'Earlier'),
                _NotificationTile(
                  icon: Icons.campaign_outlined,
                  iconColor: CourseColors.yellow,
                  title: 'New announcement',
                  subtitle: 'EthioClass\nWe will have a system maintenance on Sunday 12:00 AM - 2:00 AM.',
                  time: 'May 15, 2024',
                  isUnread: false,
                ),
                _NotificationTile(
                  icon: Icons.star_outline,
                  iconColor: CourseColors.yellow,
                  title: 'Rate your last lesson',
                  subtitle: 'How was "Physical Quantities and Units"? Your feedback helps us improve.',
                  time: 'May 14, 2024',
                  isUnread: false,
                ),
                _NotificationTile(
                  icon: Icons.card_membership_outlined,
                  iconColor: CourseColors.success,
                  title: 'Certificate earned!',
                  subtitle: 'Congratulations! You\'ve completed Physics - Chapter 1 and earned a certificate.',
                  time: 'May 12, 2024',
                  isUnread: false,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: CourseColors.bg,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CourseColors.yellow,
      unselectedItemColor: CourseColors.textSecondary,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

class _NotifSectionHeader extends StatelessWidget {
  final String title;
  const _NotifSectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: CourseColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, time;
  final bool isUnread;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? CourseColors.primaryBlue.withOpacity(0.07) : CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUnread ? CourseColors.primaryBlue.withOpacity(0.3) : CourseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            color: CourseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500)),
                  ),
                  Text(time, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
                ]),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12, height: 1.4),
                    maxLines: 3),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: CourseColors.primaryBlue, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
