import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<void> createVideo(GuidanceVideo video) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/guidance'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(video.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create guidance video');
    }
  }

  Future<void> updateVideo(GuidanceVideo video) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/guidance/${video.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(video.toJson()),
    );
    if (response.statusCode != 200) {
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
