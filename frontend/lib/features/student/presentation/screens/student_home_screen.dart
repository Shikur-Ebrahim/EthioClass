import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/providers/user_profile_provider.dart';
import '../../courses/presentation/providers/course_provider.dart';
import '../../courses/data/models/course_models.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final myEnrollmentsAsync = ref.watch(myEnrollmentsProvider);
    final continueLearningAsync = ref.watch(continueLearningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---- TOP APP BAR ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.menu, color: AppColors.textPrimary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: profileAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (profile) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${profile?.fullName.split(' ').first ?? 'Student'} ',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('👋', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            const Text(
                              'Continue your learning journey',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    profileAsync.when(
                      loading: () => const CircleAvatar(radius: 21, backgroundColor: AppColors.yellow),
                      error: (_, __) => const CircleAvatar(radius: 21, backgroundColor: AppColors.yellow),
                      data: (profile) => CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.yellow,
                        child: Text(
                          (profile?.fullName.isNotEmpty == true) ? profile!.fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- SEARCH BAR ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search courses, topics...',
                            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: Colors.black, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            // ---- EXPLORE CATEGORIES ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Explore Categories', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('View all', style: TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
                  error: (_, __) => const SizedBox(),
                  data: (cats) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: cats.length,
                    itemBuilder: (ctx, i) => _CategoryCard(category: cats[i]),
                  ),
                ),
              ),
            ),

            // ---- CONTINUE LEARNING ----
            SliverToBoxAdapter(
              child: continueLearningAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (enrollment) {
                  if (enrollment == null) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Continue Learning', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _ContinueLearningCard(enrollment: enrollment),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ---- MY COURSES ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Courses', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('View all', style: TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),

            myEnrollmentsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.yellow),
                )),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (enrollments) {
                if (enrollments.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.book_outlined, color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 12),
                            const Text('No courses yet.\nExplore and enroll!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _MyCourseCard(enrollment: enrollments[i]),
                    ),
                    childCount: enrollments.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ---- BOTTOM NAVIGATION ----
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ---- CATEGORY CARD ----
class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  Color get _cardColor {
    switch (category.name) {
      case 'Grade 12': return const Color(0xFF1565C0);
      case 'Freshman': return const Color(0xFF6A1B9A);
      case 'TVET': return const Color(0xFFE65100);
      default: return AppColors.cardBackground;
    }
  }

  IconData get _icon {
    switch (category.name) {
      case 'Grade 12': return Icons.school;
      case 'Freshman': return Icons.auto_stories;
      case 'TVET': return Icons.build;
      default: return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_cardColor, _cardColor.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: Icon(_icon, size: 70, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${category.courseCount}+ Courses', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10, bottom: 10,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- CONTINUE LEARNING CARD ----
class _ContinueLearningCard extends StatelessWidget {
  final Enrollment enrollment;
  const _ContinueLearningCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course;
    if (course == null) return const SizedBox();
    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            // Course icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.science_outlined, color: Color(0xFF42A5F5), size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Chapter ${enrollment.progressPercent ~/ 20 + 1}: Continuing...', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: enrollment.progressPercent / 100,
                      backgroundColor: AppColors.inputBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${enrollment.progressPercent}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.black, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- MY COURSE CARD ----
class _MyCourseCard extends StatelessWidget {
  final Enrollment enrollment;
  const _MyCourseCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course;
    if (course == null) return const SizedBox();
    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.book_outlined, color: AppColors.yellow, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Teacher: ${course.instructorName}', style: const TextStyle(color: AppColors.yellow, fontSize: 11)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: enrollment.progressPercent / 100,
                      backgroundColor: AppColors.inputBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('${enrollment.progressPercent}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ---- BOTTOM NAVIGATION ----
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.yellow,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.download_outlined), activeIcon: Icon(Icons.download), label: 'Downloads'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), activeIcon: Icon(Icons.bookmark), label: 'Bookmarks'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
