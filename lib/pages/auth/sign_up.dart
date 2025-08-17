import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:zendoro/pages/auth/sign_in.dart';
import '../../models/user_model.dart';
import '../home_page.dart';

class AccountSetupPage extends StatefulWidget {
  const AccountSetupPage({super.key});

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = "Male";
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }
  Future<void> _saveUser() async {
    final usersBox = Hive.box<UserModel>('usersBox');
    final userBox = Hive.box<UserModel>('userBox');

    final newUser = UserModel(
      name: _nameCtrl.text,
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passCtrl.text,
      profilePicBytes: _imageBytes,
      gender: _gender,
      age: int.parse(_ageCtrl.text),
    );

    if (usersBox.containsKey(newUser.email.trim().toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account already exists. Please sign in.')),
      );
      return;
    }

    if (newUser.email.trim().toLowerCase().isEmpty) {
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account already exists. Please sign in.')),
      );
      return;
  }
    
    await usersBox.put(newUser.email.trim().toLowerCase(), newUser);
    await userBox.put('currentUser', newUser);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyHomePage()),
    );
  }

  void showAdminKeyPrompt(BuildContext context) {
    final TextEditingController keyController = TextEditingController();
    const String adminKey = "0"; 

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Admin Key"),
        content: TextField(
          controller: keyController,
          decoration: const InputDecoration(
            labelText: "Admin Key",
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (keyController.text.trim() == adminKey) {
                Navigator.pop(context);
                showAllUsersDebug(context);
              } else {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Access Denied"),
                    content: const Text("HaHa, Ask the admin. LOL"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  void showAllUsersDebug(BuildContext context) {
    final usersBox = Hive.box<UserModel>('usersBox');
    final allUsers = usersBox.values.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("All Accounts"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allUsers.length,
            itemBuilder: (_, index) {
              final user = allUsers[index];
              return ListTile(
                title: Text(user.email),
                subtitle: Text("Password: ${user.password}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                  child: _imageBytes == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 50),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v!.isEmpty ? "Enter your email" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
                validator: (v) => v!.isEmpty ? "Enter your age" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: _gender,
                items: ["Male", "Female", "Other"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveUser,
                child: const Text("Continue"),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () => showAdminKeyPrompt(context),
                  child: const Text(
                    "Show all users info",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Sign In",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
