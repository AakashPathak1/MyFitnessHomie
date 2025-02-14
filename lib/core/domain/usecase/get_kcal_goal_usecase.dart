import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

class GetKcalGoalUsecase {
  final UserRepository _userRepository;
  final ConfigRepository _configRepository;
  final UserActivityRepository _userActivityRepository;

  GetKcalGoalUsecase(
      this._userRepository, this._configRepository, this._userActivityRepository);

  Future<double> getKcalGoal() async {
    final config = await _configRepository.getConfig();
    final totalKcalActivities = (await _userActivityRepository.getAllUserActivityByDate(DateTime.now()))
        .map((activity) => activity.burnedKcal)
        .toList()
        .sum;
    
    // Get the user's total goal (default to 2000 if not set) and add activities
    return CalorieGoalCalc.getTotalKcalGoal(
        config.userKcalGoal ?? 2000,
        totalKcalActivities);
  }
}
