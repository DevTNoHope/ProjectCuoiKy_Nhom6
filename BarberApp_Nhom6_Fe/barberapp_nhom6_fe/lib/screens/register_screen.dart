// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _fullNameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _loading = false;
  final _auth = AuthService();

  @override
  void dispose() {
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _fullNameCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // kiểm tra: ít nhất 1 trong 2
    final email = _emailCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Email hoặc Số điện thoại')),
      );
      return;
    }

    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.register(RegisterRequest(
        fullName: _fullNameCtl.text.trim(),
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        password: _passwordCtl.text,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Hãy đăng nhập.')),
        );
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại (tuỳ chọn)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              validator: (v) =>
              (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator())
                  : const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }
}
