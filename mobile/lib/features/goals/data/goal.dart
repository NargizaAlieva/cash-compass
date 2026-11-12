import 'package:equatable/equatable.dart';

/// Something the student saves money for, with a forecast from the server.
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.percent,
    required this.achieved,
    this.monthsLeft,
    this.forecastDate,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final forecast = json['forecast_date'] as String?;
    return Goal(
      id: json['id'] as int,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      savedAmount: (json['saved_amount'] as num).toDouble(),
      percent: (json['percent'] as num).toDouble(),
      achieved: json['achieved'] as bool,
      monthsLeft: json['months_left'] as int?,
      forecastDate: forecast == null ? null : DateTime.parse(forecast),
    );
  }

  final int id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final double percent;
  final bool achieved;

  /// null = the user does not save anything now, so no forecast.
  final int? monthsLeft;
  final DateTime? forecastDate;

  double get remaining =>
      (targetAmount - savedAmount).clamp(0, double.infinity).toDouble();

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        savedAmount,
        percent,
        achieved,
        monthsLeft,
        forecastDate,
      ];
}

/// Response of GET /goals.
class GoalsOverview extends Equatable {
  const GoalsOverview({required this.monthlySaving, required this.goals});

  factory GoalsOverview.fromJson(Map<String, dynamic> json) => GoalsOverview(
        monthlySaving: (json['monthly_saving'] as num).toDouble(),
        goals: (json['goals'] as List<dynamic>)
            .map((g) => Goal.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  /// Average (income - expenses) of the last 3 full months.
  final double monthlySaving;
  final List<Goal> goals;

  @override
  List<Object?> get props => [monthlySaving, goals];
}

/// What the user typed in the goal dialog.
class GoalDraft extends Equatable {
  const GoalDraft({
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
  });

  final String name;
  final double targetAmount;
  final double savedAmount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
      };

  @override
  List<Object?> get props => [name, targetAmount, savedAmount];
}

/// How many months are needed to collect [remaining] when saving
/// [monthlySaving] a month. null when nothing is saved.
int? monthsToCollect(double remaining, double monthlySaving) {
  if (remaining <= 0) {
    return 0;
  }
  if (monthlySaving <= 0) {
    return null;
  }
  return (remaining / monthlySaving).ceil();
}
