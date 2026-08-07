import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  int _activeTab = 0;
  final _tabs = ['In Progress', 'Completed', 'Saved'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: CourseColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Learning',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: CourseColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Filter pill tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == _activeTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? CourseColors.yellow : CourseColors.cardBg,
                      border: Border.all(color: active ? CourseColors.yellow : CourseColors.border),
                      borderRadius: BorderRadius.circular(22),
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
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildInProgress();
      case 1:
        return _buildCompleted();
      case 2:
        return _buildSaved();
      default:
        return _buildInProgress();
    }
  }

  Widget _buildInProgress() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        _LearningCard(
          title: 'Physics \u2013 Grade 12',
          instructor: 'Abel Bekele',
          progress: 0.65,
          lastAccessed: 'Today',
          thumbColor: Color(0xFF1E50FF),
          thumbIcon: Icons.science,
        ),
        _LearningCard(
          title: 'Mathematics \u2013 Grade 12',
          instructor: 'Mesfin Tadesse',
          progress: 0.40,
          lastAccessed: 'Yesterday',
          thumbColor: Color(0xFF7C3AED),
          thumbIcon: Icons.calculate,
        ),
        _LearningCard(
          title: 'Chemistry \u2013 Grade 12',
          instructor: 'Rahel Worku',
          progress: 0.25,
          lastAccessed: '2 days ago',
          thumbColor: Color(0xFF059669),
          thumbIcon: Icons.biotech,
        ),
        _LearningCard(
          title: 'Biology \u2013 Grade 12',
          instructor: 'Yonatan Alemu',
          progress: 0.75,
          lastAccessed: '3 days ago',
          thumbColor: Color(0xFF16A34A),
          thumbIcon: Icons.eco,
        ),
        _LearningCard(
          title: 'Engineering Drawing \u2013 TVET',
          instructor: 'Samuel Getachew',
          progress: 0.30,
          lastAccessed: '5 days ago',
          thumbColor: Color(0xFFF59E0B),
          thumbIcon: Icons.architecture,
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        _LearningCard(
          title: 'English Language \u2013 Grade 11',
          instructor: 'Betelhem T.',
          progress: 1.0,
          lastAccessed: '2 weeks ago',
          thumbColor: Color(0xFF0891B2),
          thumbIcon: Icons.text_fields,
          isCompleted: true,
        ),
        _LearningCard(
          title: 'Geography \u2013 Grade 10',
          instructor: 'Hiwot M.',
          progress: 1.0,
          lastAccessed: '1 month ago',
          thumbColor: Color(0xFFB45309),
          thumbIcon: Icons.map,
          isCompleted: true,
        ),
      ],
    );
  }

  Widget _buildSaved() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        _LearningCard(
          title: 'Physics \u2013 Grade 11',
          instructor: 'Dr. Yoseph',
          progress: 0.0,
          lastAccessed: 'Not started',
          thumbColor: Color(0xFF1E50FF),
          thumbIcon: Icons.science,
          isSaved: true,
        ),
        _LearningCard(
          title: 'ICT \u2013 Freshman',
          instructor: 'Dawit M.',
          progress: 0.0,
          lastAccessed: 'Not started',
          thumbColor: Color(0xFF7C3AED),
          thumbIcon: Icons.computer,
          isSaved: true,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: CourseColors.bg,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CourseColors.yellow,
      unselectedItemColor: CourseColors.textSecondary,
      currentIndex: 1,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class _LearningCard extends StatelessWidget {
  final String title, instructor, lastAccessed;
  final double progress;
  final Color thumbColor;
  final IconData thumbIcon;
  final bool isCompleted, isSaved;

  const _LearningCard({
    required this.title,
    required this.instructor,
    required this.progress,
    required this.lastAccessed,
    required this.thumbColor,
    required this.thumbIcon,
    this.isCompleted = false,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [thumbColor, thumbColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(thumbIcon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(instructor,
                        style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Row(children: [
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CourseColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Completed',
                        style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else if (!isSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CourseColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('In Progress',
                        style: TextStyle(color: CourseColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: CourseColors.border,
            valueColor: AlwaysStoppedAnimation(isCompleted ? CourseColors.success : CourseColors.yellow),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: CourseColors.textSecondary, size: 13),
              const SizedBox(width: 5),
              Text('Last accessed: $lastAccessed',
                  style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
