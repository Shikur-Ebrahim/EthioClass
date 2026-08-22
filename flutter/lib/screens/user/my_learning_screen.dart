import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  int _selectedTab = 0; // 0 = In Progress, 1 = Completed, 2 = Saved

  final List<Map<String, dynamic>> _inProgressCourses = [
    {
      'title': 'Physics - Grade 12',
      'instructor': 'Abel Bekele',
      'progress': 0.65,
      'lastAccessed': 'Today',
      'icon': Icons.science_rounded,
      'color': const Color(0xFF4F63D2),
    },
    {
      'title': 'Mathematics - Grade 12',
      'instructor': 'Mesfin Tadesse',
      'progress': 0.40,
      'lastAccessed': 'Yesterday',
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFFE85D04),
    },
    {
      'title': 'Chemistry - Grade 12',
      'instructor': 'Rahel Worku',
      'progress': 0.25,
      'lastAccessed': '2 days ago',
      'icon': Icons.biotech_rounded,
      'color': const Color(0xFF2D9CDB),
    },
    {
      'title': 'Biology - Grade 12',
      'instructor': 'Yonatan Alemu',
      'progress': 0.75,
      'lastAccessed': '3 days ago',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF27AE60),
    },
    {
      'title': 'Engineering Drawing - TVET',
      'instructor': 'Samuel Getachew',
      'progress': 0.30,
      'lastAccessed': '5 days ago',
      'icon': Icons.architecture_rounded,
      'color': const Color(0xFF9B51E0),
    },
  ];

  final List<Map<String, dynamic>> _completedCourses = [
    {
      'title': 'Intro to Civics - Grade 11',
      'instructor': 'Selamawit Girma',
      'progress': 1.0,
      'lastAccessed': '1 month ago',
      'icon': Icons.public_rounded,
      'color': const Color(0xFF219653),
    },
    {
      'title': 'English Grammar Mastery',
      'instructor': 'Dawit Solomon',
      'progress': 1.0,
      'lastAccessed': '2 months ago',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFF2994A),
    },
  ];

  final List<Map<String, dynamic>> _savedCourses = [
    {
      'title': 'Python Programming Bootcamp',
      'instructor': 'Kaleab Melaku',
      'progress': 0.0,
      'lastAccessed': 'Not started',
      'icon': Icons.code_rounded,
      'color': const Color(0xFFEB5757),
    },
    {
      'title': 'Web Development Fundamentals',
      'instructor': 'Bethlehem Tefera',
      'progress': 0.0,
      'lastAccessed': 'Not started',
      'icon': Icons.web_rounded,
      'color': const Color(0xFF2D9CDB),
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList;
    String badgeText;
    Color badgeColor;

    if (_selectedTab == 0) {
      currentList = _inProgressCourses;
      badgeText = 'In Progress';
      badgeColor = const Color(0xFF2D9CDB);
    } else if (_selectedTab == 1) {
      currentList = _completedCourses;
      badgeText = 'Completed';
      badgeColor = const Color(0xFF27AE60);
    } else {
      currentList = _savedCourses;
      badgeText = 'Saved';
      badgeColor = const Color(0xFF9B51E0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Learning',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('In Progress', 0),
                  const SizedBox(width: 12),
                  _buildTab('Completed', 1),
                  const SizedBox(width: 12),
                  _buildTab('Saved', 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: currentList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildCourseCard(currentList[index], badgeText, badgeColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, String badgeText, Color badgeColor) {
    final progress = course['progress'] as double;
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [course['color'].withOpacity(0.8), course['color']],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(course['icon'], color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Instructor: ${course['instructor']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.greyLight, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last accessed: ${course['lastAccessed']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: AppColors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
