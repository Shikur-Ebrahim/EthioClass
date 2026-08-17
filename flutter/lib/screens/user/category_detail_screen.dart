import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/division_model.dart';
import '../../services/course_service.dart';
import 'courses_screen.dart'; // We should probably navigate to CoursesScreen filtered by division

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final Color headerColor;
  final Color iconColor;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.headerColor,
    required this.iconColor,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = true;
  List<Division> _divisions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDivisions();
  }

  Future<void> _fetchDivisions() async {
    try {
      final divs = await CourseService().getDivisions(categoryId: widget.category.id);
      if (mounted) {
        setState(() {
          _divisions = divs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: widget.headerColor,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.category.imageUrl != null && widget.category.imageUrl!.isNotEmpty)
                    Image.network(
                      widget.category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: widget.headerColor),
                    )
                  else
                    Container(color: widget.headerColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.headerColor.withOpacity(0.3),
                          widget.headerColor.withOpacity(0.8),
                          widget.headerColor.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Icon(
                      Icons.category_rounded,
                      size: 200,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 40,
                    right: 20,
                    child: SafeArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.category.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.category_rounded, color: Colors.white, size: 44),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(value: '0', label: 'Courses', icon: Icons.book_rounded, color: widget.iconColor),
                  _Divider(),
                  _StatItem(value: '0', label: 'Videos', icon: Icons.play_circle_rounded, color: const Color(0xFF7C3AED)),
                  _Divider(),
                  _StatItem(value: '0', label: 'Practice Qs', icon: Icons.quiz_rounded, color: const Color(0xFF16A34A)),
                  _Divider(),
                  _StatItem(value: '0', label: 'Students', icon: Icons.people_rounded, color: const Color(0xFFF97316)),
                ],
              ),
            ),
          ),

          // Subjects title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

          // Subjects list
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text('Failed to load subjects: $_errorMessage',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            )
          else if (_divisions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('No subjects found in this category yet.',
                      style: TextStyle(color: AppColors.grey)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _DivisionTile(
                  division: _divisions[i],
                  index: i,
                ),
                childCount: _divisions.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// Stats item
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.greyLight);
  }
}

// Division tile
class _DivisionTile extends StatelessWidget {
  final Division division;
  final int index;
  
  const _DivisionTile({required this.division, required this.index});

  // Cycle through some colors for the icons
  static const List<Color> _bgColors = [
    Color(0xFFE3F0FF), Color(0xFFE8F5E9), Color(0xFFF3EEFF), Color(0xFFE6F9F0), Color(0xFFFFF3E0),
  ];
  static const List<Color> _iconColors = [
    Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFF7C3AED), Color(0xFF059669), Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];
    final iconColor = _iconColors[index % _iconColors.length];

    return GestureDetector(
      onTap: () {
        // We will just print for now or navigate to CoursesScreen with a filter (if supported)
        // Or to a DivisionDetailScreen. 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: ${division.name}')),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: division.imageUrl != null && division.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        division.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.class_rounded, color: iconColor, size: 26),
                      ),
                    )
                  : Icon(Icons.class_rounded, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    division.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explore subjects and courses',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

// End of file
