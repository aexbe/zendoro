import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:zendoro/models/backlog_model.dart';
import 'package:zendoro/models/board_model.dart';
import 'package:zendoro/models/focus_entry_data.dart';
import 'package:zendoro/models/journal_entry_data.dart';
import 'package:zendoro/models/media_entry_data.dart';
import 'package:zendoro/models/tasks_entry_data.dart';
import 'package:zendoro/pages/auth/lobby.dart';

import 'models/user_model.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(JournalEntryDataAdapter());
  Hive.registerAdapter(TasksEntryDataAdapter());
  Hive.registerAdapter(FocusEntryDataAdapter());
  Hive.registerAdapter(BacklogAdapter());
  Hive.registerAdapter(MediaEntryAdapter());
  Hive.registerAdapter(BoardAdapter());

  await Hive.openBox<UserModel>('usersBox'); // All stored users
  await Hive.openBox<UserModel>('userBox'); // Current logged-in user

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check if user exists
  final userBox = Hive.box<UserModel>('userBox');
  final hasAccount = userBox.get('currentUser') != null;

  runApp((MyApp(hasAccount: hasAccount)));
}

class MyApp extends StatelessWidget {
  final bool hasAccount;
  MyApp({super.key, required this.hasAccount});

  final _appTheme = FlexThemeData.light(
    scheme: FlexScheme.blackWhite,
    appBarStyle: FlexAppBarStyle.scaffoldBackground,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useMaterial3Typography: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zendoro',
      debugShowCheckedModeBanner: false,
      theme: _appTheme,
      home: hasAccount ? const MyHomePage() : Lobby(),
    );
  }
}
