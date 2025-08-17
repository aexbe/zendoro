import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zendoro/pages/auth/sign_in.dart';
import 'package:zendoro/pages/auth/sign_up.dart';

class Lobby extends StatelessWidget {
  const Lobby({super.key});

  final String icon = "icon.png";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 4,
            ),
            Text(
              'Zendoro',
              style: GoogleFonts.sanchez(
                  fontSize: 40, fontWeight: FontWeight.w700),
            ),
            const SizedBox(
              height: 20,
            ),
            CircleAvatar(
              radius: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Image.asset(
                  'assets/icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              style: ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(
                      Size(MediaQuery.of(context).size.width - 40, 60))),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AccountSetupPage()),
              ),
              child: const Text(
                'Go to account creation >',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "or",
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  fontSize: 14),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(
                      Size(MediaQuery.of(context).size.width - 40, 60))),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SignInPage()),
              ),
              child: const Text(
                'Login >',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
