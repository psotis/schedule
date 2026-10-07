import 'package:equatable/equatable.dart';

import 'app_timestamp.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class AppointMent extends Equatable {
  final String id;
  final String name;
  final String surname;
  final String phone;
  final String email;
  final String address;
  final List<String>? description;
  final String amka;
  final Timestamp? date;
  final String? employee;
  final String? position;
  final String? owes;
  final String? birthday;
  final String? allo;
  final String? startingDate;
  final String? mainIssue;
  final String? doctor;
  final String? surgeryPast;
  final String? surgeryNow;
  final String? pharmacy;
  final String? allergies;
  final String? spot;
  final String? missFunctions;
  final int? paid;
  final bool? heart;
  final bool? breathe;
  final bool? sugar;
  final bool? ypertash;
  final bool? neuro;
  final bool? orthopedic;
  final bool? selfCare;
  final bool? helpCare;
  final bool? disabled;
  final bool? good;
  final bool? medium;
  final bool? bad;
  final bool? yes;
  final bool? no;

  AppointMent({
    required this.id,
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
    required this.address,
    this.description,
    required this.amka,
    this.date,
    this.employee,
    this.position,
    this.owes,
    this.birthday,
    this.allo,
    this.startingDate,
    this.mainIssue,
    this.doctor,
    this.surgeryPast,
    this.surgeryNow,
    this.pharmacy,
    this.allergies,
    this.spot,
    this.missFunctions,
    this.paid,
    this.heart,
    this.breathe,
    this.sugar,
    this.ypertash,
    this.neuro,
    this.orthopedic,
    this.selfCare,
    this.helpCare,
    this.disabled,
    this.good,
    this.medium,
    this.bad,
    this.yes,
    this.no,
  });

  factory AppointMent.fromJson(Map<String, dynamic> json) {
    final client = Map<String, dynamic>.from(
      (json['client_record'] ?? json) as Map,
    );
    final customFields = Map<String, dynamic>.from(
      (client['custom_fields'] ?? <String, dynamic>{}) as Map,
    );
    final rawDate = json['start_time'] ?? json['date'];
    return AppointMent(
      id: (json['uuid'] ?? client['uuid'] ?? '').toString(),
      name: (client['first_name'] ?? '').toString(),
      surname: (client['last_name'] ?? '').toString(),
      phone: (client['phone'] ?? '').toString(),
      email: (client['email'] ?? '').toString(),
      address: (client['address'] ?? '').toString(),
      description: List<String>.from(client['client_description'] ?? const []),
      amka: (client['amka'] ?? '').toString(),
      date: rawDate == null ? null : Timestamp.fromJson(rawDate),
      employee: json['employee']?.toString(),
      position: json['position_description']?.toString(),
      owes: (client['owes'] ?? '').toString(),
      birthday: customFields['birthday']?.toString(),
      allo: customFields['allo']?.toString(),
      startingDate: customFields['startingDate']?.toString(),
      mainIssue: customFields['mainIssue']?.toString(),
      doctor: customFields['doctor']?.toString(),
      surgeryPast: customFields['surgeryPast']?.toString(),
      surgeryNow: customFields['surgeryNow']?.toString(),
      pharmacy: customFields['pharmacy']?.toString(),
      allergies: customFields['allergies']?.toString(),
      spot: customFields['spot']?.toString(),
      missFunctions: customFields['missFunctions']?.toString(),
      paid: (num.tryParse((json['paid'] ?? 0).toString()) ?? 0).round(),
      heart: customFields['heart'] == true,
      breathe: customFields['breathe'] == true,
      sugar: customFields['sugar'] == true,
      ypertash: customFields['ypertash'] == true,
      neuro: customFields['neuro'] == true,
      orthopedic: customFields['orthopedic'] == true,
      selfCare: customFields['selfCare'] == true,
      helpCare: customFields['helpCare'] == true,
      disabled: customFields['disabled'] == true,
      good: customFields['good'] == true,
      medium: customFields['medium'] == true,
      bad: customFields['bad'] == true,
      yes: customFields['yes'] == true,
      no: customFields['no'] == true,
    );
  }

  factory AppointMent.initial() {
    return AppointMent(
      id: '',
      name: '',
      surname: '',
      phone: '',
      email: '',
      address: '',
      description: <String>[],
      amka: '',
      date: Timestamp.now(),
      employee: '',
      position: '',
      owes: '',
      birthday: '',
      allo: '',
      startingDate: '',
      mainIssue: '',
      doctor: '',
      surgeryPast: '',
      surgeryNow: '',
      pharmacy: '',
      allergies: '',
      spot: '',
      missFunctions: '',
      paid: 0,
      heart: false,
      breathe: false,
      sugar: false,
      ypertash: false,
      neuro: false,
      orthopedic: false,
      selfCare: false,
      helpCare: false,
      disabled: false,
      good: false,
      medium: false,
      bad: false,
      yes: false,
      no: false,
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
      description ?? [''],
      amka,
      date ?? Timestamp.now(),
      employee ?? '',
      position ?? '',
      owes ?? '',
      birthday ?? '',
      allo ?? '',
      startingDate ?? '',
      mainIssue ?? '',
      doctor ?? '',
      surgeryPast ?? '',
      surgeryNow ?? '',
      pharmacy ?? '',
      allergies ?? '',
      spot ?? '',
      missFunctions ?? '',
      paid ?? 0,
      heart ?? false,
      breathe ?? false,
      sugar ?? false,
      ypertash ?? false,
      neuro ?? false,
      orthopedic ?? false,
      selfCare ?? false,
      helpCare ?? false,
      disabled ?? false,
      good ?? false,
      medium ?? false,
      bad ?? false,
      yes ?? false,
      no ?? false,
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
    List<String>? description,
    String? amka,
    Timestamp? date,
    String? employee,
    String? position,
    String? owes,
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
    int? paid,
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
      employee: employee ?? this.employee,
      position: position ?? this.position,
      owes: owes ?? this.owes,
      birthday: birthday ?? this.birthday,
      allo: allo ?? this.allo,
      startingDate: startingDate ?? this.startingDate,
      mainIssue: mainIssue ?? this.mainIssue,
      doctor: doctor ?? this.doctor,
      surgeryPast: surgeryPast ?? this.surgeryPast,
      surgeryNow: surgeryNow ?? this.surgeryNow,
      pharmacy: pharmacy ?? this.pharmacy,
      allergies: allergies ?? this.allergies,
      spot: spot ?? this.spot,
      missFunctions: missFunctions ?? this.missFunctions,
      paid: paid ?? this.paid,
      heart: heart ?? this.heart,
      breathe: breathe ?? this.breathe,
      sugar: sugar ?? this.sugar,
      ypertash: ypertash ?? this.ypertash,
      neuro: neuro ?? this.neuro,
      orthopedic: orthopedic ?? this.orthopedic,
      selfCare: selfCare ?? this.selfCare,
      helpCare: helpCare ?? this.helpCare,
      disabled: disabled ?? this.disabled,
      good: good ?? this.good,
      medium: medium ?? this.medium,
      bad: bad ?? this.bad,
      yes: yes ?? this.yes,
      no: no ?? this.no,
    );
  }
}
