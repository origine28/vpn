import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({required this.statusCode, required this.jsonBody});

  final int statusCode;
  final Object jsonBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(jsonBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
