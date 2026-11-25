class CustomerField {
  CustomerField.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      key = json['field_key'].toString(),
      label = json['label'].toString(),
      type = json['data_type'].toString(),
      group = (json['field_group'] ?? 'custom').toString(),
      active = json['is_active'] == true,
      defaultValue = json['default_value'],
      settings = Map<String, dynamic>.from(json['settings'] ?? const {}),
      options = ((json['options'] ?? const []) as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  final String id, key, label, type, group;
  final bool active;
  final dynamic defaultValue;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> options;
  bool get isPreference => group != 'custom';
}
