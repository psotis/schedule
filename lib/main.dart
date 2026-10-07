// ignore: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/keys/material_key.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/repositories/search_edit_user_repository.dart';
import 'package:scheldule/repositories/user_admin_repository.dart';
import 'package:scheldule/routes/route_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/add_appointment_repository.dart';
import 'repositories/employee_repository.dart';

SharedPreferences? prefs;

//! Starting point
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (geminiApiKey.isNotEmpty) Gemini.init(apiKey: geminiApiKey);
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle
        .loadString('assets/google_fonts/ibm_plex_sans/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  prefs = await SharedPreferences.getInstance();

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient: apiClient);
  await authRepository.initialize();

  runApp(MyApp(apiClient: apiClient, authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.apiClient,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<AppointmentRepository>(
          create: (context) => AppointmentRepository(apiClient: apiClient),
        ),
        Provider<AddAppointmentRepository>(
          create: (context) => AddAppointmentRepository(apiClient: apiClient),
        ),
        Provider<EmployeeRepository>(
          create: (context) => EmployeeRepository(apiClient: apiClient),
        ),
        Provider<SearchEditUserRepository>(
          create: (context) => SearchEditUserRepository(apiClient: apiClient),
        ),
        Provider<TransactionRepository>(
          create: (context) => TransactionRepository(apiClient: apiClient),
        ),
        Provider<UserAdminRepository>(
          create: (context) => UserAdminRepository(apiClient: apiClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(authRepository: authRepository),
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
          create: (context) => AddUserProvider(
            repository: context.read<SearchEditUserRepository>(),
          ),
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
        ChangeNotifierProvider<EmployeeProvider>(
          create: (context) => EmployeeProvider(
            employeeRepository: context.read<EmployeeRepository>(),
          ),
        ),
        ChangeNotifierProvider<TransactionStateProvider>(
          create: (context) => TransactionStateProvider(
            repository: context.read<TransactionRepository>(),
          ),
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
