import 'package:equatable/equatable.dart';

class ServiceOffering extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subcategory;
  final double price;
  final int durationMinutes;
  final bool isActive;

  const ServiceOffering({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  factory ServiceOffering.fromJson(Map<String, dynamic> json) {
    return ServiceOffering(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subcategory: (json['subcategory'] ?? '').toString(),
      price: num.tryParse((json['price'] ?? 0).toString())?.toDouble() ?? 0,
      durationMinutes:
          num.tryParse((json['duration_minutes'] ?? 30).toString())?.round() ??
              30,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'duration_minutes': durationMinutes,
        'is_active': isActive,
      };

  @override
  List<Object> get props => [
        id,
        name,
        description,
        category,
        subcategory,
        price,
        durationMinutes,
        isActive,
      ];
}

class StoreStation extends Equatable {
  final String id;
  final String name;
  final int capacity;
  final bool isActive;

  const StoreStation({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isActive,
  });

  factory StoreStation.fromJson(Map<String, dynamic> json) => StoreStation(
        id: (json['uuid'] ?? '').toString(),
        name: (json['description'] ?? '').toString(),
        capacity:
            num.tryParse((json['max_persons'] ?? 1).toString())?.round() ?? 1,
        isActive: json['is_active'] != false,
      );

  @override
  List<Object> get props => [id, name, capacity, isActive];
}

class ReportMetric extends Equatable {
  final String id;
  final String name;
  final int count;
  final double value;

  const ReportMetric({
    required this.id,
    required this.name,
    required this.count,
    required this.value,
  });

  factory ReportMetric.fromJson(Map<String, dynamic> json) => ReportMetric(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        count: num.tryParse((json['count'] ?? 0).toString())?.round() ?? 0,
        value: num.tryParse((json['value'] ?? 0).toString())?.toDouble() ?? 0,
      );

  @override
  List<Object> get props => [id, name, count, value];
}
