import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import '../core/constants.dart';
import '../models/guidance_video.dart';

class GuidanceService {
  static final GuidanceService instance = GuidanceService._();
  GuidanceService._();

  Future<List<GuidanceVideo>> getVideos() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/guidance'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => GuidanceVideo.fromJson(json)).toList();
    }
    throw Exception('Failed to load guidance videos');
  }

  Future<void> createVideo({
    required String title,
    required String description,
    required String orderIndex,
    required File videoFile,
    File? thumbnailFile,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/admin/guidance'),
    );

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['order_index'] = orderIndex;

    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType.parse(lookupMimeType(videoFile.path) ?? 'video/mp4'),
      ),
    );

    if (thumbnailFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'thumbnail',
          thumbnailFile.path,
          contentType: MediaType.parse(lookupMimeType(thumbnailFile.path) ?? 'image/jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode != 201) {
      throw Exception('Failed to create guidance video');
    }
  }

  Future<void> updateVideo({
    required String id,
    required String title,
    required String description,
    required String orderIndex,
    File? videoFile,
    File? thumbnailFile,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConstants.baseUrl}/admin/guidance/$id'),
    );

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['order_index'] = orderIndex;

    if (videoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          contentType: MediaType.parse(lookupMimeType(videoFile.path) ?? 'video/mp4'),
        ),
      );
    }

    if (thumbnailFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'thumbnail',
          thumbnailFile.path,
          contentType: MediaType.parse(lookupMimeType(thumbnailFile.path) ?? 'image/jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to update guidance video');
    }
  }

  Future<void> deleteVideo(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/guidance/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete guidance video');
    }
  }
}
