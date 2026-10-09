import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../models/custom_errors.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient apiClient;
  final GoogleSignIn _googleSignIn;
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  AuthRepository({required this.apiClient, GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb
                  ? const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')
                  : defaultTargetPlatform == TargetPlatform.iOS ||
                          defaultTargetPlatform == TargetPlatform.macOS
                      ? const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID')
                      : null,
              serverClientId: kIsWeb
                  ? null
                  : const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
              scopes: const ['email', 'profile'],
            );

  Stream<AppUser?> get user => _userController.stream;
  AppUser? get currentUser => _currentUser;

  Future<void> initialize() async {
    await apiClient.restoreSession();
    if (!apiClient.hasSession) {
      _emit(null);
      return;
    }
    try {
      final json = Map<String, dynamic>.from(
        await apiClient.get('/user/me') as Map,
      );
      json['active_store_id'] = apiClient.activeStoreId;
      _emit(AppUser.fromJson(json));
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await apiClient.clearSession();
        _emit(null);
        return;
      }
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    String storeType = 'physiotherapy',
  }) async {
    await _authenticate('/user/signup', {
      'display_name': name,
      'email': email,
      'password_hash': password,
      'store_type': storeType,
      'store_name': name,
    });
  }

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    await _authenticate('/user/login', {
      'email': email,
      'password_hash': password,
    });
  }

  Future<void> signInWithGoogle({String? storeType}) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final authentication = await account.authentication;
      if (authentication.idToken == null) {
        throw CustomError(
          code: 'google-token-missing',
          message: 'Google did not return an identity token',
          plugin: 'google_sign_in',
        );
      }
      final body = <String, dynamic>{
        'id_token': authentication.idToken,
        'store_name': account.displayName ?? account.email,
      };
      if (storeType != null) body['store_type'] = storeType;
      await _authenticate('/user/google', body);
    } on ApiException catch (error) {
      throw _customError(error);
    }
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final data = Map<String, dynamic>.from(
        await apiClient.post(path, body: body) as Map,
      );
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException(500, 'Authentication token is missing');
      }
      final storeId = data['active_store_id']?.toString();
      await apiClient.saveSession(token: token, storeId: storeId);
      _emit(AppUser.fromJson(data));
    } on ApiException catch (error) {
      throw _customError(error);
    }
  }

  Future<void> signout() async {
    try {
      if (apiClient.hasSession) await apiClient.post('/user/logout');
    } finally {
      await Future.wait([
        apiClient.clearSession(),
        _googleSignIn.signOut(),
      ]);
      _emit(null);
    }
  }

  void _emit(AppUser? user) {
    _currentUser = user;
    _userController.add(user);
  }

  CustomError _customError(ApiException error) => CustomError(
        code: error.statusCode.toString(),
        message: error.message,
        plugin: 'schedule_service',
      );

  void dispose() => _userController.close();
}
