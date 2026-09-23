class SettingModel {
  final String key;
  final String value;
  final DateTime updatedAt;

  SettingModel({
    required this.key,
    required this.value,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      key: map['key'] as String,
      value: map['value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SettingModel copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return SettingModel(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
