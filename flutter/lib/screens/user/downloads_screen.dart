import 'package:flutter/material.dart';

// Dark theme colors used for the Downloads screen
class DarkColors {
  static const Color bg = Color(0xFF0F1729);
  static const Color surface = Color(0xFF1A2340);
  static const Color card = Color(0xFF202D4A);
  static const Color primary = Color(0xFFFBB024);
  static const Color success = Color(0xFF38A169);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF8E9BB5);
  static const Color greyLight = Color(0xFF2D3A5C);
}

class _LessonItem {
  final String title;
  final String size;
  final String duration;
  final Color bgColor;
  final String shortLabel;
  final _DownloadState state;
  final double progress; // 0.0 to 1.0, used when state == downloading

  const _LessonItem({
    required this.title,
    required this.size,
    required this.duration,
    required this.bgColor,
    required this.shortLabel,
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
      bgColor: Color(0xFF1A3A5C),
      shortLabel: 'PHYSICAL\nQUANTITIES\nAND UNITS',
      state: _DownloadState.downloaded,
    ),
    _LessonItem(
      title: '2. Kinematics in One Dimension',
      size: '98 MB',
      duration: '18:30',
      bgColor: Color(0xFF1E3A2A),
      shortLabel: 'KINEMATICS\nIN ONE\nDIMENSION',
      state: _DownloadState.downloaded,
    ),
    _LessonItem(
      title: '3. Motion in Two Dimensions',
      size: '188 MB',
      duration: '22:10',
      bgColor: Color(0xFF2A1F3D),
      shortLabel: 'MOTION IN\nTWO\nDIMENSION',
      state: _DownloadState.downloading,
      progress: 0.69,
    ),
    _LessonItem(
      title: '4. Laws of Motion',
      size: '175 MB',
      duration: '30:15',
      bgColor: Color(0xFF2A1F1A),
      shortLabel: 'LAWS OF\nMOTION',
      state: _DownloadState.pending,
    ),
    _LessonItem(
      title: '5. Friction',
      size: '118 MB',
      duration: '19:40',
      bgColor: Color(0xFF1A2A2A),
      shortLabel: 'FRICTION',
      state: _DownloadState.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkColors.bg,
      appBar: AppBar(
        backgroundColor: DarkColors.bg,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DarkColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.settings_outlined,
                color: DarkColors.grey, size: 24),
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
              color: DarkColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: Color(0xFF4FC3F7), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Physics – Grade 12',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DarkColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Abel Bekele',
                        style: TextStyle(
                            fontSize: 12, color: DarkColors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '36 Lessons  •  18h 45m',
                        style: TextStyle(
                            fontSize: 12, color: DarkColors.grey),
                      ),
                    ],
                  ),
                ),
                // Circular progress
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 5,
                        backgroundColor: DarkColors.greyLight,
                        valueColor: const AlwaysStoppedAnimation(
                            DarkColors.primary),
                      ),
                    ),
                    const Text(
                      '65%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: DarkColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Downloaded lessons header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Downloaded Lessons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DarkColors.white,
                ),
              ),
              Text(
                '2.4 GB / 10 GB Used',
                style: const TextStyle(
                    fontSize: 12, color: DarkColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Storage bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.24,
              minHeight: 4,
              backgroundColor: DarkColors.greyLight,
              valueColor:
                  const AlwaysStoppedAnimation(DarkColors.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Lessons list
          ..._lessons.map((lesson) => _buildLessonItem(lesson)),
        ],
      ),
    );
  }

  Widget _buildLessonItem(_LessonItem lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarkColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: lesson.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                lesson.shortLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: DarkColors.white,
                  height: 1.3,
                ),
              ),
            ),
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
                    color: DarkColors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      lesson.duration,
                      style: const TextStyle(
                          fontSize: 11, color: DarkColors.grey),
                    ),
                    const Text(' • ',
                        style: TextStyle(
                            fontSize: 11, color: DarkColors.grey)),
                    Text(
                      lesson.size,
                      style: const TextStyle(
                          fontSize: 11, color: DarkColors.grey),
                    ),
                  ],
                ),
                if (lesson.state == _DownloadState.downloading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: lesson.progress,
                      minHeight: 3,
                      backgroundColor: DarkColors.greyLight,
                      valueColor: const AlwaysStoppedAnimation(
                          DarkColors.primary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Downloading... ${(lesson.progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, color: DarkColors.grey),
                  ),
                ],
                if (lesson.state == _DownloadState.pending)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                          fontSize: 10, color: DarkColors.grey),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // State icon
          _buildStateIcon(lesson.state),
        ],
      ),
    );
  }

  Widget _buildStateIcon(_DownloadState state) {
    switch (state) {
      case _DownloadState.downloaded:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DarkColors.success.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: DarkColors.success, size: 18),
        );
      case _DownloadState.downloading:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DarkColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pause_rounded,
              color: DarkColors.primary, size: 18),
        );
      case _DownloadState.pending:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DarkColors.greyLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.download_rounded,
              color: DarkColors.grey, size: 18),
        );
    }
  }
}
