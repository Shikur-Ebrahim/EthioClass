import 'package:dio/dio.dart';

class DioClient {
  final Dio _dio;

  DioClient() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.ethioclass.com', // To be configured for the VPS
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Dio get dio => _dio;
}
