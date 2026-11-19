import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://server.pelekaapp.com',
);

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;
  final Map<String, dynamic>? details;
  ApiException(this.message, {this.status, this.code, this.details});
  @override
  String toString() => message;
}

String friendlyErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) =>
    error is ApiException ? error.message : fallback;

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
              'Server returned an HTML page instead of JSON. '
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
        final status = err.response?.statusCode;
        final serverMessage = e?['message'];
        if (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          msg = 'Unable to connect right now. Check your internet connection and try again.';
        } else if (d is String && d.trimLeft().startsWith('<')) {
          msg = 'We are having trouble reaching Peleka. Please try again shortly.';
        } else if (status == 401) {
          msg = 'Your session has expired or your sign-in details are incorrect. Please sign in again.';
        } else if (status == 403) {
          msg = 'You do not have permission to complete this action.';
        } else if (status == 404) {
          msg = 'We could not find the requested information.';
        } else if (status == 409) {
          msg = 'This action cannot be completed because the information has changed. Refresh and try again.';
        } else if (status == 422 || status == 400) {
          msg = _friendlyValidation(serverMessage);
        } else if (status != null && status >= 500) {
          msg = 'We are having trouble processing your request. Please try again shortly.';
        } else {
          msg = 'Something went wrong. Please try again.';
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

  String _friendlyValidation(dynamic value) {
    final raw = value is List ? value.join(' ') : value?.toString() ?? '';
    final lower = raw.toLowerCase();
    if (lower.contains('password')) return 'Please check your password and try again.';
    if (lower.contains('phone')) return 'Please check the phone number and try again.';
    if (lower.contains('email')) return 'Please check the email address and try again.';
    if (lower.contains('location') || lower.contains('coordinate')) return 'Please check the pickup and delivery locations.';
    if (lower.contains('discount') || lower.contains('promo')) return 'That promo code could not be applied. Check it and try again.';
    if (lower.contains('required') || lower.contains('invalid') || lower.contains('must')) return 'Some information is missing or invalid. Please review your entries.';
    return 'Please check the information entered and try again.';
  }

  Future<Response> _request(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException('Something went wrong. Please try again.',
          status: e.response?.statusCode);
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> get(String p,
          {Map<String, dynamic>? query, Map<String, dynamic>? headers}) async =>
      _u(await _request(() => dio.get(p, queryParameters: query, options: Options(headers: headers))));
  Future<Map<String, dynamic>> post(String p, {Object? body, Map<String, dynamic>? headers}) async =>
      _u(await _request(() => dio.post(p, data: body, options: Options(headers: headers))));
  Future<Map<String, dynamic>> patch(String p, {Object? body}) async =>
      _u(await _request(() => dio.patch(p, data: body)));
  Future<Map<String, dynamic>> delete(String p) async =>
      _u(await _request(() => dio.delete(p)));
  Map<String, dynamic> _u(Response r) => r.data is Map<String, dynamic>
      ? r.data
      : {'success': true, 'data': r.data};
}

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(secureStorageProvider)));
