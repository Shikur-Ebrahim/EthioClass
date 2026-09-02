import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/category_model.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import 'how_to_start_screen.dart';
import 'all_categories_screen.dart';
import 'category_detail_screen.dart';
import 'course_detail_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onGoToCourses;
  const HomeScreen({super.key, required this.userName, this.onGoToCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Course>> _coursesFuture;

  List<Category> _allCategories = [];
  List<Course> _allCourses = [];

  List<Category> _filteredCategories = [];
  List<Course> _filteredCourses = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _dataLoaded = false;

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CourseService().getCategories();
    _coursesFuture = CourseService().getCourses();
    _loadData();
    _searchController.addListener(_onSearchChanged);

    // Pulse animation for the button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CourseService().getCategories(),
        CourseService().getCourses(),
      ]);
      if (mounted) {
        setState(() {
          _allCategories = results[0] as List<Category>;
          _allCourses = results[1] as List<Course>;
          _filteredCategories = _allCategories;
          _filteredCourses = _allCourses;
          _dataLoaded = true;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredCategories = _allCategories;
        _filteredCourses = _allCourses;
      } else {
        _filteredCategories = _allCategories.where((cat) {
          return cat.name.toLowerCase().contains(query) ||
              cat.description.toLowerCase().contains(query);
        }).toList();
        _filteredCourses = _allCourses.where((course) {
          return course.title.toLowerCase().contains(query) ||
              course.description.toLowerCase().contains(query) ||
              course.instructorName.toLowerCase().contains(query) ||
              (course.categoryName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
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
    if (!_dataLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: EthioClassLoading()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() {
                  _dataLoaded = false;
                  _searchController.clear();
                });
                await _loadData();
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
                    const SizedBox(height: 24),
                    if (_isSearching) ...[
                      _buildSearchResults(),
                    ] else ...[
                      _buildSectionHeader(
                        'Explore Categories',
                        onViewAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllCategoriesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildCategories(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(
                        'All Courses',
                        onViewAll: () {
                          widget.onGoToCourses?.call();
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildCourses(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_dataLoaded) {
      return const Center(child: EthioClassLoading());
    }

    final hasCategories = _filteredCategories.isNotEmpty;
    final hasCourses = _filteredCourses.isNotEmpty;

    if (!hasCategories && !hasCourses) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 60,
                color: AppColors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No results for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try different keywords or browse categories below',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            '${_filteredCategories.length + _filteredCourses.length} result${(_filteredCategories.length + _filteredCourses.length) == 1 ? '' : 's'} for "$_searchQuery"',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Category results
        if (hasCategories) ...[
          _buildSectionHeader('Categories', onViewAll: () {}),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCategories.length,
              itemBuilder: (_, i) =>
                  _CategoryCard(cat: _filteredCategories[i], index: i),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Course results
        if (hasCourses) ...[
          _buildSectionHeader('Courses', onViewAll: () {}),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filteredCourses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) =>
                _CourseCard(course: _filteredCourses[i], index: i),
          ),
        ],
      ],
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
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Spacer(),
              // "How to Learning" pulsing button
              ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HowToStartScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF3CAC).withOpacity(0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3CAC).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFFFF3CAC),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tap here to learn\nhow to use the app!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Greeting text below top row
          Text(
            '${_greeting()}, ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
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
                  Icon(Icons.search_rounded, color: AppColors.grey, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _onSearchChanged(),
                      decoration: InputDecoration(
                        hintText: 'Search courses, categories...',
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_isSearching)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSearching ? _clearSearch : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _isSearching ? AppColors.textDark : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isSearching ? AppColors.textDark : AppColors.primary)
                            .withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
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
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
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
          return const SizedBox(height: 120);
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Could not load categories.',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }
        final cats = snapshot.data ?? [];
        if (cats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No categories yet.',
              style: TextStyle(color: AppColors.grey),
            ),
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
          return const SizedBox(height: 160);
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Could not load courses.',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }
        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No courses yet.',
              style: TextStyle(color: AppColors.grey),
            ),
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
            initialCourses: _allCourses
                .where((c) => c.categoryId == cat.id)
                .toList(),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
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
            categoryName: course.categoryName ?? 'Course',
          ),
        ),
      ),
      child: Container(
        height: 115,
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
                width: 115,
                height: 115,
                color: cardColor,
                child:
                    course.thumbnailUrl != null &&
                        course.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        '$apiBaseUrl/media/${course.thumbnailUrl!}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallbackThumbnail(cardColor),
                      )
                    : _fallbackThumbnail(cardColor),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    if (course.categoryName != null &&
                        course.categoryName!.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final colors = _getCategoryColors(
                            course.categoryName!,
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: colors[0], // Light background
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.categoryName!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors[1], // Dark text
                              ),
                            ),
                          );
                        },
                      ),

                    // Title
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
                    const SizedBox(height: 4),

                    // Instructor Name
                    if (course.instructorName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course.instructorName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Lessons & Duration Row
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.lessonCount} lessons',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.durationMinutes ~/ 60}h ${course.durationMinutes % 60}m',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Options icon (chevron instead of more_vert for consistency)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumbnail(Color color) {
    return Center(
      child: Icon(
        Icons.play_circle_outline_rounded,
        color: Colors.white.withOpacity(0.7),
        size: 36,
      ),
    );
  }

  // Returns [lightBackground, darkText]
  List<Color> _getCategoryColors(String categoryName) {
    final cat = categoryName.toLowerCase();
    if (cat.contains('freshima')) {
      return const [Color(0xFFFEEBC8), Color(0xFFDD6B20)]; // Orange
    } else if (cat.contains('grad12') || cat.contains('grade 12')) {
      return const [Color(0xFFDBEAFE), Color(0xFF1D4ED8)]; // Blue
    } else if (cat.contains('tvet')) {
      return const [Color(0xFFDCFCE7), Color(0xFF15803D)]; // Green
    } else if (cat.contains('middle')) {
      return const [Color(0xFFFCE7F3), Color(0xFFBE185D)]; // Pink
    } else if (cat.contains('primary')) {
      return const [Color(0xFFFEF3C7), Color(0xFFB45309)]; // Amber
    } else {
      return const [Color(0xFFF3F4F6), Color(0xFF374151)]; // Grey
    }
  }
}
