import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import 'category_detail_screen.dart';
import 'course_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CourseService().getCategories();
    _coursesFuture = CourseService().getCourses();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '👋';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            setState(() {
              _categoriesFuture = CourseService().getCategories();
              _coursesFuture = CourseService().getCourses();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 28),
                _buildSectionHeader('Explore Categories', onViewAll: () {}),
                const SizedBox(height: 14),
                _buildCategories(),
                const SizedBox(height: 28),
                _buildSectionHeader('All Courses', onViewAll: () {}),
                const SizedBox(height: 14),
                _buildCourses(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Menu icon + Notification + Avatar
          Row(
            children: [
              // Hamburger menu icon
              GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded,
                      size: 22, color: AppColors.textDark),
                ),
              ),
              const Spacer(),
              // Notification bell
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.notifications_outlined,
                          size: 22, color: AppColors.textDark),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Greeting text below top row
          Row(
            children: [
              Text(
                '${_greeting()}, ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                _greetingEmoji(),
                style: const TextStyle(fontSize: 22),
              ),
            ],
          ),
          Text(
            widget.userName.isNotEmpty
                ? widget.userName.split(' ').first
                : 'Student',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Continue your learning journey',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded,
                      color: AppColors.grey, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search courses, topics...',
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORIES ──────────────────────────────────────────────
  Widget _buildCategories() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Could not load categories.',
                style: TextStyle(color: AppColors.error)),
          );
        }
        final cats = snapshot.data ?? [];
        if (cats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No categories yet.', style: TextStyle(color: AppColors.grey)),
          );
        }
        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            itemBuilder: (_, i) => _CategoryCard(cat: cats[i], index: i),
          ),
        );
      },
    );
  }

  // ── COURSES ──────────────────────────────────────────────────
  Widget _buildCourses() {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Could not load courses.',
                style: TextStyle(color: AppColors.error)),
          );
        }
        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No courses yet.', style: TextStyle(color: AppColors.grey)),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _CourseCard(course: courses[i], index: i),
        );
      },
    );
  }
}

// ── CATEGORY CARD ─────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category cat;
  final int index;

  const _CategoryCard({required this.cat, required this.index});

  static const List<Color> _fallbackColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFFC62828),
  ];

  @override
  Widget build(BuildContext context) {
    final fallbackColor = _fallbackColors[index % _fallbackColors.length];
    final hasImage = cat.imageUrl != null && cat.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            category: cat,
            headerColor: fallbackColor.withOpacity(0.2),
            iconColor: fallbackColor,
          ),
        ),
      ),
      child: Container(
        width: 140,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: fallbackColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: fallbackColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full background image
            if (hasImage)
              Image.network(
                cat.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: fallbackColor),
              )
            else
              Container(color: fallbackColor),

            // Dark gradient overlay at the bottom so text is readable
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),

            // Category name + description at bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cat.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cat.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Small arrow icon top-right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── COURSE CARD ────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  final int index;

  const _CourseCard({required this.course, required this.index});

  static const List<Color> _cardColors = [
    Color(0xFF1B5E20), // dark green
    Color(0xFF4527A0), // deep purple
    Color(0xFFE65100), // deep orange
    Color(0xFF01579B), // deep blue
    Color(0xFF880E4F), // deep pink
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = _cardColors[index % _cardColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            course: course,
            index: index,
          ),
        ),
      ),
      child: Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: Container(
              width: 90,
              height: 90,
              color: cardColor,
              child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackThumbnail(cardColor),
                    )
                  : _fallbackThumbnail(cardColor),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    course.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Options icon
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.more_vert_rounded, color: AppColors.grey, size: 20),
          ),
        ],
      ),
     ),
    );
  }

  Widget _fallbackThumbnail(Color color) {
    return Center(
      child: Icon(Icons.play_circle_outline_rounded,
          color: Colors.white.withOpacity(0.7), size: 36),
    );
  }
}
