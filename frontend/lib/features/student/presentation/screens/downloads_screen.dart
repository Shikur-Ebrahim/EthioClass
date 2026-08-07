import 'package:flutter/material.dart';
import 'course_details_screen.dart'; // To reuse CourseColors

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

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
        title: const Text('Downloads', style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: CourseColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseCard(),
              const SizedBox(height: 24),
              _buildStorageInfo(),
              const SizedBox(height: 16),
              _buildDownloadsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCourseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E50FF), Color(0xFF0F2B5B)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Physics – Grade 12', style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Abel Bekele', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                Text('36 Lessons • 18h 45m', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50, height: 50,
                child: CircularProgressIndicator(
                  value: 0.65,
                  backgroundColor: CourseColors.border,
                  valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                  strokeWidth: 4,
                ),
              ),
              const Text('65%', style: TextStyle(color: CourseColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Downloaded Lessons', style: TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('2.4 GB / 10 GB Used', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: 0.24,
          backgroundColor: CourseColors.border,
          valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildDownloadsList() {
    return Column(
      children: [
        _DownloadTile(
          title: '1. Physical Quantities and Units',
          duration: '12:45',
          size: '108 MB',
          status: DownloadStatus.downloaded,
        ),
        _DownloadTile(
          title: '2. Kinematics in One Dimension',
          duration: '18:30',
          size: '153 MB',
          status: DownloadStatus.downloaded,
        ),
        _DownloadTile(
          title: '3. Motion in Two Dimensions',
          duration: '22:10',
          size: '186 MB',
          status: DownloadStatus.downloading,
          progress: 0.6,
        ),
        _DownloadTile(
          title: '4. Laws of Motion',
          duration: '20:15',
          size: '175 MB',
          status: DownloadStatus.pending,
        ),
        _DownloadTile(
          title: '5. Friction',
          duration: '15:40',
          size: '118 MB',
          status: DownloadStatus.pending,
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
      currentIndex: 2, // Downloads active
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

enum DownloadStatus { downloaded, downloading, pending }

class _DownloadTile extends StatelessWidget {
  final String title, duration, size;
  final DownloadStatus status;
  final double? progress;

  const _DownloadTile({
    required this.title,
    required this.duration,
    required this.size,
    required this.status,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 80, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F2B5B), Color(0xFF1E50FF)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.science, color: Colors.white54, size: 30)),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$duration • $size', style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                if (status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: CourseColors.border,
                    valueColor: const AlwaysStoppedAnimation(CourseColors.primaryBlue),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text('Downloading... ${(progress! * 100).toInt()}%', style: const TextStyle(color: CourseColors.primaryBlue, fontSize: 10)),
                ] else if (status == DownloadStatus.pending) ...[
                  const SizedBox(height: 8),
                  const Text('Pending', style: TextStyle(color: CourseColors.primaryBlue, fontSize: 10)),
                ],
              ],
            ),
          ),
          // Action button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (status == DownloadStatus.downloaded)
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: CourseColors.success, size: 20),
                    SizedBox(width: 8),
                    Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 20),
                  ],
                )
              else if (status == DownloadStatus.downloading)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CourseColors.yellow)),
                  child: const Icon(Icons.pause, color: CourseColors.yellow, size: 16),
                )
              else if (status == DownloadStatus.pending)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CourseColors.textSecondary)),
                  child: const Icon(Icons.file_download_outlined, color: CourseColors.textSecondary, size: 16),
                )
            ],
          )
        ],
      ),
    );
  }
}
