import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class AiGeminiService {
  final Dio _dio;
  AiGeminiService(this._dio);

  Future<List<String>> editImageAndGetUrls({
    required String filePath,
    required String prompt,
  }) async {
    final contentType = _guessContentType(filePath);

    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType.parse(contentType),
      ),
      'prompt': prompt,
    });

    try {
      final res = await _dio.post(
        '/ai/gemini/edit-image-url',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final List urls = res.data['urls'] as List;
      return urls.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      // Xử lý 429: đợi Retry-After rồi thử lại 1 lần
      if (e.response?.statusCode == 429) {
        final retryAfter = e.response?.headers.value('retry-after');
        final waitSec = int.tryParse((retryAfter ?? '2').replaceAll('s', '')) ?? 2;
        await Future.delayed(Duration(seconds: waitSec.clamp(1, 10)));
        final res2 = await _dio.post(
          '/ai/gemini/edit-image-url',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
        final List urls = res2.data['urls'] as List;
        return urls.map((e) => e.toString()).toList();
      }
      rethrow;
    }
  }

  String _guessContentType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
