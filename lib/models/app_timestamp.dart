import 'package:equatable/equatable.dart';

class Timestamp extends Equatable implements Comparable<Timestamp> {
  final DateTime _value;

  const Timestamp._(this._value);

  factory Timestamp.fromDate(DateTime value) => Timestamp._(value);

  factory Timestamp.fromMicrosecondsSinceEpoch(int value) =>
      Timestamp._(DateTime.fromMicrosecondsSinceEpoch(value));

  factory Timestamp.now() => Timestamp._(DateTime.now());

  factory Timestamp.fromJson(Object? value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      return Timestamp.fromDate(DateTime.parse(value).toLocal());
    }
    if (value is num) {
      return Timestamp.fromMicrosecondsSinceEpoch(value.toInt());
    }
    return Timestamp.fromMicrosecondsSinceEpoch(0);
  }

  DateTime toDate() => _value;

  String toIso8601String() => _value.toUtc().toIso8601String();

  @override
  int compareTo(Timestamp other) => _value.compareTo(other._value);

  @override
  List<Object> get props => [_value];
}
