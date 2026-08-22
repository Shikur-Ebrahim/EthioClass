import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme.dart';
import '../../models/guidance_video.dart';
import '../../services/guidance_service.dart';

class ManageGuidanceScreen extends StatefulWidget {
  const ManageGuidanceScreen({super.key});

  @override
  State<ManageGuidanceScreen> createState() => _ManageGuidanceScreenState();
}

class _ManageGuidanceScreenState extends State<ManageGuidanceScreen> {
  bool _isLoading = true;
  List<GuidanceVideo> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await GuidanceService.instance.getVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e')),
        );
      }
    }
  }

  Future<void> _deleteVideo(String id) async {
    try {
      await GuidanceService.instance.deleteVideo(id);
      _loadVideos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  void _showAddEditDialog([GuidanceVideo? video]) {
    final isEditing = video != null;
    final titleController = TextEditingController(text: video?.title);
    final descController = TextEditingController(text: video?.description);
    final orderController = TextEditingController(text: video?.orderIndex.toString() ?? '0');
    
    File? selectedVideo;
    File? selectedThumbnail;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSaving = false;
            
            return AlertDialog(
              title: Text(isEditing ? 'Edit Video' : 'Add Guidance Video'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: orderController,
                      decoration: const InputDecoration(labelText: 'Order Number (e.g. 1)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedVideo != null 
                              ? 'Video: ${selectedVideo!.path.split('\\').last.split('/').last}' 
                              : isEditing ? 'Video: (Keep existing)' : 'Video: None selected',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
                            if (result != null) {
                              setDialogState(() => selectedVideo = File(result.files.single.path!));
                            }
                          },
                          child: const Text('Select Video'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedThumbnail != null 
                              ? 'Thumb: ${selectedThumbnail!.path.split('\\').last.split('/').last}' 
                              : isEditing ? 'Thumb: (Keep existing)' : 'Thumb: None selected',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null) {
                              setDialogState(() => selectedThumbnail = File(result.files.single.path!));
                            }
                          },
                          child: const Text('Select Thumb'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
                      return;
                    }
                    if (!isEditing && selectedVideo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video file')));
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      if (isEditing) {
                        await GuidanceService.instance.updateVideo(
                          id: video.id,
                          title: titleController.text,
                          description: descController.text,
                          orderIndex: orderController.text,
                          videoFile: selectedVideo,
                          thumbnailFile: selectedThumbnail,
                        );
                      } else {
                        await GuidanceService.instance.createVideo(
                          title: titleController.text,
                          description: descController.text,
                          orderIndex: orderController.text.isEmpty ? '0' : orderController.text,
                          videoFile: selectedVideo!,
                          thumbnailFile: selectedThumbnail,
                        );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _loadVideos();
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving video: $e')),
                      );
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save & Upload'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Guidance Videos', style: TextStyle(color: AppColors.textDark)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? const Center(child: Text('No videos found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text('${video.orderIndex}', style: const TextStyle(color: AppColors.primary)),
                        ),
                        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(video.videoUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(video),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteVideo(video.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
