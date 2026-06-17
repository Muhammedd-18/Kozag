import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'database_helper.dart';
import 'admin_screen.dart';
import 'mother_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _maidenNameController = TextEditingController();

  final FocusNode _tcFocusNode = FocusNode();
  String? _tcErrorText;

  @override
  void initState() {
    super.initState();
    _tcFocusNode.addListener(() {
      if (!_tcFocusNode.hasFocus) {
        setState(() {
          String text = _tcController.text.trim();
          if (text.isNotEmpty && text != 'admin' && text.length != 11) {
            _tcErrorText = 'TC Kimlik No 11 haneli olmalıdır!';
          } else {
            _tcErrorText = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tcFocusNode.dispose();
    _tcController.dispose();
    _maidenNameController.dispose();
    super.dispose();
  }

  void _login() async {
    String tc = _tcController.text.trim();
    String maidenName = _maidenNameController.text.trim();

    if (tc.isEmpty || maidenName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun.')));
      return;
    }

    if (tc != 'admin' && tc.length != 11) {
      setState(() => _tcErrorText = 'TC Kimlik No 11 haneli olmalıdır!');
      return;
    }

    final user = await DatabaseHelper.instance.loginUser(tc, maidenName);

    if (!mounted) return;

    if (user != null) {
      if (user['tc_no'] == 'admin') {

        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MotherDashboard(user: user)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hatalı giriş! Kayıt bulunamadı.'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
                      ]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.favorite, size: 70, color: Color(0xFFD67B8E)),
                      const SizedBox(height: 10),

                      const Text(
                          'Kozağ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFFD67B8E))
                      ),
                      const SizedBox(height: 35),

                      TextField(
                        controller: _tcController,
                        focusNode: _tcFocusNode,
                        inputFormatters: [LengthLimitingTextInputFormatter(11)],
                        decoration: InputDecoration(
                          labelText: 'TC Kimlik No',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          errorText: _tcErrorText,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _maidenNameController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Anne Kızlık Soyadı (Şifre)',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD67B8E),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: const Text('Giriş Yap', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}