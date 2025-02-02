import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class AppointMent extends Equatable {
  final String id;
  final String name;
  final String surname;
  final String phone;
  final String email;
  final String address;
  final String description;
  final String amka;
  Timestamp? date;
  AppointMent({
    required this.id,
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    required this.address,
    required this.description,
    required this.amka,
    this.date,
  });

  factory AppointMent.fromDoc(DocumentSnapshot doc) {
    final userData = doc.data() as Map<String, dynamic>;
    return AppointMent(
        id: doc.id,
        name: userData['name'],
        surname: userData['surname'],
        phone: userData['phone'],
        email: userData['email'],
        address: userData['address'],
        description: userData['description'],
        amka: userData['amka'],
        date: userData['date']);
  }

  factory AppointMent.initial() {
    return AppointMent(
      id: '',
      name: '',
      surname: '',
      phone: '',
      email: '',
      address: '',
      description: '',
      amka: '',
      date: Timestamp.now(),
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      name,
      surname,
      phone,
      email,
      address,
      description,
      amka,
      date ?? Timestamp.now(),
    ];
  }

  @override
  bool get stringify => true;

  AppointMent copyWith({
    String? id,
    String? name,
    String? surname,
    String? phone,
    String? email,
    String? address,
    String? description,
    String? amka,
    Timestamp? date,
  }) {
    return AppointMent(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      description: description ?? this.description,
      amka: amka ?? this.amka,
      date: date ?? this.date,
    );
  }

  // Map<String, dynamic> toMap() {
  //   return <String, dynamic>{
  //     'id': id,
  //     'name': name,
  //     'surname': surname,
  //     'phone': phone,
  //     'email': email,
  //     'address': address,
  //     'description': description,
  //     'date': date?.millisecondsSinceEpoch,
  //   };
  // }

  // factory AppointMent.fromMap(Map<String, dynamic> map) {
  //   return AppointMent(
  //     id: map['id'] != null ? map['id'] as String : '',
  //     name: map['name'] as String,
  //     surname: map['surname'] as String,
  //     phone: map['phone'] as String,
  //     email: map['email'] as String,
  //     address: map['address'] as String,
  //     description: map['description'] as String,
  //     date: map['date'] != null ? map['date'] as Timestamp : null,
  //   );
  // }

  // String toJson() => json.encode(toMap());

  // factory AppointMent.fromJson(String source) =>
  //     AppointMent.fromMap(json.decode(source) as Map<String, dynamic>);
}
