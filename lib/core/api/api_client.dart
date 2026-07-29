import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://peleka-server.vercel.app',
);

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;
  final Map<String, dynamic>? details;
  ApiException(this.message, {this.status, this.code, this.details});
  @override
  String toString() => 'ApiException($status $code): $message';
}

class ApiClient {
  final Dio dio;
  final SecureStorage _st;
  Completer<String?>? _rc;

  ApiClient(this._st)
      : dio = Dio(BaseOptions(
          baseUrl: kApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
          responseType: ResponseType.json,
          headers: {
            // ngrok free tier serves an HTML interstitial to anything that
            // looks like a browser; this header skips it. Harmless elsewhere.
            'ngrok-skip-browser-warning': 'true',
            'User-Agent': 'PelekaCustomerApp/1.0 (Dart; Flutter)',
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final t = await _st.readAccessToken();
        if (t != null && o.headers['Authorization'] == null) {
          o.headers['Authorization'] = 'Bearer $t';
        }
        if (kDebugMode) print('[api] → ${o.method} ${o.uri}');
        h.next(o);
      },
      onResponse: (r, h) {
        final data = r.data;
        if (data is String && data.trimLeft().startsWith('<')) {
          h.reject(DioException(
            requestOptions: r.requestOptions,
            response: r,
            error: ApiException(
              'Server returned an HTML page instead of JSON (tunnel warning page?). '
              'Check the backend URL baked into this build.',
              status: r.statusCode,
              code: 'HTML_RESPONSE',
            ),
          ));
          return;
        }
        h.next(r);
      },
      onError: (err, h) async {
        final req = err.requestOptions;
        final is401 = err.response?.statusCode == 401;
        final retried = req.extra['retried'] == true;
        final isRefresh = req.path.endsWith('/api/auth/refresh');

        if (is401 && !retried && !isRefresh) {
          try {
            final nt = await _refresh();
            if (nt != null) {
              req.extra['retried'] = true;
              req.headers['Authorization'] = 'Bearer $nt';
              return h.resolve(await dio.fetch(req));
            }
          } catch (_) {}
        }

        final d = err.response?.data;
        final e = d is Map ? d['error'] as Map? : null;
        String msg;
        if (e?['message'] != null) {
          msg = e!['message'].toString();
        } else if (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout) {
          msg = 'Cannot reach the server at ${req.baseUrl}. '
              'Is the backend running and the URL still valid?';
        } else if (d is String && d.trimLeft().startsWith('<')) {
          msg = 'Server returned an HTML page instead of JSON.';
        } else {
          msg = err.message ?? 'Network error';
        }

        h.reject(DioException(
          requestOptions: req,
          response: err.response,
          error: ApiException(msg,
              status: err.response?.statusCode,
              code: e?['code']?.toString(),
              details: (e?['details'] as Map?)?.cast<String, dynamic>()),
          type: err.type,
        ));
      },
    ));
  }

  Future<String?> _refresh() async {
    if (_rc != null) return _rc!.future;
    _rc = Completer<String?>();
    try {
      final rt = await _st.readRefreshToken();
      if (rt == null) throw ApiException('No refresh token');
      final res = await Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'PelekaCustomerApp/1.0 (Dart; Flutter)',
        },
      )).post('/api/auth/refresh', data: {'refresh_token': rt});
      final data = res.data['data'];
      await _st.writeTokens(
          access: data['access_token'], refresh: data['refresh_token']);
      _rc!.complete(data['access_token']);
      return data['access_token'];
    } catch (_) {
      await _st.clear();
      _rc!.complete(null);
      return null;
    } finally {
      final d = _rc;
      _rc = null;
      d?.future.ignore();
    }
  }

  Future<Map<String, dynamic>> get(String p,
          {Map<String, dynamic>? query}) async =>
      _u(await dio.get(p, queryParameters: query));
  Future<Map<String, dynamic>> post(String p, {Object? body}) async =>
      _u(await dio.post(p, data: body));
  Future<Map<String, dynamic>> patch(String p, {Object? body}) async =>
      _u(await dio.patch(p, data: body));
  Future<Map<String, dynamic>> delete(String p) async =>
      _u(await dio.delete(p));
  Map<String, dynamic> _u(Response r) => r.data is Map<String, dynamic>
      ? r.data
      : {'success': true, 'data': r.data};
}

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(secureStorageProvider)));
