// ignore: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/firebase_options.dart';
import 'package:scheldule/keys/material_key.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/search_edit_user_repository.dart';
import 'package:scheldule/routes/route_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'repositories/add_appointment_repository.dart';

SharedPreferences? prefs;

//! Starting point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle
        .loadString('assets/google_fonts/ibm_plex_sans/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  prefs = await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final Future<FirebaseApp> _fbApp = Firebase.initializeApp();
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            firebaseFirestore: FirebaseFirestore.instance,
            firebaseAuth: fb_auth.FirebaseAuth.instance,
          ),
        ),
        Provider<AppointmentRepository>(
          create: (context) => AppointmentRepository(),
        ),
        Provider<AddAppointmentRepository>(
          create: (context) => AddAppointmentRepository(),
        ),
        Provider<SearchEditUserRepository>(
          create: (context) => SearchEditUserRepository(),
        ),
        StreamProvider<fb_auth.User?>(
          create: (context) => context.read<AuthRepository>().user,
          initialData: null,
        ),
        ChangeNotifierProxyProvider<fb_auth.User?, AuthProvider>(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
          ),
          update: (BuildContext context, fb_auth.User? userStream,
                  AuthProvider? authProvider) =>
              authProvider!..update(userStream),
        ),
        ChangeNotifierProvider<SigninProvider>(
          create: (context) => SigninProvider(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<SignupProvider>(
          create: (context) => SignupProvider(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<AppointmentProvider>(
          create: (context) => AppointmentProvider(
              appointmentRepository: context.read<AppointmentRepository>()),
        ),
        ChangeNotifierProvider<AddUserProvider>(
          create: (context) => AddUserProvider(),
        ),
        ChangeNotifierProvider<SearchUserProvider>(
          create: (context) => SearchUserProvider(
              searchEditUserRepository:
                  context.read<SearchEditUserRepository>()),
        ),
        ChangeNotifierProvider<AddAppointmentProvider>(
          create: (context) => AddAppointmentProvider(
              addAppointmentRepository:
                  context.read<AddAppointmentRepository>()),
        ),
        ChangeNotifierProvider<ChangePageProvider>(
          create: (context) => ChangePageProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider<DrawerProvider>(
          create: (context) => DrawerProvider(),
        ),
        ChangeNotifierProvider<ToggleScreenProvider>(
          create: (context) => ToggleScreenProvider(),
        ),
      ],
      child: Builder(builder: (context) {
        return MaterialApp(
          title: 'My Schedule',
          debugShowCheckedModeBanner: false,
          theme: context.watch<ThemeProvider>().state?.themeData,
          onGenerateRoute: RouteGenerator.generateRoute,
          navigatorKey: AppMaterialKey.materialKey,
          initialRoute: '/',
          locale: const Locale('el'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('el'),
            const Locale('en'),
          ],
        );
      }),
    );
  }
}
