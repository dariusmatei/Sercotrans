import 'dart:convert';

int? jwtExpiry(String jwt) {
  try {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final exp = payload['exp'];
    if (exp is int) return exp;
    if (exp is num) return exp.toInt();
    return null;
  } catch (_) {
    return null;
  }
}
