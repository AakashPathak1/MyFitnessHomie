import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CalculationsDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;

  const CalculationsDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
  });

  @override
  State<CalculationsDialog> createState() => _CalculationsDialogState();
}

class _CalculationsDialogState extends State<CalculationsDialog> {
  final TextEditingController _calorieController = TextEditingController();
  int _calorieGoal = 2000; // Default value

  static const double _defaultCarbsPctSelection = 0.6;
  static const double _defaultFatPctSelection = 0.25;
  static const double _defaultProteinPctSelection = 0.15;

  // Macros percentages
  double _carbsPctSelection = _defaultCarbsPctSelection * 100;
  double _proteinPctSelection = _defaultProteinPctSelection * 100;
  double _fatPctSelection = _defaultFatPctSelection * 100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSettings();
  }

  void _initializeSettings() async {
    final userCarbsPct = await widget.settingsBloc.getUserCarbGoalPct();
    final userProteinPct = await widget.settingsBloc.getUserProteinGoalPct();
    final userFatPct = await widget.settingsBloc.getUserFatGoalPct();
    final totalKcalGoal = await widget.settingsBloc.getTotalKcalGoal();

    // Initialize calorie goal from user settings
    _calorieGoal = totalKcalGoal.toInt();
    _calorieController.text = _calorieGoal.toString();

    if (!mounted) return;

    setState(() {
      // Ensure values are at least 5%
      _carbsPctSelection =
          ((userCarbsPct ?? _defaultCarbsPctSelection) * 100).clamp(5, 90);
      _proteinPctSelection =
          ((userProteinPct ?? _defaultProteinPctSelection) * 100).clamp(5, 90);
      _fatPctSelection =
          ((userFatPct ?? _defaultFatPctSelection) * 100).clamp(5, 90);

      // Normalize to ensure total is 100%
      _normalizeMacros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Goals',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                // Reset calorie goal to default
                _calorieGoal = 2000;
                _calorieController.text = _calorieGoal.toString();
                // Reset macros to default values
                _carbsPctSelection = _defaultCarbsPctSelection * 100;
                _proteinPctSelection = _defaultProteinPctSelection * 100;
                _fatPctSelection = _defaultFatPctSelection * 100;
              });
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: TextField(
                controller: _calorieController,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: InputDecoration(
                  labelText: 'Daily Calorie Goal',
                  labelStyle: Theme.of(context).textTheme.titleMedium,
                  suffixText: 'kcal',
                  suffixStyle: Theme.of(context).textTheme.titleMedium,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _calorieGoal = int.tryParse(value) ?? _calorieGoal;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                'Macro Distribution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildMacroSlider(
              label: S.of(context).carbsLabel,
              value: _carbsPctSelection,
              color: Colors.orange,
              onChanged: (value) {
                setState(() {
                  double delta = value - _carbsPctSelection;
                  _carbsPctSelection = value;

                  // Adjust other percentages proportionally
                  double proteinRatio = _proteinPctSelection /
                      (_proteinPctSelection + _fatPctSelection);
                  double fatRatio = _fatPctSelection /
                      (_proteinPctSelection + _fatPctSelection);

                  _proteinPctSelection -= delta * proteinRatio;
                  _fatPctSelection -= delta * fatRatio;

                  // Ensure no value goes below 5%
                  if (_proteinPctSelection < 5) {
                    double overflow = 5 - _proteinPctSelection;
                    _proteinPctSelection = 5;
                    _fatPctSelection -= overflow;
                  }
                  if (_fatPctSelection < 5) {
                    double overflow = 5 - _fatPctSelection;
                    _fatPctSelection = 5;
                    _proteinPctSelection -= overflow;
                  }
                });
              },
            ),
            _buildMacroSlider(
              label: S.of(context).proteinLabel,
              value: _proteinPctSelection,
              color: Colors.blue,
              onChanged: (value) {
                setState(() {
                  double delta = value - _proteinPctSelection;
                  _proteinPctSelection = value;

                  double carbsRatio = _carbsPctSelection /
                      (_carbsPctSelection + _fatPctSelection);
                  double fatRatio = _fatPctSelection /
                      (_carbsPctSelection + _fatPctSelection);

                  _carbsPctSelection -= delta * carbsRatio;
                  _fatPctSelection -= delta * fatRatio;

                  if (_carbsPctSelection < 5) {
                    double overflow = 5 - _carbsPctSelection;
                    _carbsPctSelection = 5;
                    _fatPctSelection -= overflow;
                  }
                  if (_fatPctSelection < 5) {
                    double overflow = 5 - _fatPctSelection;
                    _fatPctSelection = 5;
                    _carbsPctSelection -= overflow;
                  }
                });
              },
            ),
            _buildMacroSlider(
              label: S.of(context).fatLabel,
              value: _fatPctSelection,
              color: Colors.green,
              onChanged: (value) {
                setState(() {
                  double delta = value - _fatPctSelection;
                  _fatPctSelection = value;

                  double carbsRatio = _carbsPctSelection /
                      (_carbsPctSelection + _proteinPctSelection);
                  double proteinRatio = _proteinPctSelection /
                      (_carbsPctSelection + _proteinPctSelection);

                  _carbsPctSelection -= delta * carbsRatio;
                  _proteinPctSelection -= delta * proteinRatio;

                  if (_carbsPctSelection < 5) {
                    double overflow = 5 - _carbsPctSelection;
                    _carbsPctSelection = 5;
                    _proteinPctSelection -= overflow;
                  }
                  if (_proteinPctSelection < 5) {
                    double overflow = 5 - _proteinPctSelection;
                    _proteinPctSelection = 5;
                    _carbsPctSelection -= overflow;
                  }
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => _saveCalculationSettings(),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    // Calculate grams based on percentage and total calories
    double caloriesFromMacro = _calorieGoal * (value / 100);
    double grams;

    // Convert calories to grams based on macro type
    if (label == S.of(context).carbsLabel) {
      grams = caloriesFromMacro / 4; // 4 calories per gram of carbs
    } else if (label == S.of(context).proteinLabel) {
      grams = caloriesFromMacro / 4; // 4 calories per gram of protein
    } else {
      grams = caloriesFromMacro / 9; // 9 calories per gram of fat
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${value.round()}% (${grams.round()}g)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 340,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
              ),
              child: Slider(
                min: 5,
                max: 90,
                value: value,
                divisions: 85,
                onChanged: (value) {
                  final newValue = value.round().toDouble();
                  if (100 - newValue >= 10) {
                    onChanged(newValue);
                    _normalizeMacros();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _normalizeMacros() {
    // First, ensure all values are rounded and clamped
    _carbsPctSelection = _carbsPctSelection.clamp(5.0, 90.0).roundToDouble();
    _proteinPctSelection =
        _proteinPctSelection.clamp(5.0, 90.0).roundToDouble();
    _fatPctSelection = _fatPctSelection.clamp(5.0, 90.0).roundToDouble();

    // Calculate total
    double total = _carbsPctSelection + _proteinPctSelection + _fatPctSelection;

    // If total isn't 100, adjust values proportionally
    if (total != 100) {
      double factor = 100 / total;

      // Adjust all values proportionally
      _carbsPctSelection =
          (_carbsPctSelection * factor).clamp(5.0, 90.0).roundToDouble();
      _proteinPctSelection =
          (_proteinPctSelection * factor).clamp(5.0, 90.0).roundToDouble();
      _fatPctSelection =
          (_fatPctSelection * factor).clamp(5.0, 90.0).roundToDouble();

      // Final adjustment to ensure total is exactly 100%
      total = _carbsPctSelection + _proteinPctSelection + _fatPctSelection;
      if (total != 100) {
        double diff = 100 - total;
        // Add the difference to the largest value
        if (_carbsPctSelection >= _proteinPctSelection &&
            _carbsPctSelection >= _fatPctSelection) {
          _carbsPctSelection += diff;
        } else if (_proteinPctSelection >= _carbsPctSelection &&
            _proteinPctSelection >= _fatPctSelection) {
          _proteinPctSelection += diff;
        } else {
          _fatPctSelection += diff;
        }
      }
    }

    setState(() {}); // Trigger rebuild with normalized values
  }

  Future<void> _saveCalculationSettings() async {
    if (!mounted) return;

    try {
      // Save the calorie goal and macro goals
      await widget.settingsBloc.setTotalKcalGoal(_calorieGoal.toDouble());
      await widget.settingsBloc.setMacroGoals(
          _carbsPctSelection, _proteinPctSelection, _fatPctSelection);

      // Wait for tracked day to update first
      await widget.settingsBloc.updateTrackedDay(DateTime.now());

      // Update all necessary blocs to refresh the UI
      widget.settingsBloc.add(LoadSettingsEvent());
      widget.profileBloc.add(LoadProfileEvent());

      // Update home and diary blocs after a small delay to ensure config is loaded
      await Future.delayed(const Duration(milliseconds: 100));
      widget.homeBloc.add(LoadItemsEvent());
      widget.calendarDayBloc.add(LoadCalendarDayEvent(DateTime.now()));
      widget.diaryBloc.add(LoadDiaryYearEvent());

      // Close the dialog
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    }
  }
}
