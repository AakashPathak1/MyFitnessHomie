import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  group('Calorie Goal Calc Test', () {
    late UserEntity youngSedentaryMaleWantingToMaintainWeight;
    late UserEntity middleAgedActiveFemaleWantingToLoseWeight;

    setUp(() {
      youngSedentaryMaleWantingToMaintainWeight =
          UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
      middleAgedActiveFemaleWantingToLoseWeight =
          UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;
    });

    test(
        'Total Kcal Goal calculation for a young sedentary male wanting to maintain weight',
        () {
      final user = youngSedentaryMaleWantingToMaintainWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(2000.0, 200.0);

      // Base goal: 2000, Activities: 200
      // 2000 + 200 = 2200
      int expectedKcal = 2200;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });

    test(
        'Total Kcal Goal calculation for a middle aged sedentary female wanting to maintain weight',
        () {
      final user = middleAgedActiveFemaleWantingToLoseWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(1800.0, 550.0);

      // Base goal: 1800, Activities: 550
      // 1800 + 550 = 2350
      int expectedKcal = 2350;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });
  });
}
