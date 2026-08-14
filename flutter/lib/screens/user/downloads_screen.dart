import 'package:flutter/material.dart';
import '../../core/theme.dart';

class _LessonItem {
  final String title;
  final String size;
  final String duration;
  final Color bgColor;
  final IconData icon;
  final Color iconColor;
  final _DownloadState state;
  final double progress;

  const _LessonItem({
    required this.title,
    required this.size,
    required this.duration,
    required this.bgColor,
    required this.icon,
    required this.iconColor,
    required this.state,
    this.progress = 0,
  });
}

enum _DownloadState { downloaded, downloading, pending }

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static const List<_LessonItem> _lessons = [
    _LessonItem(
      title: '1. Physical Quantities and Units',
      size: '125 MB',
      duration: '12:45',
      bgColor: Color(0xFFE3F0FF),
      icon: Icons.science_rounded,
      iconColor: Color(0xFF2563EB),
      state: _DownloadState.downloaded,
    ),
    _LessonItem(
      title: '2. Kinematics in One Dimension',
      size: '98 MB',
      duration: '18:30',
      bgColor: Color(0xFFE6F9F0),
      icon: Icons.speed_rounded,
      iconColor: Color(0xFF16A34A),
      state: _DownloadState.downloaded,
    ),
    _LessonItem(
      title: '3. Motion in Two Dimensions',
      size: '188 MB',
      duration: '22:10',
      bgColor: Color(0xFFF3EEFF),
      icon: Icons.open_with_rounded,
      iconColor: Color(0xFF7C3AED),
      state: _DownloadState.downloading,
      progress: 0.69,
    ),
    _LessonItem(
      title: '4. Laws of Motion',
      size: '175 MB',
      duration: '30:15',
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.gavel_rounded,
      iconColor: Color(0xFFF97316),
      state: _DownloadState.pending,
    ),
    _LessonItem(
      title: '5. Friction',
      size: '118 MB',
      duration: '19:40',
      bgColor: Color(0xFFFFECEC),
      icon: Icons.compare_arrows_rounded,
      iconColor: Color(0xFFDC2626),
      state: _DownloadState.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.settings_outlined,
                color: AppColors.grey, size: 24),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Course card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: Color(0xFF2563EB), size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Physics – Grade 12',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Abel Bekele',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                      SizedBox(height: 2),
                      Text('36 Lessons  •  18h 45m',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 5,
                        backgroundColor: AppColors.greyLight,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary),
                      ),
                    ),
                    const Text(
                      '65%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Downloaded Lessons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '2.4 GB / 10 GB Used',
                style: TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.24,
              minHeight: 5,
              backgroundColor: AppColors.greyLight,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),

          ..._lessons.map((lesson) => _buildLessonItem(lesson)),
        ],
      ),
    );
  }

  Widget _buildLessonItem(_LessonItem lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          // Icon thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lesson.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(lesson.icon, color: lesson.iconColor, size: 28),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(lesson.duration,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                    const Text('  •  ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                    Text(lesson.size,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                  ],
                ),
                if (lesson.state == _DownloadState.downloading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: lesson.progress,
                      minHeight: 3,
                      backgroundColor: AppColors.greyLight,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Downloading... ${(lesson.progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMedium),
                  ),
                ],
                if (lesson.state == _DownloadState.pending)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Pending',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.grey)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStateIcon(lesson.state),
        ],
      ),
    );
  }

  Widget _buildStateIcon(_DownloadState state) {
    switch (state) {
      case _DownloadState.downloaded:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.success, size: 18),
        );
      case _DownloadState.downloading:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pause_rounded,
              color: AppColors.primary, size: 18),
        );
      case _DownloadState.pending:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.download_rounded,
              color: AppColors.grey, size: 18),
        );
    }
  }
}
