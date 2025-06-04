import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/pages/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _feedbackMessage; // To show success or error messages

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _feedbackMessage = 'Vui lòng nhập địa chỉ email của bạn.';
      });
      return;
    }

    // Basic email validation (optional, Firebase handles more robust validation)
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      setState(() {
        _feedbackMessage = 'Địa chỉ email không hợp lệ.';
      });
      return;
    }


    setState(() {
      _isLoading = true;
      _feedbackMessage = null; // Clear previous message
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        _feedbackMessage = 'Đã gửi email đặt lại mật khẩu đến $email. Vui lòng kiểm tra hộp thư của bạn (kể cả mục spam).';
        _emailController.clear(); // Clear the field on success
      });
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy người dùng nào với địa chỉ email này.';
      } else if (e.code == 'invalid-email') {
        message = 'Địa chỉ email không hợp lệ.';
      } else {
        message = 'Đã xảy ra lỗi. Vui lòng thử lại. (${e.message})';
      }
      setState(() {
        _feedbackMessage = message;
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại. (${e.toString()})';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quên Mật Khẩu', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0, // No shadow
        iconTheme: IconThemeData(color: Colors.green), // Back button color
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đặt Lại Mật Khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 12),
                Text(
                  'Nhập địa chỉ email đã đăng ký của bạn. Chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green, width: 2)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 24),
                if (_feedbackMessage != null) ...[
                  Text(
                    _feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedbackMessage!.startsWith('Đã gửi') ? Colors.blueAccent : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                _isLoading
                    ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
                    : ElevatedButton(
                  onPressed: _sendPasswordResetEmail,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  child: Text('GỬI EMAIL ĐẶT LẠI', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) =>  LoginScreen()),
                    );                  },
                  child: Text(
                    'Quay lại Đăng nhập',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}