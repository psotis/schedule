import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/custom_errors.dart';
import 'api_client.dart';

class SearchEditUserRepository {
  final ApiClient apiClient;

  SearchEditUserRepository({required this.apiClient});

  Stream<List<AppointMent>> streamUser() async* {
    while (true) {
      yield await findUsers();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<AppointMent>> findUsers() async {
    try {
      final data = await apiClient.get('/client') as List;
      return data
          .map((item) => AppointMent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> deleteUser({required String clientId}) async {
    try {
      await apiClient.delete('/client/$clientId');
    } catch (e) {
      throw CustomError(message: e.toString());
    }
  }

  //! *********** Patient appointment length *****************
  Future<int> patientAppointmentLength({
    required String name,
    required String surename,
  }) async {
    try {
      final clients = await findUsers();
      final client = clients.where(
        (item) => item.name == name && item.surname == surename,
      );
      if (client.isEmpty) return 0;
      final appointments = await apiClient.get(
        '/appointments/client/${client.first.id}',
      ) as List;
      return appointments.length;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> editPatient({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    String? description,
    required String amka,
    required String docId,
    String? owes,

    // New optional fields
    bool? heart,
    bool? breathe,
    bool? sugar,
    bool? ypertash,
    bool? neuro,
    bool? orthopedic,
    bool? selfCare,
    bool? helpCare,
    bool? disabled,
    bool? good,
    bool? medium,
    bool? bad,
    bool? yes,
    bool? no,
    String? birthday,
    String? allo,
    String? startingDate,
    String? mainIssue,
    String? doctor,
    String? surgeryPast,
    String? surgeryNow,
    String? pharmacy,
    String? allergies,
    String? spot,
    String? missFunctions,
  }) async {
    try {
      final customFields = <String, dynamic>{
        'heart': heart ?? false,
        'breathe': breathe ?? false,
        'sugar': sugar ?? false,
        'ypertash': ypertash ?? false,
        'neuro': neuro ?? false,
        'orthopedic': orthopedic ?? false,
        'selfCare': selfCare ?? false,
        'helpCare': helpCare ?? false,
        'disabled': disabled ?? false,
        'good': good ?? false,
        'medium': medium ?? false,
        'bad': bad ?? false,
        'yes': yes ?? false,
        'no': no ?? false,
        'birthday': birthday ?? '',
        'allo': allo ?? '',
        'startingDate': startingDate ?? '',
        'mainIssue': mainIssue ?? '',
        'doctor': doctor ?? '',
        'surgeryPast': surgeryPast ?? '',
        'surgeryNow': surgeryNow ?? '',
        'pharmacy': pharmacy ?? '',
        'allergies': allergies ?? '',
        'spot': spot ?? '',
        'missFunctions': missFunctions ?? '',
      };
      final definitions = await apiClient.get('/store/client-fields') as List;
      final supportedKeys = definitions
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['is_active'] == true)
          .map((item) => item['field_key']?.toString())
          .whereType<String>()
          .toSet();
      customFields.removeWhere((key, value) => !supportedKeys.contains(key));

      await apiClient.put('/client/$docId', body: {
        'first_name': name,
        'last_name': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'client_description': description ?? '',
        'owes': owes ?? '',
        if (customFields.isNotEmpty) 'custom_fields': customFields,
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> addPatient({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String owes,
  }) async {
    try {
      await apiClient.post('/client', body: {
        'first_name': name,
        'last_name': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'afm': '',
        'amka': amka,
        'client_description': description,
        'owes': num.tryParse(owes) ?? 0,
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }
}
