
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:scalex_innovation/screens/chatScreen.dart';
import 'package:scalex_innovation/screens/homePage.dart';
import 'package:scalex_innovation/screens/login.dart';

import 'package:scalex_innovation/screens/splashScreen.dart';
import 'package:scalex_innovation/screens/summaries_screen.dart';
import 'package:scalex_innovation/screens/user_profile_screen.dart';
import 'package:scalex_innovation/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('chat_history');
  await Hive.openBox('app_prefs');
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  await dotenv.load(fileName: ".env");
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ScaleX Chatbot',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        theme: ThemeData.light().copyWith(useMaterial3: true),
        home: FirebaseAuth.instance.currentUser == null
            ? SplashScreen()
            : HomePage(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomePage(),
        '/chat': (context) => const ChatScreen(),
        '/summary': (_) => SummariesScreen(),
        '/profile': (_) => const UserProfileScreen(),
    },
    );
  }
}
