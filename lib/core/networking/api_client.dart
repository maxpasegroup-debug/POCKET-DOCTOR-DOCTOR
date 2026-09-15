import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../errors/api_failure.dart';

class ApiClient {
  ApiClient(
    this.baseUrl, {
    http.Client? transport,
    this.timeout = const Duration(seconds: 12),
  }) : _transport = transport ?? http.Client();
  final String baseUrl;
  final http.Client _transport;
  final Duration timeout;
  String? _token;
  int _generation = 0;
  void Function()? onExpired;
  void setToken(String? token) {
    _generation++;
    _token = token;
  }

  void close() => _transport.close();

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Duration? requestTimeout,
  }) async {
    final generation = _generation;
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.followRedirects = false;
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    if (body != null) request.body = jsonEncode(body);
    http.Response response;
    try {
      response = await _transport
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout ?? timeout);
    } catch (error) {
      if (kDebugMode) {
        // Classify locally; never log raw errors, URLs, request bodies or headers.
        final detail = error.toString().toLowerCase();
        final category = error is TimeoutException
            ? 'timeout'
            : detail.contains('failed host lookup') ||
                  detail.contains('name resolution')
            ? 'dns'
            : detail.contains('handshake') || detail.contains('certificate')
            ? 'tls'
            : detail.contains('refused')
            ? 'connection-refused'
            : detail.contains('network is unreachable') ||
                  detail.contains('no route')
            ? 'network-unreachable'
            : 'transport';
        debugPrint(
          'Doctor network failure: host=${request.url.host}; category=$category',
        );
      }
      throw const ApiFailure(
        'We could not connect. Check your connection and try again.',
      );
    }
    if (generation != _generation) {
      throw const ApiFailure('Your session has changed. Please sign in again.');
    }
    if (response.statusCode == 401) {
      setToken(null);
      onExpired?.call();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (path.startsWith('/doctor/registration') ||
          path.startsWith('/auth/otp/')) {
        String? code;
        try {
          code =
              ((jsonDecode(response.body) as Map<String, dynamic>)['error']
                      as Map<String, dynamic>?)?['code']
                  as String?;
        } catch (_) {}
        final message = switch (code) {
          'TEST_LOGIN_NOT_ALLOWED' =>
            'This account is not eligible for Doctor staging testing. Use your configured synthetic Doctor account; applicants should use registration.',
          'DOCTOR_REGISTRATION_REQUIRED' =>
            'No doctor account exists yet. Choose Register as Doctor to apply.',
          'DOCTOR_LOGIN_NOT_ALLOWED' =>
            'This account cannot sign in to the Doctor app. Use your linked doctor number or contact the platform team.',
          'REGISTRATION_NOT_ALLOWED' =>
            'This account cannot register as a new doctor. Contact the platform team.',
          'PRIVATE_STORAGE_UNAVAILABLE' =>
            'Secure document storage is unavailable. Your draft is saved; please try again later.',
          'DOCUMENT_POLICY_UNAVAILABLE' =>
            'The platform document review policy is not configured yet.',
          'APPLICATION_INCOMPLETE' =>
            'Complete your basic and professional information before submitting.',
          'DOCUMENTS_REQUIRED' =>
            'Upload all documents required by the review policy.',
          'APPLICATION_LOCKED' =>
            'Your application cannot be edited in its current state. Check status.',
          'INVALID_DOCUMENT' => 'Choose a valid PDF, JPEG or PNG up to 5 MB.',
          _ => null,
        };
        if (message != null) throw ApiFailure(message, response.statusCode);
      }

      throw ApiFailure(switch (response.statusCode) {
        400 => 'Please check your details and try again.',
        401 => 'Your session has ended. Please sign in again.',
        403 => 'A verified, assigned doctor account is required.',
        404 => 'This record is no longer available. Refresh and try again.',
        409 => 'This action is not available now. Refresh and try again.',
        429 => 'Please wait a moment before trying again.',
        _ => 'We could not complete that request. Please try again.',
      }, response.statusCode);
    }
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return payload['data'] as Map<String, dynamic>;
    } catch (_) {
      throw const ApiFailure(
        'We could not read the response. Please try again.',
      );
    }
  }
}
