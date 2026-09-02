import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../services/course_service.dart';
import 'category_detail_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  List<Category> _allCategories = [];
  List<Category> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<Color> _headerColors = [
    Color(0xFF1E3A8A),
    Color(0xFF166534),
    Color(0xFF831843),
    Color(0xFF065F46),
    Color(0xFF1D4ED8),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFF0F172A),
    Color(0xFF9D174D),
    Color(0xFF0369A1),
  ];

  static const List<Color> _iconColors = [
    Color(0xFF93C5FD),
    Color(0xFF86EFAC),
    Color(0xFFF9A8D4),
    Color(0xFF6EE7B7),
    Color(0xFFA5B4FC),
    Color(0xFFD8B4FE),
    Color(0xFFFCD34D),
    Color(0xFF94A3B8),
    Color(0xFFFBCFE8),
    Color(0xFF7DD3FC),
  ];

  static const List<IconData> _categoryIcons = [
    Icons.school_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.biotech_rounded,
    Icons.history_edu_rounded,
    Icons.language_rounded,
    Icons.computer_rounded,
    Icons.music_note_rounded,
    Icons.brush_rounded,
    Icons.sports_soccer_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CourseService().getCategories();
      if (mounted) {
        setState(() {
          _allCategories = cats;
          _filtered = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _searchQuery = q;
      _filtered = q.isEmpty
          ? _allCategories
          : _allCategories
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(q) ||
                      c.description.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  void _openCategory(Category cat, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: cat,
          headerColor: _headerColors[index % _headerColors.length],
          iconColor: _iconColors[index % _iconColors.length],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'All Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (!_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_allCategories.length} total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search categories...',
                                hintStyle: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: EthioClassLoading())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppColors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No categories yet',
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadCategories,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final cat = _filtered[i];
                        final origIndex = _allCategories.indexOf(cat);
                        final ci = origIndex >= 0 ? origIndex : i;
                        return _CategoryGridCard(
                          category: cat,
                          index: ci,
                          headerColor: _headerColors[ci % _headerColors.length],
                          iconColor: _iconColors[ci % _iconColors.length],
                          icon: _categoryIcons[ci % _categoryIcons.length],
                          onTap: () => _openCategory(cat, ci),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final Category category;
  final int index;
  final Color headerColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.category,
    required this.index,
    required this.headerColor,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  Widget _buildGradientBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerColor, headerColor.withOpacity(0.7)],
        ),
      ),
      child: Center(
        child: Icon(icon, color: iconColor.withOpacity(0.85), size: 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child:
                    category.imageUrl != null && category.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            _buildGradientBanner(),
                      )
                    : _buildGradientBanner(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: headerColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 10,
                              color: headerColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
