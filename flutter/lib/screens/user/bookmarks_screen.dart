import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 36, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Bookmarks Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save lessons to revisit them later',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
