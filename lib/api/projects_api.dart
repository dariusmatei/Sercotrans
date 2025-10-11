import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/project.dart';

class ProjectsApi {
  final ApiClient client;
  ProjectsApi(this.client);

  Future<List<Project>> list({
    String? search,
    String? status,
    String sort = 'name',
    String dir = 'asc',
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final resp = await client.dio.get(
        '/projects',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'sort': sort,
          'dir': dir,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = resp.data;
      if (data is List) {
        return data.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map && data['items'] is List) {
        return (data['items'] as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
      }
      return <Project>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return <Project>[];
      }
      rethrow;
    }
  }
}
