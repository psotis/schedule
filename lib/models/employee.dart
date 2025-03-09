// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

  factory Employee.fromDoc(DocumentSnapshot doc) {
    final userData = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: userData['name'],
      surname: userData['surname'],
      phone: userData['phone'],
      email: userData['email'],
      address: userData['address'],
      afm: userData['afm'],
      amka: userData['amka'],
      specialiazation: userData['specialiazation'],
      contractType: userData['contract_type'],
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
        contractType
      ];
}
