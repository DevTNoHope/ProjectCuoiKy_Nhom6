import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../services/ai_gemini_service.dart';

class HairTryOnScreen extends StatefulWidget {
  const HairTryOnScreen({super.key});
  @override
  State<HairTryOnScreen> createState() => _HairTryOnScreenState();
}

class _HairTryOnScreenState extends State<HairTryOnScreen> {
  final _picker = ImagePicker();
  File? _file;
  bool _loading = false;
  List<String> _urls = [];
  final _promptCtl = TextEditingController(
    text: 'Giữ nguyên khuôn mặt và tông da, chỉ chỉnh kiểu tóc '
        'theo phong cách layer/fade hiện đại, ánh sáng tự nhiên.',
  );

  late final AiGeminiService _svc;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Dio theo project của bạn
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ));
    // TODO: nếu có interceptor token thì thêm ở đây: dio.interceptors.add(AuthInterceptor(...));
    _svc = AiGeminiService(dio);
  }

  Future<void> _pick(bool camera) async {
    final x = await (camera
        ? _picker.pickImage(source: ImageSource.camera, imageQuality: 90)
        : _picker.pickImage(source: ImageSource.gallery, imageQuality: 90));
    if (x != null) {
      setState(() {
        _file = File(x.path);
        _urls = [];
      });
    }
  }

  Future<void> _send() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn hoặc chụp một ảnh trước đã.')));
      return;
    }
    setState(() { _loading = true; _urls = []; });
    try {
      final urls = await _svc.editImageAndGetUrls(
        filePath: _file!.path,
        prompt: _promptCtl.text.trim(),
      );
      setState(() => _urls = urls);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý kiểu tóc (Gemini)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              ElevatedButton.icon(
                onPressed: () => _pick(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _pick(false),
                icon: const Icon(Icons.photo),
                label: const Text('Thư viện'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Home'),
              ),
            ]),
            const SizedBox(height: 8),
            if (_file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_file!, height: 180, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptCtl,
              minLines: 2, maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Prompt tạo ảnh',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _send,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Gửi & nhận ảnh'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _urls.isEmpty ? const SizedBox.shrink()
                  : GridView.builder(
                padding: const EdgeInsets.only(top: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: _urls.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
