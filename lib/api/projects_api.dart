import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/project.dart';
import 'api_error.dart';

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
      throw ApiError.fromDio(e);
    }
  }

  Future<Project> getById(String id) async {
    try {
      final resp = await client.dio.get('/projects/' + id);
      return Project.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Project> create({
    required String name,
    required String client,
    required String status,
    required String owner,
    DateTime? dueDate,
  }) async {
    try {
      final resp = await client.dio.post('/projects', data: {
        'name': name,
        'client': client,
        'status': status,
        'owner': owner,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      });
      return Project.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Project> update(Project p) async {
    try {
      final resp = await client.dio.patch('/projects/' + p.id, data: {
        'name': p.name,
        'client': p.client,
        'status': p.status,
        'owner': p.owner,
        'dueDate': p.dueDate?.toIso8601String(),
      });
      return Project.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await client.dio.delete('/projects/' + id);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }
}
