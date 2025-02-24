import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class ApiClient {
  final String baseUrl = 'https://api.example.com';
  final Dio _dio = Dio();

  Future<ByteData> downloadZipFile() async {
    // TODO: Download the ZIP file from the server instead
    final ByteData data = await rootBundle.load('assets/web.zip');

    return data;
  }
}
