import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zendoro/pages/auth/sign_up.dart';
import '../../models/user_model.dart';
import '../home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _signIn() async {
    final usersBox = Hive.box<UserModel>('usersBox');
    final userBox = Hive.box<UserModel>('userBox');

    final emailKey = emailController.text.trim().toLowerCase();
    final user = usersBox.get(emailKey);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account found with this email.')),
      );
      return;
    }

    if (user.password != passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password.')),
      );
      return;
    }

    // Save a fresh copy to currentUser
    await userBox.put('currentUser', user);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 4),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Sign In'),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 5),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSetupPage()),
                );
              },
              child: const Text(
                "Don't have an account? Sign Up",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
