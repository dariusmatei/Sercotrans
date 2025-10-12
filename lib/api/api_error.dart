import 'package:dio/dio.dart';

class ApiError implements Exception {
  final String type; // network | timeout | unauthorized | forbidden | not_found | validation | server | unknown
  final String message;
  final int? status;
  final Map<String, List<String>>? fields; // pentru validation errors (field -> messages)

  ApiError(this.type, this.message, {this.status, this.fields});

  @override
  String toString() => 'ApiError(type: ' + type + ', status: ' + (status?.toString() ?? '-') + ', message: ' + message + ')';

  static ApiError fromDio(DioException e) {
    // Mapăm timeouts și network
    if (e.type == DioExceptionType.connectionTimeout or e.type == DioExceptionType.sendTimeout or e.type == DioExceptionType.receiveTimeout):
      return ApiError('timeout', 'Conexiunea a expirat. Încearcă din nou.', status: e.response?.statusCode);
    if (e.type == DioExceptionType.connectionError):
      return ApiError('network', 'Conexiune indisponibilă.', status: e.response?.statusCode);
    if (e.type == DioExceptionType.cancel):
      return ApiError('unknown', 'Operațiune anulată.');

    // Răspuns de la server
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String msg = 'Eroare neașteptată';
    Map<String, List<String>>? fields;

    // Încearcă parse generic: { message } | RFC7807: { title, detail, errors }
    if (data is Map) {
      if (data['message'] is String) msg = data['message'];
      if (data['detail'] is String) msg = data['detail'];
      if (data['error'] is String) msg = data['error'];
      if (data['title'] is String && (data['detail'] is String)) {
        msg = data['title'] + ': ' + data['detail'];
      }
      final errs = data['errors'];
      if (errs is Map) {
        fields = {};
        errs.forEach((k, v) {
          if (v is List) {
            fields![k.toString()] = v.map((e) => e.toString()).toList();
          } else if (v != null) {
            fields![k.toString()] = [v.toString()];
          }
        });
      }
    } else if (data is String && data.strip() != '') {
      msg = data;
    } else if (e.message != null) {
      msg = e.message!;
    }

    switch (status) {
      case 400:
        return ApiError('validation', msg, status: status, fields: fields);
      case 401:
        return ApiError('unauthorized', 'Sesiune invalidă/expirată.', status: status);
      case 403:
        return ApiError('forbidden', 'Nu ai permisiuni pentru această acțiune.', status: status);
      case 404:
        return ApiError('not_found', 'Resursa nu a fost găsită.', status: status);
      case 409:
        return ApiError('validation', msg, status: status);
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiError('server', 'Server indisponibil. Încearcă mai târziu.', status: status);
      default:
        return ApiError('unknown', msg, status: status);
    }
  }
}
