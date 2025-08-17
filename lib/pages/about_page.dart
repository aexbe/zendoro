import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Import URL launcher if you decide to enable the commented-out website links
// import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// Fetches the application's package information, including version and name.
  /// This helps keep the About page dynamically updated with the correct app details.
  Future<Map<String, String>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': '${packageInfo.version} (${packageInfo.buildNumber})',
      'name': packageInfo.appName,
    };
  }

  /// Helper function to launch URLs. Uncomment if you enable website links.
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      // Fallback if URL cannot be launched (e.g., show a snackbar)
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // A more friendly and inviting app bar title
        title: const Text('Greetings from Zendoro!'),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getAppInfo(),
        builder: (context, snapshot) {
          // Grabs app info, or uses defaults if something goes sideways
          final info = snapshot.data ?? {'version': '1.0.0', 'name': 'Zendoro'};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  // Your app icon, still looking sharp!
                  child: Image.asset(
                    'assets/icon.png', 
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    // Friendly greeting with the app's name
                    '${info['name']}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Center(
                  child: Text(
                    // Clearly states the version for curious minds
                    'Version: ${info['version']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 40),

                // --- About Zendoro Section ---
                const Text(
                  'What\'s the Zendoro Story?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Alright, so here\'s the real talk: we totally get it. Ever felt like your day just *vanishes* into a black hole of distractions? One minute you\'re starting a task, the next you\'re three hours deep into cat videos on the internet. Yeah, we\'ve been there too. Seriously, countless times! That nagging feeling of "I should be doing something productive" but somehow always ending up elsewhere? That\'s precisely why we cooked up **Zendoro**!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We wanted a tool that actually *helps*, without being overly complicated or preachy. Something that guides you, gently but firmly, back to what truly matters. So, we dove deep into the legendary **Pomodoro Technique**—you know, those focused sprints followed by chill breaks—and built a digital sidekick around it. It\'s not just about setting a timer; it\'s about training your brain to stay on target, celebrating small wins, and giving yourself permission to recharge.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Zendoro is all about making your work flow smoother than a fresh jar of peanut butter, keeping you on track with your daily routines, and helping you truly build those awesome productive habits that stick. No more feeling overwhelmed or constantly playing catch-up. Just focused, intentional progress, one Pomodoro at a time. We genuinely believe in making productivity less of a chore and more of a natural, satisfying part of your day. Happy focusing – we built this for *you*!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),

                // --- Developer Section ---
                const Text(
                  'Meet the developer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 27.5,
                    backgroundImage: AssetImage(
                      'assets/mihir.jpg', // Mihir's picture, looking good!
                    ),
                  ),
                  title: const Text('Mihir Dev'),
                  subtitle: const Text('Flutter Enthusiast | Student | Creator of Zendoro'),
                  // A more personal and less formal snakbar message
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Want to connect? Find Mihir on LinkedIn!')),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Contact Section ---
                const Text(
                  'Got a Question? We\'re All Ears!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Holler at Us!'),
                  subtitle: const Text('zendoro.help@gmail.com'),
                  // A friendly invitation to reach out
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Drop us an email anytime, we\'d love to hear from you!')),
                  ),
                ),
                // Uncomment these if you want to add website links later
                // ListTile(
                //   leading: const Icon(Icons.language),
                //   title: const Text('Our Home on the Web'),
                //   subtitle: const Text('https://zendoro.app'),
                //   onTap: () => _launchUrl('https://zendoro.app'),
                // ),
                 ListTile(
                   leading: const Icon(Icons.code),
                   title: const Text('Mihir\'s Digital Space'),
                   subtitle: const Text('https://www.linkedin.com/in/mihir-dev-a4165736a/'), 
                   onTap: () => _launchUrl('https://www.linkedin.com/in/mihir-dev-a4165736a/'),
                 ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Thanks for using Zendoro!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
