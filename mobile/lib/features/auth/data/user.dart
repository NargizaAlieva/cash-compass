import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.stipendDay,
    this.stipendAmount,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        stipendDay: json['stipend_day'] as int?,
        stipendAmount: (json['stipend_amount'] as num?)?.toDouble(),
      );

  final int id;
  final String email;
  final String name;
  final int? stipendDay;
  final double? stipendAmount;

  @override
  List<Object?> get props => [id, email, name, stipendDay, stipendAmount];
}