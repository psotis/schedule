// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String address;
  final String afm;
  final String amka;
  final String specialiazation;
  final String contractType;
  final String? paid;
  final String? color;
  final List<String> serviceIds;
  final List<Map<String, dynamic>> availability;
  Employee({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.address,
    required this.afm,
    required this.amka,
    required this.specialiazation,
    required this.contractType,
    this.paid,
    this.color,
    this.serviceIds = const [],
    this.availability = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> userData) {
    return Employee(
      id: (userData['uuid'] ?? '').toString(),
      name: (userData['first_name'] ?? '').toString(),
      surname: (userData['last_name'] ?? '').toString(),
      phone: (userData['phone'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      address: (userData['address'] ?? '').toString(),
      afm: (userData['afm'] ?? '').toString(),
      amka: (userData['amka'] ?? '').toString(),
      specialiazation: (userData['specialization'] ?? '').toString(),
      contractType: (userData['contract_type'] ?? '').toString(),
      paid: (userData['paid'] ?? '').toString(),
      color: (userData['color'] ?? '').toString(),
      serviceIds: ((userData['serviceCapabilities'] ?? const []) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) => (item['service_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      availability: ((userData['availability'] ?? const []) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  factory Employee.initial() {
    return Employee(
      id: '',
      name: '',
      surname: '',
      email: '',
      phone: '',
      address: '',
      afm: '',
      amka: '',
      specialiazation: '',
      contractType: '',
      paid: '',
      color: '',
      serviceIds: const [],
      availability: const [],
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? address,
    String? afm,
    String? amka,
    String? specialiazation,
    String? contractType,
    String? paid,
    String? color,
    List<String>? serviceIds,
    List<Map<String, dynamic>>? availability,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      afm: afm ?? this.afm,
      amka: amka ?? this.amka,
      specialiazation: specialiazation ?? this.specialiazation,
      contractType: contractType ?? this.contractType,
      paid: paid ?? this.paid,
      color: color ?? this.color,
      serviceIds: serviceIds ?? this.serviceIds,
      availability: availability ?? this.availability,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        id,
        name,
        surname,
        email,
        phone,
        address,
        afm,
        amka,
        specialiazation,
        contractType,
        paid,
        color,
        serviceIds,
        availability,
      ];
}
