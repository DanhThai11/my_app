import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Đảm bảo đã import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // THÊM IMPORT NÀY
import 'package:my_app/elements/appbar.dart';
import 'package:my_app/pages/admin.dart';
import 'package:my_app/pages/forgotpassword.dart';
import 'package:my_app/pages/register.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';


// --- HÀM ĐĂNG NHẬP FACEBOOK (Giữ nguyên hoặc đã sửa) ---
Future<UserCredential?> signInWithFacebook(BuildContext context) async { // Thêm context để hiển thị SnackBar
  try {
    final LoginResult loginResult = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'], // Yêu cầu quyền nếu cần
    );

    if (loginResult.status == LoginStatus.success) {
      final AccessToken? accessToken = loginResult.accessToken;
      if (accessToken == null || accessToken.token.isEmpty) {
        print('Facebook access token is null or empty.');
        throw FirebaseAuthException(
          code: 'facebook_login_failed',
          message: 'Facebook access token is null or empty.',
        );
      }

      final OAuthCredential facebookAuthCredential =
      FacebookAuthProvider.credential(accessToken.token);

      return await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
    } else if (loginResult.status == LoginStatus.cancelled) {
      print('Đăng nhập Facebook đã bị người dùng hủy bỏ.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập Facebook đã bị hủy.')),
      );
      return null;
    } else {
      print('Lỗi đăng nhập Facebook: ${loginResult.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập Facebook: ${loginResult.message ?? "Lỗi không xác định."}')),
      );
      throw FirebaseAuthException(
        code: 'facebook_login_failed',
        message: loginResult.message ?? 'Đăng nhập Facebook thất bại không rõ nguyên nhân.',
      );
    }
  } on FirebaseAuthException catch (e) {
    print('Lỗi Firebase Auth với Facebook Credential: ${e.code} - ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi Firebase với Facebook: ${e.message}')),
    );
    throw e; // Ném lại lỗi để _handleFacebookSignIn bắt
  } catch (e) {
    print('Lỗi không xác định khi đăng nhập Facebook: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi không mong muốn khi đăng nhập Facebook.')),
    );
    throw Exception('Đã xảy ra lỗi không mong muốn trong quá trình đăng nhập Facebook: ${e.toString()}');
  }
}


// --- HÀM ĐĂNG NHẬP GOOGLE ---
Future<UserCredential?> signInWithGoogle(BuildContext context) async { // Thêm context để hiển thị SnackBar
  try {
    // Bắt đầu quá trình đăng nhập Google
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      // Người dùng hủy đăng nhập
      print('Đăng nhập Google đã bị hủy.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập Google đã bị hủy.')),
      );
      return null;
    }

    // Lấy thông tin xác thực từ tài khoản Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Tạo một credential cho Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Đăng nhập vào Firebase với credential
    return await FirebaseAuth.instance.signInWithCredential(credential);

  } on FirebaseAuthException catch (e) {
    print('Lỗi Firebase Auth với Google Credential: ${e.code} - ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi Firebase với Google: ${e.message}')),
    );
    throw e; // Ném lại lỗi để _handleGoogleSignIn bắt
  } catch (e) {
    print('Lỗi không xác định khi đăng nhập Google: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi không mong muốn khi đăng nhập Google.')),
    );
    throw Exception('Đã xảy ra lỗi không mong muốn trong quá trình đăng nhập Google: ${e.toString()}');
  }
}


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = false;
    // Khởi tạo Firebase nếu chưa (thường làm ở main.dart)
    // Firebase.initializeApp(); // Bỏ comment nếu bạn chưa khởi tạo ở main.dart
  }

  void _loginWithEmail() async {
    // ... (Giữ nguyên hàm này)
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (email == 'admin' && password == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập với tài khoản Admin')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thành công')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => appBar()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy người dùng';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      } else if (e.code == 'invalid-email') {
        message = 'Địa chỉ email không hợp lệ.';
      } else if (e.code == 'invalid-credential') { // Có thể là user-disabled, etc.
        message = 'Thông tin đăng nhập không hợp lệ hoặc tài khoản đã bị vô hiệu hóa.';
      } else {
        message = e.message ?? 'Lỗi không xác định';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi không mong muốn: ${e.toString()}')),
      );
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HÀM XỬ LÝ KHI NHẤN NÚT ĐĂNG NHẬP FACEBOOK ---
  Future<void> _handleFacebookSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      UserCredential? userCredential = await signInWithFacebook(context); // Truyền context
      if (userCredential != null && userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập Facebook thành công: ${userCredential.user!.displayName ?? userCredential.user!.email}')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => appBar()),
        );
      }
      // Không cần else ở đây vì nếu null hoặc lỗi, hàm signInWithFacebook đã hiển thị SnackBar hoặc ném lỗi
    } on FirebaseAuthException catch (e) {
      // Đã xử lý SnackBar trong signInWithFacebook, chỉ log ở đây nếu cần
      print('FirebaseAuthException in _handleFacebookSignIn: ${e.message}');
    } catch (e) {
      // Đã xử lý SnackBar trong signInWithFacebook
      print('Exception in _handleFacebookSignIn: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HÀM XỬ LÝ KHI NHẤN NÚT ĐĂNG NHẬP GOOGLE ---
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return; // Ngăn chặn nhiều lần nhấn khi đang xử lý
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential = await signInWithGoogle(context); // Truyền context

      if (userCredential != null && userCredential.user != null) {
        // Đăng nhập thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập Google thành công: ${userCredential.user!.displayName ?? userCredential.user!.email}')),
        );
        // Điều hướng đến màn hình chính hoặc màn hình tiếp theo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => appBar()), // Giả sử appBar() là màn hình chính
        );
      }
      // Không cần else ở đây vì nếu null hoặc lỗi, hàm signInWithGoogle đã hiển thị SnackBar hoặc ném lỗi
    } on FirebaseAuthException catch (e) {
      // Đã xử lý SnackBar trong signInWithGoogle, chỉ log ở đây nếu cần
      print('FirebaseAuthException in _handleGoogleSignIn: ${e.message}');
    } catch (e) {
      // Đã xử lý SnackBar trong signInWithGoogle
      print('Exception in _handleGoogleSignIn: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 12),
                Text(
                  'Enter your Email address to sign in.\nEnjoy your food :)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  // ... (Giữ nguyên cấu hình TextField email)
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green, width: 2)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  // ... (Giữ nguyên cấu hình TextField password với suffixIcon)
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.green, width: 2)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text('Forgot Password?', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
                    : ElevatedButton(
                  onPressed: _loginWithEmail,
                  // ... (Giữ nguyên style nút Sign In)
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  child: Text('SIGN IN', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have account? ", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                      },
                      child: Text('Create new account.', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row( // Hiển thị lại phần "Or" và các nút đăng nhập mạng xã hội
                  children: <Widget>[
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Or', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleFacebookSignIn,
                  icon: Icon(Icons.facebook, color: Colors.white),
                  label: Text('CONNECT WITH FACEBOOK'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B5998),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  // --- GỌI HÀM XỬ LÝ ĐĂNG NHẬP GOOGLE ---
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  // Cân nhắc dùng logo Google thực tế (ví dụ: thư viện font_awesome_flutter)
                  // Hoặc sử dụng một Image.asset nếu bạn có logo Google
                  icon: Icon(Icons.g_mobiledata, color: Colors.black87),                  label: Text('CONNECT WITH GOOGLE'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.grey.shade300)),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
    _passwordController.dispose();
    super.dispose();
  }
}