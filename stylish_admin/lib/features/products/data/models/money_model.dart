import 'package:stylish_admin/features/products/domain/entities/money_entity.dart';

class MoneyModel extends MoneyEntity {
  const MoneyModel({required super.value, super.currency = 'USD'});

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    double value;

    if (json.containsKey('value')) {
      value = _parseMoneyValue(json['value']);
    } else if (json.containsKey('amount')) {
      value = _parseMoneyValue(json['amount']);
    } else {
      value = 0.0;
    }

    return MoneyModel(
      value: value,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  static double _parseMoneyValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'currency': currency};
  }

  MoneyEntity toDomain() {
    return MoneyEntity(value: value, currency: currency);
  }
}
