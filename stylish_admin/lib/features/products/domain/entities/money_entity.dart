import 'package:equatable/equatable.dart';

class MoneyEntity extends Equatable {
  final double value;
  final String? currency;

  const MoneyEntity({required this.value,  this.currency});

  @override 
  List<Object?> get props => [value, currency];


  MoneyEntity copyWith({
    double? value, 
    String? currency, 
  }) {
    return MoneyEntity(value: value??this.value, currency: currency??this.currency);
  }
  
}