import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  SettingsBloc(
      this._getConfigUsecase,
      this._addConfigUsecase,
      this._addTrackedDayUsecase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase)
      : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final userConfig = await _getConfigUsecase.getConfig();
      final appVersion = await AppConst.getVersionNumber();
      final usesImperialUnits = userConfig.usesImperialUnits;

      emit(SettingsLoadedState(
          appVersion,
          userConfig.hasAcceptedSendAnonymousData,
          userConfig.appTheme,
          usesImperialUnits));
    });
  }

  void setHasAcceptedAnonymousData(bool hasAcceptedAnonymousData) {
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }

  void setUsesImperialUnits(bool usesImperialUnits) {
    _addConfigUsecase.setConfigUsesImperialUnits(usesImperialUnits);
  }

  Future<double> getTotalKcalGoal() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userKcalGoal ?? 2000;  // Default to 2000 if not set
  }

  Future<double?> getUserCarbGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userCarbGoalPct;
  }

  Future<double?> getUserProteinGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userProteinGoalPct;
  }

  Future<double?> getUserFatGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userFatGoalPct;
  }

  Future<void> setTotalKcalGoal(double totalKcalGoal) async {
    await _addConfigUsecase.setConfigKcalGoal(totalKcalGoal);
  }
  Future<void> setMacroGoals(
      double carbGoalPct, double proteinGoalPct, double fatGoalPct) async {
    // Values are already in percentage (0-100), convert to decimal (0-1)
    await _addConfigUsecase.setConfigMacroGoalPct(
        carbGoalPct / 100,
        proteinGoalPct / 100,
        fatGoalPct / 100);
  }

  Future<void> updateTrackedDay(DateTime day) async {
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal =
        await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
    final totalProteinGoal =
        await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);

    if (hasTrackedDay) {
      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
      await _addTrackedDayUsecase.updateDayMacroGoals(day,
          carbsGoal: totalCarbsGoal,
          fatGoal: totalFatGoal,
          proteinGoal: totalProteinGoal);
    }
  }
}

enum SystemDropDownType { metric, imperial }
