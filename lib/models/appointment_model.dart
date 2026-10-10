import 'package:equatable/equatable.dart';

import 'app_timestamp.dart';

class AppointmentServiceLine extends Equatable {
  final String id;
  final String serviceId;
  final String serviceName;
  final String category;
  final String subcategory;
  final String employeeId;
  final String employeeName;
  final double price;
  final int durationMinutes;

  const AppointmentServiceLine({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.subcategory,
    required this.employeeId,
    required this.employeeName,
    required this.price,
    required this.durationMinutes,
  });

  factory AppointmentServiceLine.fromJson(Map<String, dynamic> json) {
    final employee = Map<String, dynamic>.from(
      (json['employee'] ?? const <String, dynamic>{}) as Map,
    );
    return AppointmentServiceLine(
      id: (json['id'] ?? '').toString(),
      serviceId: (json['service_id'] ?? '').toString(),
      serviceName: (json['service_name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subcategory: (json['subcategory'] ?? '').toString(),
      employeeId: (json['employee_uuid'] ?? '').toString(),
      employeeName:
          '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
              .trim(),
      price: num.tryParse((json['price'] ?? 0).toString())?.toDouble() ?? 0,
      durationMinutes:
          num.tryParse((json['duration_minutes'] ?? 0).toString())?.round() ??
              0,
    );
  }

  @override
  List<Object> get props => [
        id,
        serviceId,
        serviceName,
        category,
        subcategory,
        employeeId,
        employeeName,
        price,
        durationMinutes,
      ];
}

class AppointmentPaymentEntry extends Equatable {
  final String id;
  final double amount;
  final String method;
  final Timestamp paidAt;

  const AppointmentPaymentEntry({
    required this.id,
    required this.amount,
    required this.method,
    required this.paidAt,
  });

  factory AppointmentPaymentEntry.fromJson(Map<String, dynamic> json) {
    return AppointmentPaymentEntry(
      id: (json['id'] ?? '').toString(),
      amount: num.tryParse((json['amount'] ?? 0).toString())?.toDouble() ?? 0,
      method: (json['method'] ?? '').toString(),
      paidAt: Timestamp.fromJson(json['paid_at']),
    );
  }

  @override
  List<Object> get props => [id, amount, method, paidAt];
}

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
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final int totalDurationMinutes;
  final String notes;
  final List<AppointmentServiceLine> serviceItems;
  final List<AppointmentPaymentEntry> payments;
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
    this.status = 'scheduled',
    this.paymentStatus = 'unpaid',
    this.totalPrice = 0,
    this.totalDurationMinutes = 0,
    this.notes = '',
    this.serviceItems = const [],
    this.payments = const [],
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
      status: (json['status'] ?? 'scheduled').toString(),
      paymentStatus: (json['payment_status'] ?? 'unpaid').toString(),
      totalPrice:
          num.tryParse((json['total_price'] ?? 0).toString())?.toDouble() ?? 0,
      totalDurationMinutes:
          num.tryParse((json['total_duration_minutes'] ?? 0).toString())
                  ?.round() ??
              0,
      notes: (json['notes'] ?? '').toString(),
      serviceItems: ((json['service_items'] ?? const []) as List)
          .map((item) => AppointmentServiceLine.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      payments: ((json['payments'] ?? const []) as List)
          .map((item) => AppointmentPaymentEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
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
      status: 'scheduled',
      paymentStatus: 'unpaid',
      totalPrice: 0,
      totalDurationMinutes: 0,
      notes: '',
      serviceItems: const [],
      payments: const [],
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
      status,
      paymentStatus,
      totalPrice,
      totalDurationMinutes,
      notes,
      serviceItems,
      payments,
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
    String? status,
    String? paymentStatus,
    double? totalPrice,
    int? totalDurationMinutes,
    String? notes,
    List<AppointmentServiceLine>? serviceItems,
    List<AppointmentPaymentEntry>? payments,
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
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      notes: notes ?? this.notes,
      serviceItems: serviceItems ?? this.serviceItems,
      payments: payments ?? this.payments,
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
